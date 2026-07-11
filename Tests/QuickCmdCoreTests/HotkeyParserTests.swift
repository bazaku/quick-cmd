import XCTest
import Carbon.HIToolbox
@testable import QuickCmdCore

final class HotkeyParserTests: XCTestCase {
    func testParsesOptionSpace() {
        let parsed = HotkeyParser.parse(HotkeyConfig(key: "space", modifiers: ["option"]))
        XCTAssertEqual(parsed.keyCode, 49)
        XCTAssertEqual(parsed.modifierFlags, UInt32(optionKey))
    }

    func testParsesCommandControlK() {
        let parsed = HotkeyParser.parse(HotkeyConfig(key: "k", modifiers: ["command", "control"]))
        XCTAssertEqual(parsed.keyCode, 40)
        XCTAssertEqual(parsed.modifierFlags, UInt32(cmdKey) | UInt32(controlKey))
    }

    func testNilConfigReturnsDefault() {
        XCTAssertEqual(HotkeyParser.parse(nil), HotkeyParser.defaultHotkey)
    }

    func testUnknownKeyReturnsDefault() {
        XCTAssertEqual(HotkeyParser.parse(HotkeyConfig(key: "f19", modifiers: ["option"])),
                       HotkeyParser.defaultHotkey)
    }

    func testEmptyModifiersReturnsDefault() {
        XCTAssertEqual(HotkeyParser.parse(HotkeyConfig(key: "space", modifiers: [])),
                       HotkeyParser.defaultHotkey)
    }

    func testUnknownModifierReturnsDefault() {
        XCTAssertEqual(HotkeyParser.parse(HotkeyConfig(key: "space", modifiers: ["hyper"])),
                       HotkeyParser.defaultHotkey)
    }

    func testDefaultHotkeyValue() {
        XCTAssertEqual(HotkeyParser.defaultHotkey.keyCode, 49)
        XCTAssertEqual(HotkeyParser.defaultHotkey.modifierFlags, UInt32(optionKey))
    }
}
