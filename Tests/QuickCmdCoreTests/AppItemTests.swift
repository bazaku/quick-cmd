import XCTest
@testable import QuickCmdCore

final class AppItemTests: XCTestCase {
    func testIdIsURL() {
        let url = URL(fileURLWithPath: "/Applications/Safari.app")
        let item = AppItem(name: "Safari", url: url)
        XCTAssertEqual(item.id, url)
    }

    func testEquality() {
        let url = URL(fileURLWithPath: "/Applications/Safari.app")
        let a = AppItem(name: "Safari", url: url)
        let b = AppItem(name: "Safari", url: url)
        XCTAssertEqual(a, b)
    }

    func testInequalityOnName() {
        let url = URL(fileURLWithPath: "/Applications/Safari.app")
        let a = AppItem(name: "Safari", url: url)
        let b = AppItem(name: "Other", url: url)
        XCTAssertNotEqual(a, b)
    }
}
