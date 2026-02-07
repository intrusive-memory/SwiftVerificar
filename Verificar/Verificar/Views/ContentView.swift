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
            if documentModel.isLoading {
                loadingView
            } else if documentModel.isDocumentLoaded {
                documentLoadedView
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

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Loading document...")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var documentLoadedView: some View {
        VStack {
            Text(documentModel.title)
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(documentModel.pageCount) page\(documentModel.pageCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text("PDF rendering will be added in Sprint 3.")
                .font(.body)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environment(PDFDocumentModel())
}
