import SwiftUI

enum PageMode: String, CaseIterable, Identifiable {
    case book
    case instant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .book: return "Βιβλίο (με animation)"
        case .instant: return "Απλό (χωρίς animation)"
        }
    }

    var icon: String {
        switch self {
        case .book: return "book.fill"
        case .instant: return "rectangle.portrait"
        }
    }
}

final class AppSettings: ObservableObject {
    enum Keys {
        static let userName = "userName"
        static let setupDone = "setupDone"
        static let pageMode = "pageMode"
        static let faceID = "faceIDLock"
        static let folder = "folderBookmark"
    }

    private let defaults = UserDefaults.standard

    @Published var userName: String { didSet { defaults.set(userName, forKey: Keys.userName) } }
    @Published var setupDone: Bool { didSet { defaults.set(setupDone, forKey: Keys.setupDone) } }
    @Published var pageMode: PageMode { didSet { defaults.set(pageMode.rawValue, forKey: Keys.pageMode) } }
    @Published var faceIDLock: Bool { didSet { defaults.set(faceIDLock, forKey: Keys.faceID) } }
    @Published var folderBookmark: Data? { didSet { defaults.set(folderBookmark, forKey: Keys.folder) } }

    init() {
        userName = defaults.string(forKey: Keys.userName) ?? ""
        setupDone = defaults.bool(forKey: Keys.setupDone)
        pageMode = PageMode(rawValue: defaults.string(forKey: Keys.pageMode) ?? "") ?? .book
        faceIDLock = defaults.bool(forKey: Keys.faceID)
        folderBookmark = defaults.data(forKey: Keys.folder)
    }
}

enum FolderAccess {
    static func makeBookmark(from url: URL) -> Data? {
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        return try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    static func resolve(_ data: Data) -> URL? {
        var stale = false
        return try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
    }
}
