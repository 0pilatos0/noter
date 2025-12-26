import SwiftUI

// MARK: - NoterExpandableRow
/// Reusable expandable row component with consistent styling and accessibility
struct NoterExpandableRow<Header: View, Content: View, Actions: View>: View {
    let header: Header
    let content: Content
    let actions: Actions
    let isExpandable: Bool

    @State private var isExpanded = false
    @State private var isHovered = false

    init(
        isExpandable: Bool = true,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions
    ) {
        self.isExpandable = isExpandable
        self.header = header()
        self.content = content()
        self.actions = actions()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(alignment: .top, spacing: NoterSpacing.sm) {
                header

                Spacer()

                // Actions always visible for accessibility
                actions
                    .alwaysVisibleActions(isHovered: isHovered, isExpanded: isExpanded)

                if isExpandable {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: NoterIconSize.xs))
                        .foregroundStyle(.tertiary)
                        .frame(width: 16)
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
                    content
                }
                .padding(.horizontal, NoterSpacing.md)
                .padding(.bottom, NoterSpacing.sm)
            }
        }
        .background(isHovered ? NoterColors.surfaceSubtle : .clear)
        .cornerRadius(NoterRadius.lg)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Convenience initializers

extension NoterExpandableRow where Actions == EmptyView {
    init(
        isExpandable: Bool = true,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            isExpandable: isExpandable,
            header: header,
            content: content,
            actions: { EmptyView() }
        )
    }
}

extension NoterExpandableRow where Content == EmptyView {
    init(
        isExpandable: Bool = false,
        @ViewBuilder header: () -> Header,
        @ViewBuilder actions: () -> Actions
    ) {
        self.init(
            isExpandable: isExpandable,
            header: header,
            content: { EmptyView() },
            actions: actions
        )
    }
}

// MARK: - NoterSimpleRow
/// Non-expandable row for simple list items
struct NoterSimpleRow<Content: View, Actions: View>: View {
    let content: Content
    let actions: Actions

    @State private var isHovered = false

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions
    ) {
        self.content = content()
        self.actions = actions()
    }

    var body: some View {
        HStack(spacing: NoterSpacing.sm) {
            content

            Spacer()

            actions
                .alwaysVisibleActions(isHovered: isHovered)
        }
        .padding(.vertical, NoterSpacing.sm)
        .padding(.horizontal, NoterSpacing.md)
        .background(isHovered ? NoterColors.surfaceSubtle : .clear)
        .cornerRadius(NoterRadius.lg)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Previews
#Preview("Expandable Rows") {
    VStack(spacing: 0) {
        NoterExpandableRow {
            HStack(spacing: NoterSpacing.sm) {
                StatusIndicator(.success)
                VStack(alignment: .leading, spacing: NoterSpacing.xs) {
                    Text("This is a note title")
                        .font(NoterTypography.body)
                    Text("2 hours ago")
                        .font(NoterTypography.captionSmall)
                        .foregroundStyle(.tertiary)
                }
            }
        } content: {
            Text("This is the expanded content with more details about the item.")
                .font(NoterTypography.caption)
                .foregroundStyle(.secondary)
                .padding(NoterSpacing.sm)
                .background(NoterColors.surfaceSubtle)
                .cornerRadius(NoterRadius.md)
        } actions: {
            NoterIconButton(icon: "trash", style: .destructive, help: "Delete") {}
        }

        NoterDivider(inset: NoterSpacing.md)

        NoterExpandableRow {
            HStack(spacing: NoterSpacing.sm) {
                StatusIndicator(.error)
                VStack(alignment: .leading, spacing: NoterSpacing.xs) {
                    Text("Failed note")
                        .font(NoterTypography.body)
                    Text("Yesterday")
                        .font(NoterTypography.captionSmall)
                        .foregroundStyle(.tertiary)
                }
            }
        } content: {
            Text("Error details would go here")
                .font(NoterTypography.caption)
                .foregroundStyle(.secondary)
        } actions: {
            HStack(spacing: NoterSpacing.xs) {
                NoterButton("Retry", icon: "arrow.clockwise", style: .secondary) {}
                NoterIconButton(icon: "trash", style: .destructive, help: "Delete") {}
            }
        }
    }
    .padding()
    .frame(width: 350)
}
