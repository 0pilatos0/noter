import SwiftUI
import Combine

struct QueueListView: View {
    @State private var items: [QueuedNote] = []
    @State private var isLoading = true
    @State private var isProcessing = false
    @State private var showClearConfirmation = false
    @State private var cancellable: AnyCancellable?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Queued Notes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if isProcessing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Processing...")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                } else if !items.isEmpty {
                    HStack(spacing: 8) {
                        Button(action: retryAll) {
                            Text("Retry All")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)

                        Button(action: { showClearConfirmation = true }) {
                            Text("Clear")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Content
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if items.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)

                    Text("Queue is empty")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text("Failed notes will appear here for retry")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            QueueItemRow(
                                item: item,
                                onRetry: { retryItem(item.id) },
                                onDelete: { deleteItem(item.id) }
                            )

                            if item.id != items.last?.id {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task {
            await loadQueue()
        }
        .onAppear {
            observeQueue()
        }
        .confirmationDialog(
            "Clear Queue",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                clearQueue()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all queued notes.")
        }
    }

    private func loadQueue() async {
        isLoading = true
        items = await NoteQueueService.shared.getAll()
        isLoading = false
    }

    private func observeQueue() {
        cancellable = NoteQueueService.shared.queueCountPublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                Task {
                    items = await NoteQueueService.shared.getAll()
                }
            }
    }

    private func retryAll() {
        isProcessing = true
        Task {
            await NoteQueueService.shared.processQueue()
            await MainActor.run {
                isProcessing = false
            }
        }
    }

    private func retryItem(_ id: UUID) {
        Task {
            await NoteQueueService.shared.retryItem(id)
        }
    }

    private func deleteItem(_ id: UUID) {
        withAnimation {
            items.removeAll { $0.id == id }
        }
        Task {
            await NoteQueueService.shared.removeItem(id)
        }
    }

    private func clearQueue() {
        withAnimation {
            items.removeAll()
        }
        Task {
            await NoteQueueService.shared.clearQueue()
        }
    }
}

// MARK: - Queue Item Row

struct QueueItemRow: View {
    let item: QueuedNote
    let onRetry: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(alignment: .top, spacing: 10) {
                // Status icon
                Image(systemName: item.canRetry ? "clock.fill" : "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(item.canRetry ? .orange : .red)
                    .frame(width: 16)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.truncatedText)
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .lineLimit(isExpanded ? nil : 2)

                    HStack(spacing: 8) {
                        Text(item.displayDate)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)

                        Text(item.retryStatusText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(item.canRetry ? .orange : .red)
                    }
                }

                Spacer()

                // Expand indicator
                if item.text.count > 50 || item.lastError != nil {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Full text
                    Text(item.text)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(6)

                    // Error message
                    if let error = item.lastError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                    }

                    // Actions
                    HStack(spacing: 12) {
                        if item.canRetry {
                            Button(action: onRetry) {
                                Label("Retry", systemImage: "arrow.clockwise")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        Spacer()

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Remove from queue")
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
            }
        }
        .background(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    QueueListView()
        .frame(width: 380, height: 400)
}
