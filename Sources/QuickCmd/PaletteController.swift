import AppKit
import SwiftUI
import QuickCmdCore

final class PaletteController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private let commandsProvider: () -> [Command]
    private let appsProvider: () -> [AppItem]
    private let onRun: (Command) -> Void
    private let onOpen: (AppItem) -> Void

    init(
        commandsProvider: @escaping () -> [Command],
        appsProvider: @escaping () -> [AppItem],
        onRun: @escaping (Command) -> Void,
        onOpen: @escaping (AppItem) -> Void
    ) {
        self.commandsProvider = commandsProvider
        self.appsProvider = appsProvider
        self.onRun = onRun
        self.onOpen = onOpen
        super.init()
    }

    func toggle() {
        if panel?.isVisible == true { hide() } else { show() }
    }

    func show() {
        let root = PaletteView(
            commands: commandsProvider(),
            apps: appsProvider(),
            onRun: { [weak self] command in
                self?.hide()
                self?.onRun(command)
            },
            onOpen: { [weak self] item in
                self?.hide()
                self?.onOpen(item)
            },
            onEscape: { [weak self] in self?.hide() })

        let hosting = NSHostingController(rootView: root)
        let panel = NSPanel(contentViewController: hosting)
        panel.styleMask = [.nonactivatingPanel, .titled, .fullSizeContentView]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.delegate = self
        panel.center()

        self.panel = panel
        if #available(macOS 14, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
