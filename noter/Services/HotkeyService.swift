import Foundation
import Carbon
import AppKit

/// Service for managing global hotkey registration using Carbon Events API
final class HotkeyService {
    static let shared = HotkeyService()

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var callback: (() -> Void)?

    /// Signature used to identify our hotkey events
    private let hotkeySignature: OSType = {
        let chars = "NOTR"
        var signature: OSType = 0
        for char in chars.utf8 {
            signature = (signature << 8) | OSType(char)
        }
        return signature
    }()

    private let hotkeyID: UInt32 = 1

    private init() {}

    // MARK: - Public API

    /// Register a global hotkey with the given key combination
    /// - Parameters:
    ///   - combination: The key combination to register
    ///   - callback: The closure to call when the hotkey is triggered
    /// - Returns: true if registration was successful
    @discardableResult
    func register(_ combination: KeyCombination, callback: @escaping () -> Void) -> Bool {
        // Unregister any existing hotkey first
        unregister()

        self.callback = callback

        // Install event handler if not already installed
        if eventHandlerRef == nil {
            var eventSpec = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            let status = InstallEventHandler(
                GetEventDispatcherTarget(),
                hotkeyEventHandler,
                1,
                &eventSpec,
                Unmanaged.passUnretained(self).toOpaque(),
                &eventHandlerRef
            )

            if status != noErr {
                print("HotkeyService: Failed to install event handler: \(status)")
                return false
            }
        }

        // Register the hotkey
        var hotkeyIDStruct = EventHotKeyID(signature: hotkeySignature, id: hotkeyID)

        let status = RegisterEventHotKey(
            combination.keyCode,
            combination.modifiers,
            hotkeyIDStruct,
            GetEventDispatcherTarget(),
            0,
            &hotkeyRef
        )

        if status != noErr {
            print("HotkeyService: Failed to register hotkey: \(status)")
            return false
        }

        return true
    }

    /// Unregister the current hotkey
    func unregister() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        callback = nil
    }

    /// Update the hotkey to a new combination
    /// - Parameter combination: The new key combination
    /// - Returns: true if update was successful
    @discardableResult
    func update(_ combination: KeyCombination) -> Bool {
        guard let existingCallback = callback else {
            return false
        }
        return register(combination, callback: existingCallback)
    }

    /// Check if a hotkey is currently registered
    var isRegistered: Bool {
        hotkeyRef != nil
    }

    // MARK: - Event Handling

    fileprivate func handleHotkeyEvent() {
        DispatchQueue.main.async { [weak self] in
            self?.callback?()
        }
    }

    deinit {
        unregister()
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }
}

// MARK: - Carbon Event Handler

/// Carbon event handler callback
private func hotkeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else {
        return OSStatus(eventNotHandledErr)
    }

    let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()

    guard let event = event else {
        return OSStatus(eventNotHandledErr)
    }

    var hotkeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    if status == noErr {
        service.handleHotkeyEvent()
        return noErr
    }

    return OSStatus(eventNotHandledErr)
}
