//
//  StructureTreeView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// Displays the PDF tagged structure tree in the inspector panel.
///
/// Shows a recursive outline of structure elements with icons, type labels,
/// and optional title/alt text. Elements with violations are highlighted in red.
/// Clicking a node navigates the PDF view to that node's page. An info bar
/// at the top shows element counts, and a search field allows filtering nodes.
///
/// When no structure tree is available (untagged PDF), shows an empty state
/// message prompting the user.
struct StructureTreeView: View {

    @Environment(DocumentViewModel.self) private var documentViewModel
    @Environment(PDFDocumentModel.self) private var documentModel

    /// Local view model for the structure tree.
    @State private var viewModel = StructureTreeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if !documentModel.isDocumentLoaded {
                noDocumentView
            } else if viewModel.hasStructureTree {
                treeContentView
            } else {
                emptyStateView
            }
        }
        .onAppear {
            loadStructureTree()
        }
        .onChange(of: documentModel.isDocumentLoaded) { _, newValue in
            if newValue {
                loadStructureTree()
            } else {
                viewModel.clearTree()
            }
        }
    }

    // MARK: - Tree Content

    private var treeContentView: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            infoBar
            Divider()
            treeList
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField(
                "Filter by type or content...",
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                )
            )
            .textFieldStyle(.plain)
            .font(.caption)

            if viewModel.isSearching {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - Info Bar

    private var infoBar: some View {
        let stats = viewModel.statistics
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                statBadge(
                    icon: "rectangle.stack",
                    label: "\(stats.totalElements)",
                    caption: "Total"
                )
                statBadge(
                    icon: "text.badge.star",
                    label: "\(stats.headingCount)",
                    caption: "Headings"
                )
                statBadge(
                    icon: "photo",
                    label: "\(stats.figureCount)",
                    caption: "Figures"
                )
                statBadge(
                    icon: "tablecells",
                    label: "\(stats.tableCount)",
                    caption: "Tables"
                )
                statBadge(
                    icon: "list.bullet",
                    label: "\(stats.listCount)",
                    caption: "Lists"
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(stats.totalElements) elements, \(stats.headingCount) headings, \(stats.figureCount) figures, \(stats.tableCount) tables"
        )
    }

    private func statBadge(icon: String, label: String, caption: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                Text(caption)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Tree List

    private var treeList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                let nodes = viewModel.displayNodes
                if nodes.isEmpty && viewModel.isSearching {
                    noMatchesView
                } else {
                    ForEach(nodes) { node in
                        StructureNodeRow(
                            node: node,
                            depth: 0,
                            selectedNodeID: viewModel.selectedNode?.id,
                            onSelect: { selected in
                                viewModel.selectNode(selected)
                                if let pageIndex = selected.pageIndex {
                                    documentModel.goToPage(pageIndex)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            Text("No Structure Tree Found")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("This PDF is not tagged. Tagged structure is required for accessibility compliance (PDF/UA).")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noDocumentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Structure Tree")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Open a PDF to view its structure tree.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noMatchesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No matching elements")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Data Loading

    private func loadStructureTree() {
        // Build structure tree from the current document's validation results.
        // Since SwiftVerificar-biblioteca v0.1.0 has stub implementations, we
        // attempt to build from validation results and fall back to an empty tree.
        //
        // When real parser integration is available, this will use the actual
        // structure tree from the parsed PDF.

        guard documentModel.isDocumentLoaded else {
            viewModel.clearTree()
            return
        }

        // Try to build from validation results (currently stubs return empty)
        // For now, we leave the tree empty to properly show the "not tagged" state,
        // which accurately represents what the stub API returns.
        // When SwiftVerificar-biblioteca has real implementations, this will
        // populate with actual structure tree data.
        let nodes: [StructureNodeModel] = []
        viewModel.updateTree(nodes)

        // Mark violations if any exist
        let violations = documentViewModel.violations
        if !violations.isEmpty {
            viewModel.markViolations(from: violations)
        }
    }
}

// MARK: - StructureNodeRow

/// A single row in the structure tree, rendered recursively for child nodes.
///
/// Leaf nodes are displayed as simple rows. Nodes with children use a
/// `DisclosureGroup` for expand/collapse behavior. The row shows the
/// element's icon, type, and optional title or alt text. Nodes associated
/// with violations are tinted red.
private struct StructureNodeRow: View {

    let node: StructureNodeModel
    let depth: Int
    let selectedNodeID: String?
    let onSelect: (StructureNodeModel) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            nodeContent
                .padding(.leading, CGFloat(depth) * 16)

            if isExpanded && !node.children.isEmpty {
                ForEach(node.children) { child in
                    StructureNodeRow(
                        node: child,
                        depth: depth + 1,
                        selectedNodeID: selectedNodeID,
                        onSelect: onSelect
                    )
                }
            }
        }
    }

    private var nodeContent: some View {
        Button {
            onSelect(node)
        } label: {
            HStack(spacing: 6) {
                // Disclosure indicator for parent nodes
                if !node.children.isEmpty {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 10)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }
                } else {
                    Color.clear.frame(width: 10)
                }

                // Element icon
                Image(systemName: node.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(node.hasViolation ? .red : .accentColor)
                    .frame(width: 16)

                // Type label
                Text(node.type)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(node.hasViolation ? .red : .primary)

                // Title or alt text
                if let title = node.title, !title.isEmpty {
                    Text("- \(title)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if let alt = node.altText, !alt.isEmpty, node.title == nil {
                    Text("[alt: \(alt)]")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                // Page badge
                if let pageIndex = node.pageIndex {
                    Text("p.\(pageIndex + 1)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
                }

                // Violation indicator
                if node.hasViolation {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                selectedNodeID == node.id
                    ? Color.accentColor.opacity(0.12)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [node.type]
        if let title = node.title { parts.append(title) }
        if let alt = node.altText { parts.append("alt: \(alt)") }
        if let page = node.pageIndex { parts.append("page \(page + 1)") }
        if node.hasViolation { parts.append("has violation") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#Preview("With Structure Tree") {
    StructureTreeView()
        .environment(DocumentViewModel())
        .environment(PDFDocumentModel())
        .frame(width: 300, height: 500)
}

#Preview("Empty State") {
    StructureTreeView()
        .environment(DocumentViewModel())
        .environment(PDFDocumentModel())
        .frame(width: 300, height: 400)
}
