import XCTest
@testable import QuickCmdCore

final class AppScannerTests: XCTestCase {
    private var tmp: URL!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AppScannerTests-\(ProcessInfo.processInfo.globallyUniqueString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tmp)
        super.tearDown()
    }

    @discardableResult
    private func makeApp(_ name: String, at parent: URL, displayName: String? = nil, bundleName: String? = nil) -> URL {
        let appURL = parent.appendingPathComponent("\(name).app")
        let contentsURL = appURL.appendingPathComponent("Contents")
        try! FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

        var plist: [String: String] = [:]
        if let d = displayName { plist["CFBundleDisplayName"] = d }
        if let b = bundleName  { plist["CFBundleName"] = b }
        if !plist.isEmpty {
            let data = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try! data.write(to: contentsURL.appendingPathComponent("Info.plist"))
        }
        return appURL
    }

    func testFindsTopLevelApp() {
        makeApp("Safari", at: tmp, displayName: "Safari")
        let results = AppScanner.scan(at: tmp)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Safari")
    }

    func testFindsAppInSubfolder() {
        let sub = tmp.appendingPathComponent("Utilities")
        try! FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        makeApp("Activity Monitor", at: sub, displayName: "Activity Monitor")
        let results = AppScanner.scan(at: tmp)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Activity Monitor")
    }

    func testNameResolutionOrder() {
        makeApp("Foo", at: tmp, displayName: "Display Name", bundleName: "Bundle Name")
        let results = AppScanner.scan(at: tmp)
        XCTAssertEqual(results[0].name, "Display Name")
    }

    func testFallsBackToBundleName() {
        makeApp("Bar", at: tmp, bundleName: "Bundle Name")
        let results = AppScanner.scan(at: tmp)
        XCTAssertEqual(results[0].name, "Bundle Name")
    }

    func testFallsBackToFilename() {
        makeApp("BazApp", at: tmp)
        let results = AppScanner.scan(at: tmp)
        XCTAssertEqual(results[0].name, "BazApp")
    }

    func testResultsSortedAlphabetically() {
        makeApp("Zapp", at: tmp, displayName: "Zapp")
        makeApp("Alpha", at: tmp, displayName: "Alpha")
        let results = AppScanner.scan(at: tmp)
        XCTAssertEqual(results.map(\.name), ["Alpha", "Zapp"])
    }

    func testDoesNotDescendIntoBundles() {
        let outer = makeApp("Outer", at: tmp, displayName: "Outer")
        makeApp("Inner", at: outer.appendingPathComponent("Contents/Resources"), displayName: "Inner")
        let results = AppScanner.scan(at: tmp)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Outer")
    }

    func testMissingRootReturnsEmpty() {
        let missing = tmp.appendingPathComponent("nonexistent")
        let results = AppScanner.scan(at: missing)
        XCTAssertTrue(results.isEmpty)
    }
}
