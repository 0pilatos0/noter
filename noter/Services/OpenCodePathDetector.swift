import Foundation

class OpenCodePathDetector {

    private static let commonPaths = [
        "/opt/homebrew/bin/opencode",
        "/usr/local/bin/opencode",
        NSHomeDirectory() + "/.local/bin/opencode",
        NSHomeDirectory() + "/bin/opencode",
        "/usr/bin/opencode"
    ]

    /// Detects OpenCode path using `which` command first, then common paths
    static func detectPath() async -> String? {
        if let path = await runWhich() {
            return path
        }
        return checkCommonPaths()
    }

    private static func runWhich() async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                process.arguments = ["opencode"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    guard process.terminationStatus == 0 else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let path = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if let path = path, isExecutable(at: path) {
                        continuation.resume(returning: path)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private static func checkCommonPaths() -> String? {
        commonPaths.first { isExecutable(at: $0) }
    }

    private static func isExecutable(at path: String) -> Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }
}
