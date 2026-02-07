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
/// placeholder content when no results are available. The Violations tab displays
/// a badge with the error count when violations are present.
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
        HStack(spacing: 0) {
            ForEach(InspectorTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func tabButton(for tab: InspectorTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.caption2)
                Text(tab.label)
                    .font(.caption2)
                // Badge for violations tab
                if tab == .violations {
                    let errorCount = documentViewModel.validationViewModel.errorCount
                    if errorCount > 0 {
                        Text("\(errorCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.red, in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(
                selectedTab == tab
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
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
            StandardsPanel()
        case .violations:
            ViolationsListView()
        case .structure:
            StructureTreeView()
        case .features:
            FeaturePanel()
        }
    }

    // MARK: - Helpers

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
