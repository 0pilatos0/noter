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
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if !items.isEmpty {
                    Button(action: { showClearConfirmation = true }) {
                        Text("Clear All")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear all history")
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
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)

                    Text("No history yet")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text("Your captured notes will appear here")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
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
