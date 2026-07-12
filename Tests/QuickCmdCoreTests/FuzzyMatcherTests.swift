import XCTest
@testable import QuickCmdCore

final class FuzzyMatcherTests: XCTestCase {
    private let commands = [
        Command(name: "Quit All Apps", shell: "a"),
        Command(name: "Shut Down", shell: "b"),
        Command(name: "Restart", shell: "c"),
        Command(name: "Sleep", shell: "d"),
    ]

    private let pinnedCommands = [
        Command(name: "Quit All Apps", shell: "a", show: true),
        Command(name: "Shut Down", shell: "b", show: true),
        Command(name: "Restart", shell: "c"),
        Command(name: "Sleep", shell: "d"),
    ]

    func testEmptyQueryReturnsOnlyPinned() {
        let result = FuzzyMatcher.filter(pinnedCommands, query: "")
        XCTAssertEqual(result.map(\.name), ["Quit All Apps", "Shut Down"])
    }

    func testEmptyQueryReturnsNoneWhenNoPinned() {
        XCTAssertEqual(FuzzyMatcher.filter(commands, query: ""), [])
    }

    func testWhitespaceQueryReturnsOnlyPinned() {
        let result = FuzzyMatcher.filter(pinnedCommands, query: "   ")
        XCTAssertEqual(result.map(\.name), ["Quit All Apps", "Shut Down"])
    }

    func testAbbreviationMatches() {
        let result = FuzzyMatcher.filter(commands, query: "qaa")
        XCTAssertEqual(result.first?.name, "Quit All Apps")
    }

    func testNonSubsequenceIsFilteredOut() {
        let result = FuzzyMatcher.filter(commands, query: "xyz")
        XCTAssertTrue(result.isEmpty)
    }

    func testCaseInsensitive() {
        let result = FuzzyMatcher.filter(commands, query: "SLEEP")
        XCTAssertEqual(result.map(\.name), ["Sleep"])
    }

    func testConsecutivePrefixOutranksScattered() {
        // "sh" is a consecutive prefix of "Shut Down" but scattered in others.
        let result = FuzzyMatcher.filter(commands, query: "sh")
        XCTAssertEqual(result.first?.name, "Shut Down")
    }

    func testScoreNilForNonMatch() {
        XCTAssertNil(FuzzyMatcher.score("Restart", query: "zzz"))
    }

    func testScoreZeroForEmptyQuery() {
        XCTAssertEqual(FuzzyMatcher.score("Restart", query: ""), 0)
    }
}
