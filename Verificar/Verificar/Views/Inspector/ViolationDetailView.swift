//
//  ViolationDetailView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// Expandable detail view for an individual violation, showing complete
/// information including WCAG mapping, specification references, context,
/// and remediation suggestions.
///
/// Designed to be shown inline within the violations list when a violation
/// is selected, using a disclosure-style expansion.
struct ViolationDetailView: View {

    let violation: ViolationItem

    /// Action to navigate the PDF to this violation's location.
    var onShowInPDF: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            Divider()
            detailSections
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Violation detail: \(violation.ruleID)")
    }

    // MARK: - Header

    /// Header showing severity badge, rule ID, and short description.
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            // Severity badge
            Image(systemName: violation.severity.icon)
                .foregroundStyle(violation.severity.color)
                .font(.title3)
                .accessibilityLabel(violation.severity.rawValue)

            VStack(alignment: .leading, spacing: 4) {
                // Rule ID
                Text(violation.ruleID)
                    .font(.headline)
                    .fontWeight(.semibold)

                // Short description
                Text(violation.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - Detail Sections

    private var detailSections: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Specification Reference
            if let specification = violation.specification {
                specificationSection(specification)
            }

            // Location
            locationSection

            // WCAG Mapping
            if violation.wcagCriterion != nil || violation.wcagPrinciple != nil {
                wcagMappingSection
            }

            // Full description
            if violation.description != violation.message {
                descriptionSection
            }

            // Context excerpt
            if let context = violation.context {
                contextSection(context)
            }

            // Remediation suggestion
            if let remediation = violation.remediation {
                remediationSection(remediation)
            }

            // Navigate button
            if violation.pageIndex != nil {
                navigateButton
            }
        }
    }

    // MARK: - Specification Reference

    private func specificationSection(_ specification: String) -> some View {
        detailRow(
            label: "Specification",
            icon: "doc.text",
            content: specification
        )
    }

    // MARK: - Location

    private var locationSection: some View {
        let locationParts = ViolationDetailHelper.formatLocation(
            pageIndex: violation.pageIndex,
            objectType: violation.objectType,
            context: violation.context
        )
        return detailRow(
            label: "Location",
            icon: "mappin.and.ellipse",
            content: locationParts
        )
    }

    // MARK: - WCAG Mapping

    private var wcagMappingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("WCAG Mapping", systemImage: "globe")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                // Principle
                if let principle = violation.wcagPrinciple {
                    wcagRow(label: "Principle", value: principle)
                }

                // Success Criterion
                if let criterion = violation.wcagCriterion {
                    let criterionName = ViolationDetailHelper.wcagCriterionName(criterion)
                    let displayText = criterionName != nil
                        ? "\(criterion) \(criterionName!)"
                        : criterion
                    wcagRow(label: "Success Criterion", value: displayText)
                }

                // Level
                if let level = violation.wcagLevel {
                    wcagRow(label: "Level", value: ViolationDetailHelper.formatWCAGLevel(level))
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func wcagRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(label):")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 105, alignment: .trailing)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        detailRow(
            label: "Details",
            icon: "text.justify.left",
            content: violation.description
        )
    }

    // MARK: - Context

    private func contextSection(_ context: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Context", systemImage: "text.quote")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(context)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .textSelection(.enabled)
        }
    }

    // MARK: - Remediation

    private func remediationSection(_ remediation: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Remediation", systemImage: "wrench.and.screwdriver")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(remediation)
                .font(.caption)
                .foregroundStyle(.primary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .textSelection(.enabled)
        }
    }

    // MARK: - Navigate Button

    private var navigateButton: some View {
        Button {
            onShowInPDF?()
        } label: {
            Label("Show in PDF", systemImage: "arrow.right.doc.on.clipboard")
                .font(.caption)
                .fontWeight(.medium)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .accessibilityLabel("Show violation in PDF, page \((violation.pageIndex ?? 0) + 1)")
    }

    // MARK: - Detail Row Helper

    private func detailRow(label: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(content)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }
}

// MARK: - ViolationDetailHelper

/// Testable helper for ViolationDetailView formatting logic.
enum ViolationDetailHelper {

    /// Formats location information as a readable string.
    ///
    /// - Parameters:
    ///   - pageIndex: Zero-based page index, or nil for document-level.
    ///   - objectType: The type of PDF object (e.g., "Figure", "Table").
    ///   - context: The path in the structure tree (e.g., "/StructTreeRoot/Document/Figure").
    /// - Returns: A formatted location string.
    static func formatLocation(
        pageIndex: Int?,
        objectType: String?,
        context: String?
    ) -> String {
        var parts: [String] = []

        if let pageIndex {
            parts.append("Page \(pageIndex + 1)")
        } else {
            parts.append("Document-level")
        }

        if let objectType {
            parts.append("Object: \(objectType)")
        }

        if let context {
            parts.append("Path: \(context)")
        }

        return parts.joined(separator: " | ")
    }

    /// Returns the WCAG success criterion name for a given criterion number.
    ///
    /// - Parameter criterion: The WCAG criterion number (e.g., "1.1.1").
    /// - Returns: The criterion name (e.g., "Non-text Content"), or nil if not mapped.
    static func wcagCriterionName(_ criterion: String) -> String? {
        wcagCriterionMap[criterion]
    }

    /// Formats a WCAG conformance level with a descriptive label.
    ///
    /// - Parameter level: The raw level string (e.g., "A", "AA", "AAA").
    /// - Returns: A formatted level string (e.g., "Level A", "Level AA").
    static func formatWCAGLevel(_ level: String) -> String {
        if level.hasPrefix("Level ") {
            return level
        }
        return "Level \(level)"
    }

    /// Generates a formatted remediation text for a violation, combining
    /// the remediation suggestion with relevant context.
    ///
    /// - Parameter violation: The violation to generate remediation for.
    /// - Returns: A formatted remediation string, or nil if no remediation is available.
    static func formatRemediation(_ violation: ViolationItem) -> String? {
        guard let remediation = violation.remediation else { return nil }

        var result = remediation

        // Append WCAG reference if available
        if let criterion = violation.wcagCriterion {
            let name = wcagCriterionName(criterion) ?? ""
            let nameStr = name.isEmpty ? "" : " (\(name))"
            result += "\n\nRefer to WCAG \(criterion)\(nameStr) for guidance."
        }

        return result
    }

    /// Maps WCAG criterion numbers to their standard names (WCAG 2.1).
    static let wcagCriterionMap: [String: String] = [
        // Principle 1: Perceivable
        "1.1.1": "Non-text Content",
        "1.2.1": "Audio-only and Video-only (Prerecorded)",
        "1.2.2": "Captions (Prerecorded)",
        "1.2.3": "Audio Description or Media Alternative (Prerecorded)",
        "1.2.4": "Captions (Live)",
        "1.2.5": "Audio Description (Prerecorded)",
        "1.2.6": "Sign Language (Prerecorded)",
        "1.2.7": "Extended Audio Description (Prerecorded)",
        "1.2.8": "Media Alternative (Prerecorded)",
        "1.2.9": "Audio-only (Live)",
        "1.3.1": "Info and Relationships",
        "1.3.2": "Meaningful Sequence",
        "1.3.3": "Sensory Characteristics",
        "1.3.4": "Orientation",
        "1.3.5": "Identify Input Purpose",
        "1.3.6": "Identify Purpose",
        "1.4.1": "Use of Color",
        "1.4.2": "Audio Control",
        "1.4.3": "Contrast (Minimum)",
        "1.4.4": "Resize Text",
        "1.4.5": "Images of Text",
        "1.4.6": "Contrast (Enhanced)",
        "1.4.7": "Low or No Background Audio",
        "1.4.8": "Visual Presentation",
        "1.4.9": "Images of Text (No Exception)",
        "1.4.10": "Reflow",
        "1.4.11": "Non-text Contrast",
        "1.4.12": "Text Spacing",
        "1.4.13": "Content on Hover or Focus",
        // Principle 2: Operable
        "2.1.1": "Keyboard",
        "2.1.2": "No Keyboard Trap",
        "2.1.3": "Keyboard (No Exception)",
        "2.1.4": "Character Key Shortcuts",
        "2.2.1": "Timing Adjustable",
        "2.2.2": "Pause, Stop, Hide",
        "2.2.3": "No Timing",
        "2.2.4": "Interruptions",
        "2.2.5": "Re-authenticating",
        "2.2.6": "Timeouts",
        "2.3.1": "Three Flashes or Below Threshold",
        "2.3.2": "Three Flashes",
        "2.3.3": "Animation from Interactions",
        "2.4.1": "Bypass Blocks",
        "2.4.2": "Page Titled",
        "2.4.3": "Focus Order",
        "2.4.4": "Link Purpose (In Context)",
        "2.4.5": "Multiple Ways",
        "2.4.6": "Headings and Labels",
        "2.4.7": "Focus Visible",
        "2.4.8": "Location",
        "2.4.9": "Link Purpose (Link Only)",
        "2.4.10": "Section Headings",
        "2.5.1": "Pointer Gestures",
        "2.5.2": "Pointer Cancellation",
        "2.5.3": "Label in Name",
        "2.5.4": "Motion Actuation",
        "2.5.5": "Target Size",
        "2.5.6": "Concurrent Input Mechanisms",
        // Principle 3: Understandable
        "3.1.1": "Language of Page",
        "3.1.2": "Language of Parts",
        "3.1.3": "Unusual Words",
        "3.1.4": "Abbreviations",
        "3.1.5": "Reading Level",
        "3.1.6": "Pronunciation",
        "3.2.1": "On Focus",
        "3.2.2": "On Input",
        "3.2.3": "Consistent Navigation",
        "3.2.4": "Consistent Identification",
        "3.2.5": "Change on Request",
        "3.3.1": "Error Identification",
        "3.3.2": "Labels or Instructions",
        "3.3.3": "Error Suggestion",
        "3.3.4": "Error Prevention (Legal, Financial, Data)",
        "3.3.5": "Help",
        "3.3.6": "Error Prevention (All)",
        // Principle 4: Robust
        "4.1.1": "Parsing",
        "4.1.2": "Name, Role, Value",
        "4.1.3": "Status Messages",
    ]
}

// MARK: - Preview

#Preview("Violation Detail") {
    ViolationDetailView(
        violation: ViolationItem(
            id: "err-1", ruleID: "7.1-001", severity: .error,
            message: "Missing alt text on figure element",
            description: "The Figure structure element on page 1 does not have an alternative text attribute (Alt). All non-text content must provide a text alternative.",
            pageIndex: 0, objectType: "Figure",
            context: "/StructTreeRoot/Document/Section/Figure",
            wcagCriterion: "1.1.1", wcagPrinciple: "Perceivable",
            wcagLevel: "A", specification: "PDF/UA-2 clause 7.1",
            remediation: "Add an /Alt entry to the Figure structure element with a meaningful text description of the image content."
        ),
        onShowInPDF: { }
    )
    .frame(width: 320)
    .padding()
}

#Preview("Minimal Violation") {
    ViolationDetailView(
        violation: ViolationItem(
            id: "info-1", ruleID: "meta-001", severity: .info,
            message: "Document language not declared",
            description: "Document language not declared",
            pageIndex: nil, objectType: nil, context: nil,
            wcagCriterion: nil, wcagPrinciple: nil, wcagLevel: nil,
            specification: nil, remediation: nil
        )
    )
    .frame(width: 320)
    .padding()
}
