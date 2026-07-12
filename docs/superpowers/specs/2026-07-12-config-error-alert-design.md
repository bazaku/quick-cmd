---
title: Config Error Alert
date: 2026-07-12
status: approved
---

## Goal

Show a user-visible alert when config loading fails, on both initial launch and manual reload.

## Current Behavior

`CommandStore.load()` calls `onError(message)` on failure. `AppDelegate` handles this by logging and setting the status bar error icon. No alert is shown.

## Change

Extend the `store.onError` closure in `AppDelegate` to present an `NSAlert` after setting the error state.

**Trigger:** both `init` (initial load) and `reload()` paths in `CommandStore` — both call `load()`, which calls `onError`.

**Alert spec:**
- Style: `.warning`
- Message text: "Config Error"
- Informative text: the error string passed by `CommandStore`
- Buttons: "OK" (default), "Open Config"
- "Open Config" opens `CommandStore.defaultConfigURL` via `NSWorkspace.shared.open(_:)`

**Thread safety:** `onError` fires on whatever thread calls `load()`. Alert is dispatched to main thread via `DispatchQueue.main.async`.

## Affected Files

- `Sources/QuickCmd/AppDelegate.swift` — only change

## Out of Scope

- No changes to `CommandStore` or any Core target
- No new types or files
