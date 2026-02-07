//
//  ValidationViewModel.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import Foundation

/// View model managing the filtered, sorted, and grouped violation list.
///
/// `ValidationViewModel` holds the raw list of violations and exposes
/// computed properties for filtering by severity, searching by text, and
/// grouping by various criteria. The UI binds to `filteredViolations` and
/// `groupedViolations` for display.
///
/// This type is implicitly @MainActor due to project build settings
/// (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
@Observable
final class ValidationViewModel {

    // MARK: - Violation Data

    /// The raw list of all violations from the last validation run.
    var violations: [ViolationItem] = []

    /// The currently selected violation, if any.
    var selectedViolation: ViolationItem?

    // MARK: - Filter & Search State

    /// Filter violations by severity. `nil` means show all.
    var filterSeverity: ViolationSeverity?

    /// Text to search for in violation messages and rule IDs.
    var searchText: String = ""

    /// How to group the violations list.
    var groupBy: GroupingMode = .severity

    // MARK: - Grouping Mode

    /// Available modes for grouping violations in the list.
    enum GroupingMode: String, CaseIterable, Identifiable {
        case none = "None"
        case severity = "Severity"
        case category = "Category"
        case page = "Page"

        var id: String { rawValue }
    }

    // MARK: - Computed Properties

    /// Violations filtered by the current severity filter and search text.
    var filteredViolations: [ViolationItem] {
        violations
            .filter { item in
                if let severity = filterSeverity {
                    return item.severity == severity
                }
                return true
            }
            .filter { item in
                if searchText.isEmpty { return true }
                return item.message.localizedCaseInsensitiveContains(searchText)
                    || item.ruleID.localizedCaseInsensitiveContains(searchText)
                    || (item.wcagCriterion?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
    }

    /// Violations grouped according to the current `groupBy` mode.
    ///
    /// Returns an array of (groupLabel, violations) tuples.
    var groupedViolations: [(String, [ViolationItem])] {
        let filtered = filteredViolations
        switch groupBy {
        case .none:
            if filtered.isEmpty { return [] }
            return [("All Violations", filtered)]

        case .severity:
            return groupBySeverity(filtered)

        case .category:
            return groupByCategory(filtered)

        case .page:
            return groupByPage(filtered)
        }
    }

    /// Counts of violations by severity.
    var errorCount: Int { violations.filter { $0.severity == .error }.count }
    var warningCount: Int { violations.filter { $0.severity == .warning }.count }
    var infoCount: Int { violations.filter { $0.severity == .info }.count }

    /// Summary text for the violation count (e.g., "42 violations (28 errors, 10 warnings, 4 info)").
    var summaryText: String {
        let total = violations.count
        if total == 0 { return "No violations" }
        var parts: [String] = []
        if errorCount > 0 { parts.append("\(errorCount) error\(errorCount == 1 ? "" : "s")") }
        if warningCount > 0 { parts.append("\(warningCount) warning\(warningCount == 1 ? "" : "s")") }
        if infoCount > 0 { parts.append("\(infoCount) info") }
        return "\(total) violation\(total == 1 ? "" : "s") (\(parts.joined(separator: ", ")))"
    }

    // MARK: - Mutation

    /// Replaces the current violations list with new violations.
    ///
    /// - Parameter newViolations: The violations from the latest validation run.
    func updateViolations(_ newViolations: [ViolationItem]) {
        violations = newViolations
        selectedViolation = nil
    }

    /// Clears all violations and resets filter state.
    func clearViolations() {
        violations = []
        selectedViolation = nil
        filterSeverity = nil
        searchText = ""
    }

    // MARK: - Grouping Helpers

    private func groupBySeverity(_ items: [ViolationItem]) -> [(String, [ViolationItem])] {
        var result: [(String, [ViolationItem])] = []
        for severity in ViolationSeverity.allCases {
            let group = items.filter { $0.severity == severity }
            if !group.isEmpty {
                result.append(("\(severity.rawValue)s (\(group.count))", group))
            }
        }
        return result
    }

    private func groupByCategory(_ items: [ViolationItem]) -> [(String, [ViolationItem])] {
        var dict: [String: [ViolationItem]] = [:]
        for item in items {
            let category = item.wcagPrinciple ?? item.specification ?? "Uncategorized"
            dict[category, default: []].append(item)
        }
        return dict.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    private func groupByPage(_ items: [ViolationItem]) -> [(String, [ViolationItem])] {
        var dict: [String: [ViolationItem]] = [:]
        for item in items {
            let key: String
            if let pageIndex = item.pageIndex {
                key = "Page \(pageIndex + 1)"
            } else {
                key = "Document-level"
            }
            dict[key, default: []].append(item)
        }
        // Sort by page number (numeric), with "Document-level" first
        return dict.sorted { lhs, rhs in
            if lhs.key == "Document-level" { return true }
            if rhs.key == "Document-level" { return false }
            // Extract page numbers for numeric sort
            let lhsNum = Int(lhs.key.dropFirst(5)) ?? 0
            let rhsNum = Int(rhs.key.dropFirst(5)) ?? 0
            return lhsNum < rhsNum
        }.map { ($0.key, $0.value) }
    }
}
