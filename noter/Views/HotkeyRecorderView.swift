import SwiftUI
import AppKit
import Carbon

struct HotkeyRecorderView: View {
    @Binding var keyCombination: KeyCombination?
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 12) {
            // Display current hotkey or recording state
            HStack(spacing: 6) {
                if isRecording {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.blue)
                    Text("Press keys...")
                        .foregroundStyle(.secondary)
                } else if let combo = keyCombination {
                    Text(combo.displayString)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                } else {
                    Text("Not set")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 100)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRecording ? Color.blue.opacity(0.1) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.blue : Color.primary.opacity(0.1), lineWidth: 1)
            )

            // Record/Stop button
            Button(action: toggleRecording) {
                Text(isRecording ? "Cancel" : "Record")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)

            // Clear button
            if keyCombination != nil && !isRecording {
                Button(action: clearHotkey) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear hotkey")
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true

        // Use local event monitor to capture key presses
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyEvent(event)
            return nil // Consume the event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // Ignore modifier-only presses
        let modifierOnlyKeyCodes: Set<UInt16> = [
            54, 55,  // Command
            56, 60,  // Shift
            58, 61,  // Option
            59, 62,  // Control
            63       // Fn
        ]

        if modifierOnlyKeyCodes.contains(event.keyCode) {
            return
        }

        // Escape cancels recording
        if event.keyCode == UInt16(kVK_Escape) && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            stopRecording()
            return
        }

        // Create key combination from event
        if let combo = KeyCombination(from: event) {
            // Validate that it has proper modifiers
            if combo.hasValidModifiers {
                keyCombination = combo
                stopRecording()
            }
        }
    }

    private func clearHotkey() {
        keyCombination = nil
    }
}

#Preview {
    VStack(spacing: 20) {
        HotkeyRecorderView(keyCombination: .constant(KeyCombination.defaultHotkey))
        HotkeyRecorderView(keyCombination: .constant(nil))
    }
    .padding()
    .frame(width: 300)
}
