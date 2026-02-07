//
//  PDFKitExtensions.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import PDFKit
import AppKit

// MARK: - PDFPage Thumbnail Generation

extension PDFPage {

    /// Generates a thumbnail image of the page at the specified width,
    /// preserving the original aspect ratio.
    ///
    /// - Parameter width: The desired width in points for the thumbnail.
    /// - Returns: An `NSImage` of the page thumbnail scaled to the given width.
    func thumbnailImage(width: CGFloat) -> NSImage {
        let pageBounds = bounds(for: .mediaBox)
        guard pageBounds.width > 0, pageBounds.height > 0 else {
            return NSImage()
        }
        let aspectRatio = pageBounds.height / pageBounds.width
        let thumbnailSize = CGSize(width: width, height: width * aspectRatio)
        return thumbnail(of: thumbnailSize, for: .mediaBox)
    }
}

// MARK: - PDFDocument Page Iteration

extension PDFDocument {

    /// Returns an array of all pages in the document.
    var allPages: [PDFPage] {
        (0..<pageCount).compactMap { page(at: $0) }
    }

    /// Returns an array of `(index, page)` tuples for all pages in the document.
    var indexedPages: [(index: Int, page: PDFPage)] {
        (0..<pageCount).compactMap { index in
            guard let page = page(at: index) else { return nil }
            return (index: index, page: page)
        }
    }
}
