import SwiftUI
import Combine

struct QueueStatusView: View {
    @State private var queueCount: Int = 0
    @State private var cancellable: AnyCancellable?

    let onRetryAll: () -> Void
    let onViewQueue: () -> Void

    var body: some View {
        if queueCount > 0 {
            HStack(spacing: NoterSpacing.sm) {
                // Queue indicator
                HStack(spacing: NoterSpacing.xs + NoterSpacing.xxs) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: NoterIconSize.sm))
                        .foregroundStyle(NoterColors.Status.warning)

                    Text("\(queueCount) queued")
                        .font(NoterTypography.captionMedium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Retry button
                NoterButton("Retry All", style: .secondary) {
                    onRetryAll()
                }

                // View queue button
                NoterIconButton(icon: "list.bullet", help: "View queue") {
                    onViewQueue()
                }
            }
            .padding(.horizontal, NoterSpacing.md)
            .padding(.vertical, NoterSpacing.sm)
            .background(NoterColors.Status.warningBackground)
            .cornerRadius(NoterRadius.lg)
        }
    }

    init(onRetryAll: @escaping () -> Void, onViewQueue: @escaping () -> Void) {
        self.onRetryAll = onRetryAll
        self.onViewQueue = onViewQueue
    }

    func startObserving() {
        cancellable = NoteQueueService.shared.queueCountPublisher
            .receive(on: DispatchQueue.main)
            .sink { count in
                withAnimation {
                    queueCount = count
                }
            }
    }
}

/// Badge view for showing queue count
struct QueueBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, NoterSpacing.xs)
                .padding(.vertical, NoterSpacing.xxs)
                .background(Capsule().fill(NoterColors.Status.error))
                .fixedSize()
        }
    }
}
