import AppKit
import QuickCmdCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: CommandStore!
    private var hotkeyManager: HotkeyManager!
    private var palette: PaletteController!
    private var statusBar: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu-bar only

        store = CommandStore(configURL: CommandStore.defaultConfigURL)

        palette = PaletteController(
            commandsProvider: { [weak self] in self?.store.commands ?? [] },
            onRun: { command in CommandRunner.run(command.shell, completion: nil) })

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
        hotkeyManager.register(store.hotkey) { [weak self] in
            self?.palette.toggle()
        }
    }
}
