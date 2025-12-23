import Foundation
import AppKit

class StorageManager {
    private static let settingsKey = "appSettings"
    
    static func saveSettings(_ settings: AppSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return decoded
    }
    
    static func hasConfiguredDirectory() -> Bool {
        return loadSettings().vaultDirectory != nil
    }
}
