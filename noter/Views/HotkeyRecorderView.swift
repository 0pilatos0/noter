import SwiftUI
import AppKit
import Carbon

struct HotkeyRecorderView: View {
    @Binding var keyCombination: KeyCombination?
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: NoterSpacing.md) {
            // Display current hotkey or recording state
            HStack(spacing: NoterSpacing.xs + NoterSpacing.xxs) {
                if isRecording {
                    Image(systemName: "keyboard")
                        .foregroundStyle(NoterColors.Status.info)
                    Text("Press keys...")
                        .foregroundStyle(.secondary)
                } else if let combo = keyCombination {
                    Text(combo.displayString)
                        .font(NoterTypography.keyboardHint)
                        .foregroundStyle(.primary)
                } else {
                    Text("Not set")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 100)
            .padding(.horizontal, NoterSpacing.md)
            .padding(.vertical, NoterSpacing.xs + NoterSpacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: NoterRadius.md)
                    .fill(isRecording ? NoterColors.Status.infoBackground : NoterColors.surfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NoterRadius.md)
                    .stroke(isRecording ? NoterColors.Status.info : NoterColors.strokeSubtle, lineWidth: 1)
            )

            // Record/Stop button
            NoterButton(isRecording ? "Cancel" : "Record", style: .secondary) {
                toggleRecording()
            }

            // Clear button
            if keyCombination != nil && !isRecording {
                NoterIconButton(icon: "xmark.circle.fill", help: "Clear hotkey") {
                    clearHotkey()
                }
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
