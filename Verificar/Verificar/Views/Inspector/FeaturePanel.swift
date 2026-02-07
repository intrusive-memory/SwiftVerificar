//
//  FeaturePanel.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// Displays extracted PDF features (fonts, images, color spaces, annotations)
/// in a tabbed sub-panel within the inspector.
///
/// Each sub-tab shows an inventory of that feature category with relevant metadata.
/// Items that may indicate accessibility or compliance concerns are highlighted
/// (e.g., non-embedded fonts, images without alt text, device-dependent color spaces).
///
/// A summary bar at the top shows total counts for each category.
struct FeaturePanel: View {

    @Environment(DocumentViewModel.self) private var documentViewModel
    @Environment(PDFDocumentModel.self) private var documentModel

    /// Local view model for feature data.
    @State private var viewModel = FeatureViewModel()

    /// The active feature sub-tab.
    @State private var selectedTab: FeatureTab = .fonts

    var body: some View {
        VStack(spacing: 0) {
            if !documentModel.isDocumentLoaded {
                noDocumentView
            } else if viewModel.isExtracting {
                extractingView
            } else if viewModel.hasExtractedFeatures {
                featureContentView
            } else {
                notExtractedView
            }
        }
        .onAppear {
            loadFeatures()
        }
        .onChange(of: documentModel.isDocumentLoaded) { _, newValue in
            if newValue {
                loadFeatures()
            } else {
                viewModel.clearFeatures()
            }
        }
    }

    // MARK: - Feature Content

    private var featureContentView: some View {
        VStack(spacing: 0) {
            summaryBar
            Divider()
            featureTabBar
            Divider()
            featureTabContent
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        let stats = viewModel.summary
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                summaryBadge(
                    icon: "textformat",
                    count: stats.totalFonts,
                    label: "Fonts",
                    warningCount: stats.nonEmbeddedFontCount
                )
                summaryBadge(
                    icon: "photo",
                    count: stats.totalImages,
                    label: "Images",
                    warningCount: stats.imagesWithoutAltTextCount
                )
                summaryBadge(
                    icon: "paintpalette",
                    count: stats.totalColorSpaces,
                    label: "Colors",
                    warningCount: stats.deviceDependentColorSpaceCount
                )
                summaryBadge(
                    icon: "note.text",
                    count: stats.totalAnnotations,
                    label: "Annots",
                    warningCount: stats.annotationsWithoutAccessibleNameCount
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(stats.totalFonts) fonts, \(stats.totalImages) images, \(stats.totalColorSpaces) color spaces, \(stats.totalAnnotations) annotations"
        )
    }

    private func summaryBadge(icon: String, count: Int, label: String, warningCount: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 2) {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold))
                    if warningCount > 0 {
                        Text("(\(warningCount))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                }
                Text(label)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Feature Tab Bar

    private var featureTabBar: some View {
        HStack(spacing: 0) {
            ForEach(FeatureTab.allCases) { tab in
                featureTabButton(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private func featureTabButton(for tab: FeatureTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 9))
                Text(tab.label)
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity)
            .background(
                selectedTab == tab
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 5)
            )
            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var featureTabContent: some View {
        switch selectedTab {
        case .fonts:
            fontsTab
        case .images:
            imagesTab
        case .colorSpaces:
            colorSpacesTab
        case .annotations:
            annotationsTab
        }
    }

    // MARK: - Fonts Tab

    private var fontsTab: some View {
        Group {
            if viewModel.fonts.isEmpty {
                emptyTabView(icon: "textformat", message: "No fonts detected")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Header row
                        fontHeaderRow
                        Divider()
                        ForEach(viewModel.fonts) { font in
                            fontRow(font)
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var fontHeaderRow: some View {
        HStack(spacing: 8) {
            Text("Font Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Type")
                .frame(width: 55, alignment: .leading)
            Text("Embed")
                .frame(width: 38, alignment: .center)
            Text("Pages")
                .frame(width: 50, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func fontRow(_ font: FontFeature) -> some View {
        HStack(spacing: 8) {
            Text(font.name)
                .font(.system(size: 10))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(font.isEmbedded ? Color.primary : Color.orange)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(font.type.rawValue)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .leading)

            Image(systemName: font.isEmbedded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(font.isEmbedded ? .green : .orange)
                .frame(width: 38, alignment: .center)

            Text(FeatureExtractionHelper.formatPageList(font.usedOnPages))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(font.isEmbedded ? Color.clear : Color.orange.opacity(0.05))
        .accessibilityLabel(
            "\(font.name), \(font.type.rawValue), \(font.isEmbedded ? "embedded" : "not embedded"), pages \(FeatureExtractionHelper.formatPageList(font.usedOnPages))"
        )
    }

    // MARK: - Images Tab

    private var imagesTab: some View {
        Group {
            if viewModel.images.isEmpty {
                emptyTabView(icon: "photo", message: "No images detected")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        imageHeaderRow
                        Divider()
                        ForEach(viewModel.images) { image in
                            imageRow(image)
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var imageHeaderRow: some View {
        HStack(spacing: 8) {
            Text("Dimensions")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Color")
                .frame(width: 60, alignment: .leading)
            Text("Alt")
                .frame(width: 28, alignment: .center)
            Text("Page")
                .frame(width: 36, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func imageRow(_ image: ImageFeature) -> some View {
        HStack(spacing: 8) {
            Text(image.dimensionsLabel)
                .font(.system(size: 10, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(image.colorSpace)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 60, alignment: .leading)

            Image(systemName: image.hasAltText ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(image.hasAltText ? .green : .red)
                .frame(width: 28, alignment: .center)

            Text("\(image.pageIndex + 1)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(image.hasAltText ? Color.clear : Color.red.opacity(0.05))
        .accessibilityLabel(
            "\(image.dimensionsLabel), \(image.colorSpace), \(image.hasAltText ? "has alt text" : "missing alt text"), page \(image.pageIndex + 1)"
        )
    }

    // MARK: - Color Spaces Tab

    private var colorSpacesTab: some View {
        Group {
            if viewModel.colorSpaces.isEmpty {
                emptyTabView(icon: "paintpalette", message: "No color spaces detected")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        colorSpaceHeaderRow
                        Divider()
                        ForEach(viewModel.colorSpaces) { cs in
                            colorSpaceRow(cs)
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var colorSpaceHeaderRow: some View {
        HStack(spacing: 8) {
            Text("Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Type")
                .frame(width: 70, alignment: .leading)
            Text("Uses")
                .frame(width: 36, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func colorSpaceRow(_ cs: ColorSpaceFeature) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                if cs.isDeviceDependent {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
                Text(cs.name)
                    .font(.system(size: 10))
                    .foregroundStyle(cs.isDeviceDependent ? Color.orange : Color.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(cs.type.rawValue)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text("\(cs.usageCount)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(cs.isDeviceDependent ? Color.orange.opacity(0.05) : Color.clear)
        .accessibilityLabel(
            "\(cs.name), \(cs.type.rawValue), \(cs.usageCount) uses\(cs.isDeviceDependent ? ", device-dependent" : "")"
        )
    }

    // MARK: - Annotations Tab

    private var annotationsTab: some View {
        Group {
            if viewModel.annotations.isEmpty {
                emptyTabView(icon: "note.text", message: "No annotations detected")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        annotationHeaderRow
                        Divider()
                        ForEach(viewModel.annotations) { annotation in
                            annotationRow(annotation)
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var annotationHeaderRow: some View {
        HStack(spacing: 8) {
            Text("Type")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Accessible")
                .frame(width: 60, alignment: .center)
            Text("Page")
                .frame(width: 36, alignment: .trailing)
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func annotationRow(_ annotation: AnnotationFeature) -> some View {
        HStack(spacing: 8) {
            Text(annotation.type)
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: annotation.hasAccessibleName ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(annotation.hasAccessibleName ? .green : .orange)
                .frame(width: 60, alignment: .center)

            Text("\(annotation.pageIndex + 1)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .accessibilityLabel(
            "\(annotation.type), \(annotation.hasAccessibleName ? "accessible" : "not accessible"), page \(annotation.pageIndex + 1)"
        )
    }

    // MARK: - Empty States

    private func emptyTabView(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noDocumentView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Features")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Open a PDF to extract features.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var extractingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)

            Text("Extracting Features...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Analyzing fonts, images, color spaces, and annotations.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notExtractedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Features Not Extracted")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Feature extraction will run automatically.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button("Extract Features") {
                Task {
                    if let url = documentModel.url {
                        await viewModel.extractFeatures(from: url)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadFeatures() {
        guard documentModel.isDocumentLoaded,
              let url = documentModel.url else {
            viewModel.clearFeatures()
            return
        }

        Task {
            await viewModel.extractFeatures(from: url)
        }
    }
}

// MARK: - FeatureTab

/// The sub-tabs within the feature panel.
enum FeatureTab: String, CaseIterable, Identifiable {
    case fonts
    case images
    case colorSpaces
    case annotations

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fonts: "Fonts"
        case .images: "Images"
        case .colorSpaces: "Colors"
        case .annotations: "Annots"
        }
    }

    var icon: String {
        switch self {
        case .fonts: "textformat"
        case .images: "photo"
        case .colorSpaces: "paintpalette"
        case .annotations: "note.text"
        }
    }
}

// MARK: - Previews

#Preview("Feature Panel") {
    FeaturePanel()
        .environment(DocumentViewModel())
        .environment(PDFDocumentModel())
        .frame(width: 300, height: 500)
}
