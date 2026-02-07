//
//  VerificarApp.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct VerificarApp: App {

    @State private var documentModel = PDFDocumentModel()
    @State private var isFileImporterPresented = false

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
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    isFileImporterPresented = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
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
