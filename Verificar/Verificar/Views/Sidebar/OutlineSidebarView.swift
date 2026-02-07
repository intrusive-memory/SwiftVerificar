//
//  OutlineSidebarView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI
import PDFKit

/// Displays the PDF document outline (bookmarks / table of contents) as a
/// collapsible tree in the sidebar.
///
/// Each node shows its label text. Clicking a node navigates the PDF view
/// to the corresponding destination. When the document has no outline an
/// empty-state message is shown instead.
struct OutlineSidebarView: View {

    @Environment(PDFDocumentModel.self) private var documentModel

    var body: some View {
        if !documentModel.isDocumentLoaded {
            noDocumentView
        } else if let outlineRoot = documentModel.outlineRoot,
                  outlineRoot.numberOfChildren > 0 {
            let nodes = OutlineNode.buildTree(from: outlineRoot)
            outlineList(nodes: nodes)
        } else {
            noOutlineView
        }
    }

    // MARK: - Outline Tree

    private func outlineList(nodes: [OutlineNode]) -> some View {
        List {
            ForEach(nodes) { node in
                OutlineNodeRow(
                    node: node,
                    onNavigate: { destination in
                        documentModel.navigateToDestination(destination)
                    }
                )
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Empty States

    private var noOutlineView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.indent")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("No Outline Available")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("This PDF does not contain a document outline.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noDocumentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.indent")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Document Outline")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Open a PDF to view its outline.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - OutlineNodeRow

/// A single row in the outline tree, rendered recursively using `DisclosureGroup`
/// for nodes with children and a plain label for leaf nodes.
private struct OutlineNodeRow: View {

    let node: OutlineNode
    let onNavigate: (PDFDestination) -> Void

    /// Track expanded state per node. First-level nodes default to expanded
    /// in the initializer of `OutlineSidebarView`'s List, but SwiftUI manages
    /// disclosure state automatically when we use `DisclosureGroup`.
    @State private var isExpanded: Bool = true

    var body: some View {
        if node.children.isEmpty {
            leafRow
        } else {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(node.children) { child in
                    OutlineNodeRow(node: child, onNavigate: onNavigate)
                }
            } label: {
                nodeLabel
            }
        }
    }

    private var leafRow: some View {
        Button {
            if let destination = node.destination {
                onNavigate(destination)
            }
        } label: {
            nodeLabel
        }
        .buttonStyle(.plain)
    }

    private var nodeLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
                .font(.caption)

            Text(node.label)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let destination = node.destination {
                onNavigate(destination)
            }
        }
        .accessibilityLabel(node.label)
    }
}

// MARK: - Preview

#Preview("With Outline") {
    OutlineSidebarView()
        .environment(PDFDocumentModel())
        .frame(width: 220, height: 400)
}
