import Foundation

public enum AppScanner {
    public static func scan() -> [AppItem] {
        let roots = ["/Applications", "/System/Applications"].map { URL(fileURLWithPath: $0) }
        var seen = Set<URL>()
        var results: [AppItem] = []
        for root in roots {
            for item in scanRoot(root) where seen.insert(item.url).inserted {
                results.append(item)
            }
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public static func scan(at root: URL) -> [AppItem] {
        scanRoot(root).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func scanRoot(_ root: URL) -> [AppItem] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: []
        ) else { return [] }

        var results: [AppItem] = []
        for case let url as URL in enumerator {
            guard url.pathExtension == "app" else { continue }
            enumerator.skipDescendants()
            results.append(AppItem(name: appName(at: url), url: url))
        }
        return results
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
