# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- `make build` — release build (`swift build -c release`).
- `make bundle` — build, assemble `QuickCmd.app`, and ad-hoc codesign it.
- `make run` — bundle then `open QuickCmd.app` (launches into the menu bar; no dock icon).
- `make clean` — remove `.build` and `QuickCmd.app`.
- `swift test` — run all tests.
- `swift test --filter QuickCmdCoreTests.FuzzyMatcherTests` — run one test class (filter by `Target.Class` or `Target.Class/testMethod`).

Note: `swift build` (debug) also works, but the app must be run as a signed `.app` bundle (not the bare binary) for global hotkey registration and `SMAppService` login-item behavior to work reliably.

## Architecture

Two-target Swift package. The split is deliberate and load-bearing:

- **`QuickCmdCore`** — pure, platform-agnostic logic with **no AppKit dependency**. This is the only target with tests. Contains config models (`Command`, `HotkeyConfig`, `Config`), config loading (`CommandStore`), hotkey string→keycode parsing (`HotkeyParser`), fuzzy search (`FuzzyMatcher`), shell execution (`CommandRunner`), and the embedded default config (`DefaultConfig`).
- **`QuickCmd`** — the AppKit/SwiftUI executable. Owns all UI and OS integration: `AppDelegate` (wiring), `HotkeyManager` (Carbon global hotkey), `PaletteController`/`PaletteView` (the search panel), `StatusBarController` (menu bar), `LoginItemManager` (launch-at-login).

**Keep logic in Core, keep AppKit out of Core.** When adding behavior, prefer putting testable logic in `QuickCmdCore` and only the OS glue in `QuickCmd`.

### Wiring (`AppDelegate`)

Everything is dependency-injected via closures — no singletons. `AppDelegate.applicationDidFinishLaunching` constructs `CommandStore`, then hands the palette a `commandsProvider` closure (reads `store.commands` live) and an `onRun` closure (delegates to `CommandRunner.run`). The status bar gets `onReload`/`onQuit` closures. `store.onError` flips the menu-bar icon to an error state.

### Config flow

- Config lives at `~/.config/quickcmd/commands.json` (`CommandStore.defaultConfigURL`). Written from `DefaultConfig.json` on first launch if absent.
- `CommandStore` **seeds with `DefaultConfig` first, then loads** — so `commands`/`hotkey` are always populated. On a load failure it keeps the last-good values and calls `onError` rather than clearing state.
- Reload path: menu "Reload Config" → `AppDelegate.reloadConfig()` → `store.reload()` **and re-registers the hotkey** (config can change the hotkey).
- Each command's `shell` string runs via `/bin/sh -c`.

### Hotkey

`HotkeyParser` (Core) maps `HotkeyConfig` strings to a `ParsedHotkey` (Carbon keycode + modifier mask) using hardcoded **US-keyboard** virtual keycodes. Any invalid/missing key, empty modifiers, or unknown modifier falls back to `Option+Space` (`defaultHotkey`). `HotkeyManager` (QuickCmd) installs a single Carbon event handler once and re-registers the `EventHotKeyRef` on each `register` call (unregistering the previous one first).

### Fuzzy matching

`FuzzyMatcher.score` is case-insensitive subsequence matching: returns `nil` for non-matches, higher scores for matches near the string start and consecutive runs. Empty query scores 0 (all pass). `filter` sorts by descending score with stable tie-breaking on original index.
