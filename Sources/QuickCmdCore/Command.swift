import Foundation

public struct Command: Codable, Equatable, Identifiable {
    public let name: String
    public let shell: String

    public var id: String { name }

    public init(name: String, shell: String) {
        self.name = name
        self.shell = shell
    }
}

public struct HotkeyConfig: Codable, Equatable {
    public let key: String
    public let modifiers: [String]

    public init(key: String, modifiers: [String]) {
        self.key = key
        self.modifiers = modifiers
    }
}

public struct Config: Codable, Equatable {
    public let hotkey: HotkeyConfig?
    public let commands: [Command]

    public init(hotkey: HotkeyConfig?, commands: [Command]) {
        self.hotkey = hotkey
        self.commands = commands
    }
}
