import XCTest
@testable import QuickCmdCore

final class CommandRunnerTests: XCTestCase {
    func testRunSyncCapturesStdoutAndExitZero() {
        let result = CommandRunner.runSync("echo hello")
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "hello")
    }

    func testRunSyncReportsNonZeroExit() {
        let result = CommandRunner.runSync("exit 3")
        XCTAssertEqual(result.exitCode, 3)
    }

    func testRunSyncCapturesStderr() {
        let result = CommandRunner.runSync("echo oops 1>&2")
        XCTAssertEqual(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines), "oops")
    }

    func testAsyncRunInvokesCompletion() {
        let expectation = expectation(description: "completion called")
        CommandRunner.run("echo async") { result in
            XCTAssertEqual(result.exitCode, 0)
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }
}
