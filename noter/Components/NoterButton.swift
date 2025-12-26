import SwiftUI

// MARK: - Button Style Hierarchy
enum NoterButtonStyle {
    case primary      // Most important action - filled accent color
    case secondary    // Secondary actions - subtle background with stroke
    case tertiary     // Minimal actions - plain with hover state
    case destructive  // Delete/remove actions - red tint
}

// MARK: - NoterButton
/// Unified button component with consistent styling hierarchy
struct NoterButton: View {
    let title: String
    let icon: String?
    let style: NoterButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    init(
        _ title: String,
        icon: String? = nil,
        style: NoterButtonStyle = .secondary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NoterSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.9)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: NoterIconSize.sm))
                }
                Text(title)
                    .font(NoterTypography.captionMedium)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, NoterSpacing.xs + NoterSpacing.xxs)
            .background(background)
            .cornerRadius(NoterRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: NoterRadius.sm)
                    .stroke(strokeColor, lineWidth: hasStroke ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered && !isDisabled ? 1.02 : 1.0)
        .animation(.easeInOut(duration: NoterAnimation.fast), value: isHovered)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .tertiary: return .secondary
        case .destructive: return NoterColors.Status.error
        }
    }

    private var background: Color {
        switch style {
        case .primary: return isHovered ? Color.accentColor.opacity(0.9) : Color.accentColor
        case .secondary: return isHovered ? NoterColors.surfaceLight : NoterColors.surfaceSubtle
        case .tertiary: return isHovered ? NoterColors.surfaceSubtle : .clear
        case .destructive: return isHovered ? NoterColors.Status.errorBackground : NoterColors.Status.errorBackground.opacity(0.5)
        }
    }

    private var strokeColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return NoterColors.strokeSubtle
        case .tertiary: return .clear
        case .destructive: return NoterColors.Status.error.opacity(0.3)
        }
    }

    private var hasStroke: Bool {
        style == .secondary || style == .destructive
    }

    private var horizontalPadding: CGFloat {
        style == .tertiary ? NoterSpacing.sm : NoterSpacing.md
    }
}

// MARK: - NoterIconButton
/// Icon-only button with hover state and accessibility
struct NoterIconButton: View {
    let icon: String
    let style: NoterButtonStyle
    let size: CGFloat
    let helpText: String
    let action: () -> Void

    @State private var isHovered = false

    init(
        icon: String,
        style: NoterButtonStyle = .tertiary,
        size: CGFloat = NoterIconSize.sm,
        help: String = "",
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.helpText = help
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(foregroundColor)
                .frame(width: 24, height: 24)
                .background(isHovered ? NoterColors.surfaceSubtle : .clear)
                .cornerRadius(NoterRadius.sm)
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onHover { isHovered = $0 }
        .accessibleIconButton(label: helpText.isEmpty ? icon : helpText)
    }

    private var foregroundColor: Color {
        switch style {
        case .destructive: return isHovered ? NoterColors.Status.error : NoterColors.Status.error.opacity(0.7)
        default: return isHovered ? .primary : .secondary
        }
    }
}

// MARK: - NoterSendButton
/// Special send button for the note input (circular, prominent)
struct NoterSendButton: View {
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .foregroundStyle(isDisabled ? Color.gray : Color.accentColor)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered && !isDisabled ? 1.1 : 1.0)
        .animation(.easeInOut(duration: NoterAnimation.fast), value: isHovered)
    }
}

// MARK: - Previews
#Preview("Buttons") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            NoterButton("Primary", icon: "plus", style: .primary) {}
            NoterButton("Secondary", icon: "gear", style: .secondary) {}
            NoterButton("Tertiary", style: .tertiary) {}
            NoterButton("Delete", icon: "trash", style: .destructive) {}
        }

        HStack(spacing: 12) {
            NoterButton("Loading", style: .primary, isLoading: true) {}
            NoterButton("Disabled", style: .secondary, isDisabled: true) {}
        }

        HStack(spacing: 12) {
            NoterIconButton(icon: "gear", help: "Settings") {}
            NoterIconButton(icon: "trash", style: .destructive, help: "Delete") {}
            NoterSendButton(isLoading: false, isDisabled: false) {}
            NoterSendButton(isLoading: true, isDisabled: false) {}
            NoterSendButton(isLoading: false, isDisabled: true) {}
        }
    }
    .padding()
}
