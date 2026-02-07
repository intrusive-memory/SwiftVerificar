//
//  ContentView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

struct ContentView: View {

    @Environment(PDFDocumentModel.self) private var documentModel

    var body: some View {
        Group {
            if documentModel.isDocumentLoaded || documentModel.isLoading {
                PDFRenderView(documentModel: documentModel)
            } else {
                placeholderView
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    // MARK: - Subviews

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Open a PDF to begin")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Use File > Open or drag a PDF file into this window.")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environment(PDFDocumentModel())
}
