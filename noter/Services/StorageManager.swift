import Foundation
import AppKit

enum StorageError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode settings"
        case .decodingFailed:
            return "Failed to decode settings"
        case .saveFailed(let error):
            return "Failed to save settings: \(error.localizedDescription)"
        }
    }
}

class StorageManager {
    private static let settingsKey = "appSettings"
    
    /// Notification posted when settings are saved successfully
    static let settingsSavedNotification = Notification.Name("StorageManagerSettingsSaved")
    
    /// Notification posted when settings save fails
    static let settingsSaveFailedNotification = Notification.Name("StorageManagerSettingsSaveFailed")
    
    static func saveSettings(_ settings: AppSettings) -> Result<Void, StorageError> {
        do {
            let encoded = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(encoded, forKey: settingsKey)
            NotificationCenter.default.post(name: settingsSavedNotification, object: nil)
            return .success(())
        } catch {
            NotificationCenter.default.post(
                name: settingsSaveFailedNotification, 
                object: nil, 
                userInfo: ["error": StorageError.encodingFailed]
            )
            return .failure(.encodingFailed)
        }
    }
    
    static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            return AppSettings()
        }
        
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            // Log but return defaults - don't crash on corrupted settings
            print("Warning: Failed to decode settings, using defaults: \(error)")
            return AppSettings()
        }
    }
    
    static func hasConfiguredDirectory() -> Bool {
        return loadSettings().vaultDirectory != nil
    }
}
