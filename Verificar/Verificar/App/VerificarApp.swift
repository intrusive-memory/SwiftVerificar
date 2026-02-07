//
//  VerificarApp.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

@main
struct VerificarApp: App {

    @State private var documentModel = PDFDocumentModel()
    @State private var isFileImporterPresented = false
    @State private var isGoToPagePresented = false
    @State private var goToPageText = ""

    /// Tracks the current ContentView for forwarding toggle commands.
    /// NavigationSplitView sidebar visibility and inspector state are owned
    /// by ContentView's @State, but we need to send messages from the menu.
    /// We use FocusedValues to bridge the gap.
    @FocusedValue(\.toggleSidebarAction) private var toggleSidebar
    @FocusedValue(\.toggleInspectorAction) private var toggleInspector

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(documentModel)
                .fileImporter(
                    isPresented: $isFileImporterPresented,
                    allowedContentTypes: [UTType.pdf],
                    allowsMultipleSelection: false
                ) { result in
                    handleFileImporterResult(result)
                }
                .onDrop(of: [UTType.pdf, UTType.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers)
                }
                .sheet(isPresented: $isGoToPagePresented) {
                    goToPageSheet
                }
        }
        .commands {
            // MARK: - File Menu

            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    isFileImporterPresented = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            // MARK: - View Menu (Zoom)

            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    toggleSidebar?()
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                Button("Toggle Inspector") {
                    toggleInspector?()
                }
                .keyboardShortcut("2", modifiers: [.command, .option])

                Divider()

                Button("Zoom In") {
                    documentModel.zoomIn()
                }
                .keyboardShortcut("=", modifiers: .command)
                .disabled(!documentModel.isDocumentLoaded)

                Button("Zoom Out") {
                    documentModel.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(!documentModel.isDocumentLoaded)

                Button("Actual Size") {
                    documentModel.zoomToActualSize()
                }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(!documentModel.isDocumentLoaded)

                Button("Zoom to Fit") {
                    documentModel.zoomToFit()
                }
                .keyboardShortcut("9", modifiers: .command)
                .disabled(!documentModel.isDocumentLoaded)

                Button("Zoom to Width") {
                    documentModel.zoomToWidth()
                }
                .disabled(!documentModel.isDocumentLoaded)

                Divider()

                Button("Single Page") {
                    documentModel.displayMode = .singlePage
                }
                .disabled(!documentModel.isDocumentLoaded)

                Button("Continuous") {
                    documentModel.displayMode = .singlePageContinuous
                }
                .disabled(!documentModel.isDocumentLoaded)

                Button("Two-Up") {
                    documentModel.displayMode = .twoUpContinuous
                }
                .disabled(!documentModel.isDocumentLoaded)
            }

            // MARK: - Edit Menu (Search)

            CommandGroup(after: .textEditing) {
                Button("Find...") {
                    documentModel.isSearching = true
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(!documentModel.isDocumentLoaded)
            }

            // MARK: - Go Menu (Navigation)

            CommandMenu("Go") {
                Button("Next Page") {
                    documentModel.nextPage()
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .disabled(!documentModel.isDocumentLoaded || documentModel.currentPageIndex >= documentModel.pageCount - 1)

                Button("Previous Page") {
                    documentModel.previousPage()
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)
                .disabled(!documentModel.isDocumentLoaded || documentModel.currentPageIndex == 0)

                Divider()

                Button("First Page") {
                    documentModel.goToPage(0)
                }
                .disabled(!documentModel.isDocumentLoaded || documentModel.currentPageIndex == 0)

                Button("Last Page") {
                    documentModel.goToPage(documentModel.pageCount - 1)
                }
                .disabled(!documentModel.isDocumentLoaded || documentModel.currentPageIndex >= documentModel.pageCount - 1)

                Divider()

                Button("Go to Page...") {
                    goToPageText = ""
                    isGoToPagePresented = true
                }
                .keyboardShortcut("p", modifiers: [.command, .option])
                .disabled(!documentModel.isDocumentLoaded)
            }
        }
    }

    // MARK: - Go To Page Sheet

    @ViewBuilder
    private var goToPageSheet: some View {
        VStack(spacing: 16) {
            Text("Go to Page")
                .font(.headline)

            Text("Enter a page number (1-\(documentModel.pageCount))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Page number", text: $goToPageText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .onSubmit {
                    submitGoToPage()
                }

            HStack {
                Button("Cancel") {
                    isGoToPagePresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("Go") {
                    submitGoToPage()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(Int(goToPageText) == nil)
            }
        }
        .padding(24)
        .frame(width: 260)
    }

    private func submitGoToPage() {
        if let pageNumber = Int(goToPageText),
           pageNumber >= 1,
           pageNumber <= documentModel.pageCount {
            documentModel.goToPage(pageNumber - 1)
        }
        isGoToPagePresented = false
    }

    // MARK: - File Handling

    private func handleFileImporterResult(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            openDocument(at: url)
        case .failure(let error):
            documentModel.error = error
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Try loading as a file URL
        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Task { @MainActor in
                        openDocument(at: url)
                    }
                } else if let url = item as? URL {
                    Task { @MainActor in
                        openDocument(at: url)
                    }
                }
            }
            return true
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   url.pathExtension.lowercased() == "pdf" {
                    Task { @MainActor in
                        openDocument(at: url)
                    }
                }
            }
            return true
        }

        return false
    }

    private func openDocument(at url: URL) {
        Task {
            // Start accessing security-scoped resource for sandboxed apps
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            try await documentModel.open(url: url)
        }
    }
}

// MARK: - Focused Values for Menu <-> View Communication

/// A closure that toggles the sidebar visibility.
struct ToggleSidebarActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

/// A closure that toggles the inspector visibility.
struct ToggleInspectorActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var toggleSidebarAction: ToggleSidebarActionKey.Value? {
        get { self[ToggleSidebarActionKey.self] }
        set { self[ToggleSidebarActionKey.self] = newValue }
    }

    var toggleInspectorAction: ToggleInspectorActionKey.Value? {
        get { self[ToggleInspectorActionKey.self] }
        set { self[ToggleInspectorActionKey.self] = newValue }
    }
}
