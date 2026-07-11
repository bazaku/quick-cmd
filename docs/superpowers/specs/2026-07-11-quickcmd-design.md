# QuickCmd — Design

macOS status bar command launcher. Global hotkey opens a Spotlight-style
palette; type to fuzzy-search custom commands, run them via keyboard. Each
command is a shell string, so system actions (shutdown, restart, quit all
apps) run through AppleScript and get the same system response as a user
performing them through the native UI.

## Goals

- Menu-bar-only app (no dock icon).
- Global configurable hotkey (default `Option+Space`) toggles a centered
  search palette.
- Fuzzy-search a list of named commands; Enter runs the selected one.
- Commands defined in a JSON config file (built-in defaults on first run,
  user-editable).
- Commands execute as shell strings; destructive actions rely on native
  macOS/app dialogs for confirmation.
- Launch at login toggle.

## Non-Goals

- No GUI settings editor for commands (JSON only).
- No app-level confirmation dialogs (trust native prompts).
- No command arguments/parameters, chaining, or scheduling.
- No cross-platform support.

## Tech

- Native Swift / SwiftUI.
- `NSApplication`, `LSUIElement = true` (status bar only, no dock icon).
- Minimum target: macOS 13 Ventura (required for `SMAppService`).
- Global hotkey via Carbon `RegisterEventHotKey` (no Accessibility permission
  needed).
- Launch at login via `SMAppService.mainApp` (ServiceManagement).

## Architecture

Isolated components, each single-purpose:

1. **AppDelegate** — app lifecycle; wires components together.
2. **StatusBarController** — `NSStatusItem` icon + menu: "Launch at Login"
   toggle, "Reload Config", "About", "Quit QuickCmd".
3. **HotkeyManager** — registers/unregisters the global hotkey via Carbon
   `RegisterEventHotKey`. Parses the configured hotkey into a Carbon keycode +
   modifier mask (key-name → keycode table). Invalid config → falls back to
   `Option+Space`, logs a warning. Toggles the palette on trigger.
4. **CommandStore** — loads and parses the JSON config; exposes `[Command]`
   and the parsed hotkey. Writes defaults if the file is missing. Watches the
   file and reloads on change.
5. **CommandRunner** — runs a command's shell string via `Process` with
   `/bin/sh -c`, off the main thread. Reports non-zero exit without crashing.
6. **PaletteWindow + PaletteView (SwiftUI)** — Spotlight-style centered
   floating panel (`NSPanel`, `.nonactivatingPanel`, floating window level).
   Text field + fuzzy-filtered result list. Keyboard: arrows move selection,
   Enter runs + closes, Esc dismisses. Dismisses on focus loss.
7. **FuzzyMatcher** — scores and filters commands against the query.
8. **LoginItemManager** — wraps `SMAppService` register / unregister /
   status.

## Data Model

`Command = { name: String, shell: String }`

Config file: `~/.config/quickcmd/commands.json`, created with defaults on
first run. Single root object holding hotkey + commands:

```json
{
  "hotkey": { "key": "space", "modifiers": ["option"] },
  "commands": [
    {
      "name": "Quit All Apps",
      "shell": "osascript -e 'tell application \"System Events\" to set l to name of (every process whose visible is true and name is not \"Finder\")' -e 'repeat with a in l' -e 'tell application a to quit' -e 'end repeat'"
    },
    { "name": "Shut Down", "shell": "osascript -e 'tell application \"System Events\" to shut down'" },
    { "name": "Restart",   "shell": "osascript -e 'tell application \"System Events\" to restart'" },
    { "name": "Sleep",     "shell": "osascript -e 'tell application \"System Events\" to sleep'" },
    { "name": "Lock Screen", "shell": "pmset displaysleepnow" },
    { "name": "Empty Trash", "shell": "osascript -e 'tell application \"Finder\" to empty trash'" }
  ]
}
```

### Hotkey config

- `hotkey.key` — key name string, e.g. `"space"`, `"k"`.
- `hotkey.modifiers` — list of: `option`, `command`, `control`, `shift`.
- Missing or invalid → default `Option+Space`.

### AppleScript rationale

Commands run through `osascript` targeting `System Events`, so behavior
matches the user performing the action via native UI: apps run their own quit
handlers (unsaved-changes dialogs appear), "reopen windows" preferences are
honored, etc.

`System Events` shutdown/restart triggers a one-time macOS **Automation**
permission prompt on first run (System Settings → Privacy & Security →
Automation). Documented in README; no code workaround needed.

## Data Flow

`Option+Space` → HotkeyManager toggles PaletteWindow → user types → query
sent to FuzzyMatcher, which filters CommandStore's list → user presses Enter →
CommandRunner runs the selected command's shell string asynchronously →
palette closes.

## Error Handling

- **Invalid JSON** — keep last-good command list, surface an error state on
  the status bar icon, log the parse reason.
- **Missing config file** — write defaults.
- **Invalid hotkey** — fall back to `Option+Space`, log a warning.
- **Non-zero shell exit** — brief notification / log entry; never crash.

## Testing

Unit tests:

- **FuzzyMatcher** — `"qaa"` matches `"Quit All Apps"`; ranking order; empty
  query returns all.
- **CommandStore** — parse valid config; invalid JSON keeps last-good;
  defaults written when file missing; hotkey parsed correctly; invalid hotkey
  falls back to default.
- **CommandRunner** — run `echo`, assert exit code + captured output; failure
  path for non-zero exit.

Manual (hard to unit test): global hotkey registration, palette focus/dismiss
behavior, launch-at-login toggle, AppleScript system actions.
