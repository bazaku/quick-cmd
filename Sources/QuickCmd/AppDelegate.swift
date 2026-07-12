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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let scanned = AppScanner.scan()
            DispatchQueue.main.async { self?.apps = scanned }
        }

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

        hotkeyManager = HotkeyManager()
        hotkeyManager.register(store.hotkey) { [weak self] in
            self?.palette.toggle()
        }
    }

    private func reloadConfig() {
        statusBar.setErrorState(false)
        store.reload()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let scanned = AppScanner.scan()
            DispatchQueue.main.async { self?.apps = scanned }
        }
        hotkeyManager.register(store.hotkey) { [weak self] in
            self?.palette.toggle()
        }
    }
}
