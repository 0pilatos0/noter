import SwiftUI

// MARK: - NoterEmptyState
/// Reusable empty state component for lists and sections
struct NoterEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: NoterEmptyStateAction?

    struct NoterEmptyStateAction {
        let title: String
        let icon: String?
        let handler: () -> Void

        init(_ title: String, icon: String? = nil, handler: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.handler = handler
        }
    }

    init(
        icon: String,
        title: String,
        subtitle: String,
        action: NoterEmptyStateAction? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: NoterSpacing.md) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: NoterIconSize.heroLarge))
                .foregroundStyle(.secondary.opacity(0.6))

            Text(title)
                .font(NoterTypography.header)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(NoterTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if let action = action {
                NoterButton(action.title, icon: action.icon, style: .primary) {
                    action.handler()
                }
                .padding(.top, NoterSpacing.sm)
            }

            Spacer()
        }
        .padding(NoterSpacing.lg)
    }
}

// MARK: - NoterEmptyStateCompact
/// Compact empty state for inline/smaller contexts
struct NoterEmptyStateCompact: View {
    let icon: String
    let message: String

    init(icon: String, message: String) {
        self.icon = icon
        self.message = message
    }

    var body: some View {
        VStack(spacing: NoterSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: NoterIconSize.hero))
                .foregroundStyle(.tertiary)

            Text(message)
                .font(NoterTypography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NoterSpacing.xl)
    }
}

// MARK: - Previews
#Preview("Empty States") {
    VStack(spacing: 32) {
        NoterEmptyState(
            icon: "folder.badge.questionmark",
            title: "No Directory Configured",
            subtitle: "Please configure your Obsidian vault in Settings",
            action: .init("Go to Settings", icon: "gear") {}
        )
        .frame(height: 250)
        .border(Color.gray.opacity(0.3))

        NoterEmptyStateCompact(
            icon: "clock",
            message: "No history yet"
        )
        .border(Color.gray.opacity(0.3))
    }
    .padding()
    .frame(width: 350)
}
