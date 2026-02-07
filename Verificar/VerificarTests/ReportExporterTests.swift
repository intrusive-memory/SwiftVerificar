import Testing
import Foundation
import AppKit
@testable import Verificar

// MARK: - ReportExporter Tests

@Suite("ReportExporter")
struct ReportExporterTests {

    // MARK: - Test Data

    private static func makeSummary() -> ValidationSummary {
        ValidationSummary(
            totalRules: 50,
            passedCount: 42,
            failedCount: 5,
            warningCount: 3,
            notApplicableCount: 0,
            profileName: "PDF/UA-2",
            duration: 1.234
        )
    }

    private static func makeViolations() -> [ViolationItem] {
        [
            ViolationItem(
                id: "rule-1-p1",
                ruleID: "PDFA-1.2.3",
                severity: .error,
                message: "Missing alternative text for figure",
                description: "All figures must have alternative text",
                pageIndex: 0,
                objectType: "Figure",
                context: "/StructTreeRoot/Document/Figure[0]",
                wcagCriterion: "1.1.1",
                wcagPrinciple: "Perceivable",
                wcagLevel: "A",
                specification: "PDF/UA-2 clause 7.3",
                remediation: "Add /Alt entry to the structure element"
            ),
            ViolationItem(
                id: "rule-2-p3",
                ruleID: "WCAG-4.1.2",
                severity: .warning,
                message: "Form field missing accessible name",
                description: "Interactive controls must have accessible names",
                pageIndex: 2,
                objectType: "Widget",
                context: nil,
                wcagCriterion: "4.1.2",
                wcagPrinciple: "Robust",
                wcagLevel: "A",
                specification: nil,
                remediation: nil
            ),
            ViolationItem(
                id: "rule-3-doc",
                ruleID: "INFO-1.0.0",
                severity: .info,
                message: "Document title should be set",
                description: "Setting a document title improves accessibility",
                pageIndex: nil,
                objectType: nil,
                context: nil,
                wcagCriterion: nil,
                wcagPrinciple: nil,
                wcagLevel: nil,
                specification: "PDF/UA-2 clause 7.1",
                remediation: "Set the /Title entry in document metadata"
            ),
        ]
    }

    // MARK: - JSON Export Tests

    @Test("JSON export produces valid JSON data")
    func jsonExportProducesValidData() {
        let exporter = ReportExporter()
        let data = exporter.exportJSON(
            summary: Self.makeSummary(),
            violations: Self.makeViolations(),
            documentTitle: "Test.pdf"
        )

        #expect(!data.isEmpty)

        // Verify it parses as valid JSON.
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil)
    }

    @Test("JSON export contains expected structure")
    func jsonExportContainsExpectedStructure() throws {
        let exporter = ReportExporter()
        let data = exporter.exportJSON(
            summary: Self.makeSummary(),
            violations: Self.makeViolations(),
            documentTitle: "Test.pdf"
        )

        let report = try JSONDecoder().decode(JSONReport.self, from: data)

        #expect(report.document == "Test.pdf")
        #expect(!report.generatedAt.isEmpty)
        #expect(report.summary.profileName == "PDF/UA-2")
        #expect(report.summary.totalRules == 50)
        #expect(report.summary.passedCount == 42)
        #expect(report.summary.failedCount == 5)
        #expect(report.summary.warningCount == 3)
        #expect(report.violations.count == 3)
    }

    @Test("JSON export violation fields are correct")
    func jsonExportViolationFields() throws {
        let exporter = ReportExporter()
        let data = exporter.exportJSON(
            summary: Self.makeSummary(),
            violations: Self.makeViolations(),
            documentTitle: "Test.pdf"
        )

        let report = try JSONDecoder().decode(JSONReport.self, from: data)
        let first = report.violations[0]

        #expect(first.ruleID == "PDFA-1.2.3")
        #expect(first.severity == "Error")
        #expect(first.page == 1) // 0-based pageIndex + 1
        #expect(first.wcagCriterion == "1.1.1")
        #expect(first.remediation == "Add /Alt entry to the structure element")
    }

    @Test("JSON export handles nil page index as null")
    func jsonExportNilPageIndex() throws {
        let exporter = ReportExporter()
        let data = exporter.exportJSON(
            summary: Self.makeSummary(),
            violations: Self.makeViolations(),
            documentTitle: "Test.pdf"
        )

        let report = try JSONDecoder().decode(JSONReport.self, from: data)
        let docLevel = report.violations[2]

        #expect(docLevel.page == nil)
        #expect(docLevel.wcagCriterion == nil)
    }

    // MARK: - HTML Export Tests

    @Test("HTML export contains expected sections")
    func htmlExportContainsExpectedSections() {
        let exporter = ReportExporter()
        let html = exporter.exportHTML(
            summary: Self.makeSummary(),
            violations: Self.makeViolations(),
            documentTitle: "Test.pdf"
        )

        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("Verificar Validation Report"))
        #expect(html.contains("Test.pdf"))
        #expect(html.contains("PDF/UA-2"))
        #expect(html.contains("Summary"))
        #expect(html.contains("Violations (3)"))
        #expect(html.contains("Non-conformant"))
    }

    @Test("HTML export contains violation details")
    func htmlExportContainsViolationDetails() {
        let exporter = ReportExporter()
        let html = exporter.exportHTML(
            summary: Self.makeSummary(),
            violations: Self.makeViolations(),
            documentTitle: "Test.pdf"
        )

        #expect(html.contains("PDFA-1.2.3"))
        #expect(html.contains("Missing alternative text for figure"))
        #expect(html.contains("severity-error"))
        #expect(html.contains("severity-warning"))
        #expect(html.contains("severity-info"))
        #expect(html.contains("Page 1"))
        #expect(html.contains("Page 3"))
        #expect(html.contains("Document-level"))
    }

    @Test("HTML export escapes special characters")
    func htmlExportEscapesSpecialChars() {
        let escaped = ReportExporter.escapeHTML("<script>alert('xss')</script>")
        #expect(escaped == "&lt;script&gt;alert(&#x27;xss&#x27;)&lt;/script&gt;" || !escaped.contains("<script>"))
        #expect(!escaped.contains("<script>"))
        #expect(escaped.contains("&lt;"))
        #expect(escaped.contains("&gt;"))
    }

    @Test("HTML export with no violations shows conformant message")
    func htmlExportNoViolations() {
        let summary = ValidationSummary(
            totalRules: 10,
            passedCount: 10,
            failedCount: 0,
            warningCount: 0,
            notApplicableCount: 0,
            profileName: "PDF/UA-1",
            duration: 0.5
        )
        let exporter = ReportExporter()
        let html = exporter.exportHTML(
            summary: summary,
            violations: [],
            documentTitle: "Clean.pdf"
        )

        #expect(html.contains("No violations found"))
        #expect(html.contains("Conformant"))
    }

    // MARK: - Text Export Tests

    @Test("Text export formatting is correct")
    func textExportFormatting() {
        let exporter = ReportExporter()
        let text = exporter.exportText(
            summary: Self.makeSummary(),
            violations: Self.makeViolations(),
            documentTitle: "Test.pdf"
        )

        #expect(text.contains("VERIFICAR VALIDATION REPORT"))
        #expect(text.contains("Document:  Test.pdf"))
        #expect(text.contains("Profile:   PDF/UA-2"))
        #expect(text.contains("Status:    Non-conformant"))
        #expect(text.contains("Total Rules:     50"))
        #expect(text.contains("Passed:          42"))
        #expect(text.contains("Failed:          5"))
        #expect(text.contains("Pass Rate:       84%"))
    }

    @Test("Text export contains numbered violations")
    func textExportNumberedViolations() {
        let exporter = ReportExporter()
        let text = exporter.exportText(
            summary: Self.makeSummary(),
            violations: Self.makeViolations(),
            documentTitle: "Test.pdf"
        )

        #expect(text.contains("VIOLATIONS (3)"))
        #expect(text.contains("1. [Error] PDFA-1.2.3"))
        #expect(text.contains("2. [Warning] WCAG-4.1.2"))
        #expect(text.contains("3. [Info] INFO-1.0.0"))
        #expect(text.contains("Location: Page 1"))
        #expect(text.contains("Location: Page 3"))
        #expect(text.contains("Location: Document-level"))
    }

    @Test("Text export with no violations shows clean message")
    func textExportNoViolations() {
        let summary = ValidationSummary(
            totalRules: 10,
            passedCount: 10,
            failedCount: 0,
            warningCount: 0,
            notApplicableCount: 0,
            profileName: "PDF/UA-1",
            duration: 0.5
        )
        let exporter = ReportExporter()
        let text = exporter.exportText(
            summary: summary,
            violations: [],
            documentTitle: "Clean.pdf"
        )

        #expect(text.contains("No violations found"))
        #expect(text.contains("Status:    Conformant"))
    }

    // MARK: - ViolationAnnotation Tests

    @Test("Annotation color mapping is correct")
    func annotationColorMapping() {
        let errorColor = ViolationAnnotation.annotationColor(for: .error)
        let warningColor = ViolationAnnotation.annotationColor(for: .warning)
        let infoColor = ViolationAnnotation.annotationColor(for: .info)

        #expect(errorColor == .systemRed)
        #expect(warningColor == .systemYellow)
        #expect(infoColor == .systemBlue)
    }

    @Test("Tooltip text contains violation details")
    func tooltipTextContainsDetails() {
        let violation = Self.makeViolations()[0]
        let tooltip = ViolationAnnotation.tooltipText(for: violation)

        #expect(tooltip.contains("[Error]"))
        #expect(tooltip.contains("PDFA-1.2.3"))
        #expect(tooltip.contains("Missing alternative text for figure"))
        #expect(tooltip.contains("WCAG 1.1.1"))
    }

    @Test("Tooltip text omits WCAG when nil")
    func tooltipOmitsNilWCAG() {
        let violation = Self.makeViolations()[2] // info with no WCAG
        let tooltip = ViolationAnnotation.tooltipText(for: violation)

        #expect(tooltip.contains("[Info]"))
        #expect(!tooltip.contains("WCAG"))
    }

    // MARK: - DocumentViewModel Export Tests

    @Test("Export JSON returns nil when no results")
    func exportJSONNilWhenNoResults() {
        let vm = DocumentViewModel()
        #expect(vm.exportJSON() == nil)
    }

    @Test("Export HTML returns nil when no results")
    func exportHTMLNilWhenNoResults() {
        let vm = DocumentViewModel()
        #expect(vm.exportHTML() == nil)
    }

    @Test("Export Text returns nil when no results")
    func exportTextNilWhenNoResults() {
        let vm = DocumentViewModel()
        #expect(vm.exportText() == nil)
    }

    @Test("Show violation highlights defaults to true")
    func showHighlightsDefault() {
        let vm = DocumentViewModel()
        #expect(vm.showViolationHighlights == true)
    }

    @Test("Handle annotation clicked sets selected violation")
    func handleAnnotationClickedSetsSelection() {
        let vm = DocumentViewModel()
        let violation = Self.makeViolations()[0]
        vm.handleAnnotationClicked(violation)
        #expect(vm.validationViewModel.selectedViolation == violation)
    }
}
