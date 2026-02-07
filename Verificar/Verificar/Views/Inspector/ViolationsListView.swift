//
//  ViolationsListView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// Violations list inspector tab with filtering, grouping, search, and page navigation.
///
/// Displays violations from the current validation run, organized by the user's
/// selected grouping mode. Supports severity filtering via a segmented control,
/// text search, and context menus for copying violation details and changing
/// grouping modes. Clicking a violation expands its detail view inline; the
/// "Show in PDF" button navigates the PDF to the violation page.
struct ViolationsListView: View {

    @Environment(DocumentViewModel.self) private var documentViewModel
    @Environment(ValidationService.self) private var validationService
    @Environment(PDFDocumentModel.self) private var documentModel

    /// Tracks which violation is expanded for inline detail display.
    @State private var expandedViolationID: String?

    var body: some View {
        @Bindable var valVM = documentViewModel.validationViewModel

        if validationService.isValidating {
            validatingPlaceholder
        } else if !documentModel.isDocumentLoaded {
            noDocumentPlaceholder
        } else if validationService.lastResult == nil {
            notValidatedPlaceholder
        } else if documentViewModel.validationViewModel.violations.isEmpty {
            cleanPlaceholder
        } else {
            violationsContent
        }
    }

    // MARK: - Main Content

    private var violationsContent: some View {
        @Bindable var valVM = documentViewModel.validationViewModel

        return VStack(spacing: 0) {
            // Filter bar
            filterBar

            Divider()

            // Violations count summary
            summaryBar

            Divider()

            // Grouped violations list
            if valVM.filteredViolations.isEmpty {
                noMatchPlaceholder
            } else {
                groupedList
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        @Bindable var valVM = documentViewModel.validationViewModel

        return VStack(spacing: 8) {
            // Severity segmented control
            Picker("Severity", selection: $valVM.filterSeverity) {
                Text("All")
                    .tag(ViolationSeverity?.none)
                ForEach(ViolationSeverity.allCases, id: \.self) { severity in
                    Label(severity.filterLabel, systemImage: severity.icon)
                        .tag(Optional(severity))
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search violations...", text: $valVM.searchText)
                    .textFieldStyle(.plain)
                if !valVM.searchText.isEmpty {
                    Button {
                        valVM.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        let valVM = documentViewModel.validationViewModel
        return HStack {
            Text(valVM.summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            // Grouping picker
            Menu {
                ForEach(ValidationViewModel.GroupingMode.allCases) { mode in
                    Button {
                        documentViewModel.validationViewModel.groupBy = mode
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                            if documentViewModel.validationViewModel.groupBy == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Group", systemImage: "rectangle.3.group")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Grouped List

    private var groupedList: some View {
        let valVM = documentViewModel.validationViewModel
        return List {
            ForEach(valVM.groupedViolations, id: \.0) { groupLabel, violations in
                Section {
                    ForEach(violations) { violation in
                        violationCell(violation, valVM: valVM)
                    }
                } header: {
                    Text(groupLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .contextMenu {
            groupByContextMenu
        }
    }

    /// A single violation cell with inline disclosure expansion.
    ///
    /// Tapping toggles the inline detail view. The detail view contains
    /// full violation information and a "Show in PDF" button.
    @ViewBuilder
    private func violationCell(_ violation: ViolationItem, valVM: ValidationViewModel) -> some View {
        let isExpanded = expandedViolationID == violation.id

        VStack(alignment: .leading, spacing: 0) {
            ViolationRow(violation: violation, isExpanded: isExpanded)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedViolationID == violation.id {
                            expandedViolationID = nil
                            documentViewModel.validationViewModel.selectedViolation = nil
                        } else {
                            expandedViolationID = violation.id
                            documentViewModel.validationViewModel.selectedViolation = violation
                        }
                    }
                }

            if isExpanded {
                ViolationDetailView(
                    violation: violation,
                    onShowInPDF: {
                        documentViewModel.selectViolation(violation)
                    }
                )
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .listRowBackground(
            isExpanded
                ? Color.accentColor.opacity(0.08)
                : (valVM.selectedViolation?.id == violation.id
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear)
        )
        .contextMenu {
            violationContextMenu(for: violation)
        }
    }

    // MARK: - Context Menus

    @ViewBuilder
    private func violationContextMenu(for violation: ViolationItem) -> some View {
        Button {
            copyViolationDetails(violation)
        } label: {
            Label("Copy Violation Details", systemImage: "doc.on.doc")
        }

        if let pageIndex = violation.pageIndex {
            Button {
                documentViewModel.selectViolation(violation)
            } label: {
                Label("Go to Page \(pageIndex + 1)", systemImage: "arrow.right.doc.on.clipboard")
            }
        }

        Divider()

        groupByContextMenu
    }

    @ViewBuilder
    private var groupByContextMenu: some View {
        Menu("Group By") {
            ForEach(ValidationViewModel.GroupingMode.allCases) { mode in
                Button {
                    documentViewModel.validationViewModel.groupBy = mode
                } label: {
                    HStack {
                        Text(mode.rawValue)
                        if documentViewModel.validationViewModel.groupBy == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Copy

    private func copyViolationDetails(_ violation: ViolationItem) {
        let details = ViolationsListHelper.formatViolationDetails(violation)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(details, forType: .string)
    }

    // MARK: - Placeholder Views

    private var validatingPlaceholder: some View {
        placeholderView(
            icon: "hourglass",
            title: "Validating...",
            subtitle: "Checking for violations..."
        )
    }

    private var noDocumentPlaceholder: some View {
        placeholderView(
            icon: "exclamationmark.triangle",
            title: "Violations",
            subtitle: "Open a PDF to check for violations."
        )
    }

    private var notValidatedPlaceholder: some View {
        placeholderView(
            icon: "exclamationmark.triangle",
            title: "Not Validated",
            subtitle: "Run validation to see violations."
        )
    }

    private var cleanPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("No Violations Found")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("This document passed all validation checks.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No violations found. Document passed all validation checks.")
    }

    private var noMatchPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("No Matching Violations")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Try adjusting your filters or search text.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
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
}

// MARK: - ViolationRow

/// A single row in the violations list showing severity icon, rule ID, message,
/// page number badge, WCAG criterion tag, and a disclosure chevron indicating
/// whether the inline detail view is expanded.
private struct ViolationRow: View {

    let violation: ViolationItem
    var isExpanded: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // Disclosure chevron
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 10)

            // Severity icon
            Image(systemName: violation.severity.icon)
                .foregroundStyle(violation.severity.color)
                .font(.body)
                .frame(width: 20)
                .accessibilityLabel(violation.severity.rawValue)

            // Rule ID + message
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    // Rule ID badge
                    Text(violation.ruleID)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(violation.severity.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    // WCAG criterion tag
                    if let criterion = violation.wcagCriterion {
                        Text(criterion)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                // Short description (2-line truncation)
                Text(violation.message)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer()

            // Page number badge
            if let pageIndex = violation.pageIndex {
                Text("p.\(pageIndex + 1)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(violation.severity.rawValue): \(violation.ruleID), \(violation.message)"
            + (violation.pageIndex.map { ", page \($0 + 1)" } ?? "")
            + (isExpanded ? ", expanded" : ", collapsed")
        )
    }
}

// MARK: - ViolationSeverity Extension

extension ViolationSeverity {
    /// Label used in the filter bar segmented control.
    var filterLabel: String {
        switch self {
        case .error: "Errors"
        case .warning: "Warnings"
        case .info: "Info"
        }
    }
}

// MARK: - ViolationsListHelper

/// Testable helper for ViolationsListView logic.
enum ViolationsListHelper {

    /// Formats violation details as a copyable text string.
    static func formatViolationDetails(_ violation: ViolationItem) -> String {
        var lines: [String] = []
        lines.append("Rule: \(violation.ruleID)")
        lines.append("Severity: \(violation.severity.rawValue)")
        lines.append("Message: \(violation.message)")
        if let pageIndex = violation.pageIndex {
            lines.append("Page: \(pageIndex + 1)")
        }
        if let criterion = violation.wcagCriterion {
            lines.append("WCAG Criterion: \(criterion)")
        }
        if let principle = violation.wcagPrinciple {
            lines.append("WCAG Principle: \(principle)")
        }
        if let level = violation.wcagLevel {
            lines.append("WCAG Level: \(level)")
        }
        if let spec = violation.specification {
            lines.append("Specification: \(spec)")
        }
        if let context = violation.context {
            lines.append("Context: \(context)")
        }
        if let remediation = violation.remediation {
            lines.append("Remediation: \(remediation)")
        }
        return lines.joined(separator: "\n")
    }

    /// Computes the badge count for the violations tab (error count only).
    static func badgeCount(from viewModel: ValidationViewModel) -> Int {
        viewModel.errorCount
    }
}

// MARK: - Preview

#Preview("With Violations") {
    let docVM = DocumentViewModel()
    // seed some violations for preview
    let violations: [ViolationItem] = [
        ViolationItem(
            id: "err-1", ruleID: "7.1-001", severity: .error,
            message: "Missing alt text on figure element",
            description: "Figure element lacks alt text",
            pageIndex: 0, objectType: "Figure", context: nil,
            wcagCriterion: "1.1.1", wcagPrinciple: "Perceivable",
            wcagLevel: "A", specification: "PDF/UA-2 clause 7.1",
            remediation: "Add alt text"
        ),
        ViolationItem(
            id: "warn-1", ruleID: "8.1-002", severity: .warning,
            message: "Low contrast ratio (3.8:1) on text content",
            description: "Text contrast below threshold",
            pageIndex: 1, objectType: "Span", context: nil,
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
    docVM.validationViewModel.updateViolations(violations)

    return ViolationsListView()
        .environment(docVM)
        .environment(docVM.validationService)
        .environment(docVM.documentModel)
        .environment(docVM.validationViewModel)
        .frame(width: 320, height: 500)
}

#Preview("Clean") {
    ViolationsListView()
        .environment(DocumentViewModel())
        .environment(ValidationService())
        .environment(PDFDocumentModel())
        .environment(ValidationViewModel())
        .frame(width: 320, height: 400)
}
