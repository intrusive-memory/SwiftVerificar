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
/// Reacts to zoom level, display mode, search text changes, and violation
/// annotations on the model. Violation annotations are added/removed when
/// validation results change and can be toggled on/off via `showViolationHighlights`.
struct PDFViewRepresentable: NSViewRepresentable {

    @Bindable var documentModel: PDFDocumentModel
    var violations: [ViolationItem] = []
    var showViolationHighlights: Bool = false
    var selectedViolationID: String? = nil
    var onAnnotationClicked: ((ViolationItem) -> Void)? = nil

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

        // Listen for annotation hit notifications for violation click-to-select.
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.annotationClicked(_:)),
            name: .PDFViewAnnotationHit,
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

        // Handle violation annotation updates.
        updateViolationAnnotations(pdfView: pdfView, coordinator: coordinator)

        // Handle selected violation scrolling.
        if let selectedID = selectedViolationID,
           selectedID != coordinator.lastSelectedViolationID {
            coordinator.lastSelectedViolationID = selectedID
            scrollToViolationAnnotation(selectedID, in: pdfView, coordinator: coordinator)
        } else if selectedViolationID == nil {
            coordinator.lastSelectedViolationID = nil
        }
    }

    // MARK: - Violation Annotations

    /// Updates violation annotations on the PDF document pages.
    ///
    /// Removes existing violation annotations and re-adds them if
    /// `showViolationHighlights` is enabled and there are violations.
    private func updateViolationAnnotations(pdfView: PDFView, coordinator: Coordinator) {
        guard let document = pdfView.document else {
            coordinator.currentAnnotations = []
            return
        }

        // Check if violations or highlight toggle changed.
        let violationIDs = Set(violations.map(\.id))
        let existingIDs = Set(coordinator.currentAnnotations.map(\.violationItem.id))

        let needsUpdate = violationIDs != existingIDs
            || coordinator.lastShowHighlights != showViolationHighlights

        guard needsUpdate else { return }
        coordinator.lastShowHighlights = showViolationHighlights

        // Remove existing violation annotations.
        for annotation in coordinator.currentAnnotations {
            annotation.page?.removeAnnotation(annotation)
        }
        coordinator.currentAnnotations = []

        // Add new annotations if highlights are enabled.
        guard showViolationHighlights else { return }

        for violation in violations {
            guard let pageIndex = violation.pageIndex,
                  let page = document.page(at: pageIndex) else { continue }

            let bounds = ViolationAnnotation.defaultBounds(for: violation, on: page)
            let annotation = ViolationAnnotation(violation: violation, bounds: bounds, page: page)
            page.addAnnotation(annotation)
            coordinator.currentAnnotations.append(annotation)
        }
    }

    /// Scrolls the PDF view to the annotation matching the given violation ID.
    private func scrollToViolationAnnotation(
        _ violationID: String,
        in pdfView: PDFView,
        coordinator: Coordinator
    ) {
        guard let annotation = coordinator.currentAnnotations.first(
            where: { $0.violationItem.id == violationID }
        ) else { return }

        if let page = annotation.page {
            let destination = PDFDestination(page: page, at: CGPoint(
                x: annotation.bounds.midX,
                y: annotation.bounds.midY
            ))
            pdfView.go(to: destination)
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

        /// Tracks currently added violation annotations for removal on update.
        var currentAnnotations: [ViolationAnnotation] = []

        /// Tracks the last known highlight toggle state.
        var lastShowHighlights: Bool = false

        /// Tracks the last selected violation ID to avoid redundant scrolling.
        var lastSelectedViolationID: String?

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

        /// Handles annotation clicks in the PDF view. When a user clicks on a
        /// ViolationAnnotation, this notifies the parent to select it in the list.
        @objc func annotationClicked(_ notification: Notification) {
            guard let annotation = notification.userInfo?["PDFAnnotationHit"] as? ViolationAnnotation else {
                return
            }
            parent.onAnnotationClicked?(annotation.violationItem)
        }
    }
}
