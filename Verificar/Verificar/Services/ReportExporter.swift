//
//  ReportExporter.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

/// Provides export functionality for validation results in multiple formats.
///
/// `ReportExporter` takes the app's own `ValidationSummary` and `[ViolationItem]`
/// types as input and produces structured output in JSON, HTML, or plain text formats.
/// This avoids tight coupling to the SwiftVerificar-biblioteca library types.
struct ReportExporter {

    // MARK: - JSON Export

    /// Exports validation results as structured JSON data.
    ///
    /// The JSON includes a summary section with counts and pass rate,
    /// followed by an array of violations with full detail.
    ///
    /// - Parameters:
    ///   - summary: The validation summary.
    ///   - violations: The list of violations.
    ///   - documentTitle: The title of the validated document.
    /// - Returns: UTF-8 encoded JSON data.
    func exportJSON(
        summary: ValidationSummary,
        violations: [ViolationItem],
        documentTitle: String
    ) -> Data {
        let report = JSONReport(
            document: documentTitle,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            summary: JSONReport.Summary(
                profileName: summary.profileName,
                totalRules: summary.totalRules,
                passedCount: summary.passedCount,
                failedCount: summary.failedCount,
                warningCount: summary.warningCount,
                notApplicableCount: summary.notApplicableCount,
                passRate: summary.passRate,
                duration: summary.duration
            ),
            violations: violations.map { violation in
                JSONReport.Violation(
                    id: violation.id,
                    ruleID: violation.ruleID,
                    severity: violation.severity.rawValue,
                    message: violation.message,
                    description: violation.description,
                    page: violation.pageIndex.map { $0 + 1 },
                    objectType: violation.objectType,
                    context: violation.context,
                    wcagCriterion: violation.wcagCriterion,
                    wcagPrinciple: violation.wcagPrinciple,
                    wcagLevel: violation.wcagLevel,
                    specification: violation.specification,
                    remediation: violation.remediation
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(report)) ?? Data()
    }

    // MARK: - HTML Export

    /// Exports validation results as a styled HTML report.
    ///
    /// The HTML includes a summary table with violation counts and pass rate,
    /// followed by detailed sections for each violation with color-coded severity.
    ///
    /// - Parameters:
    ///   - summary: The validation summary.
    ///   - violations: The list of violations.
    ///   - documentTitle: The title of the validated document.
    /// - Returns: A complete HTML document string.
    func exportHTML(
        summary: ValidationSummary,
        violations: [ViolationItem],
        documentTitle: String
    ) -> String {
        let passRatePercent = Int(round(summary.passRate * 100))
        let statusLabel = summary.failedCount > 0 ? "Non-conformant" : "Conformant"
        let statusColor = summary.failedCount > 0 ? "#d32f2f" : "#388e3c"

        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Verificar Report - \(ReportExporter.escapeHTML(documentTitle))</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; color: #333; line-height: 1.6; }
                h1 { color: #1a1a1a; border-bottom: 2px solid #eee; padding-bottom: 8px; }
                h2 { color: #444; margin-top: 32px; }
                .summary-table { border-collapse: collapse; width: 100%; max-width: 600px; margin: 16px 0; }
                .summary-table td { padding: 8px 16px; border: 1px solid #ddd; }
                .summary-table td:first-child { font-weight: 600; background: #f8f8f8; width: 200px; }
                .status { font-weight: bold; color: \(statusColor); }
                .violation { border: 1px solid #ddd; border-radius: 8px; padding: 16px; margin: 12px 0; }
                .violation-header { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
                .severity-badge { padding: 2px 8px; border-radius: 4px; font-size: 12px; font-weight: 600; color: white; }
                .severity-error { background: #d32f2f; }
                .severity-warning { background: #f9a825; color: #333; }
                .severity-info { background: #1565c0; }
                .rule-id { font-family: monospace; font-weight: 600; }
                .detail-row { margin: 4px 0; }
                .detail-label { font-weight: 600; color: #666; }
                .context-block { background: #f5f5f5; padding: 8px 12px; border-radius: 4px; font-family: monospace; font-size: 13px; margin: 4px 0; }
                .remediation { background: #e8f5e9; padding: 8px 12px; border-radius: 4px; margin: 4px 0; }
                .footer { margin-top: 40px; padding-top: 16px; border-top: 1px solid #eee; color: #999; font-size: 13px; }
            </style>
        </head>
        <body>
            <h1>Verificar Validation Report</h1>

            <h2>Summary</h2>
            <table class="summary-table">
                <tr><td>Document</td><td>\(ReportExporter.escapeHTML(documentTitle))</td></tr>
                <tr><td>Profile</td><td>\(ReportExporter.escapeHTML(summary.profileName))</td></tr>
                <tr><td>Status</td><td class="status">\(statusLabel)</td></tr>
                <tr><td>Total Rules</td><td>\(summary.totalRules)</td></tr>
                <tr><td>Passed</td><td>\(summary.passedCount)</td></tr>
                <tr><td>Failed</td><td>\(summary.failedCount)</td></tr>
                <tr><td>Warnings</td><td>\(summary.warningCount)</td></tr>
                <tr><td>Pass Rate</td><td>\(passRatePercent)%</td></tr>
                <tr><td>Duration</td><td>\(String(format: "%.2f", summary.duration))s</td></tr>
            </table>

        """

        if violations.isEmpty {
            html += """
                <h2>Violations</h2>
                <p>No violations found. The document is conformant.</p>

            """
        } else {
            html += """
                <h2>Violations (\(violations.count))</h2>

            """

            for violation in violations {
                let severityClass = "severity-\(violation.severity.rawValue.lowercased())"
                let pageText = violation.pageIndex.map { "Page \($0 + 1)" } ?? "Document-level"

                html += """
                    <div class="violation">
                        <div class="violation-header">
                            <span class="severity-badge \(severityClass)">\(violation.severity.rawValue)</span>
                            <span class="rule-id">\(ReportExporter.escapeHTML(violation.ruleID))</span>
                            <span>\(ReportExporter.escapeHTML(pageText))</span>
                        </div>
                        <div class="detail-row">\(ReportExporter.escapeHTML(violation.message))</div>

                """

                if let criterion = violation.wcagCriterion {
                    html += """
                            <div class="detail-row"><span class="detail-label">WCAG:</span> \(ReportExporter.escapeHTML(criterion))</div>

                    """
                }

                if let context = violation.context {
                    html += """
                            <div class="context-block">\(ReportExporter.escapeHTML(context))</div>

                    """
                }

                if let remediation = violation.remediation {
                    html += """
                            <div class="remediation"><span class="detail-label">Remediation:</span> \(ReportExporter.escapeHTML(remediation))</div>

                    """
                }

                html += """
                    </div>

                """
            }
        }

        html += """
            <div class="footer">
                Generated by Verificar on \(ReportExporter.formattedDate())
            </div>
        </body>
        </html>
        """

        return html
    }

    // MARK: - Text Export

    /// Exports validation results as a plain text summary.
    ///
    /// The text includes a header with document info and summary stats,
    /// followed by a list of violations with their details.
    ///
    /// - Parameters:
    ///   - summary: The validation summary.
    ///   - violations: The list of violations.
    ///   - documentTitle: The title of the validated document.
    /// - Returns: A formatted plain text string.
    func exportText(
        summary: ValidationSummary,
        violations: [ViolationItem],
        documentTitle: String
    ) -> String {
        let passRatePercent = Int(round(summary.passRate * 100))
        let statusLabel = summary.failedCount > 0 ? "Non-conformant" : "Conformant"
        let separator = String(repeating: "=", count: 60)
        let thinSep = String(repeating: "-", count: 60)

        var text = """
        \(separator)
        VERIFICAR VALIDATION REPORT
        \(separator)

        Document:  \(documentTitle)
        Profile:   \(summary.profileName)
        Status:    \(statusLabel)
        Date:      \(ReportExporter.formattedDate())

        \(thinSep)
        SUMMARY
        \(thinSep)
        Total Rules:     \(summary.totalRules)
        Passed:          \(summary.passedCount)
        Failed:          \(summary.failedCount)
        Warnings:        \(summary.warningCount)
        Not Applicable:  \(summary.notApplicableCount)
        Pass Rate:       \(passRatePercent)%
        Duration:        \(String(format: "%.2f", summary.duration))s

        """

        if violations.isEmpty {
            text += """
            \(thinSep)
            VIOLATIONS
            \(thinSep)
            No violations found.

            """
        } else {
            text += """
            \(thinSep)
            VIOLATIONS (\(violations.count))
            \(thinSep)

            """

            for (index, violation) in violations.enumerated() {
                let pageText = violation.pageIndex.map { "Page \($0 + 1)" } ?? "Document-level"
                text += """
                \(index + 1). [\(violation.severity.rawValue)] \(violation.ruleID)
                   \(violation.message)
                   Location: \(pageText)
                """

                if let criterion = violation.wcagCriterion {
                    text += "\n   WCAG: \(criterion)"
                }

                if let remediation = violation.remediation {
                    text += "\n   Fix: \(remediation)"
                }

                text += "\n\n"
            }
        }

        text += """
        \(separator)
        Generated by Verificar
        \(separator)
        """

        return text
    }

    // MARK: - Save Panel

    /// Presents an NSSavePanel to save a report to disk.
    ///
    /// - Parameters:
    ///   - data: The data to write.
    ///   - defaultName: The suggested file name.
    ///   - fileType: The UTType for the file.
    static func saveToFile(data: Data, defaultName: String, fileType: UTType) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [fileType]
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? data.write(to: url)
            }
        }
    }

    // MARK: - Helpers

    /// Escapes HTML special characters in a string.
    static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Returns the current date formatted for reports.
    static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - JSON Report Model

/// The Codable model for the JSON report structure.
struct JSONReport: Codable, Sendable {

    let document: String
    let generatedAt: String
    let summary: Summary
    let violations: [Violation]

    struct Summary: Codable, Sendable {
        let profileName: String
        let totalRules: Int
        let passedCount: Int
        let failedCount: Int
        let warningCount: Int
        let notApplicableCount: Int
        let passRate: Double
        let duration: TimeInterval
    }

    struct Violation: Codable, Sendable {
        let id: String
        let ruleID: String
        let severity: String
        let message: String
        let description: String
        let page: Int?
        let objectType: String?
        let context: String?
        let wcagCriterion: String?
        let wcagPrinciple: String?
        let wcagLevel: String?
        let specification: String?
        let remediation: String?
    }
}
