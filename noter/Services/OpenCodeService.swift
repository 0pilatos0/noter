import Foundation

/// Result of a streaming operation
struct StreamResult {
    let output: String
    let error: String?
}

/// Handle for cancelling an in-progress note operation
class NoteOperationHandle {
    private let process: Process
    private(set) var isCancelled = false
    
    init(process: Process) {
        self.process = process
    }
    
    func cancel() {
        guard process.isRunning else { return }
        isCancelled = true
        process.terminate()
    }
}

class OpenCodeService {
    /// Adds a note with streaming output - yields chunks as they arrive from opencode
    /// Returns a stream, a cancel handle, and a function to get the final result
    static func addNoteStreaming(
        _ note: String,
        in directory: URL,
        opencodePath: String = "/usr/local/bin/opencode",
        model: String = "opencode/big-pickle"
    ) -> (stream: AsyncThrowingStream<String, Error>, handle: NoteOperationHandle, getResult: () async throws -> StreamResult) {
        let currentDate = DateFormatter.noteDateFormatter.string(from: Date())
        let currentTime = DateFormatter.noteTimeFormatter.string(from: Date())
        
        let prompt = """
        Add this note to today's daily note (\(currentDate)). Current time: \(currentTime).
        
        The user's raw input is:
        \(note)
        
        ## Instructions
        
        ### Content Processing
        - Refine and format the note following the conventions in claude.md
        - Fix any typos, grammar issues, or unclear phrasing
        - Keep the original meaning and intent intact
        - Use active voice and short, concise sentences
        - Be concise but complete
        - Do NOT add timestamps unless the user explicitly mentions a time or asks for one
        
        ### Grouping & Organization
        - Check if the daily note already has a relevant section for this content (e.g., "Tasks", "Meetings", "Ideas", "Notes")
        - If a relevant section exists, add the note there instead of appending to the end
        - Group related items together: tasks with tasks, meeting notes with meetings, ideas with ideas
        - If adding multiple items, keep them together under the appropriate section
        - If no relevant section exists and the note doesn't fit existing sections, append to the end
        
        ### Markdown Structure
        - Preserve the existing markdown structure of the daily note
        - Do not create duplicate headings - use existing ones
        - Maintain consistent heading hierarchy (## for main sections, ### for subsections)
        - Ensure proper spacing: one blank line before headings, no trailing whitespace
        - Keep list indentation consistent with the rest of the document
        - Do not leave orphaned or empty sections
        
        ### Formatting
        - Use `- [ ]` for action items and tasks
        - Use `- [x]` for completed tasks
        - Use bullet points (`-`) for lists and notes
        - Use bold (**text**) sparingly for emphasis
        - Add relevant tags using #tag format where appropriate
        - Add internal links using [[Note Name]] syntax for related concepts, people, or projects
        - Creating new links is encouraged even if the target page doesn't exist yet
        
        ### Output
        - Do not add unnecessary commentary, just add the refined note
        - Do not repeat or summarize what you did - just make the changes
        """
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: opencodePath)
        process.arguments = ["run", "--model", model, prompt]
        process.currentDirectoryURL = directory
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        let handle = NoteOperationHandle(process: process)
        
        // Accumulated data for final result
        var accumulatedOutput = ""
        var accumulatedError = ""
        var streamError: Error?
        
        // Create continuation for final result
        var resultContinuation: CheckedContinuation<StreamResult, Error>?
        
        let stream = AsyncThrowingStream<String, Error> { continuation in
            // Set up stdout streaming
            outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if data.isEmpty {
                    // EOF reached
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                } else if let chunk = String(data: data, encoding: .utf8) {
                    accumulatedOutput += chunk
                    continuation.yield(chunk)
                }
            }
            
            // Collect stderr (not streamed, just accumulated)
            errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if data.isEmpty {
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                } else if let chunk = String(data: data, encoding: .utf8) {
                    accumulatedError += chunk
                }
            }
            
            // Handle process termination
            process.terminationHandler = { proc in
                // Clean up handlers
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                
                // Read any remaining data
                let remainingOutput = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let remainingError = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if let chunk = String(data: remainingOutput, encoding: .utf8), !chunk.isEmpty {
                    accumulatedOutput += chunk
                    continuation.yield(chunk)
                }
                if let chunk = String(data: remainingError, encoding: .utf8), !chunk.isEmpty {
                    accumulatedError += chunk
                }
                
                // Check if cancelled
                if handle.isCancelled {
                    let error = OpenCodeError.cancelled
                    streamError = error
                    continuation.finish(throwing: error)
                    resultContinuation?.resume(throwing: error)
                } else if proc.terminationStatus != 0 {
                    let error = OpenCodeError.executionFailed(accumulatedError)
                    streamError = error
                    continuation.finish(throwing: error)
                    resultContinuation?.resume(throwing: error)
                } else {
                    continuation.finish()
                    resultContinuation?.resume(returning: StreamResult(
                        output: accumulatedOutput,
                        error: accumulatedError.isEmpty ? nil : accumulatedError
                    ))
                }
            }
            
            // Start the process
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try process.run()
                } catch {
                    streamError = error
                    continuation.finish(throwing: error)
                    resultContinuation?.resume(throwing: error)
                }
            }
        }
        
        // Function to await final result
        let getResult: () async throws -> StreamResult = {
            if let error = streamError {
                throw error
            }
            return try await withCheckedThrowingContinuation { continuation in
                resultContinuation = continuation
            }
        }
        
        return (stream, handle, getResult)
    }
    
    static func checkOpencodeInstalled(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    enum OpenCodeError: LocalizedError {
        case executionFailed(String)
        case pathNotFound(String)
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .executionFailed(let message):
                return "Opencode execution failed: \(message)"
            case .pathNotFound(let path):
                return "File not found: \(path)"
            case .cancelled:
                return "Operation cancelled"
            }
        }
    }
}

extension DateFormatter {
    static let noteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let noteTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
