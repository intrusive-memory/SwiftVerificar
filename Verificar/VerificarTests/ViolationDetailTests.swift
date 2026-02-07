import Testing
import Foundation
@testable import Verificar

// MARK: - ViolationDetail Tests

@Suite("ViolationDetail")
struct ViolationDetailTests {

    // MARK: - Test Data

    private static func makeFullViolation() -> ViolationItem {
        ViolationItem(
            id: "err-1", ruleID: "7.1-001", severity: .error,
            message: "Missing alt text on figure element",
            description: "The Figure structure element on page 1 does not have an alternative text attribute.",
            pageIndex: 0, objectType: "Figure",
            context: "/StructTreeRoot/Document/Section/Figure",
            wcagCriterion: "1.1.1", wcagPrinciple: "Perceivable",
            wcagLevel: "A", specification: "PDF/UA-2 clause 7.1",
            remediation: "Add an /Alt entry to the Figure structure element."
        )
    }

    private static func makeMinimalViolation() -> ViolationItem {
        ViolationItem(
            id: "info-1", ruleID: "meta-001", severity: .info,
            message: "Document language not declared",
            description: "Document language not declared",
            pageIndex: nil, objectType: nil, context: nil,
            wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
            specification: nil, remediation: nil
        )
    }

    // MARK: - WCAG Criterion Display Formatting Tests

    @Test("Known WCAG criterion returns correct name")
    func knownWCAGCriterionName() {
        #expect(ViolationDetailHelper.wcagCriterionName("1.1.1") == "Non-text Content")
        #expect(ViolationDetailHelper.wcagCriterionName("1.3.1") == "Info and Relationships")
        #expect(ViolationDetailHelper.wcagCriterionName("1.4.3") == "Contrast (Minimum)")
        #expect(ViolationDetailHelper.wcagCriterionName("2.4.2") == "Page Titled")
        #expect(ViolationDetailHelper.wcagCriterionName("3.1.1") == "Language of Page")
        #expect(ViolationDetailHelper.wcagCriterionName("4.1.2") == "Name, Role, Value")
    }

    @Test("Unknown WCAG criterion returns nil")
    func unknownWCAGCriterionName() {
        #expect(ViolationDetailHelper.wcagCriterionName("99.99.99") == nil)
        #expect(ViolationDetailHelper.wcagCriterionName("") == nil)
        #expect(ViolationDetailHelper.wcagCriterionName("not.a.criterion") == nil)
    }

    @Test("WCAG level formatting adds 'Level' prefix")
    func wcagLevelFormatting() {
        #expect(ViolationDetailHelper.formatWCAGLevel("A") == "Level A")
        #expect(ViolationDetailHelper.formatWCAGLevel("AA") == "Level AA")
        #expect(ViolationDetailHelper.formatWCAGLevel("AAA") == "Level AAA")
    }

    @Test("WCAG level formatting does not double-prefix")
    func wcagLevelNoDoublePrefix() {
        #expect(ViolationDetailHelper.formatWCAGLevel("Level A") == "Level A")
        #expect(ViolationDetailHelper.formatWCAGLevel("Level AA") == "Level AA")
    }

    @Test("All four WCAG principles have criteria mapped")
    func allPrinciplesHaveCriteria() {
        let map = ViolationDetailHelper.wcagCriterionMap

        // Perceivable (1.x.x)
        let perceivable = map.keys.filter { $0.hasPrefix("1.") }
        #expect(!perceivable.isEmpty)

        // Operable (2.x.x)
        let operable = map.keys.filter { $0.hasPrefix("2.") }
        #expect(!operable.isEmpty)

        // Understandable (3.x.x)
        let understandable = map.keys.filter { $0.hasPrefix("3.") }
        #expect(!understandable.isEmpty)

        // Robust (4.x.x)
        let robust = map.keys.filter { $0.hasPrefix("4.") }
        #expect(!robust.isEmpty)
    }

    // MARK: - Remediation Text Generation Tests

    @Test("Format remediation includes base text and WCAG reference")
    func formatRemediationWithWCAG() {
        let violation = Self.makeFullViolation()
        let result = ViolationDetailHelper.formatRemediation(violation)

        #expect(result != nil)
        #expect(result?.contains("Add an /Alt entry") == true)
        #expect(result?.contains("WCAG 1.1.1") == true)
        #expect(result?.contains("Non-text Content") == true)
    }

    @Test("Format remediation returns nil when no remediation provided")
    func formatRemediationNilWhenNoRemediation() {
        let violation = Self.makeMinimalViolation()
        let result = ViolationDetailHelper.formatRemediation(violation)
        #expect(result == nil)
    }

    @Test("Format remediation without WCAG criterion omits reference")
    func formatRemediationWithoutWCAG() {
        let violation = ViolationItem(
            id: "no-wcag", ruleID: "struct-001", severity: .error,
            message: "Invalid structure", description: "Invalid structure",
            pageIndex: 0, objectType: nil, context: nil,
            wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
            specification: "PDF/UA-2", remediation: "Fix the structure tree."
        )
        let result = ViolationDetailHelper.formatRemediation(violation)

        #expect(result != nil)
        #expect(result == "Fix the structure tree.")
        #expect(result?.contains("WCAG") == false)
    }

    @Test("Format remediation with unknown criterion still includes reference")
    func formatRemediationWithUnknownCriterion() {
        let violation = ViolationItem(
            id: "unknown-wcag", ruleID: "custom-001", severity: .warning,
            message: "Custom check", description: "Custom check",
            pageIndex: nil, objectType: nil, context: nil,
            wcagCriterion: "99.1.1", wcagPrinciple: nil, wcagLevel: nil,
            specification: nil, remediation: "Apply custom fix."
        )
        let result = ViolationDetailHelper.formatRemediation(violation)

        #expect(result != nil)
        #expect(result?.contains("Apply custom fix.") == true)
        #expect(result?.contains("WCAG 99.1.1") == true)
        // No name for unknown criterion, so no parenthetical
        #expect(result?.contains("(") == false)
    }

    // MARK: - Location Formatting Tests

    @Test("Format location with all fields")
    func formatLocationFull() {
        let result = ViolationDetailHelper.formatLocation(
            pageIndex: 0,
            objectType: "Figure",
            context: "/StructTreeRoot/Document/Figure"
        )

        #expect(result.contains("Page 1"))
        #expect(result.contains("Object: Figure"))
        #expect(result.contains("Path: /StructTreeRoot/Document/Figure"))
    }

    @Test("Format location with page only")
    func formatLocationPageOnly() {
        let result = ViolationDetailHelper.formatLocation(
            pageIndex: 4,
            objectType: nil,
            context: nil
        )

        #expect(result == "Page 5")
    }

    @Test("Format location with no page shows Document-level")
    func formatLocationNoPage() {
        let result = ViolationDetailHelper.formatLocation(
            pageIndex: nil,
            objectType: nil,
            context: nil
        )

        #expect(result == "Document-level")
    }

    @Test("Format location with object type but no page")
    func formatLocationObjectTypeNoPage() {
        let result = ViolationDetailHelper.formatLocation(
            pageIndex: nil,
            objectType: "Table",
            context: nil
        )

        #expect(result.contains("Document-level"))
        #expect(result.contains("Object: Table"))
    }

    // MARK: - WCAG Criterion Map Coverage

    @Test("WCAG criterion map has expected minimum count")
    func wcagCriterionMapCount() {
        // WCAG 2.1 has 78 success criteria
        let count = ViolationDetailHelper.wcagCriterionMap.count
        #expect(count >= 78, "Expected at least 78 WCAG 2.1 criteria, got \(count)")
    }

    @Test("All criterion map values are non-empty")
    func wcagCriterionMapValuesNonEmpty() {
        for (key, value) in ViolationDetailHelper.wcagCriterionMap {
            #expect(!value.isEmpty, "Criterion \(key) has empty name")
        }
    }
}
