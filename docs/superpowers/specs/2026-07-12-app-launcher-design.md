# App Launcher Feature Design

**Date:** 2026-07-12

## Goal

Add ability to search and open macOS apps from `/Applications` (including subfolders) directly from the QuickCmd palette. App rows display a 32×32pt icon + app name. Apps appear as a separate section below commands, visible only when a query is active.

## Data Model & Scanner (`QuickCmdCore`)

### `AppItem`

New file `Sources/QuickCmdCore/AppItem.swift`:

```swift
public struct AppItem: Equatable, Identifiable {
    public let name: String  // CFBundleDisplayName → CFBundleName → filename sans ".app"
    public let url: URL
    public var id: URL { url }
}
```

### `AppScanner`

New file `Sources/QuickCmdCore/AppScanner.swift`:

- `public static func scan() -> [AppItem]`
- Walks `/Applications` recursively with `FileManager.default.enumerator`
- Stops descending into `.app` bundles (treats them as leaf nodes)
- Name resolution order: `CFBundleDisplayName` → `CFBundleName` → `url.deletingPathExtension().lastPathComponent`
- Returns results sorted alphabetically by name
- Returns `[]` if `/Applications` is unreadable (no crash)

`FuzzyMatcher.score(_:query:)` already accepts a `String` — used on `item.name` directly, no changes.

## Wiring (`QuickCmd`)

### `AppDelegate`

```swift
private var apps: [AppItem] = []
```

In `applicationDidFinishLaunching`:
```swift
apps = AppScanner.scan()

palette = PaletteController(
    commandsProvider: { [weak self] in self?.store.commands ?? [] },
    appsProvider:     { [weak self] in self?.apps ?? [] },
    onRun:   { command in CommandRunner.run(command.shell, completion: nil) },
    onOpen:  { item in NSWorkspace.shared.open(item.url) }
)
```

In `reloadConfig`:
```swift
apps = AppScanner.scan()
```

### `PaletteController`

Gains `appsProvider: () -> [AppItem]` and `onOpen: (AppItem) -> Void` init parameters. Passes them through to `PaletteView`.

## UI (`PaletteView`)

### Row type

```swift
enum PaletteRow: Identifiable {
    case command(Command)
    case app(AppItem)

    var id: String {
        switch self {
        case .command(let c): return "cmd:\(c.id)"
        case .app(let a):     return "app:\(a.id)"
        }
    }
}
```

### Layout

- `query == ""` → show commands section only (all commands, no filter)
- `query != ""` → show commands section (fuzzy filtered) + apps section (fuzzy filtered, only if non-empty)
- Single flat `[PaletteRow]` array drives `List` — arrow key navigation and Enter work linearly across both sections
- Section headers: `Text("Commands")` / `Text("Applications")` styled muted

### App row

```swift
HStack(spacing: 8) {
    Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
        .resizable()
        .frame(width: 32, height: 32)
    Text(app.name)
}
```

Icon loading is inline — `NSWorkspace` caches icons, no extra caching layer needed.

### Other changes

- Placeholder text: `"Search commands and apps…"`
- No window size changes

## Error Handling

| Scenario | Behavior |
|---|---|
| `/Applications` unreadable | `AppScanner.scan()` returns `[]` |
| Bundle missing `Info.plist` | Fall back to filename sans `.app` |
| `NSWorkspace.open` failure | Silent (matches existing `CommandRunner` behavior) |
| Duplicate app names | Both shown; acceptable |

## Out of Scope

- `~/Applications` or other app directories
- Spotlight metadata or `mdfind`
- Background refresh timer
- Caching app list to disk
