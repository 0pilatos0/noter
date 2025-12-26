import SwiftUI

struct HistoryItemRow: View {
    let item: NoteHistoryItem
    let onUseAgain: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var isHovered = false

    private var isExpandable: Bool {
        item.originalText.count > 60 || item.originalText.contains("\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row content
            HStack(alignment: .top, spacing: NoterSpacing.sm + NoterSpacing.xxs) {
                // Status icon with shape differentiation for accessibility
                StatusIndicator(statusIndicatorType, size: NoterIconSize.sm)
                    .frame(width: NoterSpacing.lg)

                // Text content
                VStack(alignment: .leading, spacing: NoterSpacing.xs) {
                    Text(item.truncatedText)
                        .font(NoterTypography.body)
                        .foregroundStyle(.primary)
                        .lineLimit(isExpanded ? nil : 2)

                    Text(item.fullDisplayDate)
                        .font(NoterTypography.captionSmall)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Actions - always visible for accessibility
                HStack(spacing: NoterSpacing.xs) {
                    NoterIconButton(icon: "trash", style: .destructive, help: "Delete from history") {
                        onDelete()
                    }
                }
                .alwaysVisibleActions(isHovered: isHovered, isExpanded: isExpanded)

                // Expand/collapse indicator
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
                    // Full text in a card
                    Text(item.originalText)
                        .font(NoterTypography.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(NoterSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(NoterColors.surfaceSubtle)
                        .cornerRadius(NoterRadius.md)

                    // Action buttons
                    HStack(spacing: NoterSpacing.md) {
                        NoterButton("Use Again", icon: "arrow.uturn.left", style: .secondary) {
                            onUseAgain()
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

    private var statusIndicatorType: StatusIndicator.Status {
        switch item.status {
        case .processed:
            return .success
        case .failed:
            return .error
        case .queued:
            return .pending
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

        NoterDivider(inset: NoterSpacing.md)

        HistoryItemRow(
            item: NoteHistoryItem(
                originalText: "This is a much longer note that spans multiple lines and should be truncated in the preview but shown in full when expanded. It contains a lot of text to demonstrate the truncation behavior.",
                status: .failed,
                vaultPath: "/path/to/vault"
            ),
            onUseAgain: {},
            onDelete: {}
        )

        NoterDivider(inset: NoterSpacing.md)

        HistoryItemRow(
            item: NoteHistoryItem(
                originalText: "Queued note waiting to be processed",
                status: .queued,
                vaultPath: "/path/to/vault"
            ),
            onUseAgain: {},
            onDelete: {}
        )
    }
    .frame(width: 350)
    .padding()
}
