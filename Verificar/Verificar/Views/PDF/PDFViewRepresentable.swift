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

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Update the document reference only when it has actually changed.
        if pdfView.document !== documentModel.pdfDocument {
            pdfView.document = documentModel.pdfDocument
        }

        // Sync the current page if the model's page differs from the view's.
        if let targetPage = documentModel.currentPage,
           pdfView.currentPage !== targetPage {
            pdfView.go(to: targetPage)
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

        init(parent: PDFViewRepresentable) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else { return }

            let pageIndex = document.index(for: currentPage)
            if parent.documentModel.currentPageIndex != pageIndex {
                parent.documentModel.currentPageIndex = pageIndex
            }
        }
    }
}
