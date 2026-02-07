//
//  PDFViewRepresentable.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI
import PDFKit

/// Wraps PDFKit's `PDFView` (an AppKit view) for use in SwiftUI via NSViewRepresentable.
///
/// Configures the PDF view for continuous vertical scrolling with auto-scaling,
/// and uses a Coordinator to observe page-change notifications so the model's
/// `currentPageIndex` stays in sync with user scrolling.
///
/// Reacts to zoom level, display mode, and search text changes on the model.
struct PDFViewRepresentable: NSViewRepresentable {

    @Bindable var documentModel: PDFDocumentModel

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator

        // Listen for page-change notifications from the PDFView.
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        // Listen for scale-change notifications to sync zoom level back to model.
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scaleChanged(_:)),
            name: .PDFViewScaleChanged,
            object: pdfView
        )

        // Store reference for search delegate use.
        context.coordinator.pdfView = pdfView

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Track whether we're programmatically updating to avoid feedback loops.
        context.coordinator.isUpdating = true
        defer { context.coordinator.isUpdating = false }

        // Update the document reference only when it has actually changed.
        if pdfView.document !== documentModel.pdfDocument {
            pdfView.document = documentModel.pdfDocument
        }

        // Update display mode.
        if pdfView.displayMode != documentModel.displayMode {
            pdfView.displayMode = documentModel.displayMode
        }

        // Update zoom / auto-scale.
        if documentModel.autoScalesEnabled {
            if !pdfView.autoScales {
                pdfView.autoScales = true
            }
        } else if documentModel.fitWidthRequested {
            pdfView.autoScales = false
            if let currentPage = pdfView.currentPage {
                let pageBounds = currentPage.bounds(for: pdfView.displayBox)
                let viewWidth = pdfView.bounds.width - 40 // Account for some padding
                if pageBounds.width > 0 {
                    let fitWidthScale = viewWidth / pageBounds.width
                    pdfView.scaleFactor = fitWidthScale
                }
            }
        } else {
            pdfView.autoScales = false
            let tolerance: CGFloat = 0.001
            if abs(pdfView.scaleFactor - documentModel.zoomLevel) > tolerance {
                pdfView.scaleFactor = documentModel.zoomLevel
            }
        }

        // Sync the current page if the model's page differs from the view's.
        if let targetPage = documentModel.currentPage,
           pdfView.currentPage !== targetPage {
            pdfView.go(to: targetPage)
        }

        // Handle search text changes.
        let coordinator = context.coordinator
        if coordinator.lastSearchText != documentModel.searchText {
            coordinator.lastSearchText = documentModel.searchText
            if documentModel.searchText.isEmpty {
                // Clear highlights.
                pdfView.highlightedSelections = nil
                documentModel.searchResults = []
            } else {
                // Perform search using PDFDocument's built-in find.
                if let document = pdfView.document {
                    let selections = document.findString(
                        documentModel.searchText,
                        withOptions: [.caseInsensitive]
                    )
                    documentModel.searchResults = selections
                    pdfView.highlightedSelections = selections
                    // Go to the first result.
                    if let first = selections.first {
                        pdfView.setCurrentSelection(first, animate: true)
                        if let firstPage = first.pages.first {
                            pdfView.go(to: firstPage)
                        }
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    static func dismantleNSView(_ pdfView: PDFView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }

    // MARK: - Coordinator

    /// Receives delegate callbacks and notifications from the underlying PDFView,
    /// then propagates changes back to the SwiftUI model layer.
    final class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFViewRepresentable
        var isUpdating: Bool = false
        var lastSearchText: String = ""
        weak var pdfView: PDFView?

        init(parent: PDFViewRepresentable) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard !isUpdating,
                  let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else { return }

            let pageIndex = document.index(for: currentPage)
            if parent.documentModel.currentPageIndex != pageIndex {
                parent.documentModel.currentPageIndex = pageIndex
            }
        }

        @objc func scaleChanged(_ notification: Notification) {
            guard !isUpdating,
                  let pdfView = notification.object as? PDFView else { return }

            // Sync the scale factor back to the model so the toolbar percentage stays accurate.
            let newScale = pdfView.scaleFactor
            let tolerance: CGFloat = 0.001
            if abs(parent.documentModel.zoomLevel - newScale) > tolerance {
                parent.documentModel.zoomLevel = newScale
            }
        }
    }
}
