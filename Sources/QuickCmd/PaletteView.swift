import SwiftUI
import QuickCmdCore

struct PaletteView: View {
    let commands: [Command]
    let onRun: (Command) -> Void
    let onEscape: () -> Void

    @State private var query = ""
    @State private var selection = 0
    @FocusState private var fieldFocused: Bool

    private var results: [Command] {
        FuzzyMatcher.filter(commands, query: query)
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search commands…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 22))
                .padding(16)
                .focused($fieldFocused)
                .onChange(of: query) { _ in selection = 0 }
                .onSubmit { runSelected() }

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
        .onAppear { fieldFocused = true }
        .background(KeyCatcher(
            onDown: { moveSelection(1) },
            onUp: { moveSelection(-1) },
            onEnter: { runSelected() },
            onEscape: onEscape))
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

/// Bridges raw arrow/enter/escape key events into SwiftUI closures.
private struct KeyCatcher: NSViewRepresentable {
    let onDown: () -> Void
    let onUp: () -> Void
    let onEnter: () -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = CatcherView()
        view.onDown = onDown
        view.onUp = onUp
        view.onEnter = onEnter
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class CatcherView: NSView {
        var onDown: (() -> Void)?
        var onUp: (() -> Void)?
        var onEnter: (() -> Void)?
        var onEscape: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            switch Int(event.keyCode) {
            case 125: onDown?()      // down arrow
            case 126: onUp?()        // up arrow
            case 36, 76: onEnter?()  // return / enter
            case 53: onEscape?()     // escape
            default: super.keyDown(with: event)
            }
        }
    }
}
