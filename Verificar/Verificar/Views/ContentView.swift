//
//  ContentView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// Root three-column layout using NavigationSplitView.
///
/// - Sidebar: `SidebarView` (thumbnails / outline modes)
/// - Content: `PDFRenderView` (PDF rendering via PDFKit)
/// - Detail/Inspector: `InspectorView` (standards, violations, structure, features)
///
/// Since Sprint 9, the view pulls `DocumentViewModel` from the environment,
/// which owns the `PDFDocumentModel`, `ValidationService`, and `ValidationViewModel`.
/// These are also injected into the environment individually for child views.
struct ContentView: View {

    @Environment(DocumentViewModel.self) private var documentViewModel
    @Environment(PDFDocumentModel.self) private var documentModel

    /// Controls the visibility of the sidebar column.
    @State var sidebarVisibility: NavigationSplitViewVisibility = .automatic

    /// Controls whether the inspector panel is shown.
    @State var isInspectorPresented: Bool = true

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } content: {
            PDFRenderView(documentModel: documentModel)
                .frame(minWidth: 400)
        } detail: {
            if isInspectorPresented {
                InspectorView()
                    .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 450)
            }
        }
        .toolbar {
            VerificarToolbar(documentModel: documentModel)
        }
        .frame(minWidth: 800, minHeight: 500)
        .focusedSceneValue(\.toggleSidebarAction, toggleSidebar)
        .focusedSceneValue(\.toggleInspectorAction, toggleInspector)
    }

    // MARK: - Sidebar Toggle

    /// Toggles the sidebar between visible and hidden states.
    func toggleSidebar() {
        withAnimation {
            if sidebarVisibility == .detailOnly {
                sidebarVisibility = .all
            } else {
                sidebarVisibility = .detailOnly
            }
        }
    }

    /// Toggles the inspector panel visibility.
    func toggleInspector() {
        withAnimation {
            isInspectorPresented.toggle()
        }
    }
}

#Preview {
    ContentView()
        .environment(DocumentViewModel())
        .environment(PDFDocumentModel())
        .environment(ValidationService())
        .environment(ValidationViewModel())
}
