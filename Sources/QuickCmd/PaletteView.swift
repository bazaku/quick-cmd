import SwiftUI
import AppKit
import QuickCmdCore

struct PaletteView: View {
    let commands: [Command]
    let onRun: (Command) -> Void
    let onEscape: () -> Void

    @State private var query = ""
    @State private var selection = 0

    private var results: [Command] {
        FuzzyMatcher.filter(commands, query: query)
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

            List(Array(results.enumerated()), id: \.element.id) { index, command in
                Text(command.name)
                    .padding(.vertical, 4)
                    .listRowBackground(index == selection ? Color.accentColor.opacity(0.25) : Color.clear)
            }
            .listStyle(.plain)
            .frame(height: 260)
        }
        .frame(width: 560)
        .background(.ultraThinMaterial)
    }

    private func moveSelection(_ delta: Int) {
        guard !results.isEmpty else { return }
        selection = min(max(0, selection + delta), results.count - 1)
    }

    private func runSelected() {
        guard results.indices.contains(selection) else { return }
        onRun(results[selection])
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
        field.placeholderString = "Search commands…"
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

        // Field editor routes special keys here before acting on them.
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
