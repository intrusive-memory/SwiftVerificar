//
//  StructureTreeViewModel.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import Foundation

/// View model managing the PDF structure tree display state.
///
/// `StructureTreeViewModel` builds a tree of `StructureNodeModel` nodes from
/// validation/parser results and provides search filtering, node selection,
/// and element statistics. The UI binds to `displayNodes` for the filtered
/// tree view and `statistics` for the info bar.
///
/// This type is implicitly @MainActor due to project build settings
/// (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
@Observable
final class StructureTreeViewModel {

    // MARK: - Tree Data

    /// The root-level structure nodes of the PDF document.
    var rootNodes: [StructureNodeModel] = []

    /// The currently selected node, if any.
    var selectedNode: StructureNodeModel?

    // MARK: - Search State

    /// Text to search/filter tree nodes by type or content.
    var searchText: String = ""

    // MARK: - Computed Properties

    /// Nodes to display, filtered by the current search text.
    ///
    /// When `searchText` is empty, returns `rootNodes` unchanged.
    /// When searching, returns a filtered tree where only matching nodes
    /// (and their parents) are included.
    var displayNodes: [StructureNodeModel] {
        StructureTreeBuilder.filterNodes(rootNodes, matching: searchText)
    }

    /// Statistics computed from the full (unfiltered) tree.
    var statistics: StructureNodeStatistics {
        StructureTreeBuilder.computeStatistics(for: rootNodes)
    }

    /// Whether the tree has any structure nodes.
    var hasStructureTree: Bool {
        !rootNodes.isEmpty
    }

    /// Whether the tree is currently being searched/filtered.
    var isSearching: Bool {
        !searchText.isEmpty
    }

    /// The number of nodes currently displayed (after filtering).
    var displayedNodeCount: Int {
        countNodes(displayNodes)
    }

    // MARK: - Methods

    /// Updates the root nodes from validation or parser results.
    ///
    /// - Parameter nodes: The new root-level structure nodes.
    func updateTree(_ nodes: [StructureNodeModel]) {
        rootNodes = nodes
        selectedNode = nil
        searchText = ""
    }

    /// Clears the structure tree and resets state.
    func clearTree() {
        rootNodes = []
        selectedNode = nil
        searchText = ""
    }

    /// Selects a node in the tree.
    ///
    /// - Parameter node: The node to select, or nil to deselect.
    func selectNode(_ node: StructureNodeModel?) {
        selectedNode = node
    }

    /// Marks nodes that have violations based on violation page indices and types.
    ///
    /// - Parameter violations: The list of violations to cross-reference.
    func markViolations(from violations: [ViolationItem]) {
        rootNodes = rootNodes.map { markNodeViolations($0, violations: violations) }
    }

    // MARK: - Private Helpers

    private func markNodeViolations(
        _ node: StructureNodeModel,
        violations: [ViolationItem]
    ) -> StructureNodeModel {
        let hasViolation = violations.contains { violation in
            // Match by page index and optionally by object type
            if let violationPage = violation.pageIndex, let nodePage = node.pageIndex {
                if violationPage == nodePage {
                    if let objectType = violation.objectType {
                        return objectType.uppercased() == node.type.uppercased()
                    }
                    return true
                }
            }
            return false
        }

        let updatedChildren = node.children.map { markNodeViolations($0, violations: violations) }

        return StructureNodeModel(
            id: node.id,
            type: node.type,
            title: node.title,
            altText: node.altText,
            language: node.language,
            children: updatedChildren,
            pageIndex: node.pageIndex,
            hasViolation: hasViolation || node.hasViolation
        )
    }

    private func countNodes(_ nodes: [StructureNodeModel]) -> Int {
        nodes.reduce(0) { count, node in
            count + 1 + countNodes(node.children)
        }
    }
}
