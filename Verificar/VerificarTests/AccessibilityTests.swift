import Testing
import Foundation
import PDFKit
@testable import Verificar

// MARK: - Accessibility Tests

@Suite("Accessibility")
struct AccessibilityTests {

    // MARK: - Violation Severity Accessibility

    @Test("All violation severity levels have icon names")
    func allSeveritiesHaveIcons() {
        for severity in ViolationSeverity.allCases {
            #expect(!severity.icon.isEmpty, "Severity \(severity.rawValue) should have an icon")
        }
    }

    @Test("All violation severity levels have distinct icons")
    func allSeveritiesHaveDistinctIcons() {
        let icons = ViolationSeverity.allCases.map(\.icon)
        let uniqueIcons = Set(icons)
        #expect(uniqueIcons.count == ViolationSeverity.allCases.count,
                "Each severity should have a unique icon")
    }

    @Test("All violation severity levels have color values")
    func allSeveritiesHaveColors() {
        // Verify each severity returns a non-default color (they are all defined)
        let errorColor = ViolationSeverity.error.color
        let warningColor = ViolationSeverity.warning.color
        let infoColor = ViolationSeverity.info.color

        // Colors should be distinct (red, orange, blue)
        #expect(errorColor != warningColor)
        #expect(errorColor != infoColor)
        #expect(warningColor != infoColor)
    }

    // MARK: - Compliance Status Accessibility

    @Test("All compliance statuses have labels for VoiceOver")
    func allComplianceStatusesHaveLabels() {
        let statuses: [ComplianceStatus] = [
            .conformant,
            .nonConformant(errors: 5),
            .unknown,
            .inProgress,
            .notValidated,
        ]

        for status in statuses {
            #expect(!status.label.isEmpty, "Status should have a non-empty label")
            #expect(!status.icon.isEmpty, "Status should have a non-empty icon name")
        }
    }

    @Test("All compliance statuses have distinct labels")
    func allComplianceStatusesHaveDistinctLabels() {
        let labels = [
            ComplianceStatus.conformant.label,
            ComplianceStatus.nonConformant(errors: 1).label,
            ComplianceStatus.unknown.label,
            ComplianceStatus.inProgress.label,
            ComplianceStatus.notValidated.label,
        ]
        let uniqueLabels = Set(labels)
        #expect(uniqueLabels.count == labels.count,
                "Each compliance status should have a unique label for accessibility")
    }

    @Test("Non-conformant status label includes error count")
    func nonConformantLabelIncludesCount() {
        let singleError = ComplianceStatus.nonConformant(errors: 1)
        #expect(singleError.label.contains("1 error"))

        let multipleErrors = ComplianceStatus.nonConformant(errors: 5)
        #expect(multipleErrors.label.contains("5 errors"))
    }

    // MARK: - Inspector Tab Accessibility

    @Test("All inspector tabs have labels")
    func allInspectorTabsHaveLabels() {
        for tab in InspectorTab.allCases {
            #expect(!tab.label.isEmpty, "Tab \(tab.rawValue) should have a label")
            #expect(!tab.icon.isEmpty, "Tab \(tab.rawValue) should have an icon")
        }
    }

    @Test("All inspector tabs have distinct identifiers")
    func allInspectorTabsHaveDistinctIds() {
        let ids = InspectorTab.allCases.map(\.id)
        let uniqueIds = Set(ids)
        #expect(uniqueIds.count == InspectorTab.allCases.count)
    }

    @Test("Inspector tab count is four")
    func inspectorTabCountIsFour() {
        #expect(InspectorTab.allCases.count == 4)
    }

    // MARK: - Grouping Mode Accessibility

    @Test("All grouping modes have labels for pickers")
    func allGroupingModesHaveLabels() {
        for mode in ValidationViewModel.GroupingMode.allCases {
            #expect(!mode.rawValue.isEmpty, "Grouping mode should have a raw value for display")
            #expect(!mode.id.isEmpty, "Grouping mode should have an ID")
        }
    }

    // MARK: - Settings Accessibility

    @Test("Settings available profiles list is non-empty")
    func settingsProfilesNonEmpty() {
        #expect(!SettingsHelper.availableProfiles.isEmpty)
    }

    @Test("Settings view modes list is non-empty")
    func settingsViewModesNonEmpty() {
        #expect(!SettingsHelper.viewModes.isEmpty)
    }

    @Test("Settings highlight colors list is non-empty")
    func settingsHighlightColorsNonEmpty() {
        #expect(!SettingsHelper.highlightColors.isEmpty)
    }

    @Test("All settings profiles are non-empty strings")
    func allSettingsProfilesAreNonEmpty() {
        for profile in SettingsHelper.availableProfiles {
            #expect(!profile.isEmpty, "Profile name should not be empty")
        }
    }

    @Test("All settings view modes are non-empty strings")
    func allViewModesAreNonEmpty() {
        for mode in SettingsHelper.viewModes {
            #expect(!mode.isEmpty, "View mode name should not be empty")
        }
    }

    @Test("All settings highlight colors are non-empty strings")
    func allHighlightColorsAreNonEmpty() {
        for color in SettingsHelper.highlightColors {
            #expect(!color.isEmpty, "Highlight color name should not be empty")
        }
    }

    // MARK: - Violation Item Accessibility

    @Test("Violation items have required fields for accessibility")
    func violationItemsHaveRequiredFields() {
        let violation = ViolationItem(
            id: "test-1",
            ruleID: "7.1-001",
            severity: .error,
            message: "Missing alt text",
            description: "Figure element lacks alt text",
            pageIndex: 0,
            objectType: "Figure",
            context: nil,
            wcagCriterion: "1.1.1",
            wcagPrinciple: "Perceivable",
            wcagLevel: "A",
            specification: "PDF/UA-2",
            remediation: "Add alt text"
        )

        // These fields are needed for VoiceOver to announce violations properly
        #expect(!violation.id.isEmpty)
        #expect(!violation.ruleID.isEmpty)
        #expect(!violation.message.isEmpty)
        #expect(!violation.description.isEmpty)
        #expect(!violation.severity.icon.isEmpty)
    }

    @Test("Violation severity filter labels exist for picker accessibility")
    func violationSeverityFilterLabelsExist() {
        for severity in ViolationSeverity.allCases {
            #expect(!severity.rawValue.isEmpty, "Severity \(severity) should have a raw value for filters")
        }
    }

    // MARK: - Navigation Landmarks

    @Test("Document model provides page navigation info for VoiceOver")
    func documentModelProvidesNavigationInfo() {
        let model = PDFDocumentModel()

        // Empty state provides meaningful values
        #expect(model.pageCount == 0)
        #expect(model.currentPageIndex == 0)
        #expect(model.title == "Untitled")
        #expect(model.isDocumentLoaded == false)

        // With a document loaded
        let document = PDFDocument()
        let page = PDFPage()
        document.insert(page, at: 0)
        model.pdfDocument = document
        model.url = URL(fileURLWithPath: "/tmp/nav-test.pdf")

        #expect(model.pageCount == 1)
        #expect(model.isDocumentLoaded == true)
        #expect(model.title == "nav-test")
    }

    @Test("Validation summary text provides accessible description")
    func validationSummaryTextAccessible() {
        let vm = ValidationViewModel()

        // Empty state
        #expect(vm.summaryText == "No violations")

        // With violations
        vm.violations = [
            ViolationItem(
                id: "e1", ruleID: "R1", severity: .error,
                message: "Error 1", description: "Desc",
                pageIndex: 0, objectType: nil, context: nil,
                wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
                specification: nil, remediation: nil
            ),
            ViolationItem(
                id: "w1", ruleID: "R2", severity: .warning,
                message: "Warning 1", description: "Desc",
                pageIndex: nil, objectType: nil, context: nil,
                wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
                specification: nil, remediation: nil
            ),
        ]

        let text = vm.summaryText
        #expect(text.contains("2 violations"))
        #expect(text.contains("1 error"))
        #expect(text.contains("1 warning"))
    }
}

// MARK: - Settings Helper Tests

@Suite("Settings Helper")
struct SettingsHelperTests {

    @Test("Available profiles matches StandardsPanel profiles")
    func availableProfilesMatchStandardsPanel() {
        #expect(SettingsHelper.availableProfiles == StandardsPanel.availableProfiles)
    }

    @Test("isValidProfile returns true for valid profiles")
    func isValidProfileTrue() {
        #expect(SettingsHelper.isValidProfile("PDF/UA-2") == true)
        #expect(SettingsHelper.isValidProfile("PDF/A-1a") == true)
        #expect(SettingsHelper.isValidProfile("PDF/A-4") == true)
    }

    @Test("isValidProfile returns false for invalid profiles")
    func isValidProfileFalse() {
        #expect(SettingsHelper.isValidProfile("InvalidProfile") == false)
        #expect(SettingsHelper.isValidProfile("") == false)
    }

    @Test("isValidViewMode returns true for valid modes")
    func isValidViewModeTrue() {
        #expect(SettingsHelper.isValidViewMode("Single Page") == true)
        #expect(SettingsHelper.isValidViewMode("Continuous") == true)
        #expect(SettingsHelper.isValidViewMode("Two-Up") == true)
    }

    @Test("isValidViewMode returns false for invalid modes")
    func isValidViewModeFalse() {
        #expect(SettingsHelper.isValidViewMode("Three-Up") == false)
        #expect(SettingsHelper.isValidViewMode("") == false)
    }

    @Test("isValidHighlightColor returns true for valid colors")
    func isValidHighlightColorTrue() {
        #expect(SettingsHelper.isValidHighlightColor("red") == true)
        #expect(SettingsHelper.isValidHighlightColor("blue") == true)
        #expect(SettingsHelper.isValidHighlightColor("green") == true)
    }

    @Test("isValidHighlightColor returns false for invalid colors")
    func isValidHighlightColorFalse() {
        #expect(SettingsHelper.isValidHighlightColor("pink") == false)
        #expect(SettingsHelper.isValidHighlightColor("") == false)
    }

    @Test("Clamp zoom level to valid range")
    func clampZoomLevel() {
        #expect(SettingsHelper.clampZoomLevel(0.1) == 0.25)
        #expect(SettingsHelper.clampZoomLevel(1.0) == 1.0)
        #expect(SettingsHelper.clampZoomLevel(5.0) == 4.0)
        #expect(SettingsHelper.clampZoomLevel(2.5) == 2.5)
    }

    @Test("Clamp max violations to valid range")
    func clampMaxViolations() {
        #expect(SettingsHelper.clampMaxViolations(10) == 50)
        #expect(SettingsHelper.clampMaxViolations(500) == 500)
        #expect(SettingsHelper.clampMaxViolations(3000) == 2000)
        #expect(SettingsHelper.clampMaxViolations(1000) == 1000)
    }

    @Test("Default settings values are correct types")
    func defaultSettingsValues() {
        let defaults = SettingsHelper.defaults

        #expect(defaults["defaultValidationProfile"] as? String == "PDF/UA-2")
        #expect(defaults["autoValidateOnOpen"] as? Bool == true)
        #expect(defaults["maxViolationsToDisplay"] as? Double == 500.0)
        #expect(defaults["defaultZoomLevel"] as? Double == 1.0)
        #expect(defaults["defaultViewMode"] as? String == "Continuous")
        #expect(defaults["showPageNumbersInThumbnails"] as? Bool == true)
        #expect(defaults["highlightColorName"] as? String == "red")
    }

    @Test("View modes list has three entries")
    func viewModesCount() {
        #expect(SettingsHelper.viewModes.count == 3)
    }

    @Test("Highlight colors list has six entries")
    func highlightColorsCount() {
        #expect(SettingsHelper.highlightColors.count == 6)
    }

    @Test("Available profiles list has eleven entries")
    func availableProfilesCount() {
        #expect(SettingsHelper.availableProfiles.count == 11)
    }
}
