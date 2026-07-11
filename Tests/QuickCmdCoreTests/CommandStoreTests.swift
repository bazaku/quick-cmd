import XCTest
@testable import QuickCmdCore

final class CommandStoreTests: XCTestCase {
    func testDefaultConfigDecodes() throws {
        let config = try JSONDecoder().decode(Config.self, from: Data(DefaultConfig.json.utf8))
        XCTAssertEqual(config.hotkey, HotkeyConfig(key: "space", modifiers: ["option"]))
        XCTAssertEqual(config.commands.map(\.name), [
            "Quit All Apps", "Shut Down", "Restart", "Sleep", "Lock Screen", "Empty Trash",
        ])
    }

    func testDefaultConfigConvenienceMatchesJSON() throws {
        let decoded = try JSONDecoder().decode(Config.self, from: Data(DefaultConfig.json.utf8))
        XCTAssertEqual(DefaultConfig.config, decoded)
    }

    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("quickcmd-test-\(UUID().uuidString)")
            .appendingPathComponent("commands.json")
    }

    func testWritesDefaultsWhenFileMissing() throws {
        let url = tempURL()
        let store = CommandStore(configURL: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(store.commands.map(\.name).first, "Quit All Apps")
        XCTAssertEqual(store.hotkey, HotkeyParser.defaultHotkey)
    }

    func testLoadsValidConfig() throws {
        let url = tempURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let json = """
        { "hotkey": { "key": "k", "modifiers": ["command"] },
          "commands": [ { "name": "Only", "shell": "echo hi" } ] }
        """
        try json.write(to: url, atomically: true, encoding: .utf8)

        let store = CommandStore(configURL: url)
        XCTAssertEqual(store.commands, [Command(name: "Only", shell: "echo hi")])
        XCTAssertEqual(store.hotkey.keyCode, 40)
    }

    func testInvalidJsonAtInitFallsBackToDefaults() throws {
        let url = tempURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "{ not json".write(to: url, atomically: true, encoding: .utf8)

        let store = CommandStore(configURL: url)
        XCTAssertEqual(store.commands.first?.name, "Quit All Apps")
    }

    func testReloadKeepsLastGoodOnInvalidJson() throws {
        let url = tempURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let good = """
        { "commands": [ { "name": "Good", "shell": "echo ok" } ] }
        """
        try good.write(to: url, atomically: true, encoding: .utf8)
        let store = CommandStore(configURL: url)
        XCTAssertEqual(store.commands.map(\.name), ["Good"])

        var errorMessage: String?
        store.onError = { errorMessage = $0 }
        try "{ broken".write(to: url, atomically: true, encoding: .utf8)
        store.reload()

        XCTAssertEqual(store.commands.map(\.name), ["Good"])   // last-good retained
        XCTAssertNotNil(errorMessage)
    }
}
