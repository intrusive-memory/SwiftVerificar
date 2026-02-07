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
            ThumbnailSidebarView()
        case .outline:
            OutlineSidebarView()
        }
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
