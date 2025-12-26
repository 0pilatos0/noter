import SwiftUI
import AppKit
import Combine

@main
struct noterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    private var hotkeyObserver: NSObjectProtocol?
    private var queueRetryTimer: Timer?
    private var queueProcessedObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager()

        NSApp.setActivationPolicy(.accessory)

        // Set up global hotkey
        setupGlobalHotkey()

        // Listen for hotkey activation
        hotkeyObserver = NotificationCenter.default.addObserver(
            forName: .showPopoverFromHotkey,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.menuBarManager?.showPopover()
        }

        // Set up queue auto-retry timer (every 5 minutes)
        setupQueueRetryTimer()

        // Listen for queue processed notifications
        queueProcessedObserver = NotificationCenter.default.addObserver(
            forName: .queueItemsProcessed,
            object: nil,
            queue: .main
        ) { notification in
            if let count = notification.object as? Int, count > 0 {
                // Could show a notification here if desired
                print("Noter: \(count) queued notes processed successfully")
            }
        }

        // Process queue on launch
        Task {
            await NoteQueueService.shared.processQueue()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyService.shared.unregister()
        queueRetryTimer?.invalidate()
        if let observer = hotkeyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = queueProcessedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func setupGlobalHotkey() {
        let settings = StorageManager.loadSettings()
        if settings.hotkeyEnabled, let combo = settings.globalHotkey {
            HotkeyService.shared.register(combo) {
                NotificationCenter.default.post(name: .showPopoverFromHotkey, object: nil)
            }
        }
    }

    private func setupQueueRetryTimer() {
        // Retry queued notes every 5 minutes
        queueRetryTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await NoteQueueService.shared.processQueue()
            }
        }
    }
}
