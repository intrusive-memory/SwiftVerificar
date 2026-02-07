//
//  ThumbnailSidebarView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI
import PDFKit

/// Displays a scrollable list of page thumbnails in the sidebar.
///
/// Each thumbnail shows a page number label and a rendered image from PDFKit.
/// The selected page is highlighted with an accent color border. Clicking a
/// thumbnail updates `currentPageIndex` on the document model, and the list
/// auto-scrolls to reflect the current page when it changes elsewhere (e.g.,
/// from the main PDFView).
struct ThumbnailSidebarView: View {

    @Environment(PDFDocumentModel.self) private var documentModel

    /// The width used for thumbnail rendering.
    private let thumbnailWidth: CGFloat = 120

    var body: some View {
        if documentModel.isDocumentLoaded {
            thumbnailList
        } else {
            emptyState
        }
    }

    // MARK: - Thumbnail List

    private var thumbnailList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<documentModel.pageCount, id: \.self) { index in
                        thumbnailCell(for: index)
                            .id(index)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .onChange(of: documentModel.currentPageIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                // Scroll to the current page when the view first appears
                proxy.scrollTo(documentModel.currentPageIndex, anchor: .center)
            }
        }
    }

    // MARK: - Thumbnail Cell

    private func thumbnailCell(for pageIndex: Int) -> some View {
        let isSelected = documentModel.currentPageIndex == pageIndex

        return Button {
            documentModel.goToPage(pageIndex)
        } label: {
            VStack(spacing: 4) {
                thumbnailImage(for: pageIndex)
                    .frame(width: thumbnailWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                isSelected ? Color.accentColor : Color.clear,
                                lineWidth: isSelected ? 3 : 0
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.15),
                        radius: isSelected ? 4 : 2,
                        x: 0,
                        y: 1
                    )

                Text("\(pageIndex + 1)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Page \(pageIndex + 1)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Thumbnail Image

    private func thumbnailImage(for pageIndex: Int) -> some View {
        Group {
            if let page = documentModel.pdfDocument?.page(at: pageIndex) {
                let nsImage = page.thumbnailImage(width: thumbnailWidth * 2) // 2x for Retina
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .aspectRatio(8.5 / 11, contentMode: .fit)
                    .overlay {
                        Image(systemName: "doc")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.grid.1x2")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Page Thumbnails")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Open a PDF to view thumbnails.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("With Document") {
    let model = PDFDocumentModel()
    ThumbnailSidebarView()
        .environment(model)
        .frame(width: 220, height: 500)
        .onAppear {
            let document = PDFDocument()
            for i in 0..<5 {
                if let page = PDFPage() as PDFPage? {
                    document.insert(page, at: i)
                }
            }
            model.pdfDocument = document
        }
}

#Preview("Empty") {
    ThumbnailSidebarView()
        .environment(PDFDocumentModel())
        .frame(width: 220, height: 500)
}
