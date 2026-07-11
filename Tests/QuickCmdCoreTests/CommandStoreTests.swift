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
}
