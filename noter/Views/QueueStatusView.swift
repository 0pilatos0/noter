import SwiftUI
import Combine

struct QueueStatusView: View {
    @State private var queueCount: Int = 0
    @State private var cancellable: AnyCancellable?

    let onRetryAll: () -> Void
    let onViewQueue: () -> Void

    var body: some View {
        if queueCount > 0 {
            HStack(spacing: 8) {
                // Queue indicator
                HStack(spacing: 6) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)

                    Text("\(queueCount) queued")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Retry button
                Button(action: onRetryAll) {
                    Text("Retry All")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                // View queue button
                Button(action: onViewQueue) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
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
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Capsule().fill(.red))
                .fixedSize()
        }
    }
}
