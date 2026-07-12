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
