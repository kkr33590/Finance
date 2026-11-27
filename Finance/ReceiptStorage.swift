import UIKit
import PDFKit

/// റെസിപ്റ്റ് ഇമേജുകൾ ഫോണിലെ Documents/Receipts ഫോൾഡറിൽ സൂക്ഷിക്കുന്നു
enum ReceiptStorage {
    private static var folder: URL {
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Receipts", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// ഇമേജ് ചെറുതാക്കി JPEG ആയി സേവ് ചെയ്ത് ഫയലിൻ്റെ പേര് തിരിച്ചു തരുന്നു
    static func save(_ image: UIImage) -> String? {
        let resized = downscale(image, maxSide: 1800)
        guard let data = resized.jpegData(compressionQuality: 0.8) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try data.write(to: folder.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            print("Receipt save failed: \(error)")
            return nil
        }
    }

    static func load(_ name: String) -> UIImage? {
        UIImage(contentsOfFile: folder.appendingPathComponent(name).path)
    }

    static func delete(_ name: String?) {
        if let name = name {
            try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
        }
    }

    /// Files ആപ്പിൽ നിന്നുള്ള ഇമേജ് / PDF (ആദ്യ പേജ്) UIImage ആക്കുന്നു
    static func image(fromFile url: URL) -> UIImage? {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }

        if url.pathExtension.lowercased() == "pdf" {
            guard let doc = PDFDocument(url: url), let page = doc.page(at: 0) else { return nil }
            let box = page.bounds(for: .mediaBox)
            let scale = 1600 / max(box.width, box.height)
            let size = CGSize(width: box.width * scale, height: box.height * scale)
            return page.thumbnail(of: size, for: .mediaBox)
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private static func downscale(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxSide else { return image }
        let scale = maxSide / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}