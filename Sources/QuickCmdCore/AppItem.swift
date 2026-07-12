import Foundation

public struct AppItem: Equatable, Identifiable {
    public let name: String
    public let url: URL

    public var id: URL { url }

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}
