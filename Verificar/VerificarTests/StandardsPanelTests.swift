import Testing
import Foundation
@testable import Verificar

// MARK: - StandardsPanel Tests

@Suite("StandardsPanel")
struct StandardsPanelTests {

    // MARK: - Summary Computation Tests

    @Test("Summary stats computed from ValidationSummary")
    func summaryStatsComputed() {
        let summary = ValidationSummary(
            totalRules: 100,
            passedCount: 75,
            failedCount: 15,
            warningCount: 5,
            notApplicableCount: 5,
            profileName: "PDF/UA-2",
            duration: 1.5
        )

        let stats = StandardsPanelHelper.summaryStats(from: summary)

        #expect(stats.totalRules == 100)
        #expect(stats.passedCount == 75)
        #expect(stats.failedCount == 15)
        #expect(stats.warningCount == 5)
        #expect(stats.notApplicableCount == 5)
        #expect(stats.passRate == 0.75)
    }

    @Test("Summary stats with zero total rules yields zero pass rate")
    func summaryStatsZeroTotal() {
        let summary = ValidationSummary(
            totalRules: 0,
            passedCount: 0,
            failedCount: 0,
            warningCount: 0,
            notApplicableCount: 0,
            profileName: "PDF/UA-1",
            duration: 0.0
        )

        let stats = StandardsPanelHelper.summaryStats(from: summary)

        #expect(stats.totalRules == 0)
        #expect(stats.passRate == 0.0)
    }

    @Test("Summary stats with all passed yields 100% pass rate")
    func summaryStatsAllPassed() {
        let summary = ValidationSummary(
            totalRules: 50,
            passedCount: 50,
            failedCount: 0,
            warningCount: 0,
            notApplicableCount: 0,
            profileName: "PDF/UA-2",
            duration: 0.8
        )

        let stats = StandardsPanelHelper.summaryStats(from: summary)

        #expect(stats.passRate == 1.0)
    }

    // MARK: - Compliance Badge State Mapping Tests

    @Test("Badge state maps conformant to pass")
    func badgeStateConformant() {
        let state = StandardsPanelHelper.badgeState(from: .conformant)
        #expect(state == .pass)
    }

    @Test("Badge state maps nonConformant to fail")
    func badgeStateNonConformant() {
        let state = StandardsPanelHelper.badgeState(from: .nonConformant(errors: 5))
        #expect(state == .fail)
    }

    @Test("Badge state maps unknown to unknown")
    func badgeStateUnknown() {
        let state = StandardsPanelHelper.badgeState(from: .unknown)
        #expect(state == .unknown)
    }

    @Test("Badge state maps inProgress to inProgress")
    func badgeStateInProgress() {
        let state = StandardsPanelHelper.badgeState(from: .inProgress)
        #expect(state == .inProgress)
    }

    @Test("Badge state maps notValidated to notValidated")
    func badgeStateNotValidated() {
        let state = StandardsPanelHelper.badgeState(from: .notValidated)
        #expect(state == .notValidated)
    }

    // MARK: - Standards Identification Tests

    @Test("PDF/A identification returns profile for PDF/A profiles")
    func pdfAIdentificationForPDFAProfile() {
        #expect(StandardsPanelHelper.pdfAIdentification(for: "PDF/A-2b") == "PDF/A-2b")
        #expect(StandardsPanelHelper.pdfAIdentification(for: "PDF/A-1a") == "PDF/A-1a")
        #expect(StandardsPanelHelper.pdfAIdentification(for: "PDF/A-4") == "PDF/A-4")
    }

    @Test("PDF/A identification returns 'Not declared' for non-PDF/A profiles")
    func pdfAIdentificationForNonPDFAProfile() {
        #expect(StandardsPanelHelper.pdfAIdentification(for: "PDF/UA-2") == "Not declared")
        #expect(StandardsPanelHelper.pdfAIdentification(for: "PDF/UA-1") == "Not declared")
    }

    @Test("PDF/UA identification returns profile for PDF/UA profiles")
    func pdfUAIdentificationForPDFUAProfile() {
        #expect(StandardsPanelHelper.pdfUAIdentification(for: "PDF/UA-1") == "PDF/UA-1")
        #expect(StandardsPanelHelper.pdfUAIdentification(for: "PDF/UA-2") == "PDF/UA-2")
    }

    @Test("PDF/UA identification returns 'Not declared' for non-PDF/UA profiles")
    func pdfUAIdentificationForNonPDFUAProfile() {
        #expect(StandardsPanelHelper.pdfUAIdentification(for: "PDF/A-2b") == "Not declared")
        #expect(StandardsPanelHelper.pdfUAIdentification(for: "PDF/A-1a") == "Not declared")
    }

    // MARK: - Available Profiles Tests

    @Test("Available profiles contains expected profile set")
    func availableProfilesContainsExpected() {
        let profiles = StandardsPanel.availableProfiles
        #expect(profiles.contains("PDF/UA-1"))
        #expect(profiles.contains("PDF/UA-2"))
        #expect(profiles.contains("PDF/A-1a"))
        #expect(profiles.contains("PDF/A-1b"))
        #expect(profiles.contains("PDF/A-2a"))
        #expect(profiles.contains("PDF/A-2b"))
        #expect(profiles.contains("PDF/A-2u"))
        #expect(profiles.contains("PDF/A-3a"))
        #expect(profiles.contains("PDF/A-3b"))
        #expect(profiles.contains("PDF/A-3u"))
        #expect(profiles.contains("PDF/A-4"))
        #expect(profiles.count == 11)
    }

    // MARK: - Badge State Equatable Tests

    @Test("Badge state raw values are distinct")
    func badgeStateRawValues() {
        let allStates: [StandardsPanelHelper.BadgeState] = [.pass, .fail, .unknown, .inProgress, .notValidated]
        let rawValues = allStates.map(\.rawValue)
        #expect(Set(rawValues).count == allStates.count)
    }
}
