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

        ### First: Understand the Vault
        Before making changes, explore the vault to understand its structure:
        1. Check CLAUDE.md (if it exists) for vault-specific conventions and guidelines
        2. Read today's daily note to understand its current structure and sections
        3. Look for a People/ directory to find existing person notes for linking
        4. Look for common project/documentation folders to find linkable notes

        ### Content Processing
        - Refine and format the note (fix typos, grammar, unclear phrasing)
        - Keep the original meaning and intent intact
        - Use active voice and concise sentences
        - Do NOT add timestamps unless explicitly requested

        ### Intelligent Section Placement
        - Read the existing daily note to identify its sections
        - Place content in the most appropriate existing section:
          - Tasks/accomplishments → task-related sections (e.g., "Goals", "Done", "Tasks")
          - Problems/obstacles → blocker-related sections (e.g., "Blockers", "Issues")
          - General notes → notes/misc sections
        - If no relevant section exists, append to the end
        - Never create duplicate headings - use existing ones

        ### Smart Linking
        - When names are mentioned, check if a matching note exists in People/ (or similar directory)
        - Link to existing notes using [[Note Name]] syntax
        - Before creating a link, verify the target note exists or is a reasonable new page
        - Prefer full names for people links (e.g., [[John Smith]] not [[John]])

        ### Markdown Structure
        - Preserve the existing markdown structure of the daily note
        - Maintain consistent heading hierarchy
        - Keep list indentation consistent with the rest of the document
        - Preserve any footer patterns (tags, backlinks, separators)

        ### Output
        - Just make the changes - no commentary or summaries
        - Do not repeat or summarize what you did
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
