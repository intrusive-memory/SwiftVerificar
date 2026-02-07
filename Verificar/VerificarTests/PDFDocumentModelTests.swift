//
//  PDFDocumentModelTests.swift
//  VerificarTests
//
//  Created by TOM STOVALL on 2/7/26.
//

import Testing
import PDFKit
@testable import Verificar

@Suite("PDFDocumentModel")
struct PDFDocumentModelTests {

    // MARK: - Initialization

    @Test("Newly created model has no document loaded")
    @MainActor
    func initialState() {
        let model = PDFDocumentModel()

        #expect(model.pdfDocument == nil)
        #expect(model.url == nil)
        #expect(model.isLoading == false)
        #expect(model.error == nil)
        #expect(model.pageCount == 0)
        #expect(model.currentPageIndex == 0)
        #expect(model.currentPage == nil)
        #expect(model.isDocumentLoaded == false)
        #expect(model.title == "Untitled")
    }

    // MARK: - Page Navigation

    @Test("goToPage clamps index to valid range")
    @MainActor
    func goToPageClamping() async throws {
        let model = PDFDocumentModel()

        // Create a minimal in-memory PDF with multiple pages
        let document = createTestPDFDocument(pageCount: 5)
        model.pdfDocument = document

        // Navigate beyond bounds — should clamp to last page
        model.goToPage(100)
        #expect(model.currentPageIndex == 4)

        // Navigate to negative — should clamp to 0
        model.goToPage(-5)
        #expect(model.currentPageIndex == 0)

        // Navigate to valid index
        model.goToPage(2)
        #expect(model.currentPageIndex == 2)
    }

    @Test("nextPage and previousPage navigate correctly")
    @MainActor
    func nextAndPreviousPage() {
        let model = PDFDocumentModel()
        let document = createTestPDFDocument(pageCount: 3)
        model.pdfDocument = document

        #expect(model.currentPageIndex == 0)

        model.nextPage()
        #expect(model.currentPageIndex == 1)

        model.nextPage()
        #expect(model.currentPageIndex == 2)

        // Should stay at last page
        model.nextPage()
        #expect(model.currentPageIndex == 2)

        model.previousPage()
        #expect(model.currentPageIndex == 1)

        model.previousPage()
        #expect(model.currentPageIndex == 0)

        // Should stay at first page
        model.previousPage()
        #expect(model.currentPageIndex == 0)
    }

    @Test("pageCount reflects the underlying PDFDocument")
    @MainActor
    func pageCountReflectsDocument() {
        let model = PDFDocumentModel()

        #expect(model.pageCount == 0)

        let document = createTestPDFDocument(pageCount: 7)
        model.pdfDocument = document

        #expect(model.pageCount == 7)
    }

    @Test("currentPage returns the correct page for the current index")
    @MainActor
    func currentPageReturnsCorrectPage() {
        let model = PDFDocumentModel()
        let document = createTestPDFDocument(pageCount: 3)
        model.pdfDocument = document

        // Page 0
        let page0 = model.currentPage
        #expect(page0 != nil)
        #expect(page0 === document.page(at: 0))

        // Navigate to page 2
        model.goToPage(2)
        let page2 = model.currentPage
        #expect(page2 != nil)
        #expect(page2 === document.page(at: 2))
    }

    // MARK: - Close

    @Test("close resets all document state")
    @MainActor
    func closeResetsState() {
        let model = PDFDocumentModel()
        let document = createTestPDFDocument(pageCount: 3)
        model.pdfDocument = document

        model.goToPage(2)
        #expect(model.isDocumentLoaded == true)
        #expect(model.currentPageIndex == 2)

        model.close()

        #expect(model.pdfDocument == nil)
        #expect(model.url == nil)
        #expect(model.currentPageIndex == 0)
        #expect(model.error == nil)
        #expect(model.isDocumentLoaded == false)
    }

    @Test("title returns filename when no PDF metadata title exists")
    @MainActor
    func titleFromFilename() {
        let model = PDFDocumentModel()
        // Set a URL directly to test the filename fallback
        model.url = URL(fileURLWithPath: "/tmp/My Report.pdf")

        #expect(model.title == "My Report")
    }

    @Test("goToPage is a no-op when no document is loaded")
    @MainActor
    func goToPageNoDocument() {
        let model = PDFDocumentModel()
        model.goToPage(5)
        #expect(model.currentPageIndex == 0)
    }

    // MARK: - Helpers

    /// Creates a minimal in-memory PDFDocument with the given number of blank pages.
    private func createTestPDFDocument(pageCount: Int) -> PDFDocument {
        let document = PDFDocument()
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        for index in 0..<pageCount {
            let page = PDFPage()
            document.insert(page, at: index)
            _ = pageSize // suppress unused warning
        }
        return document
    }
}
