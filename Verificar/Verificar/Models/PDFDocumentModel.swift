//
//  PDFDocumentModel.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import PDFKit
import Observation

/// Observable model wrapping a PDFKit.PDFDocument.
///
/// Provides document loading, page navigation, and metadata access.
/// This type is implicitly @MainActor due to project build settings
/// (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
@Observable
final class PDFDocumentModel {

    // MARK: - Document State

    /// The underlying PDFKit document, or nil if no document is loaded.
    internal(set) var pdfDocument: PDFDocument?

    /// The file URL of the currently loaded document, or nil.
    internal(set) var url: URL?

    /// Whether a document is currently being loaded.
    private(set) var isLoading: Bool = false

    /// The last error encountered during loading, or nil.
    var error: (any Error)?

    // MARK: - Navigation

    /// The zero-based index of the current page.
    var currentPageIndex: Int = 0

    // MARK: - Computed Properties

    /// The number of pages in the loaded document, or 0 if no document.
    var pageCount: Int {
        pdfDocument?.pageCount ?? 0
    }

    /// The current PDFPage based on `currentPageIndex`, or nil.
    var currentPage: PDFPage? {
        pdfDocument?.page(at: currentPageIndex)
    }

    /// The document title derived from PDF metadata or the filename.
    var title: String {
        if let pdfDocument,
           let attributes = pdfDocument.documentAttributes,
           let pdfTitle = attributes[PDFDocumentAttribute.titleAttribute] as? String,
           !pdfTitle.isEmpty {
            return pdfTitle
        }
        if let url {
            return url.deletingPathExtension().lastPathComponent
        }
        return "Untitled"
    }

    /// Whether a document is currently loaded and ready for display.
    var isDocumentLoaded: Bool {
        pdfDocument != nil
    }

    // MARK: - Document Operations

    /// Opens a PDF document from the given file URL.
    ///
    /// - Parameter url: The file URL of the PDF to open.
    /// - Throws: `PDFDocumentError.failedToLoad` if the document cannot be loaded.
    func open(url: URL) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // PDFDocument init is synchronous but can be slow for large files.
        // We wrap it so callers can await it without blocking the main actor.
        guard let document = PDFDocument(url: url) else {
            let loadError = PDFDocumentError.failedToLoad(url: url)
            error = loadError
            throw loadError
        }

        pdfDocument = document
        self.url = url
        currentPageIndex = 0
    }

    /// Closes the currently loaded document and resets state.
    func close() {
        pdfDocument = nil
        url = nil
        currentPageIndex = 0
        error = nil
    }

    // MARK: - Navigation

    /// Navigates to the page at the given zero-based index.
    ///
    /// The index is clamped to the valid range `[0, pageCount - 1]`.
    /// If no document is loaded this is a no-op.
    func goToPage(_ index: Int) {
        guard pageCount > 0 else { return }
        currentPageIndex = max(0, min(index, pageCount - 1))
    }

    /// Advances to the next page, if available.
    func nextPage() {
        goToPage(currentPageIndex + 1)
    }

    /// Goes back to the previous page, if available.
    func previousPage() {
        goToPage(currentPageIndex - 1)
    }
}

// MARK: - Errors

/// Errors that can occur when loading a PDF document.
enum PDFDocumentError: LocalizedError, Sendable {
    case failedToLoad(url: URL)

    var errorDescription: String? {
        switch self {
        case .failedToLoad(let url):
            return "Failed to load PDF document at \(url.lastPathComponent)."
        }
    }
}
