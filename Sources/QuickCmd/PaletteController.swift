import AppKit
import SwiftUI
import QuickCmdCore

final class PaletteController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private let commandsProvider: () -> [Command]
    private let onRun: (Command) -> Void

    init(commandsProvider: @escaping () -> [Command], onRun: @escaping (Command) -> Void) {
        self.commandsProvider = commandsProvider
        self.onRun = onRun
        super.init()
    }

    func toggle() {
        if panel?.isVisible == true { hide() } else { show() }
    }

    func show() {
        let root = PaletteView(
            commands: commandsProvider(),
            onRun: { [weak self] command in
                self?.hide()
                self?.onRun(command)
            },
            onEscape: { [weak self] in self?.hide() })

        let hosting = NSHostingController(rootView: root)
        let panel = NSPanel(
            contentViewController: hosting)
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

    // Dismiss when the palette loses key status (focus loss).
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
