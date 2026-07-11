import XCTest
@testable import QuickCmdCore

final class CommandTests: XCTestCase {
    func testDecodesConfigWithHotkeyAndCommands() throws {
        let json = """
        {
          "hotkey": { "key": "space", "modifiers": ["option"] },
          "commands": [
            { "name": "Shut Down", "shell": "osascript -e 'x'" }
          ]
        }
        """
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        XCTAssertEqual(config.hotkey, HotkeyConfig(key: "space", modifiers: ["option"]))
        XCTAssertEqual(config.commands, [Command(name: "Shut Down", shell: "osascript -e 'x'")])
    }

    func testDecodesConfigWithMissingHotkey() throws {
        let json = """
        { "commands": [ { "name": "Sleep", "shell": "s" } ] }
        """
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        XCTAssertNil(config.hotkey)
        XCTAssertEqual(config.commands.count, 1)
    }

    func testCommandIdIsName() {
        XCTAssertEqual(Command(name: "Restart", shell: "r").id, "Restart")
    }
}
