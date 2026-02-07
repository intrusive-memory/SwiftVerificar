//
//  OutlineNode.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import PDFKit
import Foundation

/// A UI-friendly representation of a PDF outline (bookmark) node.
///
/// Wraps `PDFOutline` data into a recursive `Identifiable` struct suitable
/// for SwiftUI's `List` / `DisclosureGroup` rendering.
struct OutlineNode: Identifiable {

    let id = UUID()

    /// The display label for this outline entry.
    let label: String

    /// The destination in the PDF this outline entry points to, if any.
    let destination: PDFDestination?

    /// Child outline nodes nested under this entry.
    let children: [OutlineNode]

    // MARK: - Tree Building

    /// Builds an array of `OutlineNode` from a `PDFOutline` root.
    ///
    /// The root outline itself is not included as a node; only its children
    /// (the top-level entries) become nodes.
    ///
    /// - Parameter outline: The root `PDFOutline` from `PDFDocument.outlineRoot`.
    /// - Returns: An array of top-level `OutlineNode` values. Returns an empty
    ///   array if the outline has no children.
    static func buildTree(from outline: PDFOutline) -> [OutlineNode] {
        var nodes: [OutlineNode] = []
        let childCount = outline.numberOfChildren
        for index in 0..<childCount {
            if let child = outline.child(at: index) {
                nodes.append(buildNode(from: child))
            }
        }
        return nodes
    }

    // MARK: - Private Helpers

    /// Recursively converts a `PDFOutline` node and its descendants into an `OutlineNode`.
    private static func buildNode(from outline: PDFOutline) -> OutlineNode {
        var children: [OutlineNode] = []
        let childCount = outline.numberOfChildren
        for index in 0..<childCount {
            if let child = outline.child(at: index) {
                children.append(buildNode(from: child))
            }
        }

        // PDFOutline.label may be nil or an empty string depending on
        // framework state. Treat both as "Untitled".
        let label: String
        if let rawLabel = outline.label, !rawLabel.isEmpty {
            label = rawLabel
        } else {
            label = "Untitled"
        }

        return OutlineNode(
            label: label,
            destination: outline.destination,
            children: children
        )
    }
}
