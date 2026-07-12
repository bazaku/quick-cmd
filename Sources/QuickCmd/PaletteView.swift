import SwiftUI
import AppKit
import QuickCmdCore

private enum PaletteRow: Identifiable {
    case command(Command)
    case app(AppItem)

    var id: String {
        switch self {
        case .command(let c): return "cmd:\(c.id)"
        case .app(let a):     return "app:\(a.url.path)"
        }
    }
}

struct PaletteView: View {
    let commands: [Command]
    let apps: [AppItem]
    let onRun: (Command) -> Void
    let onOpen: (AppItem) -> Void
    let onEscape: () -> Void

    @State private var query = ""
    @State private var selection = 0

    private var filteredCommands: [Command] {
        FuzzyMatcher.filter(commands, query: query)
    }

    private var filteredApps: [AppItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return apps
            .compactMap { item -> (Int, AppItem)? in
                guard let s = FuzzyMatcher.score(item.name, query: query) else { return nil }
                return (s, item)
            }
            .sorted { $0.0 > $1.0 }
            .map(\.1)
    }

    private var rows: [PaletteRow] {
        filteredCommands.map { .command($0) } + filteredApps.map { .app($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            CommandTextField(
                text: $query,
                onDown:   { moveSelection(1) },
                onUp:     { moveSelection(-1) },
                onEnter:  { runSelected() },
                onEscape: onEscape
            )
            .font(.system(size: 22))
            .frame(height: 54)
            .padding(.horizontal, 16)
            .onChange(of: query) { _ in selection = 0 }

            Divider()

            List {
                Section(header: Text("Commands").foregroundColor(.secondary).font(.caption)) {
                    ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                        Text(command.name)
                            .padding(.vertical, 4)
                            .listRowBackground(index == selection
                                ? Color.accentColor.opacity(0.25) : Color.clear)
                    }
                }

                if !filteredApps.isEmpty {
                    Section(header: Text("Applications").foregroundColor(.secondary).font(.caption)) {
                        ForEach(Array(filteredApps.enumerated()), id: \.element.id) { index, app in
                            HStack(spacing: 8) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                Text(app.name)
                            }
                            .padding(.vertical, 2)
                            .listRowBackground((filteredCommands.count + index) == selection
                                ? Color.accentColor.opacity(0.25) : Color.clear)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: 260)
        }
        .frame(width: 560)
        .background(.ultraThinMaterial)
    }

    private func moveSelection(_ delta: Int) {
        guard !rows.isEmpty else { return }
        selection = min(max(0, selection + delta), rows.count - 1)
    }

    private func runSelected() {
        guard rows.indices.contains(selection) else { return }
        switch rows[selection] {
        case .command(let c): onRun(c)
        case .app(let a):     onOpen(a)
        }
    }
}

// MARK: - CommandTextField

/// NSTextField wrapper that intercepts arrow/enter/escape keys before AppKit
/// consumes them, so the palette can navigate the list while typing.
private struct CommandTextField: NSViewRepresentable {
    @Binding var text: String
    let onDown: () -> Void
    let onUp: () -> Void
    let onEnter: () -> Void
    let onEscape: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = "Search commands and apps…"
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.delegate = context.coordinator
        field.stringValue = text
        DispatchQueue.main.async { field.becomeFirstResponder() }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CommandTextField
        init(_ parent: CommandTextField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.moveDown(_:)):
                parent.onDown(); return true
            case #selector(NSResponder.moveUp(_:)):
                parent.onUp(); return true
            case #selector(NSResponder.insertNewline(_:)):
                parent.onEnter(); return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onEscape(); return true
            default:
                return false
            }
        }
    }
}
