import Foundation

struct NoteHistoryItem: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let originalText: String
    let status: NoteStatus
    let vaultPath: String
    let outputPreview: String?

    enum NoteStatus: String, Codable {
        case processed
        case failed
        case queued
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        originalText: String,
        status: NoteStatus,
        vaultPath: String,
        outputPreview: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.originalText = originalText
        self.status = status
        self.vaultPath = vaultPath
        self.outputPreview = outputPreview
    }

    // MARK: - Display Helpers

    var displayDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var fullDisplayDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(timestamp) {
            formatter.dateFormat = "'Today' HH:mm"
        } else if Calendar.current.isDateInYesterday(timestamp) {
            formatter.dateFormat = "'Yesterday' HH:mm"
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
        }
        return formatter.string(from: timestamp)
    }

    var truncatedText: String {
        let firstLine = originalText.components(separatedBy: .newlines).first ?? originalText
        if firstLine.count > 60 {
            return String(firstLine.prefix(60)) + "..."
        }
        return firstLine
    }

    var statusIcon: String {
        switch status {
        case .processed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .queued:
            return "clock.fill"
        }
    }

    var statusColor: String {
        switch status {
        case .processed:
            return "green"
        case .failed:
            return "red"
        case .queued:
            return "orange"
        }
    }
}
