import Foundation
import ServiceManagement

struct AppSettings: Codable {
    var vaultDirectory: URL?
    var opencodePath: String = "/usr/local/bin/opencode"
    var launchAtLogin: Bool = false
    
    /// Updates the system launch-at-login setting to match the stored preference
    static func syncLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
    
    /// Returns the current system state for launch at login
    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
