import Foundation

class OpenCodeService {
    static func addNote(_ note: String, in directory: URL, opencodePath: String = "/usr/local/bin/opencode") async throws -> String {
        let currentDate = DateFormatter.noteDateFormatter.string(from: Date())
        let prompt = "Add this note to today's daily note (\(currentDate)): \(note)"
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "\(opencodePath) run --model opencode/big-pickle \"\(prompt)\""]
        process.currentDirectoryURL = directory
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let error = String(data: errorData, encoding: .utf8) ?? ""
                    
                    if process.terminationStatus != 0 {
                        continuation.resume(throwing: OpenCodeError.executionFailed(error))
                    } else {
                        continuation.resume(returning: output)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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
}
