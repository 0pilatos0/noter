import Foundation

/// Result of a streaming operation
struct StreamResult {
    let output: String
    let error: String?
}

class OpenCodeService {
    /// Adds a note with streaming output - yields chunks as they arrive from opencode
    static func addNoteStreaming(
        _ note: String,
        in directory: URL,
        opencodePath: String = "/usr/local/bin/opencode"
    ) -> (stream: AsyncThrowingStream<String, Error>, getResult: () async throws -> StreamResult) {
        let currentDate = DateFormatter.noteDateFormatter.string(from: Date())
        let currentTime = DateFormatter.noteTimeFormatter.string(from: Date())
        
        let prompt = """
        Add this note to today's daily note (\(currentDate)). Current time: \(currentTime).
        
        The user's raw input is:
        \(note)
        
        Instructions:
        - Refine and format the note following the conventions in claude.md
        - Fix any typos, grammar issues, or unclear phrasing
        - Keep the original meaning and intent intact
        - Use active voice and short, concise sentences
        - Use appropriate formatting based on content type:
          - `- [ ]` for action items and tasks
          - Bullet points for lists
          - Bold (**text**) sparingly for emphasis
        - Add relevant tags using #tag format where appropriate
        - Add internal links using [[Note Name]] syntax for related concepts, people, or projects
        - Creating new links is encouraged even if the target page doesn't exist yet
        - If it's a task completion, mark it appropriately
        - If it's a blocker or issue, format it clearly
        - Be concise but complete
        - Do not add unnecessary commentary, just add the refined note
        """
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "\(opencodePath) run --model opencode/big-pickle \"\(prompt)\""]
        process.currentDirectoryURL = directory
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Accumulated data for final result
        var accumulatedOutput = ""
        var accumulatedError = ""
        var streamError: Error?
        
        // Create continuation for final result
        var resultContinuation: CheckedContinuation<StreamResult, Error>?
        
        let stream = AsyncThrowingStream<String, Error> { continuation in
            // Set up stdout streaming
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    // EOF reached
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                } else if let chunk = String(data: data, encoding: .utf8) {
                    accumulatedOutput += chunk
                    continuation.yield(chunk)
                }
            }
            
            // Collect stderr (not streamed, just accumulated)
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
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
                
                if proc.terminationStatus != 0 {
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
        
        return (stream, getResult)
    }
    
    static func checkOpencodeInstalled(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    enum OpenCodeError: LocalizedError {
        case executionFailed(String)
        case pathNotFound(String)
        
        var errorDescription: String? {
            switch self {
            case .executionFailed(let message):
                return "Opencode execution failed: \(message)"
            case .pathNotFound(let path):
                return "File not found: \(path)"
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
