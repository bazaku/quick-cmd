import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onReload: () -> Void
    private let onQuit: () -> Void
    private let loginItem = NSMenuItem(
        title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")

    init(onReload: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onReload = onReload
        self.onQuit = onQuit
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        statusItem.button?.image = NSImage(
            systemSymbolName: "command", accessibilityDescription: "QuickCmd")

        let menu = NSMenu()
        loginItem.target = self
        loginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        let reload = NSMenuItem(title: "Reload Config", action: #selector(reload), keyEquivalent: "r")
        reload.target = self
        menu.addItem(reload)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "About QuickCmd", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "Quit QuickCmd", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    func setErrorState(_ hasError: Bool) {
        let symbol = hasError ? "exclamationmark.triangle" : "command"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbol, accessibilityDescription: "QuickCmd")
    }

    @objc private func toggleLogin() {
        let newValue = !LoginItemManager.isEnabled
        do {
            try LoginItemManager.setEnabled(newValue)
            loginItem.state = newValue ? .on : .off
        } catch {
            NSSound.beep()
        }
    }

    @objc private func reload() { onReload() }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() { onQuit() }
}
