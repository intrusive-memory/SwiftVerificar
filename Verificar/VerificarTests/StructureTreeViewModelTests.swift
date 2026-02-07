import Testing
import Foundation
@testable import Verificar

// MARK: - StructureTreeViewModel Tests

@Suite("StructureTreeViewModel")
struct StructureTreeViewModelTests {

    // MARK: - Test Data

    private static func makeSampleNodes() -> [StructureNodeModel] {
        [
            StructureNodeModel(
                id: "doc-1",
                type: "Document",
                title: "Test Document",
                altText: nil,
                language: "en",
                children: [
                    StructureNodeModel(
                        id: "h1-1",
                        type: "H1",
                        title: "Chapter One",
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
                        title: "Chart",
                        altText: "A bar chart showing revenue",
                        language: nil,
                        children: [],
                        pageIndex: 1
                    ),
                    StructureNodeModel(
                        id: "h2-1",
                        type: "H2",
                        title: "Section A",
                        altText: nil,
                        language: nil,
                        children: [
                            StructureNodeModel(
                                id: "table-1",
                                type: "Table",
                                title: "Data",
                                altText: nil,
                                language: nil,
                                children: [],
                                pageIndex: 1
                            ),
                            StructureNodeModel(
                                id: "p-2",
                                type: "P",
                                title: nil,
                                altText: nil,
                                language: nil,
                                children: [],
                                pageIndex: 2
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
                                title: "First item",
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

    // MARK: - Tree Building Tests

    @Test("updateTree sets root nodes and clears search")
    func updateTreeSetsRootNodes() {
        let vm = StructureTreeViewModel()
        let nodes = Self.makeSampleNodes()

        vm.searchText = "some query"
        vm.updateTree(nodes)

        #expect(vm.rootNodes.count == 1)
        #expect(vm.rootNodes[0].type == "Document")
        #expect(vm.searchText.isEmpty)
        #expect(vm.selectedNode == nil)
    }

    @Test("clearTree removes all nodes and resets state")
    func clearTreeRemovesAll() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())
        vm.searchText = "test"

        vm.clearTree()

        #expect(vm.rootNodes.isEmpty)
        #expect(vm.selectedNode == nil)
        #expect(vm.searchText.isEmpty)
        #expect(!vm.hasStructureTree)
    }

    @Test("hasStructureTree reflects node presence")
    func hasStructureTreeReflectsPresence() {
        let vm = StructureTreeViewModel()
        #expect(!vm.hasStructureTree)

        vm.updateTree(Self.makeSampleNodes())
        #expect(vm.hasStructureTree)

        vm.clearTree()
        #expect(!vm.hasStructureTree)
    }

    // MARK: - Statistics Tests

    @Test("Statistics compute correct element counts")
    func statisticsComputeCorrectCounts() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        let stats = vm.statistics

        // Count all nodes: Document(1) + H1(1) + P(1) + Figure(1) + H2(1) +
        //                  Table(1) + P(1) + L(1) + LI(1) = 9
        #expect(stats.totalElements == 9)
        #expect(stats.headingCount == 2)  // H1, H2
        #expect(stats.figureCount == 1)   // Figure
        #expect(stats.tableCount == 1)    // Table
        #expect(stats.listCount == 1)     // L
        #expect(stats.paragraphCount == 2) // two P elements
    }

    @Test("Statistics typeCounts map has correct entries")
    func statisticsTypeCountsAreCorrect() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        let typeCounts = vm.statistics.typeCounts

        #expect(typeCounts["Document"] == 1)
        #expect(typeCounts["H1"] == 1)
        #expect(typeCounts["H2"] == 1)
        #expect(typeCounts["P"] == 2)
        #expect(typeCounts["Figure"] == 1)
        #expect(typeCounts["Table"] == 1)
        #expect(typeCounts["L"] == 1)
        #expect(typeCounts["LI"] == 1)
    }

    @Test("Empty tree produces zero statistics")
    func emptyTreeStatisticsZero() {
        let vm = StructureTreeViewModel()

        let stats = vm.statistics

        #expect(stats.totalElements == 0)
        #expect(stats.headingCount == 0)
        #expect(stats.figureCount == 0)
        #expect(stats.tableCount == 0)
        #expect(stats.listCount == 0)
    }

    // MARK: - Search Filtering Tests

    @Test("Search filters nodes by type")
    func searchFiltersByType() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        vm.searchText = "H1"
        let displayed = vm.displayNodes

        // Document is included as parent, and H1 matches
        #expect(!displayed.isEmpty)
        // The filtered tree should have the Document root with only the H1 child
        let docChildren = displayed[0].children
        #expect(docChildren.contains { $0.type == "H1" })
    }

    @Test("Search filters nodes by title")
    func searchFiltersByTitle() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        vm.searchText = "Chapter"
        let displayed = vm.displayNodes

        #expect(!displayed.isEmpty)
        // Should find H1 with title "Chapter One"
        let docChildren = displayed[0].children
        #expect(docChildren.contains { $0.title == "Chapter One" })
    }

    @Test("Search filters nodes by alt text")
    func searchFiltersByAltText() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        vm.searchText = "bar chart"
        let displayed = vm.displayNodes

        #expect(!displayed.isEmpty)
        // Should find Figure with altText containing "bar chart"
        let docChildren = displayed[0].children
        #expect(docChildren.contains { $0.altText?.contains("bar chart") == true })
    }

    @Test("Empty search returns all nodes")
    func emptySearchReturnsAll() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        vm.searchText = ""
        let displayed = vm.displayNodes

        #expect(displayed.count == vm.rootNodes.count)
    }

    @Test("Search with no matches returns empty")
    func searchNoMatchesReturnsEmpty() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        vm.searchText = "xyznonexistent"
        let displayed = vm.displayNodes

        #expect(displayed.isEmpty)
    }

    @Test("Search is case insensitive")
    func searchIsCaseInsensitive() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        vm.searchText = "figure"
        let displayed = vm.displayNodes

        #expect(!displayed.isEmpty)
        let docChildren = displayed[0].children
        #expect(docChildren.contains { $0.type == "Figure" })
    }

    // MARK: - Node Selection Tests

    @Test("selectNode sets selectedNode")
    func selectNodeSetsSelection() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        let node = vm.rootNodes[0].children[0] // H1
        vm.selectNode(node)

        #expect(vm.selectedNode?.id == node.id)
    }

    @Test("selectNode with nil deselects")
    func selectNodeNilDeselects() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())
        vm.selectNode(vm.rootNodes[0])

        vm.selectNode(nil)

        #expect(vm.selectedNode == nil)
    }

    // MARK: - Node Model Tests

    @Test("StructureNodeModel icon returns correct SF Symbol for types")
    func nodeIconsAreCorrect() {
        #expect(StructureNodeModel.iconForType("H1") == "text.badge.1")
        #expect(StructureNodeModel.iconForType("H2") == "text.badge.2")
        #expect(StructureNodeModel.iconForType("H3") == "text.badge.3")
        #expect(StructureNodeModel.iconForType("P") == "text.alignleft")
        #expect(StructureNodeModel.iconForType("Figure") == "photo")
        #expect(StructureNodeModel.iconForType("Table") == "tablecells")
        #expect(StructureNodeModel.iconForType("L") == "list.bullet")
        #expect(StructureNodeModel.iconForType("Document") == "doc.text")
        #expect(StructureNodeModel.iconForType("Span") == "character")
        #expect(StructureNodeModel.iconForType("Link") == "link")
        #expect(StructureNodeModel.iconForType("UnknownType") == "rectangle.badge.questionmark")
    }

    @Test("StructureNodeModel isHeading detects heading types")
    func nodeIsHeadingDetection() {
        let h1 = StructureNodeModel(id: "1", type: "H1", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)
        let h6 = StructureNodeModel(id: "2", type: "H6", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)
        let p = StructureNodeModel(id: "3", type: "P", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)

        #expect(h1.isHeading)
        #expect(h6.isHeading)
        #expect(!p.isHeading)
    }

    @Test("StructureNodeModel displayLabel uses title then altText then type")
    func nodeDisplayLabel() {
        let withTitle = StructureNodeModel(id: "1", type: "H1", title: "Intro", altText: "Alt", language: nil, children: [], pageIndex: 0)
        let withAlt = StructureNodeModel(id: "2", type: "Figure", title: nil, altText: "A photo", language: nil, children: [], pageIndex: 0)
        let typeOnly = StructureNodeModel(id: "3", type: "P", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)

        #expect(withTitle.displayLabel == "Intro")
        #expect(withAlt.displayLabel == "A photo")
        #expect(typeOnly.displayLabel == "P")
    }

    @Test("StructureNodeModel type detection: isFigure, isTable, isList")
    func nodeTypeDetection() {
        let figure = StructureNodeModel(id: "1", type: "Figure", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)
        let table = StructureNodeModel(id: "2", type: "Table", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)
        let list = StructureNodeModel(id: "3", type: "L", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)
        let list2 = StructureNodeModel(id: "4", type: "List", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)
        let other = StructureNodeModel(id: "5", type: "P", title: nil, altText: nil, language: nil, children: [], pageIndex: 0)

        #expect(figure.isFigure)
        #expect(!figure.isTable)
        #expect(table.isTable)
        #expect(!table.isFigure)
        #expect(list.isList)
        #expect(list2.isList)
        #expect(!other.isList)
    }

    // MARK: - Violation Marking Tests

    @Test("markViolations flags matching nodes")
    func markViolationsFlags() {
        let vm = StructureTreeViewModel()
        let nodes = [
            StructureNodeModel(
                id: "fig-1",
                type: "Figure",
                title: nil,
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
                pageIndex: 1
            ),
        ]
        vm.updateTree(nodes)

        let violations = [
            ViolationItem(
                id: "v1", ruleID: "7.1-001", severity: .error,
                message: "Missing alt text", description: "Missing alt text",
                pageIndex: 0, objectType: "Figure", context: nil,
                wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
                specification: nil, remediation: nil
            ),
        ]
        vm.markViolations(from: violations)

        #expect(vm.rootNodes[0].hasViolation == true)  // Figure on page 0 matches
        #expect(vm.rootNodes[1].hasViolation == false)  // P on page 1 does not match
    }

    // MARK: - Sample Tree Builder Tests

    @Test("Sample tree is well-formed with expected structure")
    func sampleTreeWellFormed() {
        let sample = StructureTreeBuilder.makeSampleTree()

        #expect(sample.count == 1)
        #expect(sample[0].type == "Document")
        #expect(!sample[0].children.isEmpty)

        let stats = StructureTreeBuilder.computeStatistics(for: sample)
        #expect(stats.totalElements > 0)
        #expect(stats.headingCount >= 2)
        #expect(stats.figureCount >= 1)
        #expect(stats.tableCount >= 1)
    }

    @Test("displayedNodeCount matches total for unfiltered tree")
    func displayedNodeCountMatchesTotal() {
        let vm = StructureTreeViewModel()
        vm.updateTree(Self.makeSampleNodes())

        #expect(vm.displayedNodeCount == vm.statistics.totalElements)
    }
}
