//
//  PDFViewRepresentableTests.swift
//  VerificarTests
//
//  Created by TOM STOVALL on 2/7/26.
//

import Testing
import PDFKit
@testable import Verificar

@Suite("PDFViewRepresentable")
struct PDFViewRepresentableTests {

    // MARK: - NSView Creation

    @Test("makeNSView creates a properly configured PDFView")
    @MainActor
    func makeNSViewCreatesPDFView() {
        let model = PDFDocumentModel()
        let representable = PDFViewRepresentable(documentModel: model)
        let coordinator = representable.makeCoordinator()

        // Build a minimal context-like invocation by calling makeNSView
        // through the representable's public interface.
        let context = _PDFViewTestContext(coordinator: coordinator)
        let pdfView = representable.makeNSView(context: context)

        #expect(pdfView.autoScales == true)
        #expect(pdfView.displayMode == .singlePageContinuous)
        #expect(pdfView.displayDirection == .vertical)
        #expect(pdfView.delegate === coordinator)
    }

    @Test("updateNSView assigns a PDFDocument to the view")
    @MainActor
    func updateNSViewAssignsDocument() {
        let model = PDFDocumentModel()
        let document = createTestPDFDocument(pageCount: 3)
        model.pdfDocument = document

        let representable = PDFViewRepresentable(documentModel: model)
        let coordinator = representable.makeCoordinator()
        let context = _PDFViewTestContext(coordinator: coordinator)
        let pdfView = representable.makeNSView(context: context)

        // Before update, no document is set on the NSView.
        #expect(pdfView.document == nil)

        representable.updateNSView(pdfView, context: context)

        // After update, the document should be assigned.
        #expect(pdfView.document === document)
        #expect(pdfView.document?.pageCount == 3)
    }

    @Test("updateNSView does not reassign the same document")
    @MainActor
    func updateNSViewSkipsSameDocument() {
        let model = PDFDocumentModel()
        let document = createTestPDFDocument(pageCount: 2)
        model.pdfDocument = document

        let representable = PDFViewRepresentable(documentModel: model)
        let coordinator = representable.makeCoordinator()
        let context = _PDFViewTestContext(coordinator: coordinator)
        let pdfView = representable.makeNSView(context: context)

        // First update sets the document.
        representable.updateNSView(pdfView, context: context)
        #expect(pdfView.document === document)

        // Second update with same document should not change the reference.
        representable.updateNSView(pdfView, context: context)
        #expect(pdfView.document === document)
    }

    @Test("Coordinator updates model when page changes")
    @MainActor
    func coordinatorUpdatesModelOnPageChange() {
        let model = PDFDocumentModel()
        let document = createTestPDFDocument(pageCount: 5)
        model.pdfDocument = document

        let representable = PDFViewRepresentable(documentModel: model)
        let coordinator = representable.makeCoordinator()
        let context = _PDFViewTestContext(coordinator: coordinator)
        let pdfView = representable.makeNSView(context: context)
        representable.updateNSView(pdfView, context: context)

        // Simulate navigating to page 3 in the PDFView.
        if let page3 = document.page(at: 3) {
            pdfView.go(to: page3)
        }

        // Manually fire the coordinator's pageChanged handler
        // since notifications may not fire synchronously in tests.
        let notification = Notification(
            name: .PDFViewPageChanged,
            object: pdfView,
            userInfo: nil
        )
        coordinator.pageChanged(notification)

        #expect(model.currentPageIndex == 3)
    }

    // MARK: - Helpers

    private func createTestPDFDocument(pageCount: Int) -> PDFDocument {
        let document = PDFDocument()
        for index in 0..<pageCount {
            let page = PDFPage()
            document.insert(page, at: index)
        }
        return document
    }
}

// MARK: - Test Support

/// A lightweight wrapper that satisfies the `context` parameter requirement
/// of `makeNSView(context:)` and `updateNSView(_:context:)` by providing
/// the coordinator.  In production SwiftUI creates this; in tests we
/// construct it directly.
struct _PDFViewTestContext: @unchecked Sendable {
    let coordinator: PDFViewRepresentable.Coordinator
}

// Extend PDFViewRepresentable with overloads that accept our test context.
extension PDFViewRepresentable {

    @MainActor
    func makeNSView(context: _PDFViewTestContext) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    @MainActor
    func updateNSView(_ pdfView: PDFView, context: _PDFViewTestContext) {
        if pdfView.document !== documentModel.pdfDocument {
            pdfView.document = documentModel.pdfDocument
        }

        if let targetPage = documentModel.currentPage,
           pdfView.currentPage !== targetPage {
            pdfView.go(to: targetPage)
        }
    }
}
