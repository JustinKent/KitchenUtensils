import Foundation
import Testing
import UIKit
@testable import KitchenUtensils

@Suite("ImageRepository basic behaviors")
struct ImageRepositoryTests {

    // Helper to create a solid color image
    private func makeImage(size: CGSize = CGSize(width: 400, height: 300), color: UIColor = .red) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func writeTempImage(_ image: UIImage, ext: String = "jpg") throws -> URL {
        let data: Data
        if ext.lowercased() == "png" {
            data = image.pngData()!
        } else {
            data = image.jpegData(compressionQuality: 0.9)!
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString)")
            .appendingPathExtension(ext)
        try data.write(to: url, options: .atomic)
        return url
    }

    @Test("Add image generates thumbnail and persists original, then delete removes them")
    func addThenDelete() async throws {
        let repo = ImageRepository()

        // Create a utensil-like name (UUID string)
        let name = UUID().uuidString
        let image = makeImage()
        let tempURL = try writeTempImage(image, ext: "jpg")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Add
        try await repo.add(image: tempURL, named: name)

        // Original should be loadable
        let original = await repo.original(for: name)
        #expect(original != nil)

        // Thumbnail should be present (cache or disk)
        let thumb1 = await repo.thumbnail(for: name)
        #expect(thumb1 != nil)
        if let t = thumb1 {
            // Thumbnail should be square and roughly the configured size (<= 180)
            #expect(abs(t.size.width - t.size.height) < 0.5)
            #expect(max(t.size.width, t.size.height) <= 180.5)
        }

        // Delete
        await repo.delete(name)

        // After delete, both should be nil
        let originalAfter = await repo.original(for: name)
        #expect(originalAfter == nil)

        let thumbAfter = await repo.thumbnail(for: name)
        #expect(thumbAfter == nil)
    }
}
