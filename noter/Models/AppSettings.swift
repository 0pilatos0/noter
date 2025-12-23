import Foundation
import ServiceManagement

enum LaunchAtLoginError: LocalizedError {
    case registrationFailed(Error)
    case unregistrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .registrationFailed(let error):
            return "Failed to enable launch at login: \(error.localizedDescription)"
        case .unregistrationFailed(let error):
            return "Failed to disable launch at login: \(error.localizedDescription)"
        }
    }
}

struct AppSettings: Codable {
    var vaultDirectory: URL?
    var opencodePath: String = "/usr/local/bin/opencode"
    var model: String = "opencode/big-pickle"
    var launchAtLogin: Bool = false
    
    /// Default available models for quick selection
    static let defaultModels = [
        "opencode/big-pickle",
        "anthropic/claude-sonnet-4-20250514",
        "anthropic/claude-3-5-haiku-20241022",
        "openai/gpt-4o",
        "openai/gpt-4o-mini"
    ]
    
    /// Updates the system launch-at-login setting to match the stored preference
    /// Returns an error if the operation fails
    static func syncLaunchAtLogin(_ enabled: Bool) -> Result<Void, LaunchAtLoginError> {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return .success(())
        } catch {
            if enabled {
                return .failure(.registrationFailed(error))
            } else {
                return .failure(.unregistrationFailed(error))
            }
        }
    }
    
    /// Returns the current system state for launch at login
    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    /// Validates that a directory is an Obsidian vault by checking for .obsidian folder
    static func isValidObsidianVault(_ url: URL) -> Bool {
        let obsidianFolder = url.appendingPathComponent(".obsidian")
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: obsidianFolder.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
