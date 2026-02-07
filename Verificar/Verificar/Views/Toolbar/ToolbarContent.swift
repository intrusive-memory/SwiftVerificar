//
//  ToolbarContent.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI
import PDFKit

/// Display mode options for the segmented control in the toolbar.
///
/// Wraps PDFKit's `PDFDisplayMode` with user-facing labels.
enum ViewModeOption: String, CaseIterable, Identifiable {
    case singlePage = "Single Page"
    case continuous = "Continuous"
    case twoUp = "Two-Up"

    var id: String { rawValue }

    var pdfDisplayMode: PDFDisplayMode {
        switch self {
        case .singlePage: .singlePage
        case .continuous: .singlePageContinuous
        case .twoUp: .twoUpContinuous
        }
    }

    var icon: String {
        switch self {
        case .singlePage: "doc"
        case .continuous: "doc.on.doc"
        case .twoUp: "book"
        }
    }

    /// Creates a ViewModeOption from a PDFDisplayMode.
    init(from displayMode: PDFDisplayMode) {
        switch displayMode {
        case .singlePage:
            self = .singlePage
        case .singlePageContinuous:
            self = .continuous
        case .twoUpContinuous:
            self = .twoUp
        case .twoUp:
            self = .twoUp
        @unknown default:
            self = .continuous
        }
    }
}

/// Toolbar content providing page navigation, zoom, view mode, and search controls.
///
/// Uses the `PDFDocumentModel` from the environment to drive all state.
struct VerificarToolbar: ToolbarContent {

    @Bindable var documentModel: PDFDocumentModel

    /// Local state for the Go To Page text field.
    @State private var goToPageText: String = ""

    /// Local state for tracking the selected view mode.
    @State private var selectedViewMode: ViewModeOption = .continuous

    var body: some ToolbarContent {

        // MARK: - Navigation Group

        ToolbarItemGroup(placement: .automatic) {
            Button(action: { documentModel.previousPage() }) {
                Label("Previous Page", systemImage: "chevron.left")
            }
            .disabled(!documentModel.isDocumentLoaded || documentModel.currentPageIndex == 0)
            .help("Previous Page")

            Button(action: { documentModel.nextPage() }) {
                Label("Next Page", systemImage: "chevron.right")
            }
            .disabled(!documentModel.isDocumentLoaded || documentModel.currentPageIndex >= documentModel.pageCount - 1)
            .help("Next Page")

            // Page indicator.
            if documentModel.isDocumentLoaded {
                Text("Page \(documentModel.currentPageIndex + 1) of \(documentModel.pageCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            // Go To Page field.
            TextField("Go to", text: $goToPageText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
                .onSubmit {
                    if let pageNumber = Int(goToPageText),
                       pageNumber >= 1,
                       pageNumber <= documentModel.pageCount {
                        documentModel.goToPage(pageNumber - 1)
                    }
                    goToPageText = ""
                }
                .disabled(!documentModel.isDocumentLoaded)
                .help("Go to page number")
        }

        // MARK: - Zoom Group

        ToolbarItemGroup(placement: .automatic) {
            Button(action: { documentModel.zoomOut() }) {
                Label("Zoom Out", systemImage: "minus.magnifyingglass")
            }
            .disabled(!documentModel.isDocumentLoaded)
            .help("Zoom Out (Cmd -)")

            Text("\(documentModel.zoomPercentage)%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: 40)

            Button(action: { documentModel.zoomIn() }) {
                Label("Zoom In", systemImage: "plus.magnifyingglass")
            }
            .disabled(!documentModel.isDocumentLoaded)
            .help("Zoom In (Cmd +)")

            Menu {
                Button("Fit Page") { documentModel.zoomToFit() }
                Button("Fit Width") { documentModel.zoomToWidth() }
                Divider()
                Button("Actual Size (100%)") { documentModel.zoomToActualSize() }
                Divider()
                Button("50%") { documentModel.autoScalesEnabled = false; documentModel.fitWidthRequested = false; documentModel.setZoom(0.5) }
                Button("75%") { documentModel.autoScalesEnabled = false; documentModel.fitWidthRequested = false; documentModel.setZoom(0.75) }
                Button("100%") { documentModel.zoomToActualSize() }
                Button("125%") { documentModel.autoScalesEnabled = false; documentModel.fitWidthRequested = false; documentModel.setZoom(1.25) }
                Button("150%") { documentModel.autoScalesEnabled = false; documentModel.fitWidthRequested = false; documentModel.setZoom(1.5) }
                Button("200%") { documentModel.autoScalesEnabled = false; documentModel.fitWidthRequested = false; documentModel.setZoom(2.0) }
            } label: {
                Label("Zoom Options", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .disabled(!documentModel.isDocumentLoaded)
            .help("Zoom presets")
        }

        // MARK: - View Mode Group

        ToolbarItemGroup(placement: .automatic) {
            Picker("View Mode", selection: $selectedViewMode) {
                ForEach(ViewModeOption.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .disabled(!documentModel.isDocumentLoaded)
            .onChange(of: selectedViewMode) { _, newValue in
                documentModel.displayMode = newValue.pdfDisplayMode
            }
            .help("View mode")
        }

        // MARK: - Search Group

        ToolbarItemGroup(placement: .automatic) {
            if documentModel.isSearching {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search...", text: Bindable(documentModel).searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .onSubmit {
                            documentModel.search(documentModel.searchText)
                        }

                    if !documentModel.searchResults.isEmpty {
                        Text("\(documentModel.searchResults.count) found")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Button(action: {
                        documentModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button(action: {
                    documentModel.isSearching = true
                }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .disabled(!documentModel.isDocumentLoaded)
                .help("Search (Cmd F)")
            }
        }
    }
}
