# App Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add search-and-open for `/Applications` apps (including subfolders) in the QuickCmd palette, with icon + name rows in a separate "Applications" section.

**Architecture:** `AppItem` + `AppScanner` live in `QuickCmdCore` (pure, no AppKit). `AppDelegate` scans on launch and reload, passes an `appsProvider` closure + `onOpen` closure into `PaletteController`. `PaletteView` introduces a `PaletteRow` enum and renders two sections — commands always, apps only when a query is active.

**Tech Stack:** Swift, AppKit, SwiftUI, `FileManager`, `NSWorkspace`, `XCTest`

## Global Constraints

- `QuickCmdCore` must not import AppKit — keep it pure Foundation only
- Follow existing code style: no comments unless non-obvious, no error handling for impossible scenarios
- Run `swift test` after every task that touches Core
- Run `make bundle && make run` to smoke-test UI tasks

---

### Task 1: `AppItem` struct in `QuickCmdCore`

**Files:**
- Create: `Sources/QuickCmdCore/AppItem.swift`
- Create: `Tests/QuickCmdCoreTests/AppItemTests.swift`

**Interfaces:**
- Produces: `public struct AppItem: Equatable, Identifiable { public let name: String; public let url: URL; public var id: URL { url } }`

- [ ] **Step 1: Write the failing test**

Create `Tests/QuickCmdCoreTests/AppItemTests.swift`:

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

```
swift test --filter QuickCmdCoreTests.AppItemTests
```

Expected: compile error — `AppItem` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `Sources/QuickCmdCore/AppItem.swift`:

```swift
import Foundation

public struct AppItem: Equatable, Identifiable {
    public let name: String
    public let url: URL

    public var id: URL { url }

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
swift test --filter QuickCmdCoreTests.AppItemTests
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/QuickCmdCore/AppItem.swift Tests/QuickCmdCoreTests/AppItemTests.swift
git commit -m "feat(core): add AppItem model"
```

---

### Task 2: `AppScanner` in `QuickCmdCore`

**Files:**
- Create: `Sources/QuickCmdCore/AppScanner.swift`
- Create: `Tests/QuickCmdCoreTests/AppScannerTests.swift`

**Interfaces:**
- Consumes: `AppItem(name:url:)` from Task 1
- Produces: `public enum AppScanner { public static func scan(at root: URL) -> [AppItem] }`
- Note: `scan()` (no args) is a convenience that calls `scan(at: URL(fileURLWithPath: "/Applications"))`; tests use `scan(at:)` with a temp dir

- [ ] **Step 1: Write the failing tests**

Create `Tests/QuickCmdCoreTests/AppScannerTests.swift`:

```swift
import XCTest
@testable import QuickCmdCore

final class AppScannerTests: XCTestCase {
    private var tmp: URL!

    override func setUp() {
        super.setUp()
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AppScannerTests-\(ProcessInfo.processInfo.globallyUniqueString)")
        try! FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tmp)
        super.tearDown()
    }

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
        // CFBundleDisplayName wins over CFBundleName
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
        makeApp("BazApp", at: tmp)  // no Info.plist
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
        // App inside another .app — should not appear as a separate result
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
```

- [ ] **Step 2: Run tests to verify they fail**

```
swift test --filter QuickCmdCoreTests.AppScannerTests
```

Expected: compile error — `AppScanner` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `Sources/QuickCmdCore/AppScanner.swift`:

```swift
import Foundation

public enum AppScanner {
    public static func scan(at root: URL = URL(fileURLWithPath: "/Applications")) -> [AppItem] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: []
        ) else { return [] }

        var results: [AppItem] = []

        for case let url as URL in enumerator {
            guard url.pathExtension == "app" else { continue }
            enumerator.skipDescendants()
            let name = appName(at: url)
            results.append(AppItem(name: name, url: url))
        }

        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func appName(at url: URL) -> String {
        let plistURL = url.appendingPathComponent("Contents/Info.plist")
        if let plist = NSDictionary(contentsOf: plistURL) {
            if let d = plist["CFBundleDisplayName"] as? String, !d.isEmpty { return d }
            if let b = plist["CFBundleName"] as? String, !b.isEmpty { return b }
        }
        return url.deletingPathExtension().lastPathComponent
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
swift test --filter QuickCmdCoreTests.AppScannerTests
```

Expected: 8 tests pass.

- [ ] **Step 5: Run full test suite**

```
swift test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/QuickCmdCore/AppScanner.swift Tests/QuickCmdCoreTests/AppScannerTests.swift
git commit -m "feat(core): add AppScanner to discover /Applications"
```

---

### Task 3: Wire `appsProvider` + `onOpen` through `PaletteController` and `AppDelegate`

**Files:**
- Modify: `Sources/QuickCmd/PaletteController.swift`
- Modify: `Sources/QuickCmd/AppDelegate.swift`

**Interfaces:**
- Consumes: `AppItem` from Task 1, `AppScanner.scan()` from Task 2
- Produces: `PaletteController.init(commandsProvider:appsProvider:onRun:onOpen:)` where `appsProvider: () -> [AppItem]` and `onOpen: (AppItem) -> Void`

- [ ] **Step 1: Update `PaletteController`**

Replace `Sources/QuickCmd/PaletteController.swift` with:

```swift
import AppKit
import SwiftUI
import QuickCmdCore

final class PaletteController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private let commandsProvider: () -> [Command]
    private let appsProvider: () -> [AppItem]
    private let onRun: (Command) -> Void
    private let onOpen: (AppItem) -> Void

    init(
        commandsProvider: @escaping () -> [Command],
        appsProvider: @escaping () -> [AppItem],
        onRun: @escaping (Command) -> Void,
        onOpen: @escaping (AppItem) -> Void
    ) {
        self.commandsProvider = commandsProvider
        self.appsProvider = appsProvider
        self.onRun = onRun
        self.onOpen = onOpen
        super.init()
    }

    func toggle() {
        if panel?.isVisible == true { hide() } else { show() }
    }

    func show() {
        let root = PaletteView(
            commands: commandsProvider(),
            apps: appsProvider(),
            onRun: { [weak self] command in
                self?.hide()
                self?.onRun(command)
            },
            onOpen: { [weak self] item in
                self?.hide()
                self?.onOpen(item)
            },
            onEscape: { [weak self] in self?.hide() })

        let hosting = NSHostingController(rootView: root)
        let panel = NSPanel(contentViewController: hosting)
        panel.styleMask = [.nonactivatingPanel, .titled, .fullSizeContentView]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.delegate = self
        panel.center()

        self.panel = panel
        if #available(macOS 14, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
```

- [ ] **Step 2: Update `AppDelegate`**

Replace `Sources/QuickCmd/AppDelegate.swift` with:

```swift
import AppKit
import QuickCmdCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: CommandStore!
    private var hotkeyManager: HotkeyManager!
    private var palette: PaletteController!
    private var statusBar: StatusBarController!
    private var apps: [AppItem] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        store = CommandStore(configURL: CommandStore.defaultConfigURL)
        apps = AppScanner.scan()

        palette = PaletteController(
            commandsProvider: { [weak self] in self?.store.commands ?? [] },
            appsProvider:     { [weak self] in self?.apps ?? [] },
            onRun:  { command in CommandRunner.run(command.shell, completion: nil) },
            onOpen: { item in NSWorkspace.shared.open(item.url) })

        statusBar = StatusBarController(
            onReload: { [weak self] in self?.reloadConfig() },
            onQuit: { NSApp.terminate(nil) })

        store.onError = { [weak self] message in
            NSLog("QuickCmd: \(message)")
            self?.statusBar.setErrorState(true)
        }

        hotkeyManager = HotkeyManager()
        hotkeyManager.register(store.hotkey) { [weak self] in
            self?.palette.toggle()
        }
    }

    private func reloadConfig() {
        statusBar.setErrorState(false)
        store.reload()
        apps = AppScanner.scan()
        hotkeyManager.register(store.hotkey) { [weak self] in
            self?.palette.toggle()
        }
    }
}
```

- [ ] **Step 3: Verify build**

```
make build
```

Expected: build succeeds (PaletteView not yet updated — will get a compile error on `PaletteView.init` call; that's fixed in Task 4).

> **Note:** Task 3 and Task 4 must be committed together since `PaletteController` now calls `PaletteView` with the new signature. Do not commit until Task 4 is complete.

---

### Task 4: Update `PaletteView` with two-section list and app icons

**Files:**
- Modify: `Sources/QuickCmd/PaletteView.swift`

**Interfaces:**
- Consumes: `AppItem` from Task 1; `onOpen: (AppItem) -> Void` and `apps: [AppItem]` wired in Task 3
- Produces: `PaletteView(commands:apps:onRun:onOpen:onEscape:)` — renders commands section always, apps section when query is non-empty and has matches; app rows show 32×32 icon + name

- [ ] **Step 1: Replace `PaletteView.swift`**

Replace the entire contents of `Sources/QuickCmd/PaletteView.swift` with:

```swift
import SwiftUI
import AppKit
import QuickCmdCore

// Flat list item spanning both sections for unified keyboard navigation.
private enum PaletteRow: Identifiable {
    case command(Command)
    case app(AppItem)

    var id: String {
        switch self {
        case .command(let c): return "cmd:\(c.id)"
        case .app(let a):     return "app:\(a.url.path)"
        }
    }

    var displayName: String {
        switch self {
        case .command(let c): return c.name
        case .app(let a):     return a.name
        }
    }
}

struct PaletteView: View {
    let commands: [Command]
    let apps: [AppItem]
    let onRun: (Command) -> Void
    let onOpen: (AppItem) -> Void
    let onEscape: () -> Void

    @State private var query = ""
    @State private var selection = 0

    private var filteredCommands: [Command] {
        FuzzyMatcher.filter(commands, query: query)
    }

    private var filteredApps: [AppItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return apps
            .compactMap { item -> (Int, AppItem)? in
                guard let s = FuzzyMatcher.score(item.name, query: query) else { return nil }
                return (s, item)
            }
            .sorted { $0.0 > $1.0 }
            .map(\.1)
    }

    private var rows: [PaletteRow] {
        filteredCommands.map { .command($0) } + filteredApps.map { .app($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            CommandTextField(
                text: $query,
                onDown:   { moveSelection(1) },
                onUp:     { moveSelection(-1) },
                onEnter:  { runSelected() },
                onEscape: onEscape
            )
            .font(.system(size: 22))
            .frame(height: 54)
            .padding(.horizontal, 16)
            .onChange(of: query) { _ in selection = 0 }

            Divider()

            List {
                if !filteredCommands.isEmpty {
                    Section(header: Text("Commands").foregroundColor(.secondary).font(.caption)) {
                        ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                            Text(command.name)
                                .padding(.vertical, 4)
                                .listRowBackground(rowIndex(for: .command(command)) == selection
                                    ? Color.accentColor.opacity(0.25) : Color.clear)
                        }
                    }
                }

                if !filteredApps.isEmpty {
                    Section(header: Text("Applications").foregroundColor(.secondary).font(.caption)) {
                        ForEach(Array(filteredApps.enumerated()), id: \.element.id) { index, app in
                            HStack(spacing: 8) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                Text(app.name)
                            }
                            .padding(.vertical, 2)
                            .listRowBackground(rowIndex(for: .app(app)) == selection
                                ? Color.accentColor.opacity(0.25) : Color.clear)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: 260)
        }
        .frame(width: 560)
        .background(.ultraThinMaterial)
    }

    private func rowIndex(for row: PaletteRow) -> Int {
        rows.firstIndex(where: { $0.id == row.id }) ?? -1
    }

    private func moveSelection(_ delta: Int) {
        guard !rows.isEmpty else { return }
        selection = min(max(0, selection + delta), rows.count - 1)
    }

    private func runSelected() {
        guard rows.indices.contains(selection) else { return }
        switch rows[selection] {
        case .command(let c): onRun(c)
        case .app(let a):     onOpen(a)
        }
    }
}

// MARK: - CommandTextField

/// NSTextField wrapper that intercepts arrow/enter/escape keys before AppKit
/// consumes them, so the palette can navigate the list while typing.
private struct CommandTextField: NSViewRepresentable {
    @Binding var text: String
    let onDown: () -> Void
    let onUp: () -> Void
    let onEnter: () -> Void
    let onEscape: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = "Search commands and apps…"
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.delegate = context.coordinator
        field.stringValue = text
        DispatchQueue.main.async { field.becomeFirstResponder() }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CommandTextField
        init(_ parent: CommandTextField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.moveDown(_:)):
                parent.onDown(); return true
            case #selector(NSResponder.moveUp(_:)):
                parent.onUp(); return true
            case #selector(NSResponder.insertNewline(_:)):
                parent.onEnter(); return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onEscape(); return true
            default:
                return false
            }
        }
    }
}
```

- [ ] **Step 2: Build**

```
make build
```

Expected: build succeeds, no errors.

- [ ] **Step 3: Commit Tasks 3 + 4 together**

```bash
git add Sources/QuickCmd/PaletteController.swift Sources/QuickCmd/AppDelegate.swift Sources/QuickCmd/PaletteView.swift
git commit -m "feat: add app launcher — two-section palette with icons"
```

- [ ] **Step 4: Smoke test**

```
make bundle && make run
```

Manual checks:
1. Palette opens with hotkey — shows commands only (empty query)
2. Type a letter — "Applications" section appears with app icons (32×32) + names
3. Arrow keys navigate across both sections
4. Enter on a command runs it; Enter on an app opens it
5. Escape closes the palette
6. "Reload Config" in menu bar rescans apps (install a test `.app` in `/Applications` if possible, or verify no crash)

- [ ] **Step 5: Run full test suite**

```
swift test
```

Expected: all tests pass.
