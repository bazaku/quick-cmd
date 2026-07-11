import Foundation
import Carbon.HIToolbox

public struct ParsedHotkey: Equatable {
    public let keyCode: UInt32
    public let modifierFlags: UInt32

    public init(keyCode: UInt32, modifierFlags: UInt32) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }
}

public enum HotkeyParser {
    public static let defaultHotkey = ParsedHotkey(keyCode: 49, modifierFlags: UInt32(optionKey))

    // US-keyboard virtual keycodes for the keys we support.
    private static let keyCodes: [String: UInt32] = [
        "space": 49, "return": 36, "tab": 48, "escape": 53,
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "o": 31, "u": 32, "i": 34, "p": 35, "l": 37,
        "j": 38, "k": 40, "n": 45, "m": 46,
        "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26,
        "8": 28, "9": 25, "0": 29,
    ]

    private static let modifierFlags: [String: UInt32] = [
        "command": UInt32(cmdKey),
        "shift": UInt32(shiftKey),
        "option": UInt32(optionKey),
        "control": UInt32(controlKey),
    ]

    public static func parse(_ config: HotkeyConfig?) -> ParsedHotkey {
        guard let config,
              let keyCode = keyCodes[config.key.lowercased()],
              !config.modifiers.isEmpty
        else { return defaultHotkey }

        var mask: UInt32 = 0
        for modifier in config.modifiers {
            guard let flag = modifierFlags[modifier.lowercased()] else {
                return defaultHotkey
            }
            mask |= flag
        }
        return ParsedHotkey(keyCode: keyCode, modifierFlags: mask)
    }
}
