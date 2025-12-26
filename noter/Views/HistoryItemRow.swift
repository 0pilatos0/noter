import SwiftUI

struct HistoryItemRow: View {
    let item: NoteHistoryItem
    let onUseAgain: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row content
            HStack(alignment: .top, spacing: 10) {
                // Status icon
                Image(systemName: item.statusIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(statusColor)
                    .frame(width: 16)

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.truncatedText)
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .lineLimit(isExpanded ? nil : 2)

                    Text(item.fullDisplayDate)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Expand/collapse indicator
                if item.originalText.count > 60 || item.originalText.contains("\n") {
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
                    Text(item.originalText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(6)

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: onUseAgain) {
                            Label("Use Again", systemImage: "arrow.uturn.left")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer()

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Delete from history")
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

    private var statusColor: Color {
        switch item.status {
        case .processed:
            return .green
        case .failed:
            return .red
        case .queued:
            return .orange
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        HistoryItemRow(
            item: NoteHistoryItem(
                originalText: "This is a short note",
                status: .processed,
                vaultPath: "/path/to/vault"
            ),
            onUseAgain: {},
            onDelete: {}
        )

        Divider()

        HistoryItemRow(
            item: NoteHistoryItem(
                originalText: "This is a much longer note that spans multiple lines and should be truncated in the preview but shown in full when expanded. It contains a lot of text to demonstrate the truncation behavior.",
                status: .failed,
                vaultPath: "/path/to/vault"
            ),
            onUseAgain: {},
            onDelete: {}
        )
    }
    .frame(width: 350)
    .padding()
}
