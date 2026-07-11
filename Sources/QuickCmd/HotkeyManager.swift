import AppKit
import Carbon.HIToolbox
import QuickCmdCore

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: (() -> Void)?

    private let signature: OSType = {
        // Four-char code 'QCMD'.
        let chars = Array("QCMD".utf8)
        return chars.reduce(OSType(0)) { ($0 << 8) + OSType($1) }
    }()

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hkID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                  EventParamType(typeEventHotKeyID), nil,
                                  MemoryLayout<EventHotKeyID>.size, nil, &hkID)
                manager.handler?()
                return noErr
            },
            1, &eventType, selfPtr, &eventHandlerRef)

        if status != noErr {
            NSLog("HotkeyManager: InstallEventHandler failed with status %d", status)
        }
    }

    func register(_ hotkey: ParsedHotkey, handler: @escaping () -> Void) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        self.handler = handler

        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef)

        if status != noErr {
            NSLog("HotkeyManager: RegisterEventHotKey failed with status %d", status)
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        handler = nil
    }
}
