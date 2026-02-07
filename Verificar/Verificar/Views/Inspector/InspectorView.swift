//
//  InspectorView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// Inspector panel container that provides a tab bar for different inspector panels:
/// Standards, Violations, Structure, and Features.
///
/// Shows validation progress when a validation is in progress, and contextual
/// placeholder content when no results are available.
struct InspectorView: View {

    @Environment(PDFDocumentModel.self) private var documentModel
    @Environment(ValidationService.self) private var validationService
    @Environment(DocumentViewModel.self) private var documentViewModel

    /// The active inspector tab.
    @State private var selectedTab: InspectorTab = .standards

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            // Validation progress indicator
            if validationService.isValidating {
                validationProgressView
            }

            Divider()
            tabContent
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        Picker("Inspector Tab", selection: $selectedTab) {
            ForEach(InspectorTab.allCases) { tab in
                Label(tab.label, systemImage: tab.icon)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(8)
    }

    // MARK: - Validation Progress

    private var validationProgressView: some View {
        VStack(spacing: 4) {
            ProgressView(value: validationService.progress, total: 1.0)
                .progressViewStyle(.linear)
            Text("Validating... \(Int(validationService.progress * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .standards:
            standardsTabContent
        case .violations:
            violationsTabContent
        case .structure:
            tabPlaceholder(
                icon: "list.bullet.rectangle",
                title: "Structure Tree",
                subtitle: documentModel.isDocumentLoaded
                    ? "Structure tree will appear here."
                    : "Open a PDF to view its structure."
            )
        case .features:
            tabPlaceholder(
                icon: "doc.text.magnifyingglass",
                title: "Features",
                subtitle: documentModel.isDocumentLoaded
                    ? "Font, image, and annotation details will appear here."
                    : "Open a PDF to extract features."
            )
        }
    }

    // MARK: - Standards Tab Content

    @ViewBuilder
    private var standardsTabContent: some View {
        if validationService.isValidating {
            tabPlaceholder(
                icon: "hourglass",
                title: "Validating...",
                subtitle: "Checking document against \(documentViewModel.selectedProfile)."
            )
        } else if let summary = documentViewModel.validationSummary {
            // Show a brief summary while we build the full Standards panel in Sprint 10
            VStack(spacing: 12) {
                Image(systemName: summary.complianceStatus.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(summary.complianceStatus.color)

                Text(summary.complianceStatus.label)
                    .font(.headline)

                Text("Profile: \(summary.profileName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    statBadge(count: summary.passedCount, label: "Passed", color: .green)
                    statBadge(count: summary.failedCount, label: "Failed", color: .red)
                    statBadge(count: summary.warningCount, label: "Warnings", color: .orange)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 16)
        } else if validationService.error != nil {
            tabPlaceholder(
                icon: "exclamationmark.triangle",
                title: "Validation Error",
                subtitle: "An error occurred during validation. Try again."
            )
        } else if !documentModel.isDocumentLoaded {
            tabPlaceholder(
                icon: "checkmark.shield",
                title: "Standards Compliance",
                subtitle: "Open a PDF to check compliance."
            )
        } else {
            tabPlaceholder(
                icon: "checkmark.shield",
                title: "Not Validated",
                subtitle: "Validation results will appear here."
            )
        }
    }

    // MARK: - Violations Tab Content

    @ViewBuilder
    private var violationsTabContent: some View {
        if validationService.isValidating {
            tabPlaceholder(
                icon: "hourglass",
                title: "Validating...",
                subtitle: "Checking for violations..."
            )
        } else if !documentViewModel.violations.isEmpty {
            // Brief violations summary while we build the full list view in Sprint 11
            VStack(spacing: 8) {
                Text(documentViewModel.validationViewModel.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)

                Divider()
                    .padding(.horizontal)

                List(documentViewModel.violations, id: \.id) { violation in
                    HStack(spacing: 8) {
                        Image(systemName: violation.severity.icon)
                            .foregroundStyle(violation.severity.color)
                            .font(.caption)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(violation.ruleID)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(violation.message)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        if let page = violation.pageIndex {
                            Text("p.\(page + 1)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        documentViewModel.selectViolation(violation)
                    }
                }
                .listStyle(.plain)
            }
        } else if validationService.lastResult != nil {
            // Validation ran but no violations
            tabPlaceholder(
                icon: "checkmark.circle",
                title: "No Violations",
                subtitle: "No violations were found."
            )
        } else if !documentModel.isDocumentLoaded {
            tabPlaceholder(
                icon: "exclamationmark.triangle",
                title: "Violations",
                subtitle: "Open a PDF to check for violations."
            )
        } else {
            tabPlaceholder(
                icon: "exclamationmark.triangle",
                title: "Not Validated",
                subtitle: "Run validation to see violations."
            )
        }
    }

    // MARK: - Helpers

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func tabPlaceholder(icon: String, title: String, subtitle: String) -> some View {
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
}

// MARK: - InspectorTab

/// The available tabs in the inspector panel.
enum InspectorTab: String, CaseIterable, Identifiable {
    case standards
    case violations
    case structure
    case features

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standards: "Standards"
        case .violations: "Violations"
        case .structure: "Structure"
        case .features: "Features"
        }
    }

    var icon: String {
        switch self {
        case .standards: "checkmark.shield"
        case .violations: "exclamationmark.triangle"
        case .structure: "list.bullet.rectangle"
        case .features: "doc.text.magnifyingglass"
        }
    }
}

#Preview {
    InspectorView()
        .environment(PDFDocumentModel())
        .environment(ValidationService())
        .environment(DocumentViewModel())
        .environment(ValidationViewModel())
        .frame(width: 300, height: 400)
}
