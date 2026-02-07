//
//  OutlineNodeTests.swift
//  VerificarTests
//
//  Created by TOM STOVALL on 2/7/26.
//

import Testing
import PDFKit
@testable import Verificar

@Suite("OutlineNode")
struct OutlineNodeTests {

    // MARK: - Tree Building

    @Test("buildTree converts PDFOutline children into OutlineNode array")
    @MainActor
    func buildTreeCreatesNodes() {
        // Build a PDFOutline with two top-level children
        let root = PDFOutline()

        let child1 = PDFOutline()
        child1.label = "Chapter 1"
        root.insertChild(child1, at: 0)

        let child2 = PDFOutline()
        child2.label = "Chapter 2"
        root.insertChild(child2, at: 1)

        let nodes = OutlineNode.buildTree(from: root)

        #expect(nodes.count == 2)
        #expect(nodes[0].label == "Chapter 1")
        #expect(nodes[1].label == "Chapter 2")
        #expect(nodes[0].children.isEmpty)
        #expect(nodes[1].children.isEmpty)
    }

    @Test("buildTree handles nested children recursively")
    @MainActor
    func buildTreeHandlesNestedChildren() {
        let root = PDFOutline()

        let chapter = PDFOutline()
        chapter.label = "Chapter 1"
        root.insertChild(chapter, at: 0)

        let section1 = PDFOutline()
        section1.label = "Section 1.1"
        chapter.insertChild(section1, at: 0)

        let section2 = PDFOutline()
        section2.label = "Section 1.2"
        chapter.insertChild(section2, at: 1)

        let subsection = PDFOutline()
        subsection.label = "Subsection 1.2.1"
        section2.insertChild(subsection, at: 0)

        let nodes = OutlineNode.buildTree(from: root)

        #expect(nodes.count == 1)
        #expect(nodes[0].label == "Chapter 1")
        #expect(nodes[0].children.count == 2)
        #expect(nodes[0].children[0].label == "Section 1.1")
        #expect(nodes[0].children[0].children.isEmpty)
        #expect(nodes[0].children[1].label == "Section 1.2")
        #expect(nodes[0].children[1].children.count == 1)
        #expect(nodes[0].children[1].children[0].label == "Subsection 1.2.1")
    }

    @Test("buildTree returns empty array for outline with no children")
    @MainActor
    func buildTreeEmptyOutline() {
        let root = PDFOutline()

        let nodes = OutlineNode.buildTree(from: root)

        #expect(nodes.isEmpty)
    }

    @Test("buildTree assigns 'Untitled' label when PDFOutline label is nil")
    @MainActor
    func buildTreeNilLabel() {
        // PDFOutline with no label set may return nil or an empty string
        // depending on framework state. Our buildNode handles nil -> "Untitled".
        // We test the OutlineNode.buildNode path directly by verifying
        // it produces a valid label that is either "Untitled" (nil case)
        // or a non-empty string (if the framework provides a default).
        let root = PDFOutline()

        let child = PDFOutline()
        // Explicitly set label to nil to guarantee the nil path
        child.label = nil
        root.insertChild(child, at: 0)

        let nodes = OutlineNode.buildTree(from: root)

        #expect(nodes.count == 1)
        // When label is nil, our code maps it to "Untitled"
        #expect(nodes[0].label == "Untitled")
    }

    // MARK: - Destination

    @Test("OutlineNode preserves destination from PDFOutline")
    @MainActor
    func nodePreservesDestination() {
        let document = PDFDocument()
        let page = PDFPage()
        document.insert(page, at: 0)

        let destination = PDFDestination(page: page, at: NSPoint(x: 0, y: 500))

        let root = PDFOutline()
        let child = PDFOutline()
        child.label = "Page 1"
        child.destination = destination
        root.insertChild(child, at: 0)

        let nodes = OutlineNode.buildTree(from: root)

        #expect(nodes.count == 1)
        #expect(nodes[0].destination != nil)
        #expect(nodes[0].destination?.page === page)
    }

    // MARK: - Identifiability

    @Test("Each OutlineNode has a unique id")
    @MainActor
    func nodesHaveUniqueIds() {
        let root = PDFOutline()

        for index in 0..<5 {
            let child = PDFOutline()
            child.label = "Item \(index)"
            root.insertChild(child, at: index)
        }

        let nodes = OutlineNode.buildTree(from: root)
        let ids = Set(nodes.map(\.id))

        #expect(ids.count == 5, "All nodes should have unique IDs")
    }

    // MARK: - PDFDocumentModel Integration

    @Test("PDFDocumentModel.hasOutline is false when no document loaded")
    @MainActor
    func hasOutlineFalseWhenNoDocument() {
        let model = PDFDocumentModel()
        #expect(!model.hasOutline)
        #expect(model.outlineRoot == nil)
    }

    @Test("navigateToDestination updates currentPageIndex")
    @MainActor
    func navigateToDestinationUpdatesPage() {
        let model = PDFDocumentModel()
        let document = PDFDocument()

        // Insert 5 blank pages
        for i in 0..<5 {
            let page = PDFPage()
            document.insert(page, at: i)
        }

        model.pdfDocument = document

        // Navigate to page 3 via destination
        guard let targetPage = document.page(at: 3) else {
            Issue.record("Failed to get page at index 3")
            return
        }
        let destination = PDFDestination(page: targetPage, at: NSPoint(x: 0, y: 0))
        model.navigateToDestination(destination)

        #expect(model.currentPageIndex == 3)
    }
}
