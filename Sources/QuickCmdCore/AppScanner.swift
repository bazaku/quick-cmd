import Foundation

public enum AppScanner {
    public static func scan(at root: URL = URL(fileURLWithPath: "/Applications")) -> [AppItem] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: []
        ) else { return [] }

        var results: [AppItem] = []

        for case let url as URL in enumerator {
            guard url.pathExtension == "app" else { continue }
            enumerator.skipDescendants()
            let name = appName(at: url)
            results.append(AppItem(name: name, url: url))
        }

        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func appName(at url: URL) -> String {
        let plistURL = url.appendingPathComponent("Contents/Info.plist")
        if let plist = NSDictionary(contentsOf: plistURL) {
            if let d = plist["CFBundleDisplayName"] as? String, !d.isEmpty { return d }
            if let b = plist["CFBundleName"] as? String, !b.isEmpty { return b }
        }
        return url.deletingPathExtension().lastPathComponent
    }
}
