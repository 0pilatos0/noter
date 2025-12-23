import Foundation

struct AppSettings: Codable {
    var vaultDirectory: URL?
    var opencodePath: String = "/usr/local/bin/opencode"
}
