import SwiftUI

// MARK: - NoterStatusBanner
/// Unified status banner with consistent styling and timing
struct NoterStatusBanner: View {
    enum BannerType {
        case success(String)
        case error(String)
        case warning(String)
        case info(String)

        var message: String {
            switch self {
            case .success(let msg), .error(let msg),
                 .warning(let msg), .info(let msg):
                return msg
            }
        }

        var status: StatusIndicator.Status {
            switch self {
            case .success: return .success
            case .error: return .error
            case .warning: return .warning
            case .info: return .info
            }
        }

        var backgroundColor: Color {
            switch self {
            case .success: return NoterColors.Status.successBackground
            case .error: return NoterColors.Status.errorBackground
            case .warning: return NoterColors.Status.warningBackground
            case .info: return NoterColors.Status.infoBackground
            }
        }
    }

    let type: BannerType
    let showDismiss: Bool
    let onDismiss: (() -> Void)?

    init(_ type: BannerType, showDismiss: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.type = type
        self.showDismiss = showDismiss
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: NoterSpacing.sm) {
            StatusIndicator(type.status)

            Text(type.message)
                .font(NoterTypography.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()

            if showDismiss, let onDismiss = onDismiss {
                NoterIconButton(icon: "xmark", size: NoterIconSize.xs, help: "Dismiss") {
                    onDismiss()
                }
            }
        }
        .padding(.horizontal, NoterSpacing.md)
        .padding(.vertical, NoterSpacing.sm + NoterSpacing.xxs)
        .background(type.backgroundColor)
        .cornerRadius(NoterRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(statusLabel): \(type.message)")
    }

    private var statusLabel: String {
        switch type {
        case .success: return "Success"
        case .error: return "Error"
        case .warning: return "Warning"
        case .info: return "Info"
        }
    }
}

// MARK: - Animated Status Banner Container
/// Container that handles banner show/hide with animation
struct AnimatedStatusBanner: View {
    let type: NoterStatusBanner.BannerType?
    let onDismiss: (() -> Void)?

    init(_ type: NoterStatusBanner.BannerType?, onDismiss: (() -> Void)? = nil) {
        self.type = type
        self.onDismiss = onDismiss
    }

    var body: some View {
        if let type = type {
            NoterStatusBanner(type, showDismiss: onDismiss != nil, onDismiss: onDismiss)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
        }
    }
}

// MARK: - Previews
#Preview("Status Banners") {
    VStack(spacing: 16) {
        NoterStatusBanner(.success("Note added to daily note"))
        NoterStatusBanner(.error("Failed to connect to OpenCode"))
        NoterStatusBanner(.warning("Queued for later processing"))
        NoterStatusBanner(.info("Processing note..."))

        Divider()

        NoterStatusBanner(.error("With dismiss button"), showDismiss: true) {
            print("Dismissed")
        }
    }
    .padding()
    .frame(width: 350)
}
