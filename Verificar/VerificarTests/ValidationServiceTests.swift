import Testing
import Foundation
@testable import Verificar
import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

// MARK: - ValidationService Tests

@Suite("ValidationService")
struct ValidationServiceTests {

    @Test("Service initializes with default state")
    func serviceInitializesWithDefaultState() {
        let service = ValidationService()
        #expect(service.isValidating == false)
        #expect(service.progress == 0.0)
        #expect(service.lastResult == nil)
        #expect(service.error == nil)
    }

    @Test("Cancel sets isValidating to false")
    func cancelSetsIsValidatingToFalse() {
        let service = ValidationService()
        service.cancelValidation()
        #expect(service.isValidating == false)
    }

    @Test("Validate sets error for stub implementation")
    func validateSetsErrorForStubImplementation() async {
        let service = ValidationService()

        // The biblioteca v0.1.0 throws VerificarError.configurationError
        // because the validation engine is not yet wired.
        // The service should capture this as an error, not crash.
        let testURL = URL(fileURLWithPath: "/tmp/nonexistent.pdf")
        await service.validate(url: testURL, profile: "PDF/UA-2")

        // After validation completes (even with error), isValidating should be false
        #expect(service.isValidating == false)
        // The stub throws, so error should be set
        #expect(service.error != nil)
        // No result since it failed
        #expect(service.lastResult == nil)
    }

    @Test("Validate resets state before starting")
    func validateResetsStateBeforeStarting() async {
        let service = ValidationService()

        // Run validation once to set some state
        let testURL = URL(fileURLWithPath: "/tmp/nonexistent.pdf")
        await service.validate(url: testURL, profile: "PDF/UA-2")

        #expect(service.error != nil)

        // Run again -- error should be cleared at start
        await service.validate(url: testURL, profile: "PDF/UA-2")

        // Final state should still have an error from the stub
        #expect(service.error != nil)
        #expect(service.isValidating == false)
    }
}

// MARK: - ValidationState Model Tests

@Suite("ValidationState Models")
struct ValidationStateModelTests {

    @Test("ViolationSeverity has correct icons")
    func violationSeverityIcons() {
        #expect(ViolationSeverity.error.icon == "xmark.circle.fill")
        #expect(ViolationSeverity.warning.icon == "exclamationmark.triangle.fill")
        #expect(ViolationSeverity.info.icon == "info.circle.fill")
    }

    @Test("ViolationSeverity allCases contains all three")
    func violationSeverityAllCases() {
        #expect(ViolationSeverity.allCases.count == 3)
        #expect(ViolationSeverity.allCases.contains(.error))
        #expect(ViolationSeverity.allCases.contains(.warning))
        #expect(ViolationSeverity.allCases.contains(.info))
    }

    @Test("ComplianceStatus labels are correct")
    func complianceStatusLabels() {
        #expect(ComplianceStatus.conformant.label == "Conformant")
        #expect(ComplianceStatus.nonConformant(errors: 5).label == "Non-conformant (5 errors)")
        #expect(ComplianceStatus.nonConformant(errors: 1).label == "Non-conformant (1 error)")
        #expect(ComplianceStatus.unknown.label == "Unknown")
        #expect(ComplianceStatus.inProgress.label == "Validating...")
        #expect(ComplianceStatus.notValidated.label == "Not validated")
    }

    @Test("ComplianceStatus equality")
    func complianceStatusEquality() {
        #expect(ComplianceStatus.conformant == ComplianceStatus.conformant)
        #expect(ComplianceStatus.nonConformant(errors: 3) == ComplianceStatus.nonConformant(errors: 3))
        #expect(ComplianceStatus.nonConformant(errors: 3) != ComplianceStatus.nonConformant(errors: 5))
        #expect(ComplianceStatus.unknown != ComplianceStatus.notValidated)
    }

    @Test("ValidationSummary passRate computes correctly")
    func validationSummaryPassRate() {
        let summary = ValidationSummary(
            totalRules: 100,
            passedCount: 75,
            failedCount: 20,
            warningCount: 5,
            notApplicableCount: 0,
            profileName: "PDF/UA-2",
            duration: 1.5
        )
        #expect(summary.passRate == 0.75)
    }

    @Test("ValidationSummary passRate handles zero total")
    func validationSummaryPassRateZeroTotal() {
        let summary = ValidationSummary(
            totalRules: 0,
            passedCount: 0,
            failedCount: 0,
            warningCount: 0,
            notApplicableCount: 0,
            profileName: "PDF/UA-2",
            duration: 0.0
        )
        #expect(summary.passRate == 0.0)
    }

    @Test("ValidationSummary complianceStatus conformant when no failures")
    func validationSummaryConformant() {
        let summary = ValidationSummary(
            totalRules: 50,
            passedCount: 50,
            failedCount: 0,
            warningCount: 0,
            notApplicableCount: 0,
            profileName: "PDF/UA-2",
            duration: 1.0
        )
        #expect(summary.complianceStatus == .conformant)
    }

    @Test("ValidationSummary complianceStatus non-conformant when failures exist")
    func validationSummaryNonConformant() {
        let summary = ValidationSummary(
            totalRules: 50,
            passedCount: 45,
            failedCount: 5,
            warningCount: 0,
            notApplicableCount: 0,
            profileName: "PDF/UA-2",
            duration: 1.0
        )
        #expect(summary.complianceStatus == .nonConformant(errors: 5))
    }
}

// MARK: - ValidationStateMapper Tests

@Suite("ValidationStateMapper")
struct ValidationStateMapperTests {

    @Test("Mapper creates summary from ValidationResult")
    func mapperCreatesSummary() {
        let ruleID = RuleID(
            specification: .iso142892,
            clause: "8.2.5.26",
            testNumber: 1
        )
        let passedAssertion = TestAssertion(
            ruleID: ruleID,
            status: .passed,
            message: "Alt text present"
        )
        let failedAssertion = TestAssertion(
            ruleID: ruleID,
            status: .failed,
            message: "Missing alt text"
        )
        let unknownAssertion = TestAssertion(
            ruleID: ruleID,
            status: .unknown,
            message: "Could not evaluate"
        )

        let duration = ValidationDuration(start: Date(), end: Date().addingTimeInterval(2.0))
        let result = ValidationResult(
            profileName: "PDF/UA-2",
            documentURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            isCompliant: false,
            assertions: [passedAssertion, failedAssertion, unknownAssertion],
            duration: duration
        )

        let summary = ValidationStateMapper.makeSummary(from: result)

        #expect(summary.totalRules == 3)
        #expect(summary.passedCount == 1)
        #expect(summary.failedCount == 1)
        #expect(summary.warningCount == 1)
        #expect(summary.profileName == "PDF/UA-2")
    }

    @Test("Mapper creates violations from ValidationResult")
    func mapperCreatesViolations() {
        let ruleID = RuleID(
            specification: .iso142892,
            clause: "8.2.5.26",
            testNumber: 1
        )
        let passedAssertion = TestAssertion(
            ruleID: ruleID,
            status: .passed,
            message: "Alt text present"
        )
        let failedAssertion = TestAssertion(
            ruleID: ruleID,
            status: .failed,
            message: "Missing alt text",
            location: PDFLocation(pageNumber: 3),
            context: "Figure"
        )
        let unknownAssertion = TestAssertion(
            ruleID: ruleID,
            status: .unknown,
            message: "Could not evaluate"
        )

        let duration = ValidationDuration.zero()
        let result = ValidationResult(
            profileName: "PDF/UA-2",
            documentURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            isCompliant: false,
            assertions: [passedAssertion, failedAssertion, unknownAssertion],
            duration: duration
        )

        let violations = ValidationStateMapper.makeViolations(from: result)

        // Only failed + unknown should be mapped (not passed)
        #expect(violations.count == 2)

        // First violation should be the failed one
        let errorViolation = violations.first { $0.severity == .error }
        #expect(errorViolation != nil)
        #expect(errorViolation?.message == "Missing alt text")
        #expect(errorViolation?.pageIndex == 2) // 1-based page 3 -> 0-based index 2
        #expect(errorViolation?.objectType == "Figure")

        // Second violation should be the unknown one (mapped to warning)
        let warningViolation = violations.first { $0.severity == .warning }
        #expect(warningViolation != nil)
        #expect(warningViolation?.message == "Could not evaluate")
    }

    @Test("Mapper handles empty result")
    func mapperHandlesEmptyResult() {
        let duration = ValidationDuration.zero()
        let result = ValidationResult(
            profileName: "PDF/UA-2",
            documentURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            isCompliant: true,
            assertions: [],
            duration: duration
        )

        let summary = ValidationStateMapper.makeSummary(from: result)
        #expect(summary.totalRules == 0)
        #expect(summary.passedCount == 0)
        #expect(summary.failedCount == 0)
        #expect(summary.complianceStatus == .conformant)

        let violations = ValidationStateMapper.makeViolations(from: result)
        #expect(violations.isEmpty)
    }
}
