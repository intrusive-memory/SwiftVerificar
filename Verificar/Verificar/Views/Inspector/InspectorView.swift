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
/// Placeholder content is shown for each tab until later sprints implement
/// the real panel views.
struct InspectorView: View {

    @Environment(PDFDocumentModel.self) private var documentModel

    /// The active inspector tab.
    @State private var selectedTab: InspectorTab = .standards

    var body: some View {
        VStack(spacing: 0) {
            tabBar
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

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .standards:
            tabPlaceholder(
                icon: "checkmark.shield",
                title: "Standards Compliance",
                subtitle: documentModel.isDocumentLoaded
                    ? "Validation results will appear here."
                    : "Open a PDF to check compliance."
            )
        case .violations:
            tabPlaceholder(
                icon: "exclamationmark.triangle",
                title: "Violations",
                subtitle: documentModel.isDocumentLoaded
                    ? "Run validation to see violations."
                    : "Open a PDF to check for violations."
            )
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

    // MARK: - Placeholder

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
        .frame(width: 300, height: 400)
}
