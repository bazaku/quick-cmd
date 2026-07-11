import Foundation

public final class CommandStore {
    public private(set) var commands: [Command]
    public private(set) var hotkey: ParsedHotkey
    public var onError: ((String) -> Void)?

    private let configURL: URL

    public static var defaultConfigURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/quickcmd/commands.json")
    }

    public init(configURL: URL) {
        self.configURL = configURL

        if !FileManager.default.fileExists(atPath: configURL.path) {
            try? FileManager.default.createDirectory(
                at: configURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            try? DefaultConfig.json.write(to: configURL, atomically: true, encoding: .utf8)
        }

        // Seed with defaults so `commands`/`hotkey` are always populated,
        // then attempt a real load.
        self.commands = DefaultConfig.config.commands
        self.hotkey = HotkeyParser.parse(DefaultConfig.config.hotkey)
        load()
    }

    public func reload() {
        load()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(Config.self, from: data)
            commands = config.commands
            hotkey = HotkeyParser.parse(config.hotkey)
        } catch {
            // Keep last-good commands/hotkey; report the failure.
            onError?("Failed to load config: \(error.localizedDescription)")
        }
    }
}
