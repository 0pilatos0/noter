import SwiftUI

// MARK: - NoterCard
/// Unified card component with consistent styling
struct NoterCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let hasStroke: Bool

    init(
        padding: CGFloat = NoterSpacing.md,
        hasStroke: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.hasStroke = hasStroke
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(NoterColors.surfaceSubtle)
            .cornerRadius(NoterRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: NoterRadius.xl)
                    .stroke(hasStroke ? NoterColors.strokeSubtle : .clear, lineWidth: 1)
            )
    }
}

// MARK: - NoterInputCard
/// Card specifically designed for input areas (like TextEditor)
struct NoterInputCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(NoterColors.surfaceSubtle)
            .cornerRadius(NoterRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: NoterRadius.xl)
                    .stroke(NoterColors.strokeSubtle, lineWidth: 1)
            )
    }
}

// MARK: - NoterInfoCard
/// Info/tip card with icon and message
struct NoterInfoCard: View {
    let icon: String
    let message: String
    let style: Style

    enum Style {
        case info
        case warning
        case success
        case error
    }

    init(icon: String = "info.circle", message: String, style: Style = .info) {
        self.icon = icon
        self.message = message
        self.style = style
    }

    var body: some View {
        HStack(alignment: .top, spacing: NoterSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: NoterIconSize.sm))
                .foregroundStyle(iconColor)

            Text(message)
                .font(NoterTypography.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding(NoterSpacing.md)
        .background(backgroundColor)
        .cornerRadius(NoterRadius.lg)
    }

    private var iconColor: Color {
        switch style {
        case .info: return NoterColors.Status.info
        case .warning: return NoterColors.Status.warning
        case .success: return NoterColors.Status.success
        case .error: return NoterColors.Status.error
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .info: return NoterColors.Status.infoBackground
        case .warning: return NoterColors.Status.warningBackground
        case .success: return NoterColors.Status.successBackground
        case .error: return NoterColors.Status.errorBackground
        }
    }
}

// MARK: - Previews
#Preview("Cards") {
    VStack(spacing: 16) {
        NoterCard {
            Text("Default card with padding and stroke")
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        NoterCard(padding: NoterSpacing.lg, hasStroke: false) {
            Text("Card with larger padding, no stroke")
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        NoterInfoCard(message: "This is an informational tip for the user.")
        NoterInfoCard(icon: "exclamationmark.triangle", message: "Warning message", style: .warning)
        NoterInfoCard(icon: "checkmark.circle", message: "Success message", style: .success)
    }
    .padding()
    .frame(width: 350)
}
