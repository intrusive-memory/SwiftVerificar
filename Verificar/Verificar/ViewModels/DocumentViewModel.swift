//
//  DocumentViewModel.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

/// Central view model coordinating document state and validation orchestration.
///
/// `DocumentViewModel` owns the `PDFDocumentModel` and `ValidationService`,
/// wiring them together so that opening a document automatically triggers
/// validation. It acts as the single source of truth for the document lifecycle
/// and validation results.
///
/// This type is implicitly @MainActor due to project build settings
/// (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
@Observable
final class DocumentViewModel {

    // MARK: - Owned Models

    /// The PDF document model managing rendering state.
    let documentModel = PDFDocumentModel()

    /// The validation service wrapping SwiftVerificar-biblioteca.
    let validationService = ValidationService()

    /// The validation view model managing filtered/sorted violation lists.
    let validationViewModel = ValidationViewModel()

    // MARK: - Validation Configuration

    /// The selected validation profile name.
    var selectedProfile: String = "PDF/UA-2"

    /// Whether to automatically run validation when a document is opened.
    var autoValidateOnOpen: Bool = true

    /// Whether violation annotations are shown overlaid on the PDF view.
    var showViolationHighlights: Bool = true

    // MARK: - Computed State (Derived from Validation Results)

    /// The summary of the last validation run, if any.
    var validationSummary: ValidationSummary? {
        guard let result = validationService.lastResult else { return nil }
        return ValidationStateMapper.makeSummary(from: result)
    }

    /// All violation items from the last validation run.
    var violations: [ViolationItem] {
        guard let result = validationService.lastResult else { return [] }
        return ValidationStateMapper.makeViolations(from: result)
    }

    /// The overall compliance status of the current document.
    var complianceStatus: ComplianceStatus {
        if validationService.isValidating {
            return .inProgress
        }
        if let summary = validationSummary {
            return summary.complianceStatus
        }
        if documentModel.isDocumentLoaded {
            return .notValidated
        }
        return .notValidated
    }

    // MARK: - Document Lifecycle

    /// Opens a PDF document and optionally triggers validation.
    ///
    /// This is the primary entry point for the document lifecycle. It:
    /// 1. Opens the PDF document via `PDFDocumentModel`
    /// 2. Clears previous validation results
    /// 3. Automatically runs validation if `autoValidateOnOpen` is true
    ///
    /// - Parameter url: The file URL of the PDF document to open.
    func openDocument(at url: URL) async {
        // Clear previous validation state
        validationService.cancelValidation()
        validationViewModel.clearViolations()

        // Open the document
        do {
            try await documentModel.open(url: url)
        } catch {
            // Error is stored on documentModel.error
            return
        }

        // Auto-validate if enabled
        if autoValidateOnOpen {
            await validate()
        }
    }

    // MARK: - Validation

    /// Runs validation on the currently loaded document with the selected profile.
    ///
    /// After validation completes, the results are mapped to UI models and
    /// pushed into the `validationViewModel` for display.
    func validate() async {
        guard let url = documentModel.url else { return }
        await validationService.validate(url: url, profile: selectedProfile)

        // Map results to the validation view model
        let mappedViolations = violations
        validationViewModel.updateViolations(mappedViolations)
    }

    /// Re-runs validation with the current profile. Convenience wrapper for `validate()`.
    func revalidate() async {
        await validate()
    }

    // MARK: - Violation Navigation

    /// Selects a violation and navigates the PDF view to its page.
    ///
    /// - Parameter violation: The violation to select and navigate to.
    func selectViolation(_ violation: ViolationItem) {
        validationViewModel.selectedViolation = violation
        if let pageIndex = violation.pageIndex {
            documentModel.goToPage(pageIndex)
        }
    }

    /// Handles an annotation click in the PDF view by selecting the corresponding violation.
    ///
    /// This provides the PDF-to-list direction of bidirectional navigation:
    /// clicking a violation annotation in the PDF selects it in the violations list.
    ///
    /// - Parameter violation: The violation item from the clicked annotation.
    func handleAnnotationClicked(_ violation: ViolationItem) {
        validationViewModel.selectedViolation = violation
    }

    // MARK: - Report Export

    /// Exports validation results as JSON data using ReportExporter.
    ///
    /// - Returns: JSON data, or nil if no validation results are available.
    func exportJSON() -> Data? {
        guard let summary = validationSummary else { return nil }
        let exporter = ReportExporter()
        return exporter.exportJSON(
            summary: summary,
            violations: violations,
            documentTitle: documentModel.title
        )
    }

    /// Exports validation results as an HTML string using ReportExporter.
    ///
    /// - Returns: HTML string, or nil if no validation results are available.
    func exportHTML() -> String? {
        guard let summary = validationSummary else { return nil }
        let exporter = ReportExporter()
        return exporter.exportHTML(
            summary: summary,
            violations: violations,
            documentTitle: documentModel.title
        )
    }

    /// Exports validation results as a plain text string using ReportExporter.
    ///
    /// - Returns: Plain text string, or nil if no validation results are available.
    func exportText() -> String? {
        guard let summary = validationSummary else { return nil }
        let exporter = ReportExporter()
        return exporter.exportText(
            summary: summary,
            violations: violations,
            documentTitle: documentModel.title
        )
    }
}
