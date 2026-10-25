import UIKit
import PDFKit
import ImageIO
import ZIPFoundation

protocol ComicDocument: AnyObject {
    var pageCount: Int { get }
    func image(at index: Int, maxDimension: CGFloat) -> UIImage?
}

enum ImageTools {
    static func downsample(data: Data, maxDimension: CGFloat) -> UIImage? {
        let srcOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let src = CGImageSourceCreateWithData(data as CFData, srcOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, options) else { return nil }
        return UIImage(cgImage: cg)
    }
}

final class PDFComic: ComicDocument {
    private let doc: PDFDocument

    init?(url: URL) {
        guard let d = PDFDocument(url: url), d.pageCount > 0 else { return nil }
        doc = d
    }

    var pageCount: Int { doc.pageCount }

    func image(at index: Int, maxDimension: CGFloat) -> UIImage? {
        guard let page = doc.page(at: index) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = maxDimension / max(bounds.width, bounds.height)
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        return page.thumbnail(of: size, for: .mediaBox)
    }
}

final class CBZComic: ComicDocument {
    private let archive: Archive
    private let entries: [Entry]

    init?(url: URL) {
        guard let archive = try? Archive(url: url, accessMode: .read) else { return nil }
        let allowed: Set<String> = ["jpg", "jpeg", "png", "gif", "webp", "heic", "bmp", "tif", "tiff"]
        var list: [Entry] = []
        for entry in archive {
            guard entry.type == .file else { continue }
            let path = entry.path
            let last = (path as NSString).lastPathComponent
            if path.contains("__MACOSX") || last.hasPrefix(".") { continue }
            if allowed.contains((last as NSString).pathExtension.lowercased()) {
                list.append(entry)
            }
        }
        guard !list.isEmpty else { return nil }
        list.sort { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
        self.archive = archive
        self.entries = list
    }

    var pageCount: Int { entries.count }

    func image(at index: Int, maxDimension: CGFloat) -> UIImage? {
        guard entries.indices.contains(index) else { return nil }
        var data = Data()
        do {
            _ = try archive.extract(entries[index]) { chunk in
                data.append(chunk)
            }
        } catch {
            return nil
        }
        return ImageTools.downsample(data: data, maxDimension: maxDimension)
    }
}

enum ComicLoader {
    static func open(url: URL) -> ComicDocument? {
        switch url.pathExtension.lowercased() {
        case "pdf": return PDFComic(url: url)
        case "cbz", "zip": return CBZComic(url: url)
        default: return nil
        }
    }
}

/// Φορτώνει σελίδες στο παρασκήνιο, με cache και prefetch.
final class ComicSession {
    private let doc: ComicDocument
    private let cache = NSCache<NSNumber, UIImage>()
    private let queue = DispatchQueue(label: "comic.render", qos: .userInitiated)
    private let maxDimension: CGFloat = 2200

    init(doc: ComicDocument) {
        self.doc = doc
        cache.countLimit = 6
    }

    var pageCount: Int { doc.pageCount }

    func load(_ index: Int, completion: @escaping (UIImage?) -> Void) {
        let key = NSNumber(value: index)
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }
        queue.async { [weak self] in
            guard let self else { return }
            var image = self.cache.object(forKey: key)
            if image == nil {
                image = self.doc.image(at: index, maxDimension: self.maxDimension)
                if let image { self.cache.setObject(image, forKey: key) }
            }
            DispatchQueue.main.async { completion(image) }
        }
    }

    func prefetch(_ index: Int) {
        guard index >= 0, index < pageCount else { return }
        load(index) { _ in }
    }
}
