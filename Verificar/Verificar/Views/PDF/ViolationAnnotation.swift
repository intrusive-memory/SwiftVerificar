//
//  ViolationAnnotation.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import PDFKit
import AppKit

/// Custom PDFAnnotation subclass that represents a validation violation on a PDF page.
///
/// Each `ViolationAnnotation` is associated with a `ViolationItem` and is color-coded
/// by severity: red for errors, yellow for warnings, blue for info. The annotation
/// renders as a bordered rectangle at the specified location on the page.
///
/// Hovering shows a tooltip with the violation summary. Clicking the annotation
/// can be detected by the coordinator to select the violation in the list.
final class ViolationAnnotation: PDFAnnotation {

    /// The violation item this annotation represents.
    let violationItem: ViolationItem

    /// The tooltip text displayed when hovering over this annotation.
    private let _tooltipText: String

    /// Override the toolTip getter to provide the violation summary tooltip.
    override var toolTip: String? {
        _tooltipText
    }

    /// Creates a new violation annotation for the given violation item.
    ///
    /// - Parameters:
    ///   - violation: The violation item to represent.
    ///   - bounds: The rectangle on the page where the annotation is placed.
    ///   - page: The PDF page the annotation belongs to.
    init(violation: ViolationItem, bounds: CGRect, page: PDFPage) {
        self.violationItem = violation
        self._tooltipText = ViolationAnnotation.tooltipText(for: violation)
        super.init(bounds: bounds, forType: .square, withProperties: nil)

        // Set the border color based on severity.
        self.color = ViolationAnnotation.annotationColor(for: violation.severity)

        // Configure border.
        let border = PDFBorder()
        border.lineWidth = 2.0
        border.style = .solid
        self.border = border

        // Set interior color with transparency for a highlight effect.
        self.interiorColor = ViolationAnnotation.annotationColor(for: violation.severity)
            .withAlphaComponent(0.1)

        // Allow interaction.
        self.shouldDisplay = true
        self.shouldPrint = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for ViolationAnnotation")
    }

    // MARK: - Color Mapping

    /// Returns the NSColor for a given violation severity.
    ///
    /// - Parameter severity: The violation severity level.
    /// - Returns: An NSColor corresponding to the severity: red for errors, yellow/orange for warnings, blue for info.
    static func annotationColor(for severity: ViolationSeverity) -> NSColor {
        switch severity {
        case .error:
            return NSColor.systemRed
        case .warning:
            return NSColor.systemYellow
        case .info:
            return NSColor.systemBlue
        }
    }

    // MARK: - Tooltip

    /// Builds a tooltip string summarizing the violation.
    ///
    /// - Parameter violation: The violation item.
    /// - Returns: A multi-line tooltip string with rule ID, severity, and message.
    static func tooltipText(for violation: ViolationItem) -> String {
        var lines: [String] = []
        lines.append("[\(violation.severity.rawValue)] \(violation.ruleID)")
        lines.append(violation.message)
        if let criterion = violation.wcagCriterion {
            lines.append("WCAG \(criterion)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Default Bounds

    /// Creates default annotation bounds for a violation on a given page.
    ///
    /// If the violation has no specific location, creates a small marker in the
    /// top-right corner of the page. Otherwise, creates a reasonable highlight area.
    ///
    /// - Parameters:
    ///   - violation: The violation item.
    ///   - page: The PDF page.
    /// - Returns: A CGRect for the annotation bounds.
    static func defaultBounds(for violation: ViolationItem, on page: PDFPage) -> CGRect {
        let pageBounds = page.bounds(for: .mediaBox)

        // Place a marker in the upper-right area of the page.
        // Offset slightly from edges so multiple markers stack vertically.
        let markerWidth: CGFloat = 24
        let markerHeight: CGFloat = 24
        let rightMargin: CGFloat = 8
        let topMargin: CGFloat = 8

        // Use the violation ID hash to offset markers vertically so they don't overlap.
        let hash = abs(violation.id.hashValue)
        let offset = CGFloat(hash % 20) * 28

        let x = pageBounds.maxX - markerWidth - rightMargin
        let y = pageBounds.maxY - markerHeight - topMargin - offset

        return CGRect(x: x, y: max(pageBounds.minY, y), width: markerWidth, height: markerHeight)
    }
}
