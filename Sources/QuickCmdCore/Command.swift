import Foundation

public struct Command: Codable, Equatable, Identifiable {
    public let name: String
    public let shell: String
    public let show: Bool?

    public var id: String { name }

    public init(name: String, shell: String, show: Bool? = nil) {
        self.name = name
        self.shell = shell
        self.show = show
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
