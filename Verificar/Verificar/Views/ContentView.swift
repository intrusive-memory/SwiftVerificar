//
//  ContentView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
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
}
