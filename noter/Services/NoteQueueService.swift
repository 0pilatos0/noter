import Foundation
import Combine

/// Thread-safe service for managing the offline note queue
actor NoteQueueService {
    static let shared = NoteQueueService()

    private var queue: [QueuedNote] = []
    private var isProcessing = false
    private let fileURL: URL

    /// Publisher for queue count changes
    nonisolated let queueCountPublisher = CurrentValueSubject<Int, Never>(0)

    private init() {
        // Set up file URL in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let noterDir = appSupport.appendingPathComponent("noter", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: noterDir, withIntermediateDirectories: true)

        fileURL = noterDir.appendingPathComponent("queue.json")

        // Load existing queue
        Task {
            await load()
        }
    }

    // MARK: - Public API

    /// Add a note to the queue
    func enqueue(_ note: QueuedNote) {
        queue.append(note)
        updatePublisher()
        Task {
            try? await persist()
        }

        // Also add to history as queued
        Task {
            await HistoryService.shared.add(NoteHistoryItem(
                originalText: note.text,
                status: .queued,
                vaultPath: note.vaultPath
            ))
        }
    }

    /// Get all queued notes
    func getAll() -> [QueuedNote] {
        queue
    }

    /// Get queue count
    var count: Int {
        queue.count
    }

    /// Remove a note from the queue
    func removeItem(_ id: UUID) {
        queue.removeAll { $0.id == id }
        updatePublisher()
        Task {
            try? await persist()
        }
    }

    /// Clear the entire queue
    func clearQueue() {
        queue.removeAll()
        updatePublisher()
        Task {
            try? await persist()
        }
    }

    /// Process all queued notes
    func processQueue() async {
        guard !isProcessing else { return }
        guard !queue.isEmpty else { return }

        isProcessing = true
        defer { isProcessing = false }

        // Process each item
        var processedIds: [UUID] = []
        var updatedItems: [QueuedNote] = []

        for note in queue {
            guard note.canRetry else {
                // Skip permanently failed items
                continue
            }

            do {
                try await attemptSubmission(note)
                processedIds.append(note.id)

                // Update history status to processed
                await HistoryService.shared.updateStatus(note.id, status: .processed)

            } catch {
                // Update retry count
                let updated = note.withIncrementedRetry(error: error.localizedDescription)
                updatedItems.append(updated)

                // If max retries reached, update history to failed
                if !updated.canRetry {
                    await HistoryService.shared.updateStatus(note.id, status: .failed)
                }
            }

            // Small delay between attempts
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        // Remove processed items
        for id in processedIds {
            queue.removeAll { $0.id == id }
        }

        // Update failed items with new retry count
        for updated in updatedItems {
            if let index = queue.firstIndex(where: { $0.id == updated.id }) {
                queue[index] = updated
            }
        }

        updatePublisher()
        try? await persist()

        // Post notification if items were processed
        if !processedIds.isEmpty {
            await MainActor.run {
                NotificationCenter.default.post(name: .queueItemsProcessed, object: processedIds.count)
            }
        }
    }

    /// Retry a specific item
    func retryItem(_ id: UUID) async {
        guard let note = queue.first(where: { $0.id == id }) else { return }
        guard note.canRetry else { return }

        do {
            try await attemptSubmission(note)
            removeItem(id)
            await HistoryService.shared.updateStatus(id, status: .processed)
        } catch {
            // Update retry count
            if let index = queue.firstIndex(where: { $0.id == id }) {
                queue[index] = note.withIncrementedRetry(error: error.localizedDescription)
                try? await persist()
            }
        }
    }

    /// Check if queue is currently processing
    var processing: Bool {
        isProcessing
    }

    // MARK: - Private Methods

    private func attemptSubmission(_ note: QueuedNote) async throws {
        let vaultURL = URL(fileURLWithPath: note.vaultPath)

        let (stream, _, getResult) = await MainActor.run {
            OpenCodeService.addNoteStreaming(
                note.text,
                in: vaultURL,
                opencodePath: note.opencodePath,
                model: note.model
            )
        }

        // Consume the stream
        for try await _ in stream {
            // Just consume, don't need to display
        }

        // Check final result
        let result = try await getResult()
        if let errorMessage = result.error {
            throw QueueSubmissionError.failed(errorMessage)
        }
    }

    enum QueueSubmissionError: LocalizedError {
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .failed(let message):
                return message
            }
        }
    }

    private func updatePublisher() {
        let currentCount = queue.count
        Task { @MainActor in
            queueCountPublisher.send(currentCount)
        }
    }

    // MARK: - Persistence

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(queue)
        try data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            queue = try decoder.decode([QueuedNote].self, from: data)
            updatePublisher()
        } catch {
            print("NoteQueueService: Failed to load queue: \(error)")
            queue = []
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let queueItemsProcessed = Notification.Name("queueItemsProcessed")
}

// MARK: - Non-isolated convenience methods

extension NoteQueueService {
    /// Convenience method to enqueue a failed note
    nonisolated func enqueueFailedNote(
        text: String,
        vaultPath: String,
        model: String,
        opencodePath: String,
        error: String
    ) {
        Task {
            await enqueue(QueuedNote(
                text: text,
                lastError: error,
                vaultPath: vaultPath,
                model: model,
                opencodePath: opencodePath
            ))
        }
    }
}
