//
//  StructureNodeModel.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import Foundation

/// UI-friendly structure tree node representing a PDF tagged structure element.
///
/// Maps from SwiftVerificar's structure analysis results to a simple tree
/// model suitable for display in a `List` or `OutlineGroup`. Each node
/// represents a structure element (heading, paragraph, figure, table, etc.)
/// with optional metadata and children.
struct StructureNodeModel: Identifiable, Sendable, Equatable {

    /// Unique identifier for this node.
    let id: String

    /// The structure element type (e.g., "H1", "P", "Figure", "Table", "Span", "Document").
    let type: String

    /// Optional title attribute from the structure element.
    let title: String?

    /// Optional alternative text attribute (used for figures, formulas, etc.).
    let altText: String?

    /// Optional language attribute override on this element.
    let language: String?

    /// Child structure elements.
    let children: [StructureNodeModel]

    /// The 0-based page index this element is associated with, if any.
    let pageIndex: Int?

    /// Whether this node has an associated violation.
    var hasViolation: Bool = false

    // MARK: - Computed Properties

    /// SF Symbol name representing this structure element type.
    var icon: String {
        StructureNodeModel.iconForType(type)
    }

    /// A display label combining the type and optional title or alt text.
    var displayLabel: String {
        if let title, !title.isEmpty {
            return title
        }
        if let altText, !altText.isEmpty {
            return altText
        }
        return type
    }

    /// Whether this node represents a heading element.
    var isHeading: Bool {
        let upper = type.uppercased()
        return upper.hasPrefix("H") && upper.count <= 3
            && Int(String(upper.dropFirst())) != nil
    }

    /// Whether this node represents a figure element.
    var isFigure: Bool {
        type.uppercased() == "FIGURE"
    }

    /// Whether this node represents a table element.
    var isTable: Bool {
        type.uppercased() == "TABLE"
    }

    /// Whether this node represents a list element.
    var isList: Bool {
        let upper = type.uppercased()
        return upper == "L" || upper == "LIST"
    }

    // MARK: - Equatable

    static func == (lhs: StructureNodeModel, rhs: StructureNodeModel) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Icon Mapping

    /// Returns the appropriate SF Symbol name for a given structure element type.
    static func iconForType(_ type: String) -> String {
        let upper = type.uppercased()

        // Headings
        if upper.hasPrefix("H") && upper.count <= 3,
           let level = Int(String(upper.dropFirst())), (1...6).contains(level) {
            return "text.badge.\(level)"
        }

        switch upper {
        // Grouping elements
        case "DOCUMENT", "DOC":
            return "doc.text"
        case "PART":
            return "rectangle.split.3x1"
        case "ART", "ARTICLE":
            return "doc.plaintext"
        case "SECT", "SECTION":
            return "rectangle.3.group"
        case "DIV":
            return "square.split.2x1"
        case "BLOCKQUOTE":
            return "text.quote"
        case "CAPTION":
            return "text.below.photo"
        case "TOC":
            return "list.bullet.rectangle"
        case "TOCI":
            return "list.bullet.indent"
        case "INDEX":
            return "magnifyingglass"
        case "NONSTRUCT":
            return "square.dashed"

        // Block-level structure elements
        case "P", "PARAGRAPH":
            return "text.alignleft"
        case "FIGURE":
            return "photo"
        case "FORMULA":
            return "function"
        case "FORM":
            return "rectangle.and.pencil.and.ellipsis"

        // Table elements
        case "TABLE":
            return "tablecells"
        case "TR":
            return "rectangle.split.1x2"
        case "TH":
            return "rectangle.fill.badge.checkmark"
        case "TD":
            return "rectangle"
        case "THEAD":
            return "tablecells.badge.ellipsis"
        case "TBODY":
            return "tablecells.fill"
        case "TFOOT":
            return "tablecells.badge.ellipsis"

        // List elements
        case "L", "LIST":
            return "list.bullet"
        case "LI":
            return "list.bullet.indent"
        case "LBL":
            return "number"
        case "LBODY":
            return "text.justify"

        // Inline-level structure elements
        case "SPAN":
            return "character"
        case "QUOTE":
            return "quote.opening"
        case "NOTE":
            return "note.text"
        case "REFERENCE":
            return "link"
        case "BIBENTRY":
            return "book"
        case "CODE":
            return "chevron.left.forwardslash.chevron.right"
        case "LINK":
            return "link"
        case "ANNOT", "ANNOTATION":
            return "pin"
        case "RUBY":
            return "textformat.size"
        case "WARICHU":
            return "textformat.subscript"

        default:
            return "rectangle.badge.questionmark"
        }
    }
}

// MARK: - StructureNodeStatistics

/// Statistics about a structure tree: counts of elements by type.
struct StructureNodeStatistics: Sendable, Equatable {
    /// Total number of structure elements in the tree.
    let totalElements: Int

    /// Number of heading elements (H1-H6).
    let headingCount: Int

    /// Number of figure elements.
    let figureCount: Int

    /// Number of table elements.
    let tableCount: Int

    /// Number of list elements.
    let listCount: Int

    /// Number of paragraph elements.
    let paragraphCount: Int

    /// Number of link/annotation elements.
    let linkCount: Int

    /// Breakdown of counts per element type.
    let typeCounts: [String: Int]
}

// MARK: - StructureTreeBuilder

/// Builds a `StructureNodeModel` tree from various input sources.
///
/// Since SwiftVerificar-biblioteca v0.1.0 has stub implementations for
/// structure tree parsing, this builder also supports creating trees from
/// sample/mock data for development and testing.
enum StructureTreeBuilder {

    /// Computes statistics for a tree of structure nodes.
    static func computeStatistics(for nodes: [StructureNodeModel]) -> StructureNodeStatistics {
        var total = 0
        var headings = 0
        var figures = 0
        var tables = 0
        var lists = 0
        var paragraphs = 0
        var links = 0
        var typeCounts: [String: Int] = [:]

        func visit(_ node: StructureNodeModel) {
            total += 1
            let upper = node.type.uppercased()
            typeCounts[node.type, default: 0] += 1

            if node.isHeading { headings += 1 }
            if node.isFigure { figures += 1 }
            if node.isTable { tables += 1 }
            if node.isList { lists += 1 }
            if upper == "P" || upper == "PARAGRAPH" { paragraphs += 1 }
            if upper == "LINK" || upper == "ANNOT" || upper == "ANNOTATION" { links += 1 }

            for child in node.children {
                visit(child)
            }
        }

        for node in nodes {
            visit(node)
        }

        return StructureNodeStatistics(
            totalElements: total,
            headingCount: headings,
            figureCount: figures,
            tableCount: tables,
            listCount: lists,
            paragraphCount: paragraphs,
            linkCount: links,
            typeCounts: typeCounts
        )
    }

    /// Filters tree nodes matching a search query.
    ///
    /// A node matches if its type, title, or alt text contains the query
    /// (case-insensitive). If a child matches, the parent is included with
    /// only matching children.
    static func filterNodes(
        _ nodes: [StructureNodeModel],
        matching query: String
    ) -> [StructureNodeModel] {
        guard !query.isEmpty else { return nodes }

        return nodes.compactMap { node in
            filterNode(node, matching: query)
        }
    }

    private static func filterNode(
        _ node: StructureNodeModel,
        matching query: String
    ) -> StructureNodeModel? {
        let matches = nodeMatchesQuery(node, query: query)
        let filteredChildren = node.children.compactMap { filterNode($0, matching: query) }

        if matches || !filteredChildren.isEmpty {
            return StructureNodeModel(
                id: node.id,
                type: node.type,
                title: node.title,
                altText: node.altText,
                language: node.language,
                children: filteredChildren,
                pageIndex: node.pageIndex,
                hasViolation: node.hasViolation
            )
        }

        return nil
    }

    private static func nodeMatchesQuery(_ node: StructureNodeModel, query: String) -> Bool {
        node.type.localizedCaseInsensitiveContains(query)
            || (node.title?.localizedCaseInsensitiveContains(query) ?? false)
            || (node.altText?.localizedCaseInsensitiveContains(query) ?? false)
    }

    /// Creates a sample structure tree for development and testing.
    static func makeSampleTree() -> [StructureNodeModel] {
        [
            StructureNodeModel(
                id: "doc-1",
                type: "Document",
                title: "Sample Document",
                altText: nil,
                language: "en",
                children: [
                    StructureNodeModel(
                        id: "h1-1",
                        type: "H1",
                        title: "Introduction",
                        altText: nil,
                        language: nil,
                        children: [],
                        pageIndex: 0
                    ),
                    StructureNodeModel(
                        id: "p-1",
                        type: "P",
                        title: nil,
                        altText: nil,
                        language: nil,
                        children: [],
                        pageIndex: 0
                    ),
                    StructureNodeModel(
                        id: "fig-1",
                        type: "Figure",
                        title: "Logo",
                        altText: "Company logo in blue",
                        language: nil,
                        children: [],
                        pageIndex: 0,
                        hasViolation: true
                    ),
                    StructureNodeModel(
                        id: "h2-1",
                        type: "H2",
                        title: "Details",
                        altText: nil,
                        language: nil,
                        children: [
                            StructureNodeModel(
                                id: "p-2",
                                type: "P",
                                title: nil,
                                altText: nil,
                                language: nil,
                                children: [],
                                pageIndex: 1
                            ),
                            StructureNodeModel(
                                id: "table-1",
                                type: "Table",
                                title: "Data Summary",
                                altText: nil,
                                language: nil,
                                children: [
                                    StructureNodeModel(
                                        id: "tr-1",
                                        type: "TR",
                                        title: nil,
                                        altText: nil,
                                        language: nil,
                                        children: [
                                            StructureNodeModel(
                                                id: "th-1",
                                                type: "TH",
                                                title: "Name",
                                                altText: nil,
                                                language: nil,
                                                children: [],
                                                pageIndex: 1
                                            ),
                                            StructureNodeModel(
                                                id: "th-2",
                                                type: "TH",
                                                title: "Value",
                                                altText: nil,
                                                language: nil,
                                                children: [],
                                                pageIndex: 1
                                            ),
                                        ],
                                        pageIndex: 1
                                    ),
                                ],
                                pageIndex: 1
                            ),
                        ],
                        pageIndex: 1
                    ),
                    StructureNodeModel(
                        id: "list-1",
                        type: "L",
                        title: nil,
                        altText: nil,
                        language: nil,
                        children: [
                            StructureNodeModel(
                                id: "li-1",
                                type: "LI",
                                title: "Item one",
                                altText: nil,
                                language: nil,
                                children: [],
                                pageIndex: 2
                            ),
                            StructureNodeModel(
                                id: "li-2",
                                type: "LI",
                                title: "Item two",
                                altText: nil,
                                language: nil,
                                children: [],
                                pageIndex: 2
                            ),
                        ],
                        pageIndex: 2
                    ),
                ],
                pageIndex: nil
            ),
        ]
    }
}
