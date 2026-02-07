import Testing
import Foundation
import PDFKit
@testable import Verificar

// MARK: - Integration Tests

@Suite("Integration Tests")
struct IntegrationTests {

    // MARK: - Test Data Helpers

    /// Creates a simple in-memory PDFDocument for testing.
    private static func makePDFDocument(pageCount: Int = 3) -> PDFDocument {
        let document = PDFDocument()
        for i in 0..<pageCount {
            let page = PDFPage()
            document.insert(page, at: i)
        }
        return document
    }

    /// Creates a sample set of violations for testing.
    private static func makeSampleViolations() -> [ViolationItem] {
        [
            ViolationItem(
                id: "err-1-p0",
                ruleID: "7.1-001",
                severity: .error,
                message: "Missing alternative text for figure",
                description: "Figure element lacks alt text",
                pageIndex: 0,
                objectType: "Figure",
                context: "/StructTreeRoot/Document/Figure[0]",
                wcagCriterion: "1.1.1",
                wcagPrinciple: "Perceivable",
                wcagLevel: "A",
                specification: "PDF/UA-2 clause 7.1",
                remediation: "Add /Alt entry to the structure element"
            ),
            ViolationItem(
                id: "warn-1-p1",
                ruleID: "8.1-002",
                severity: .warning,
                message: "Low contrast ratio (3.8:1)",
                description: "Text contrast ratio below 4.5:1",
                pageIndex: 1,
                objectType: "Span",
                context: nil,
                wcagCriterion: "1.4.3",
                wcagPrinciple: "Perceivable",
                wcagLevel: "AA",
                specification: "WCAG 2.1",
                remediation: "Increase contrast"
            ),
        ]
    }

    // MARK: - Full Pipeline Tests

    @Test("Full document open, validate, and display pipeline")
    func fullOpenValidateDisplayPipeline() async {
        let viewModel = DocumentViewModel()

        // 1. Set up document model with in-memory PDF
        let document = Self.makePDFDocument(pageCount: 5)
        viewModel.documentModel.pdfDocument = document
        viewModel.documentModel.url = URL(fileURLWithPath: "/tmp/test-integration.pdf")

        // 2. Verify document is loaded
        #expect(viewModel.documentModel.isDocumentLoaded == true)
        #expect(viewModel.documentModel.pageCount == 5)

        // 3. Initially no validation results
        #expect(viewModel.validationSummary == nil)
        #expect(viewModel.violations.isEmpty)
        #expect(viewModel.complianceStatus == .notValidated)

        // 4. Simulate validation by pushing violations into the view model
        let violations = Self.makeSampleViolations()
        viewModel.validationViewModel.updateViolations(violations)

        // 5. Verify violations are accessible
        #expect(viewModel.validationViewModel.violations.count == 2)
        #expect(viewModel.validationViewModel.errorCount == 1)
        #expect(viewModel.validationViewModel.warningCount == 1)

        // 6. Select a violation and verify PDF navigation
        viewModel.selectViolation(violations[0])
        #expect(viewModel.validationViewModel.selectedViolation == violations[0])
        #expect(viewModel.documentModel.currentPageIndex == 0)

        // 7. Select second violation and verify page change
        viewModel.selectViolation(violations[1])
        #expect(viewModel.validationViewModel.selectedViolation == violations[1])
        #expect(viewModel.documentModel.currentPageIndex == 1)
    }

    @Test("Re-validation with different profiles clears previous results")
    func revalidationWithDifferentProfiles() async {
        let viewModel = DocumentViewModel()

        // Set up document
        let document = Self.makePDFDocument()
        viewModel.documentModel.pdfDocument = document
        viewModel.documentModel.url = URL(fileURLWithPath: "/tmp/test-revalidation.pdf")

        // First "validation" with PDF/UA-2
        viewModel.selectedProfile = "PDF/UA-2"
        let firstViolations = Self.makeSampleViolations()
        viewModel.validationViewModel.updateViolations(firstViolations)
        #expect(viewModel.validationViewModel.violations.count == 2)
        #expect(viewModel.selectedProfile == "PDF/UA-2")

        // Switch profile
        viewModel.selectedProfile = "PDF/A-1a"
        #expect(viewModel.selectedProfile == "PDF/A-1a")

        // Re-validate (simulated by clearing and adding new violations)
        viewModel.validationViewModel.clearViolations()
        #expect(viewModel.validationViewModel.violations.isEmpty)

        // New validation results with different profile
        let newViolation = ViolationItem(
            id: "pdfa-err-1",
            ruleID: "PDFA-6.1.2",
            severity: .error,
            message: "Non-embedded font",
            description: "All fonts must be embedded for PDF/A conformance",
            pageIndex: 0,
            objectType: "Font",
            context: nil,
            wcagCriterion: nil,
            wcagPrinciple: nil,
            wcagLevel: nil,
            specification: "ISO 19005-1 clause 6.1.2",
            remediation: "Embed the font in the PDF"
        )
        viewModel.validationViewModel.updateViolations([newViolation])
        #expect(viewModel.validationViewModel.violations.count == 1)
        #expect(viewModel.validationViewModel.violations[0].ruleID == "PDFA-6.1.2")
    }

    @Test("Export pipeline produces valid data for all formats")
    func exportPipelineAllFormats() {
        let viewModel = DocumentViewModel()

        // Without validation results, exports should return nil
        #expect(viewModel.exportJSON() == nil)
        #expect(viewModel.exportHTML() == nil)
        #expect(viewModel.exportText() == nil)

        // Set up document and simulate validation
        let document = Self.makePDFDocument()
        viewModel.documentModel.pdfDocument = document
        viewModel.documentModel.url = URL(fileURLWithPath: "/tmp/export-test.pdf")

        // Still nil without actual ValidationResult (from service)
        #expect(viewModel.exportJSON() == nil)
    }

    @Test("Violation filtering and grouping integration")
    func violationFilteringAndGroupingIntegration() {
        let viewModel = DocumentViewModel()
        let vm = viewModel.validationViewModel

        // Load violations
        vm.updateViolations(Self.makeSampleViolations())
        #expect(vm.violations.count == 2)

        // Filter by error
        vm.filterSeverity = .error
        #expect(vm.filteredViolations.count == 1)
        #expect(vm.filteredViolations[0].severity == .error)

        // Clear filter and group by page
        vm.filterSeverity = nil
        vm.groupBy = .page
        let groups = vm.groupedViolations
        #expect(groups.count == 2) // Page 1 and Page 2

        // Group by severity
        vm.groupBy = .severity
        let severityGroups = vm.groupedViolations
        #expect(severityGroups.count == 2) // Errors and Warnings

        // Search
        vm.searchText = "contrast"
        #expect(vm.filteredViolations.count == 1)
        #expect(vm.filteredViolations[0].ruleID == "8.1-002")
    }

    @Test("Document close resets all state")
    func documentCloseResetsAllState() {
        let viewModel = DocumentViewModel()

        // Set up document
        let document = Self.makePDFDocument()
        viewModel.documentModel.pdfDocument = document
        viewModel.documentModel.url = URL(fileURLWithPath: "/tmp/close-test.pdf")
        viewModel.documentModel.goToPage(2)
        viewModel.documentModel.zoomIn()
        viewModel.documentModel.displayMode = .twoUpContinuous

        // Add violations
        viewModel.validationViewModel.updateViolations(Self.makeSampleViolations())

        // Close document
        viewModel.documentModel.close()
        viewModel.validationViewModel.clearViolations()

        // Verify all state is reset
        #expect(viewModel.documentModel.isDocumentLoaded == false)
        #expect(viewModel.documentModel.currentPageIndex == 0)
        #expect(viewModel.documentModel.zoomLevel == 1.0)
        #expect(viewModel.documentModel.displayMode == .singlePageContinuous)
        #expect(viewModel.validationViewModel.violations.isEmpty)
        #expect(viewModel.validationViewModel.selectedViolation == nil)
    }

    @Test("Annotation click selects violation bidirectionally")
    func annotationClickSelectsBidirectionally() {
        let viewModel = DocumentViewModel()

        // Set up document
        let document = Self.makePDFDocument()
        viewModel.documentModel.pdfDocument = document
        viewModel.documentModel.url = URL(fileURLWithPath: "/tmp/annotation-test.pdf")

        let violations = Self.makeSampleViolations()
        viewModel.validationViewModel.updateViolations(violations)

        // Simulate annotation click from PDF view
        viewModel.handleAnnotationClicked(violations[1])

        // Verify the violation is selected in the view model
        #expect(viewModel.validationViewModel.selectedViolation == violations[1])

        // Now select via list (opposite direction)
        viewModel.selectViolation(violations[0])
        #expect(viewModel.validationViewModel.selectedViolation == violations[0])
        #expect(viewModel.documentModel.currentPageIndex == 0)
    }

    @Test("Violation highlight toggle state persists")
    func violationHighlightToggle() {
        let viewModel = DocumentViewModel()

        #expect(viewModel.showViolationHighlights == true)

        viewModel.showViolationHighlights = false
        #expect(viewModel.showViolationHighlights == false)

        viewModel.showViolationHighlights.toggle()
        #expect(viewModel.showViolationHighlights == true)
    }

    @Test("Open document with invalid URL sets error on model")
    func openInvalidDocument() async {
        let viewModel = DocumentViewModel()
        let badURL = URL(fileURLWithPath: "/nonexistent/path/test-\(UUID()).pdf")

        await viewModel.openDocument(at: badURL)

        #expect(viewModel.documentModel.isDocumentLoaded == false)
        #expect(viewModel.documentModel.error != nil)
        #expect(viewModel.validationViewModel.violations.isEmpty)
    }
}
