import Foundation

/// Thread-safe service for managing note history
actor HistoryService {
    static let shared = HistoryService()

    private let maxItems = 50
    private var items: [NoteHistoryItem] = []
    private let fileURL: URL

    private init() {
        // Set up file URL in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let noterDir = appSupport.appendingPathComponent("noter", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: noterDir, withIntermediateDirectories: true)

        fileURL = noterDir.appendingPathComponent("history.json")

        // Load existing history
        Task {
            await load()
        }
    }

    // MARK: - Public API

    /// Add a new history item
    func add(_ item: NoteHistoryItem) {
        items.insert(item, at: 0)

        // Trim to max items
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        Task {
            try? await persist()
        }
    }

    /// Get all history items
    func getAll() -> [NoteHistoryItem] {
        items
    }

    /// Get history item by ID
    func get(_ id: UUID) -> NoteHistoryItem? {
        items.first { $0.id == id }
    }

    /// Delete a history item
    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        Task {
            try? await persist()
        }
    }

    /// Clear all history
    func clearAll() {
        items.removeAll()
        Task {
            try? await persist()
        }
    }

    /// Update an item's status
    func updateStatus(_ id: UUID, status: NoteHistoryItem.NoteStatus) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }

        let item = items[index]
        items[index] = NoteHistoryItem(
            id: item.id,
            timestamp: item.timestamp,
            originalText: item.originalText,
            status: status,
            vaultPath: item.vaultPath,
            outputPreview: item.outputPreview
        )

        Task {
            try? await persist()
        }
    }

    /// Get count of history items
    var count: Int {
        items.count
    }

    // MARK: - Persistence

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([NoteHistoryItem].self, from: data)
        } catch {
            print("HistoryService: Failed to load history: \(error)")
            items = []
        }
    }
}

// MARK: - Non-isolated convenience methods

extension HistoryService {
    /// Convenience method to add a processed note
    nonisolated func addProcessedNote(
        text: String,
        vaultPath: String,
        outputPreview: String? = nil
    ) {
        Task {
            await add(NoteHistoryItem(
                originalText: text,
                status: .processed,
                vaultPath: vaultPath,
                outputPreview: outputPreview
            ))
        }
    }

    /// Convenience method to add a failed note
    nonisolated func addFailedNote(
        text: String,
        vaultPath: String
    ) {
        Task {
            await add(NoteHistoryItem(
                originalText: text,
                status: .failed,
                vaultPath: vaultPath
            ))
        }
    }
}
