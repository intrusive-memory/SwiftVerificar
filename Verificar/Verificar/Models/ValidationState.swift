import Foundation
import SwiftUI
import SwiftVerificarBiblioteca
import SwiftVerificarValidationProfiles

// MARK: - ValidationSummary

/// Aggregated summary of validation results for UI display.
struct ValidationSummary: Sendable {
    let totalRules: Int
    let passedCount: Int
    let failedCount: Int
    let warningCount: Int
    let notApplicableCount: Int
    let profileName: String
    let duration: TimeInterval

    var passRate: Double {
        guard totalRules > 0 else { return 0.0 }
        return Double(passedCount) / Double(totalRules)
    }

    var complianceStatus: ComplianceStatus {
        if failedCount == 0 && warningCount == 0 {
            return .conformant
        } else if failedCount > 0 {
            return .nonConformant(errors: failedCount)
        } else {
            return .conformant
        }
    }
}

// MARK: - ViolationItem

/// A UI-friendly violation with all details needed for display and navigation.
struct ViolationItem: Identifiable, Sendable, Equatable {
    let id: String
    let ruleID: String
    let severity: ViolationSeverity
    let message: String
    let description: String
    let pageIndex: Int?
    let objectType: String?
    let context: String?
    let wcagCriterion: String?
    let wcagPrinciple: String?
    let wcagLevel: String?
    let specification: String?
    let remediation: String?

    static func == (lhs: ViolationItem, rhs: ViolationItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ViolationSeverity

/// Severity levels for violations.
enum ViolationSeverity: String, CaseIterable, Sendable {
    case error = "Error"
    case warning = "Warning"
    case info = "Info"

    var icon: String {
        switch self {
        case .error: "xmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .error: .red
        case .warning: .orange
        case .info: .blue
        }
    }
}

// MARK: - ComplianceStatus

/// Overall compliance status of a validated document.
enum ComplianceStatus: Sendable, Equatable {
    case conformant
    case nonConformant(errors: Int)
    case unknown
    case inProgress
    case notValidated

    var label: String {
        switch self {
        case .conformant:
            return "Conformant"
        case .nonConformant(let errors):
            return "Non-conformant (\(errors) error\(errors == 1 ? "" : "s"))"
        case .unknown:
            return "Unknown"
        case .inProgress:
            return "Validating..."
        case .notValidated:
            return "Not validated"
        }
    }

    var icon: String {
        switch self {
        case .conformant:
            return "checkmark.seal.fill"
        case .nonConformant:
            return "xmark.seal.fill"
        case .unknown:
            return "questionmark.circle.fill"
        case .inProgress:
            return "progress.indicator"
        case .notValidated:
            return "minus.circle"
        }
    }

    var color: Color {
        switch self {
        case .conformant: .green
        case .nonConformant: .red
        case .unknown: .gray
        case .inProgress: .blue
        case .notValidated: .secondary
        }
    }
}

// MARK: - Mapping Helpers

/// Helpers to map SwiftVerificar-biblioteca types to UI models.
enum ValidationStateMapper {

    /// Creates a `ValidationSummary` from a biblioteca `ValidationResult`.
    ///
    /// Since the current biblioteca v0.1.0 API only provides `passedCount`,
    /// `failedCount`, and `unknownCount` on `ValidationResult`, we map
    /// `unknownCount` to `warningCount` for UI purposes. The `notApplicableCount`
    /// is derived as the difference between total and categorized counts.
    static func makeSummary(
        from result: ValidationResult
    ) -> ValidationSummary {
        let total = result.totalCount
        let passed = result.passedCount
        let failed = result.failedCount
        let unknown = result.unknownCount

        return ValidationSummary(
            totalRules: total,
            passedCount: passed,
            failedCount: failed,
            warningCount: unknown,
            notApplicableCount: 0,
            profileName: result.profileName,
            duration: result.duration.duration
        )
    }

    /// Creates an array of `ViolationItem` from a biblioteca `ValidationResult`.
    ///
    /// Only failed and unknown assertions are included as violations.
    /// Failed assertions map to `.error` severity; unknown assertions map
    /// to `.warning` severity.
    static func makeViolations(
        from result: ValidationResult
    ) -> [ViolationItem] {
        result.assertions
            .filter { $0.status != .passed }
            .map { assertion in
                let severity: ViolationSeverity = assertion.status == .failed ? .error : .warning
                let locationHash = assertion.location?.pageNumber.map { String($0) } ?? "doc"
                let itemID = "\(assertion.ruleID.uniqueID)-\(locationHash)-\(assertion.id.uuidString.prefix(8))"

                return ViolationItem(
                    id: itemID,
                    ruleID: assertion.ruleID.uniqueID,
                    severity: severity,
                    message: assertion.message,
                    description: assertion.message,
                    pageIndex: assertion.location?.pageNumber.map { $0 - 1 },
                    objectType: assertion.context,
                    context: assertion.location?.contentPath,
                    wcagCriterion: nil,
                    wcagPrinciple: nil,
                    wcagLevel: nil,
                    specification: assertion.ruleID.uniqueID,
                    remediation: nil
                )
            }
    }
}
