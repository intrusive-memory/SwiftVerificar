//
//  StandardsPanel.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI
import PDFKit

/// The first inspector tab showing compliance status, standards identification,
/// document metadata, and validation controls.
///
/// This panel provides a comprehensive overview of the PDF's accessibility
/// compliance including:
/// - A large compliance badge (pass/fail/unknown)
/// - The validation profile used
/// - A horizontal summary bar showing passed/failed/not-applicable rule counts
/// - Standards identification (PDF/A, PDF/UA, WCAG)
/// - Document metadata (title, author, dates, producer, etc.)
/// - A re-validate button and profile picker
struct StandardsPanel: View {

    @Environment(DocumentViewModel.self) private var documentViewModel
    @Environment(ValidationService.self) private var validationService
    @Environment(PDFDocumentModel.self) private var documentModel

    var body: some View {
        if validationService.isValidating {
            validatingView
        } else if let summary = documentViewModel.validationSummary {
            ScrollView {
                VStack(spacing: 16) {
                    complianceBadge(for: summary)
                    summaryBar(for: summary)
                    standardsIdentificationSection
                    metadataSection
                    validationControls
                }
                .padding()
            }
        } else if validationService.error != nil {
            errorView
        } else if !documentModel.isDocumentLoaded {
            placeholderView(
                icon: "checkmark.shield",
                title: "Standards Compliance",
                subtitle: "Open a PDF to check compliance."
            )
        } else {
            VStack(spacing: 16) {
                placeholderView(
                    icon: "checkmark.shield",
                    title: "Not Validated",
                    subtitle: "Run validation to see compliance status."
                )
                validationControls
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Compliance Badge

    private func complianceBadge(for summary: ValidationSummary) -> some View {
        VStack(spacing: 8) {
            Image(systemName: summary.complianceStatus.icon)
                .font(.system(size: 48))
                .foregroundStyle(summary.complianceStatus.color)
                .accessibilityLabel(summary.complianceStatus.label)

            Text(summary.complianceStatus.label)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Profile: \(summary.profileName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if summary.duration > 0 {
                Text("Completed in \(formattedDuration(summary.duration))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Summary Bar

    private func summaryBar(for summary: ValidationSummary) -> some View {
        VStack(spacing: 8) {
            // Horizontal stacked bar
            if summary.totalRules > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        let total = CGFloat(summary.totalRules)
                        let passedWidth = CGFloat(summary.passedCount) / total * geometry.size.width
                        let failedWidth = CGFloat(summary.failedCount) / total * geometry.size.width
                        let warningWidth = CGFloat(summary.warningCount) / total * geometry.size.width
                        let naWidth = CGFloat(summary.notApplicableCount) / total * geometry.size.width

                        if summary.passedCount > 0 {
                            Rectangle()
                                .fill(.green)
                                .frame(width: max(passedWidth, 2))
                        }
                        if summary.failedCount > 0 {
                            Rectangle()
                                .fill(.red)
                                .frame(width: max(failedWidth, 2))
                        }
                        if summary.warningCount > 0 {
                            Rectangle()
                                .fill(.orange)
                                .frame(width: max(warningWidth, 2))
                        }
                        if summary.notApplicableCount > 0 {
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: max(naWidth, 2))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: 12)
                .accessibilityLabel("Pass rate: \(Int(summary.passRate * 100))%")
            }

            // Legend
            HStack(spacing: 12) {
                summaryLegendItem(count: summary.passedCount, label: "Passed", color: .green)
                summaryLegendItem(count: summary.failedCount, label: "Failed", color: .red)
                summaryLegendItem(count: summary.warningCount, label: "Warnings", color: .orange)
                summaryLegendItem(count: summary.notApplicableCount, label: "N/A", color: .gray)
            }
            .font(.caption2)
        }
        .padding(.horizontal, 4)
    }

    private func summaryLegendItem(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count)")
                .fontWeight(.medium)
            Text(label)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")
    }

    // MARK: - Standards Identification

    private var standardsIdentificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Standards Identification")

            standardsRow(label: "PDF/A", value: pdfAIdentification)
            standardsRow(label: "PDF/UA", value: pdfUAIdentification)
            standardsRow(label: "WCAG", value: wcagConformance)
        }
        .padding(.horizontal, 4)
    }

    private func standardsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 55, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(value == "Not declared" || value == "Not assessed" ? .tertiary : .primary)
            Spacer()
        }
    }

    /// Derives PDF/A identification from the selected profile name.
    private var pdfAIdentification: String {
        let profile = documentViewModel.selectedProfile.lowercased()
        if profile.contains("pdf/a") {
            return documentViewModel.selectedProfile
        }
        return "Not declared"
    }

    /// Derives PDF/UA identification from the selected profile name.
    private var pdfUAIdentification: String {
        let profile = documentViewModel.selectedProfile.lowercased()
        if profile.contains("pdf/ua") {
            return documentViewModel.selectedProfile
        }
        return "Not declared"
    }

    /// WCAG conformance level placeholder.
    private var wcagConformance: String {
        "Not assessed"
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Document Metadata")

            let attributes = documentModel.pdfDocument?.documentAttributes

            metadataRow(label: "Title", value: metadataString(from: attributes, key: PDFDocumentAttribute.titleAttribute) ?? "N/A")
            metadataRow(label: "Author", value: metadataString(from: attributes, key: PDFDocumentAttribute.authorAttribute) ?? "N/A")
            metadataRow(label: "Subject", value: metadataString(from: attributes, key: PDFDocumentAttribute.subjectAttribute) ?? "N/A")
            metadataRow(label: "Keywords", value: metadataKeywords(from: attributes))
            metadataRow(label: "Created", value: metadataDate(from: attributes, key: PDFDocumentAttribute.creationDateAttribute))
            metadataRow(label: "Modified", value: metadataDate(from: attributes, key: PDFDocumentAttribute.modificationDateAttribute))
            metadataRow(label: "Producer", value: metadataString(from: attributes, key: PDFDocumentAttribute.producerAttribute) ?? "N/A")
            metadataRow(label: "Creator", value: metadataString(from: attributes, key: PDFDocumentAttribute.creatorAttribute) ?? "N/A")
            metadataRow(label: "PDF Version",
                        value: pdfVersionString)
        }
        .padding(.horizontal, 4)
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(value == "N/A" ? .tertiary : .secondary)
                .textSelection(.enabled)
            Spacer()
        }
    }

    private func metadataString(from attributes: [AnyHashable: Any]?, key: PDFDocumentAttribute) -> String? {
        guard let value = attributes?[key] as? String, !value.isEmpty else { return nil }
        return value
    }

    private func metadataKeywords(from attributes: [AnyHashable: Any]?) -> String {
        if let keywords = attributes?[PDFDocumentAttribute.keywordsAttribute] as? [String], !keywords.isEmpty {
            return keywords.joined(separator: ", ")
        }
        if let keywords = attributes?[PDFDocumentAttribute.keywordsAttribute] as? String, !keywords.isEmpty {
            return keywords
        }
        return "N/A"
    }

    private func metadataDate(from attributes: [AnyHashable: Any]?, key: PDFDocumentAttribute) -> String {
        if let date = attributes?[key] as? Date {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return "N/A"
    }

    private var pdfVersionString: String {
        guard let document = documentModel.pdfDocument else { return "N/A" }
        let major = document.majorVersion
        let minor = document.minorVersion
        return "\(major).\(minor)"
    }

    // MARK: - Validation Controls

    private var validationControls: some View {
        @Bindable var vm = documentViewModel
        return VStack(spacing: 8) {
            Divider()

            Picker("Profile", selection: $vm.selectedProfile) {
                ForEach(StandardsPanel.availableProfiles, id: \.self) { profile in
                    Text(profile).tag(profile)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Validation Profile")

            Button {
                Task {
                    await documentViewModel.revalidate()
                }
            } label: {
                Label("Validate", systemImage: "checkmark.shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(!documentModel.isDocumentLoaded || validationService.isValidating)
            .accessibilityLabel("Re-validate document")
        }
        .padding(.top, 4)
    }

    // MARK: - Available Validation Profiles

    /// The list of validation profiles available for the profile picker.
    static let availableProfiles: [String] = [
        "PDF/UA-1",
        "PDF/UA-2",
        "PDF/A-1a",
        "PDF/A-1b",
        "PDF/A-2a",
        "PDF/A-2b",
        "PDF/A-2u",
        "PDF/A-3a",
        "PDF/A-3b",
        "PDF/A-3u",
        "PDF/A-4",
    ]

    // MARK: - State Views

    private var validatingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Validating...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Checking against \(documentViewModel.selectedProfile)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("Validation Error")
                .font(.headline)
            Text("An error occurred during validation.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                Task {
                    await documentViewModel.revalidate()
                }
            }
            .buttonStyle(.bordered)
            .disabled(!documentModel.isDocumentLoaded)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func placeholderView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        if duration < 1.0 {
            return String(format: "%.0f ms", duration * 1000)
        } else {
            return String(format: "%.1f s", duration)
        }
    }
}

// MARK: - Summary Computation Helpers (for testing)

/// Helpers for computing standards panel data, accessible from tests.
enum StandardsPanelHelper {

    /// Maps a `ComplianceStatus` to its badge state for display.
    enum BadgeState: String, Sendable {
        case pass
        case fail
        case unknown
        case inProgress
        case notValidated
    }

    /// Derives the badge state from a `ComplianceStatus`.
    static func badgeState(from status: ComplianceStatus) -> BadgeState {
        switch status {
        case .conformant:
            return .pass
        case .nonConformant:
            return .fail
        case .unknown:
            return .unknown
        case .inProgress:
            return .inProgress
        case .notValidated:
            return .notValidated
        }
    }

    /// Computes summary statistics from a `ValidationSummary`.
    struct SummaryStats: Sendable, Equatable {
        let totalRules: Int
        let passedCount: Int
        let failedCount: Int
        let warningCount: Int
        let notApplicableCount: Int
        let passRate: Double
    }

    /// Extracts summary stats from a `ValidationSummary`.
    static func summaryStats(from summary: ValidationSummary) -> SummaryStats {
        SummaryStats(
            totalRules: summary.totalRules,
            passedCount: summary.passedCount,
            failedCount: summary.failedCount,
            warningCount: summary.warningCount,
            notApplicableCount: summary.notApplicableCount,
            passRate: summary.passRate
        )
    }

    /// Determines the PDF/A identification string from a profile name.
    static func pdfAIdentification(for profile: String) -> String {
        if profile.lowercased().contains("pdf/a") {
            return profile
        }
        return "Not declared"
    }

    /// Determines the PDF/UA identification string from a profile name.
    static func pdfUAIdentification(for profile: String) -> String {
        if profile.lowercased().contains("pdf/ua") {
            return profile
        }
        return "Not declared"
    }
}

#Preview("With Summary") {
    StandardsPanel()
        .environment(PDFDocumentModel())
        .environment(ValidationService())
        .environment(DocumentViewModel())
        .frame(width: 300, height: 600)
}

#Preview("No Document") {
    StandardsPanel()
        .environment(PDFDocumentModel())
        .environment(ValidationService())
        .environment(DocumentViewModel())
        .frame(width: 300, height: 400)
}
