//
//  ImageRepository.swift
//  KitchenUtensils
//
//  Created by Justin Kent on 9/2/25.
//

import Foundation
import UIKit

actor ImageRepository {
    private let fileManager: FileManager
    private let appSupportBaseURL: URL
    private let originalsDirectoryURL: URL
    private let thumbnailsDirectoryURL: URL
    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let thumbnailMaxPixelSize: CGFloat = 180

    // MARK: - Init

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        if let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            self.appSupportBaseURL = base.appendingPathComponent("KitchenUtensils", isDirectory: true)
        } else {
            // fallback to documents if application support is unavailable
            self.appSupportBaseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("KitchenUtensils", isDirectory: true)
        }

        self.originalsDirectoryURL = appSupportBaseURL.appendingPathComponent("Images/originals", isDirectory: true)
        self.thumbnailsDirectoryURL = appSupportBaseURL.appendingPathComponent("Images/thumbnails", isDirectory: true)

        Task { [weak self] in
            await self?.ensureDirectoriesSafely()
        }
    }

    // MARK: - Public API

    func add(image sourceURL: URL, named name: String) throws {
        try ensureDirectories()

        let originalURL = originalURLForName(name, sourceURL: sourceURL)
        let thumbnailURL = thumbnailURLForName(name)

        if fileManager.fileExists(atPath: originalURL.path) {
            try fileManager.removeItem(at: originalURL)
        }
        try fileManager.copyItem(at: sourceURL, to: originalURL)

        if let originalImage = UIImage(contentsOfFile: originalURL.path),
           let thumb = generateThumbnail(from: originalImage, maxPixelSize: thumbnailMaxPixelSize) {
            thumbnailCache.setObject(thumb, forKey: name as NSString)
            if let data = thumb.jpegData(compressionQuality: 0.8) {
                try fileManager.createDirectory(at: thumbnailsDirectoryURL, withIntermediateDirectories: true)
                try data.write(to: thumbnailURL, options: .atomic)
            }
        }
    }

    func thumbnail(for name: String) -> UIImage? {
        if let cached = thumbnailCache.object(forKey: name as NSString) {
            return cached
        }

        let url = thumbnailURLForName(name)
        guard fileManager.fileExists(atPath: url.path),
              let image = UIImage(contentsOfFile: url.path) else {
            // As a fallback, generate a thumbnail from the original if none exists
            if let original = original(for: name) {
                if let thumb = generateThumbnail(from: original, maxPixelSize: thumbnailMaxPixelSize) {
                    thumbnailCache.setObject(thumb, forKey: name as NSString)
                    if let data = thumb.jpegData(compressionQuality: 0.8) {
                        try? fileManager.createDirectory(at: thumbnailsDirectoryURL, withIntermediateDirectories: true)
                        try? data.write(to: url, options: .atomic)
                    }
                    return thumb
                }
            }
            return nil
        }

        thumbnailCache.setObject(image, forKey: name as NSString)
        return image
    }

    func original(for name: String) -> UIImage? {
        for ext in possibleExtensions {
            let url = originalsDirectoryURL.appendingPathComponent(name).appendingPathExtension(ext)
            if fileManager.fileExists(atPath: url.path), let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return nil
    }

    func delete(_ name: String) {
        thumbnailCache.removeObject(forKey: name as NSString)

        let thumbURL = thumbnailURLForName(name)
        if fileManager.fileExists(atPath: thumbURL.path) {
            try? fileManager.removeItem(at: thumbURL)
        }

        for ext in possibleExtensions {
            let url = originalsDirectoryURL.appendingPathComponent(name).appendingPathExtension(ext)
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
    }
    
    let possibleExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "bmp", "dat"]
    
    // MARK: - Helpers
    
    // Non-throwing async wrapper to call from Task in init
    private func ensureDirectoriesSafely() async {
        do {
            try ensureDirectories()
        } catch {
            fatalError("ImageRepository: Failed to ensure directories at \(appSupportBaseURL.path): \(error)")
        }
    }
    
    private func ensureDirectories() throws {
        // Ensure base Application Support/KitchenUtensils exists first
        try fileManager.createDirectory(at: appSupportBaseURL, withIntermediateDirectories: true)
        
        // Then ensure subdirectories
        try fileManager.createDirectory(at: originalsDirectoryURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: thumbnailsDirectoryURL, withIntermediateDirectories: true)
    }

    private func originalURLForName(_ name: String, sourceURL: URL) -> URL {
        let ext = sourceURL.pathExtension.isEmpty ? "dat" : sourceURL.pathExtension.lowercased()
        return originalsDirectoryURL.appendingPathComponent(name).appendingPathExtension(ext)
    }

    private func thumbnailURLForName(_ name: String) -> URL {
        thumbnailsDirectoryURL.appendingPathComponent(name).appendingPathExtension("jpg")
    }

    // Aspect fill with center crop to a square of size maxPixelSize x maxPixelSize
    private func generateThumbnail(from image: UIImage, maxPixelSize: CGFloat) -> UIImage? {
        let targetSide = max(1, Int(round(maxPixelSize)))
        let targetSize = CGSize(width: targetSide, height: targetSide)

        // Determine source size in pixels
        let sourceSizePoints = image.size
        let sourceScale = image.scale
        let sourcePixelSize = CGSize(width: sourceSizePoints.width * sourceScale,
                                     height: sourceSizePoints.height * sourceScale)

        guard sourcePixelSize.width > 0, sourcePixelSize.height > 0 else { return nil }

        // Compute aspect-fill scale so the shorter side meets targetSide
        let scale = max(CGFloat(targetSide) / sourcePixelSize.width,
                        CGFloat(targetSide) / sourcePixelSize.height)

        let scaledSize = CGSize(width: sourcePixelSize.width * scale,
                                height: sourcePixelSize.height * scale)

        // Compute origin so we center-crop to the square
        let x = (scaledSize.width - CGFloat(targetSide)) / 2.0
        let y = (scaledSize.height - CGFloat(targetSide)) / 2.0
        let drawRect = CGRect(origin: CGPoint(x: -x, y: -y), size: scaledSize)

        // Render at scale 1 to work in pixel space explicitly
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let result = renderer.image { _ in
            // Use CGImage if available to avoid resampling issues with UIImage’s scale/orientation
            if let cg = image.cgImage {
                let oriented = UIImage(cgImage: cg, scale: 1, orientation: image.imageOrientation)
                oriented.draw(in: drawRect)
            } else {
                // Fallback: draw UIImage directly (may be vector or CI-backed)
                image.draw(in: drawRect)
            }
        }

        return result
    }
}

import SwiftUI

private struct ImageRepositoryKey: EnvironmentKey {
    static let defaultValue: ImageRepository = ImageRepository()
}

extension EnvironmentValues {
    var imageRepository: ImageRepository {
        get { self[ImageRepositoryKey.self] }
        set { self[ImageRepositoryKey.self] = newValue }
    }
}
