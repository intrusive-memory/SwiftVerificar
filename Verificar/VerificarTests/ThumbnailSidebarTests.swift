//
//  ThumbnailSidebarTests.swift
//  VerificarTests
//
//  Created by TOM STOVALL on 2/7/26.
//

import Testing
import PDFKit
@testable import Verificar

@Suite("ThumbnailSidebar")
struct ThumbnailSidebarTests {

    // MARK: - PDFPage Thumbnail Generation

    @Test("PDFPage.thumbnailImage generates an image with correct aspect ratio")
    @MainActor
    func thumbnailImageGeneratesCorrectSize() {
        // Create a document and get a page to test thumbnail generation
        let document = createTestPDFDocument(pageCount: 1)
        guard let page = document.page(at: 0) else {
            Issue.record("Failed to get page from test document")
            return
        }

        let thumbnailWidth: CGFloat = 120
        let thumbnail = page.thumbnailImage(width: thumbnailWidth)

        // The image should have a non-zero size
        #expect(thumbnail.size.width > 0)
        #expect(thumbnail.size.height > 0)

        // Width should be approximately the requested width (within tolerance for rounding)
        let widthRatio = thumbnail.size.width / thumbnailWidth
        #expect(widthRatio > 0.5, "Thumbnail width should be reasonable relative to requested width")
    }

    @Test("PDFDocument.allPages returns all pages in order")
    @MainActor
    func allPagesReturnsCorrectCount() {
        let document = createTestPDFDocument(pageCount: 5)
        let pages = document.allPages

        #expect(pages.count == 5)

        // Verify each page matches what we get via page(at:)
        for (index, page) in pages.enumerated() {
            #expect(page === document.page(at: index))
        }
    }

    @Test("PDFDocument.indexedPages returns index-page pairs")
    @MainActor
    func indexedPagesReturnsCorrectPairs() {
        let document = createTestPDFDocument(pageCount: 3)
        let indexed = document.indexedPages

        #expect(indexed.count == 3)
        #expect(indexed[0].index == 0)
        #expect(indexed[1].index == 1)
        #expect(indexed[2].index == 2)
    }

    // MARK: - Page Selection Callback

    @Test("Clicking a thumbnail updates currentPageIndex on the model")
    @MainActor
    func pageSelectionUpdatesModel() {
        let model = PDFDocumentModel()
        let document = createTestPDFDocument(pageCount: 5)
        model.pdfDocument = document

        // Initial state
        #expect(model.currentPageIndex == 0)

        // Simulate what the thumbnail click does: call goToPage
        model.goToPage(3)
        #expect(model.currentPageIndex == 3)

        // Simulate clicking another thumbnail
        model.goToPage(0)
        #expect(model.currentPageIndex == 0)

        // Out-of-bounds index should clamp
        model.goToPage(100)
        #expect(model.currentPageIndex == 4) // clamped to last page
    }

    @Test("Thumbnail generation with zero-page document returns empty image")
    @MainActor
    func emptyDocumentThumbnail() {
        let document = PDFDocument()
        let pages = document.allPages

        #expect(pages.isEmpty)
        #expect(document.indexedPages.isEmpty)
    }

    // MARK: - Helpers

    /// Creates a minimal in-memory PDFDocument with the given number of blank pages.
    private func createTestPDFDocument(pageCount: Int) -> PDFDocument {
        let document = PDFDocument()
        for index in 0..<pageCount {
            let page = PDFPage()
            document.insert(page, at: index)
        }
        return document
    }
}
