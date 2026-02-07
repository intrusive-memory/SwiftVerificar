//
//  SidebarView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// Sidebar container that provides a Picker to toggle between Thumbnails and Outline modes.
///
/// Placeholder content is shown for each mode until Sprints 5 and 6 implement
/// `ThumbnailSidebarView` and `OutlineSidebarView`.
struct SidebarView: View {

    @Environment(PDFDocumentModel.self) private var documentModel

    /// The active sidebar mode.
    @State private var sidebarMode: SidebarMode = .thumbnails

    var body: some View {
        VStack(spacing: 0) {
            modePicker
            Divider()
            modeContent
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("Sidebar Mode", selection: $sidebarMode) {
            ForEach(SidebarMode.allCases) { mode in
                Label(mode.label, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(8)
    }

    // MARK: - Mode Content

    @ViewBuilder
    private var modeContent: some View {
        switch sidebarMode {
        case .thumbnails:
            thumbnailsPlaceholder
        case .outline:
            outlinePlaceholder
        }
    }

    private var thumbnailsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.grid.1x2")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Page Thumbnails")
                .font(.headline)
                .foregroundStyle(.secondary)

            if documentModel.isDocumentLoaded {
                Text("\(documentModel.pageCount) pages")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Open a PDF to view thumbnails.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var outlinePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.indent")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Document Outline")
                .font(.headline)
                .foregroundStyle(.secondary)

            if documentModel.isDocumentLoaded {
                Text("Outline will appear here.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Open a PDF to view its outline.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SidebarMode

/// The display mode for the sidebar.
enum SidebarMode: String, CaseIterable, Identifiable {
    case thumbnails
    case outline

    var id: String { rawValue }

    var label: String {
        switch self {
        case .thumbnails: "Thumbnails"
        case .outline: "Outline"
        }
    }

    var icon: String {
        switch self {
        case .thumbnails: "rectangle.grid.1x2"
        case .outline: "list.bullet.indent"
        }
    }
}

#Preview {
    SidebarView()
        .environment(PDFDocumentModel())
        .frame(width: 220, height: 400)
}
