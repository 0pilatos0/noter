import SwiftUI

struct HistoryView: View {
    @State private var items: [NoteHistoryItem] = []
    @State private var isLoading = true
    @State private var showClearConfirmation = false

    var onUseNote: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(NoterTypography.sectionHeader)
                    .foregroundStyle(.primary)

                Spacer()

                if !items.isEmpty {
                    NoterButton("Clear All", style: .tertiary) {
                        showClearConfirmation = true
                    }
                    .help("Clear all history")
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
                    icon: "clock",
                    message: "No history yet"
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            HistoryItemRow(
                                item: item,
                                onUseAgain: {
                                    onUseNote?(item.originalText)
                                },
                                onDelete: {
                                    deleteItem(item.id)
                                }
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
            await loadHistory()
        }
        .confirmationDialog(
            "Clear History",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all history items.")
        }
    }

    private func loadHistory() async {
        isLoading = true
        items = await HistoryService.shared.getAll()
        isLoading = false
    }

    private func deleteItem(_ id: UUID) {
        withAnimation {
            items.removeAll { $0.id == id }
        }
        Task {
            await HistoryService.shared.delete(id)
        }
    }

    private func clearHistory() {
        withAnimation {
            items.removeAll()
        }
        Task {
            await HistoryService.shared.clearAll()
        }
    }
}

#Preview {
    HistoryView()
        .frame(width: 380, height: 400)
}
