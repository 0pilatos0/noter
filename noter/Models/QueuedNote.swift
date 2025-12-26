import Foundation

struct QueuedNote: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: Date
    var retryCount: Int
    var lastError: String?
    let vaultPath: String
    let model: String
    let opencodePath: String

    init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        retryCount: Int = 0,
        lastError: String? = nil,
        vaultPath: String,
        model: String,
        opencodePath: String
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.retryCount = retryCount
        self.lastError = lastError
        self.vaultPath = vaultPath
        self.model = model
        self.opencodePath = opencodePath
    }

    // MARK: - Display Helpers

    var displayDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var truncatedText: String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        if firstLine.count > 50 {
            return String(firstLine.prefix(50)) + "..."
        }
        return firstLine
    }

    var retryStatusText: String {
        if retryCount == 0 {
            return "Pending"
        } else if retryCount >= 5 {
            return "Failed permanently"
        } else {
            return "Retry \(retryCount)/5"
        }
    }

    var canRetry: Bool {
        retryCount < 5
    }

    /// Create an updated copy with incremented retry count
    func withIncrementedRetry(error: String? = nil) -> QueuedNote {
        QueuedNote(
            id: id,
            text: text,
            timestamp: timestamp,
            retryCount: retryCount + 1,
            lastError: error,
            vaultPath: vaultPath,
            model: model,
            opencodePath: opencodePath
        )
    }
}
