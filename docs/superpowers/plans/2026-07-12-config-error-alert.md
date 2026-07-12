# Config Error Alert Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show an NSAlert with "OK" and "Open Config" buttons whenever config loading fails (initial load or reload).

**Architecture:** Extend the existing `store.onError` closure in `AppDelegate` to present an `NSAlert` on the main thread. No new types or files needed.

**Tech Stack:** Swift, AppKit (`NSAlert`, `NSWorkspace`), `DispatchQueue.main.async`

## Global Constraints

- Only `Sources/QuickCmd/AppDelegate.swift` changes — no Core target changes
- Alert must run on main thread
- "Open Config" opens `CommandStore.defaultConfigURL` via `NSWorkspace.shared.open(_:)`

---

### Task 1: Show NSAlert on config load error

**Files:**
- Modify: `Sources/QuickCmd/AppDelegate.swift:30-33`

**Interfaces:**
- Consumes: `CommandStore.defaultConfigURL: URL`, `store.onError: ((String) -> Void)?`
- Produces: nothing (UI side-effect only)

- [ ] **Step 1: Open the file and locate the `store.onError` closure**

In `AppDelegate.applicationDidFinishLaunching`, find:

```swift
store.onError = { [weak self] message in
    NSLog("QuickCmd: \(message)")
    self?.statusBar.setErrorState(true)
}
```

- [ ] **Step 2: Replace the closure with the alert-showing version**

```swift
store.onError = { [weak self] message in
    NSLog("QuickCmd: \(message)")
    self?.statusBar.setErrorState(true)
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Config Error"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Config")
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(CommandStore.defaultConfigURL)
        }
    }
}
```

- [ ] **Step 3: Build to verify no compile errors**

```bash
make build
```

Expected: build succeeds with no errors or warnings.

- [ ] **Step 4: Manual smoke test — initial load error**

Temporarily corrupt `~/.config/quickcmd/commands.json` (e.g. write `{bad json}`), then:

```bash
make run
```

Expected: alert appears on launch with message "Config Error", informative text describing the JSON parse failure, and two buttons "OK" and "Open Config". Clicking "Open Config" opens the file. Status bar icon shows error state.

- [ ] **Step 5: Manual smoke test — reload error**

With the app running and a valid config, corrupt the file, then click "Reload Config" in the status bar menu.

Expected: same alert appears again.

- [ ] **Step 6: Restore config and verify clean state**

```bash
make run
```

Expected: no alert on launch, status bar icon normal.

- [ ] **Step 7: Commit**

```bash
git add Sources/QuickCmd/AppDelegate.swift docs/superpowers/specs/2026-07-12-config-error-alert-design.md docs/superpowers/plans/2026-07-12-config-error-alert.md
git commit -m "feat: show alert on config load error with Open Config action"
```
