//
//  PDFRenderView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// Container view that wraps `PDFViewRepresentable` and provides
/// loading and empty-state overlays.
///
/// Passes violation data and highlight state through to the PDF representable
/// so that violation annotations can be overlaid on the PDF view.
struct PDFRenderView: View {

    @Bindable var documentModel: PDFDocumentModel
    var violations: [ViolationItem] = []
    var showViolationHighlights: Bool = false
    var selectedViolationID: String? = nil
    var onAnnotationClicked: ((ViolationItem) -> Void)? = nil

    var body: some View {
        ZStack {
            if documentModel.isLoading {
                loadingOverlay
            } else if documentModel.isDocumentLoaded {
                PDFViewRepresentable(
                    documentModel: documentModel,
                    violations: violations,
                    showViolationHighlights: showViolationHighlights,
                    selectedViolationID: selectedViolationID,
                    onAnnotationClicked: onAnnotationClicked
                )
            } else {
                noDocumentOverlay
            }
        }
    }

    // MARK: - Overlays

    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Loading document...")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private var noDocumentOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Document")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Open a PDF file to view it here.")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

#Preview("No Document") {
    PDFRenderView(documentModel: PDFDocumentModel())
}
