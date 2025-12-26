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
                    .font(NoterTypography.sectionHeader)
                    .foregroundStyle(.primary)

                Spacer()

                if isProcessing {
                    HStack(spacing: NoterSpacing.xs) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Processing...")
                            .font(NoterTypography.captionSmall)
                            .foregroundStyle(.secondary)
                    }
                } else if !items.isEmpty {
                    HStack(spacing: NoterSpacing.sm) {
                        NoterButton("Retry All", style: .secondary) {
                            retryAll()
                        }

                        NoterButton("Clear", style: .destructive) {
                            showClearConfirmation = true
                        }
                    }
                }
            }
            .padding(.horizontal, NoterSpacing.lg)
            .padding(.vertical, NoterSpacing.md)

            NoterDivider()

            // Content
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            } else if items.isEmpty {
                NoterEmptyStateCompact(
                    icon: "tray",
                    message: "Queue is empty"
                )
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
                                NoterDivider(inset: NoterSpacing.md)
                            }
                        }
                    }
                    .padding(.vertical, NoterSpacing.xs)
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

    private var isExpandable: Bool {
        item.text.count > 50 || item.lastError != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(alignment: .top, spacing: NoterSpacing.sm + NoterSpacing.xxs) {
                // Status icon with shape differentiation
                StatusIndicator(item.canRetry ? .pending : .error, size: NoterIconSize.sm)
                    .frame(width: NoterSpacing.lg)

                // Content
                VStack(alignment: .leading, spacing: NoterSpacing.xs) {
                    Text(item.truncatedText)
                        .font(NoterTypography.body)
                        .foregroundStyle(.primary)
                        .lineLimit(isExpanded ? nil : 2)

                    HStack(spacing: NoterSpacing.sm) {
                        Text(item.displayDate)
                            .font(NoterTypography.captionSmall)
                            .foregroundStyle(.tertiary)

                        Text(item.retryStatusText)
                            .font(.system(size: NoterIconSize.xs, weight: .medium))
                            .foregroundStyle(item.canRetry ? NoterColors.Status.warning : NoterColors.Status.error)
                    }
                }

                Spacer()

                // Actions - always visible for accessibility
                HStack(spacing: NoterSpacing.xs) {
                    NoterIconButton(icon: "trash", style: .destructive, help: "Remove from queue") {
                        onDelete()
                    }
                }
                .alwaysVisibleActions(isHovered: isHovered, isExpanded: isExpanded)

                // Expand indicator
                if isExpandable {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: NoterIconSize.xs))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, NoterSpacing.sm + NoterSpacing.xxs)
            .padding(.horizontal, NoterSpacing.md)
            .contentShape(Rectangle())
            .onTapGesture {
                if isExpandable {
                    withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
                        isExpanded.toggle()
                    }
                }
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: NoterSpacing.sm) {
                    // Full text
                    Text(item.text)
                        .font(NoterTypography.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(NoterSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(NoterColors.surfaceSubtle)
                        .cornerRadius(NoterRadius.md)

                    // Error message
                    if let error = item.lastError {
                        HStack(spacing: NoterSpacing.xs + NoterSpacing.xxs) {
                            StatusIndicator(.error, size: NoterIconSize.xs)
                            Text(error)
                                .font(NoterTypography.captionSmall)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Actions
                    HStack(spacing: NoterSpacing.md) {
                        if item.canRetry {
                            NoterButton("Retry", icon: "arrow.clockwise", style: .secondary) {
                                onRetry()
                            }
                        }

                        Spacer()
                    }
                }
                .padding(.horizontal, NoterSpacing.md)
                .padding(.bottom, NoterSpacing.sm + NoterSpacing.xxs)
            }
        }
        .background(isHovered ? NoterColors.surfaceSubtle : Color.clear)
        .cornerRadius(NoterRadius.lg)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    QueueListView()
        .frame(width: 380, height: 400)
}
