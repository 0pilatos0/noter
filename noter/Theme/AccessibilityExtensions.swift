import SwiftUI

// MARK: - Status Indicator with Shape Differentiation
/// Accessible status indicator that uses both color AND shape to convey status
struct StatusIndicator: View {
    enum Status {
        case success
        case error
        case warning
        case pending
        case info
    }

    let status: Status
    let showLabel: Bool
    let size: CGFloat

    init(_ status: Status, showLabel: Bool = false, size: CGFloat = NoterIconSize.sm) {
        self.status = status
        self.showLabel = showLabel
        self.size = size
    }

    var body: some View {
        HStack(spacing: NoterSpacing.xs) {
            Image(systemName: iconName)
                .font(.system(size: size))
                .foregroundStyle(statusColor)

            if showLabel {
                Text(labelText)
                    .font(NoterTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // Each status uses a distinct shape for color-blind accessibility
    private var iconName: String {
        switch status {
        case .success: return "checkmark.circle.fill"      // Circle with checkmark
        case .error: return "xmark.octagon.fill"           // Octagon (stop sign shape)
        case .warning: return "exclamationmark.triangle.fill" // Triangle
        case .pending: return "clock.fill"                  // Clock
        case .info: return "info.circle.fill"              // Circle with i
        }
    }

    private var statusColor: Color {
        switch status {
        case .success: return NoterColors.Status.success
        case .error: return NoterColors.Status.error
        case .warning: return NoterColors.Status.warning
        case .pending: return NoterColors.Status.warning
        case .info: return NoterColors.Status.info
        }
    }

    private var labelText: String {
        switch status {
        case .success: return "Success"
        case .error: return "Error"
        case .warning: return "Warning"
        case .pending: return "Pending"
        case .info: return "Info"
        }
    }

    private var accessibilityText: String {
        labelText
    }
}

// MARK: - Validation Badge
/// Compact badge showing valid/invalid state with appropriate status indicator
struct ValidationBadge: View {
    let isValid: Bool
    let validText: String
    let invalidText: String

    init(isValid: Bool, validText: String = "Valid", invalidText: String = "Invalid") {
        self.isValid = isValid
        self.validText = validText
        self.invalidText = invalidText
    }

    var body: some View {
        HStack(spacing: NoterSpacing.xs) {
            StatusIndicator(isValid ? .success : .error, size: NoterIconSize.xs)
            Text(isValid ? validText : invalidText)
                .font(NoterTypography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, NoterSpacing.sm)
        .padding(.vertical, NoterSpacing.xs)
        .background(isValid ? NoterColors.Status.successBackground : NoterColors.Status.errorBackground)
        .cornerRadius(NoterRadius.sm)
    }
}

// MARK: - Focus Ring Modifier
/// Adds a visible focus ring for keyboard navigation accessibility
struct FocusRingStyle: ViewModifier {
    let isFocused: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.accentColor.opacity(isFocused ? 0.5 : 0), lineWidth: 2)
                    .padding(-2)
            )
            .animation(.easeInOut(duration: NoterAnimation.fast), value: isFocused)
    }
}

extension View {
    /// Adds a focus ring that appears when the view is focused
    func focusRing(isFocused: Bool, cornerRadius: CGFloat = NoterRadius.md) -> some View {
        modifier(FocusRingStyle(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}

// MARK: - Accessible Icon Button
/// Extension for making icon-only buttons accessible
extension View {
    func accessibleIconButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Always Visible Actions Modifier
/// Makes actions visible with reduced opacity when not hovered, full opacity on hover
struct AlwaysVisibleActions: ViewModifier {
    let isHovered: Bool
    let isExpanded: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isHovered || isExpanded ? 1.0 : 0.5)
            .animation(.easeInOut(duration: NoterAnimation.fast), value: isHovered)
    }
}

extension View {
    /// Makes content always visible but more prominent on hover
    func alwaysVisibleActions(isHovered: Bool, isExpanded: Bool = false) -> some View {
        modifier(AlwaysVisibleActions(isHovered: isHovered, isExpanded: isExpanded))
    }
}

// MARK: - Previews
#Preview("Status Indicators") {
    VStack(spacing: 16) {
        StatusIndicator(.success, showLabel: true)
        StatusIndicator(.error, showLabel: true)
        StatusIndicator(.warning, showLabel: true)
        StatusIndicator(.pending, showLabel: true)
        StatusIndicator(.info, showLabel: true)

        Divider()

        ValidationBadge(isValid: true, validText: "Connected")
        ValidationBadge(isValid: false, invalidText: "Not found")
    }
    .padding()
}
