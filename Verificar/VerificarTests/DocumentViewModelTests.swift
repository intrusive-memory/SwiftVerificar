import Testing
import Foundation
import PDFKit
@testable import Verificar

// MARK: - DocumentViewModel Tests

@Suite("DocumentViewModel")
struct DocumentViewModelTests {

    @Test("Initial state has no document and not validated")
    func initialState() {
        let viewModel = DocumentViewModel()
        #expect(viewModel.documentModel.pdfDocument == nil)
        #expect(viewModel.documentModel.isDocumentLoaded == false)
        #expect(viewModel.validationService.isValidating == false)
        #expect(viewModel.validationService.lastResult == nil)
        #expect(viewModel.validationSummary == nil)
        #expect(viewModel.violations.isEmpty)
        #expect(viewModel.complianceStatus == .notValidated)
        #expect(viewModel.selectedProfile == "PDF/UA-2")
        #expect(viewModel.autoValidateOnOpen == true)
    }

    @Test("Compliance status is notValidated when no document loaded")
    func complianceStatusNotValidated() {
        let viewModel = DocumentViewModel()
        #expect(viewModel.complianceStatus == .notValidated)
    }

    @Test("Select violation updates selected and navigates to page")
    func selectViolationNavigates() {
        let viewModel = DocumentViewModel()

        // Create a multi-page document so goToPage has pages to navigate to
        let document = PDFDocument()
        let page1 = PDFPage()
        let page2 = PDFPage()
        let page3 = PDFPage()
        document.insert(page1, at: 0)
        document.insert(page2, at: 1)
        document.insert(page3, at: 2)

        viewModel.documentModel.pdfDocument = document
        viewModel.documentModel.url = URL(fileURLWithPath: "/tmp/test.pdf")

        let violation = ViolationItem(
            id: "test-1",
            ruleID: "7.1-001",
            severity: .error,
            message: "Missing alt text",
            description: "Figure element lacks alt text",
            pageIndex: 2,
            objectType: "Figure",
            context: nil,
            wcagCriterion: "1.1.1",
            wcagPrinciple: "Perceivable",
            wcagLevel: "A",
            specification: "PDF/UA-2 clause 7.1",
            remediation: "Add alt text"
        )

        viewModel.selectViolation(violation)

        #expect(viewModel.validationViewModel.selectedViolation == violation)
        #expect(viewModel.documentModel.currentPageIndex == 2)
    }

    @Test("Select violation with nil page does not change page")
    func selectViolationNilPage() {
        let viewModel = DocumentViewModel()

        let document = PDFDocument()
        let page1 = PDFPage()
        document.insert(page1, at: 0)
        viewModel.documentModel.pdfDocument = document
        viewModel.documentModel.url = URL(fileURLWithPath: "/tmp/test.pdf")
        viewModel.documentModel.goToPage(0)

        let violation = ViolationItem(
            id: "test-2",
            ruleID: "meta-001",
            severity: .warning,
            message: "Missing metadata",
            description: "Document-level metadata issue",
            pageIndex: nil,
            objectType: nil,
            context: nil,
            wcagCriterion: nil,
            wcagPrinciple: nil,
            wcagLevel: nil,
            specification: nil,
            remediation: nil
        )

        viewModel.selectViolation(violation)

        #expect(viewModel.validationViewModel.selectedViolation == violation)
        #expect(viewModel.documentModel.currentPageIndex == 0)
    }

    @Test("Open document with non-existent file sets error")
    func openDocumentFailure() async {
        let viewModel = DocumentViewModel()
        let badURL = URL(fileURLWithPath: "/tmp/definitely_nonexistent_\(UUID()).pdf")

        await viewModel.openDocument(at: badURL)

        // Document should not be loaded
        #expect(viewModel.documentModel.isDocumentLoaded == false)
        #expect(viewModel.documentModel.error != nil)
    }

    @Test("Open document clears previous validation state")
    func openDocumentClearsPreviousState() async {
        let viewModel = DocumentViewModel()

        // Seed some violations into the view model
        let violation = ViolationItem(
            id: "old-1",
            ruleID: "old-rule",
            severity: .error,
            message: "Old violation",
            description: "Should be cleared",
            pageIndex: 0,
            objectType: nil,
            context: nil,
            wcagCriterion: nil,
            wcagPrinciple: nil,
            wcagLevel: nil,
            specification: nil,
            remediation: nil
        )
        viewModel.validationViewModel.updateViolations([violation])
        #expect(viewModel.validationViewModel.violations.count == 1)

        // Open a non-existent file (will fail, but should still clear state)
        let badURL = URL(fileURLWithPath: "/tmp/definitely_nonexistent_\(UUID()).pdf")
        await viewModel.openDocument(at: badURL)

        // Previous violations should be cleared
        #expect(viewModel.validationViewModel.violations.isEmpty)
    }
}

// MARK: - ValidationViewModel Tests

@Suite("ValidationViewModel")
struct ValidationViewModelTests {

    // MARK: - Test Data

    private static func makeSampleViolations() -> [ViolationItem] {
        [
            ViolationItem(
                id: "err-1", ruleID: "7.1-001", severity: .error,
                message: "Missing alt text on figure",
                description: "Figure element lacks alt text",
                pageIndex: 0, objectType: "Figure", context: nil,
                wcagCriterion: "1.1.1", wcagPrinciple: "Perceivable",
                wcagLevel: "A", specification: "PDF/UA-2 clause 7.1",
                remediation: "Add alt text"
            ),
            ViolationItem(
                id: "err-2", ruleID: "7.2-003", severity: .error,
                message: "Table missing headers",
                description: "Table element has no TH children",
                pageIndex: 2, objectType: "Table", context: nil,
                wcagCriterion: "1.3.1", wcagPrinciple: "Perceivable",
                wcagLevel: "A", specification: "PDF/UA-2 clause 7.2",
                remediation: "Add table headers"
            ),
            ViolationItem(
                id: "warn-1", ruleID: "8.1-002", severity: .warning,
                message: "Low contrast ratio (3.8:1)",
                description: "Text contrast ratio below 4.5:1",
                pageIndex: 0, objectType: "Span", context: nil,
                wcagCriterion: "1.4.3", wcagPrinciple: "Perceivable",
                wcagLevel: "AA", specification: "WCAG 2.1",
                remediation: "Increase contrast"
            ),
            ViolationItem(
                id: "info-1", ruleID: "meta-001", severity: .info,
                message: "Document language not declared",
                description: "The document does not declare a language",
                pageIndex: nil, objectType: nil, context: nil,
                wcagCriterion: "3.1.1", wcagPrinciple: "Understandable",
                wcagLevel: "A", specification: "PDF/UA-2",
                remediation: "Set document language"
            ),
        ]
    }

    @Test("Filter by error severity returns only errors")
    func filterBySeverityError() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.filterSeverity = .error

        let filtered = vm.filteredViolations
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.severity == .error })
    }

    @Test("Filter by warning severity returns only warnings")
    func filterBySeverityWarning() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.filterSeverity = .warning

        let filtered = vm.filteredViolations
        #expect(filtered.count == 1)
        #expect(filtered[0].severity == .warning)
    }

    @Test("Filter by info severity returns only info")
    func filterBySeverityInfo() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.filterSeverity = .info

        let filtered = vm.filteredViolations
        #expect(filtered.count == 1)
        #expect(filtered[0].severity == .info)
    }

    @Test("No filter returns all violations")
    func noFilterReturnsAll() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.filterSeverity = nil

        #expect(vm.filteredViolations.count == 4)
    }

    @Test("Search by message text")
    func searchByMessage() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.searchText = "alt text"

        let filtered = vm.filteredViolations
        #expect(filtered.count == 1)
        #expect(filtered[0].ruleID == "7.1-001")
    }

    @Test("Search by rule ID")
    func searchByRuleID() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.searchText = "7.2-003"

        let filtered = vm.filteredViolations
        #expect(filtered.count == 1)
        #expect(filtered[0].message == "Table missing headers")
    }

    @Test("Search is case insensitive")
    func searchCaseInsensitive() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.searchText = "ALT TEXT"

        #expect(vm.filteredViolations.count == 1)
    }

    @Test("Combined filter and search")
    func combinedFilterAndSearch() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.filterSeverity = .error
        vm.searchText = "table"

        let filtered = vm.filteredViolations
        #expect(filtered.count == 1)
        #expect(filtered[0].ruleID == "7.2-003")
    }

    @Test("Empty search returns all (respecting severity filter)")
    func emptySearchReturnsAll() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.searchText = ""
        vm.filterSeverity = nil

        #expect(vm.filteredViolations.count == 4)
    }

    @Test("Group by severity produces correct groups")
    func groupBySeverity() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.groupBy = .severity

        let groups = vm.groupedViolations
        // Should have Error, Warning, Info groups
        #expect(groups.count == 3)
        #expect(groups[0].0.contains("Error"))
        #expect(groups[0].1.count == 2)
        #expect(groups[1].0.contains("Warning"))
        #expect(groups[1].1.count == 1)
        #expect(groups[2].0.contains("Info"))
        #expect(groups[2].1.count == 1)
    }

    @Test("Group by page produces correct groups")
    func groupByPage() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.groupBy = .page

        let groups = vm.groupedViolations
        // Should have Document-level, Page 1, Page 3
        #expect(groups.count == 3)
        // Document-level comes first
        #expect(groups[0].0 == "Document-level")
        #expect(groups[0].1.count == 1)
    }

    @Test("Group by none returns single group")
    func groupByNone() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.groupBy = .none

        let groups = vm.groupedViolations
        #expect(groups.count == 1)
        #expect(groups[0].0 == "All Violations")
        #expect(groups[0].1.count == 4)
    }

    @Test("Summary text is correct")
    func summaryText() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()

        #expect(vm.summaryText == "4 violations (2 errors, 1 warning, 1 info)")
    }

    @Test("Summary text for empty violations")
    func summaryTextEmpty() {
        let vm = ValidationViewModel()
        #expect(vm.summaryText == "No violations")
    }

    @Test("UpdateViolations replaces and clears selection")
    func updateViolationsReplacesAndClearsSelection() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.selectedViolation = vm.violations.first

        let newViolation = ViolationItem(
            id: "new-1", ruleID: "new-rule", severity: .info,
            message: "New", description: "New violation",
            pageIndex: nil, objectType: nil, context: nil,
            wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
            specification: nil, remediation: nil
        )
        vm.updateViolations([newViolation])

        #expect(vm.violations.count == 1)
        #expect(vm.selectedViolation == nil)
    }

    @Test("ClearViolations resets everything")
    func clearViolationsResetsEverything() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.filterSeverity = .error
        vm.searchText = "test"
        vm.selectedViolation = vm.violations.first

        vm.clearViolations()

        #expect(vm.violations.isEmpty)
        #expect(vm.selectedViolation == nil)
        #expect(vm.filterSeverity == nil)
        #expect(vm.searchText == "")
    }

    @Test("GroupingMode has all four cases")
    func groupingModeCases() {
        let cases = ValidationViewModel.GroupingMode.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.none))
        #expect(cases.contains(.severity))
        #expect(cases.contains(.category))
        #expect(cases.contains(.page))
    }

    @Test("Error, warning, and info counts are correct")
    func severityCounts() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        #expect(vm.errorCount == 2)
        #expect(vm.warningCount == 1)
        #expect(vm.infoCount == 1)
    }
}
