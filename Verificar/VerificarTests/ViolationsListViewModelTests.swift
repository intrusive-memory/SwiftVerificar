import Testing
import Foundation
@testable import Verificar

// MARK: - ViolationsListView Model Tests

@Suite("ViolationsListView Model")
struct ViolationsListViewModelTests {

    // MARK: - Test Data

    private static func makeSampleViolations() -> [ViolationItem] {
        [
            ViolationItem(
                id: "err-1", ruleID: "7.1-001", severity: .error,
                message: "Missing alt text on figure",
                description: "Figure element lacks alt text",
                pageIndex: 0, objectType: "Figure", context: "/StructTreeRoot/Document/Figure",
                wcagCriterion: "1.1.1", wcagPrinciple: "Perceivable",
                wcagLevel: "A", specification: "PDF/UA-2 clause 7.1",
                remediation: "Add alt text to the figure element"
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

    // MARK: - Badge Count Tests

    @Test("Badge count returns error count only")
    func badgeCountReturnsErrorCount() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()

        let badge = ViolationsListHelper.badgeCount(from: vm)
        #expect(badge == 2)
    }

    @Test("Badge count is zero when no errors")
    func badgeCountZeroWhenNoErrors() {
        let vm = ValidationViewModel()
        vm.violations = [
            ViolationItem(
                id: "warn-only", ruleID: "test", severity: .warning,
                message: "Warning only", description: "Warning only",
                pageIndex: nil, objectType: nil, context: nil,
                wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
                specification: nil, remediation: nil
            ),
        ]

        #expect(ViolationsListHelper.badgeCount(from: vm) == 0)
    }

    @Test("Badge count is zero when no violations")
    func badgeCountZeroWhenEmpty() {
        let vm = ValidationViewModel()
        #expect(ViolationsListHelper.badgeCount(from: vm) == 0)
    }

    // MARK: - Format Violation Details Tests

    @Test("Format violation details includes all fields")
    func formatDetailsIncludesAllFields() {
        let violation = Self.makeSampleViolations()[0]
        let text = ViolationsListHelper.formatViolationDetails(violation)

        #expect(text.contains("Rule: 7.1-001"))
        #expect(text.contains("Severity: Error"))
        #expect(text.contains("Message: Missing alt text on figure"))
        #expect(text.contains("Page: 1"))
        #expect(text.contains("WCAG Criterion: 1.1.1"))
        #expect(text.contains("WCAG Principle: Perceivable"))
        #expect(text.contains("WCAG Level: A"))
        #expect(text.contains("Specification: PDF/UA-2 clause 7.1"))
        #expect(text.contains("Context: /StructTreeRoot/Document/Figure"))
        #expect(text.contains("Remediation: Add alt text to the figure element"))
    }

    @Test("Format violation details omits nil fields")
    func formatDetailsOmitsNilFields() {
        let violation = ViolationItem(
            id: "min-1", ruleID: "test-001", severity: .info,
            message: "Minimal violation",
            description: "Minimal",
            pageIndex: nil, objectType: nil, context: nil,
            wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
            specification: nil, remediation: nil
        )
        let text = ViolationsListHelper.formatViolationDetails(violation)

        #expect(text.contains("Rule: test-001"))
        #expect(text.contains("Severity: Info"))
        #expect(text.contains("Message: Minimal violation"))
        #expect(!text.contains("Page:"))
        #expect(!text.contains("WCAG Criterion:"))
        #expect(!text.contains("WCAG Principle:"))
        #expect(!text.contains("WCAG Level:"))
        #expect(!text.contains("Specification:"))
        #expect(!text.contains("Context:"))
        #expect(!text.contains("Remediation:"))
    }

    @Test("Format violation details shows 1-based page number")
    func formatDetailsShowsOneBasedPage() {
        let violation = ViolationItem(
            id: "page-test", ruleID: "test", severity: .error,
            message: "Test", description: "Test",
            pageIndex: 4, objectType: nil, context: nil,
            wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
            specification: nil, remediation: nil
        )
        let text = ViolationsListHelper.formatViolationDetails(violation)
        // pageIndex 4 should display as page 5
        #expect(text.contains("Page: 5"))
    }

    // MARK: - Filter Label Tests

    @Test("Severity filter labels are correct")
    func severityFilterLabels() {
        #expect(ViolationSeverity.error.filterLabel == "Errors")
        #expect(ViolationSeverity.warning.filterLabel == "Warnings")
        #expect(ViolationSeverity.info.filterLabel == "Info")
    }

    // MARK: - Grouping with Filters Tests

    @Test("Grouped violations respect severity filter")
    func groupedViolationsRespectFilter() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.filterSeverity = .error
        vm.groupBy = .severity

        let groups = vm.groupedViolations
        // Only error group should appear
        #expect(groups.count == 1)
        #expect(groups[0].1.count == 2)
        #expect(groups[0].1.allSatisfy { $0.severity == .error })
    }

    @Test("Grouped violations respect search text")
    func groupedViolationsRespectSearch() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.searchText = "alt text"
        vm.groupBy = .severity

        let groups = vm.groupedViolations
        // Only 1 violation matches, so 1 group (errors) with 1 entry
        #expect(groups.count == 1)
        #expect(groups[0].1.count == 1)
        #expect(groups[0].1[0].ruleID == "7.1-001")
    }

    @Test("Group by category produces principle-based groups")
    func groupByCategoryProducesPrincipleGroups() {
        let vm = ValidationViewModel()
        vm.violations = Self.makeSampleViolations()
        vm.groupBy = .category

        let groups = vm.groupedViolations
        // "Perceivable" (3 items), "Understandable" (1 item)
        #expect(groups.count == 2)

        let perceivable = groups.first { $0.0 == "Perceivable" }
        #expect(perceivable != nil)
        #expect(perceivable?.1.count == 3)

        let understandable = groups.first { $0.0 == "Understandable" }
        #expect(understandable != nil)
        #expect(understandable?.1.count == 1)
    }

    // MARK: - Selection Navigation Test

    @Test("Selecting violation updates view model state")
    func selectingViolationUpdatesState() {
        let vm = ValidationViewModel()
        let violations = Self.makeSampleViolations()
        vm.violations = violations

        // Initially no selection
        #expect(vm.selectedViolation == nil)

        // Select first violation
        vm.selectedViolation = violations[0]
        #expect(vm.selectedViolation?.id == "err-1")

        // Select different violation
        vm.selectedViolation = violations[2]
        #expect(vm.selectedViolation?.id == "warn-1")
    }
}
