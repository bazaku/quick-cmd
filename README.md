# QuickCmd

macOS menu-bar command launcher. Press the global hotkey (default
`Option+Space`) to open a search palette, type to fuzzy-search commands, and
press Enter to run one.

## Build & run

    make run

This builds a release binary, assembles `QuickCmd.app`, ad-hoc signs it, and
launches it. The app lives in the menu bar (no dock icon).

## Configuration

Commands and the hotkey live in `~/.config/quickcmd/commands.json`, created
with defaults on first launch. Each command is a shell string run via
`/bin/sh -c`. Edit the file, then choose **Reload Config** from the menu-bar
menu.

    {
      "hotkey": { "key": "space", "modifiers": ["option"] },
      "commands": [
        { "name": "Sleep", "shell": "osascript -e 'tell application \"System Events\" to sleep'" }
      ]
    }

- `hotkey.key`: a key name such as `space` or `k`.
- `hotkey.modifiers`: any of `option`, `command`, `control`, `shift`.
- Invalid or missing hotkey falls back to `Option+Space`.

## Permissions

Commands that shut down or restart the Mac go through AppleScript
(`System Events`). The first time you run one, macOS shows a one-time
**Automation** permission prompt (System Settings → Privacy & Security →
Automation). Approve it for QuickCmd.

## Launch at login

Toggle **Launch at Login** in the menu-bar menu. This uses `SMAppService` and
works reliably when the app is run from a stable location (e.g. move
`QuickCmd.app` to `/Applications`).
