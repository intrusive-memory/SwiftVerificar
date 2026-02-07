//
//  FeatureViewModel.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import Foundation
import PDFKit

// MARK: - Feature Model Types

/// A font found in the PDF document.
struct FontFeature: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let type: FontType
    let isEmbedded: Bool
    let usedOnPages: [Int]

    /// The type classification of a PDF font.
    enum FontType: String, Sendable, CaseIterable {
        case type1 = "Type1"
        case trueType = "TrueType"
        case cid = "CID"
        case type3 = "Type3"
        case openType = "OpenType"
        case unknown = "Unknown"
    }
}

/// An image found in the PDF document.
struct ImageFeature: Identifiable, Sendable, Equatable {
    let id: String
    let width: Int
    let height: Int
    let colorSpace: String
    let hasAltText: Bool
    let pageIndex: Int

    /// Formatted dimensions string (e.g. "640 x 480").
    var dimensionsLabel: String {
        "\(width) x \(height)"
    }
}

/// A color space used in the PDF document.
struct ColorSpaceFeature: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let type: ColorSpaceType
    let usageCount: Int

    /// Whether this color space is device-dependent (a PDF/A concern).
    var isDeviceDependent: Bool {
        type.isDeviceDependent
    }

    /// The type classification of a PDF color space.
    enum ColorSpaceType: String, Sendable, CaseIterable {
        case deviceRGB = "DeviceRGB"
        case deviceCMYK = "DeviceCMYK"
        case deviceGray = "DeviceGray"
        case iccBased = "ICCBased"
        case calRGB = "CalRGB"
        case calGray = "CalGray"
        case lab = "Lab"
        case indexed = "Indexed"
        case separation = "Separation"
        case deviceN = "DeviceN"
        case pattern = "Pattern"
        case unknown = "Unknown"

        /// Whether this color space type is device-dependent.
        var isDeviceDependent: Bool {
            switch self {
            case .deviceRGB, .deviceCMYK, .deviceGray:
                return true
            default:
                return false
            }
        }
    }
}

/// An annotation found in the PDF document.
struct AnnotationFeature: Identifiable, Sendable, Equatable {
    let id: String
    let type: String
    let pageIndex: Int
    let hasAccessibleName: Bool
}

/// Summary statistics for all extracted features.
struct FeatureSummary: Sendable, Equatable {
    let totalFonts: Int
    let totalImages: Int
    let totalColorSpaces: Int
    let totalAnnotations: Int
    let nonEmbeddedFontCount: Int
    let imagesWithoutAltTextCount: Int
    let deviceDependentColorSpaceCount: Int
    let annotationsWithoutAccessibleNameCount: Int
}

// MARK: - FeatureViewModel

/// View model managing extracted PDF feature data for the Feature panel.
///
/// `FeatureViewModel` processes PDF documents to extract inventories of fonts,
/// images, color spaces, and annotations. It provides computed summary statistics
/// and highlights potential accessibility and compliance concerns.
///
/// This type is implicitly @MainActor due to project build settings
/// (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
@Observable
final class FeatureViewModel {

    // MARK: - Feature Data

    /// All fonts found in the document.
    var fonts: [FontFeature] = []

    /// All images found in the document.
    var images: [ImageFeature] = []

    /// All color spaces found in the document.
    var colorSpaces: [ColorSpaceFeature] = []

    /// All annotations found in the document.
    var annotations: [AnnotationFeature] = []

    /// Whether feature extraction is in progress.
    var isExtracting: Bool = false

    /// Whether features have been extracted for the current document.
    var hasExtractedFeatures: Bool = false

    // MARK: - Computed Properties

    /// Summary statistics across all feature categories.
    var summary: FeatureSummary {
        FeatureSummary(
            totalFonts: fonts.count,
            totalImages: images.count,
            totalColorSpaces: colorSpaces.count,
            totalAnnotations: annotations.count,
            nonEmbeddedFontCount: fonts.filter { !$0.isEmbedded }.count,
            imagesWithoutAltTextCount: images.filter { !$0.hasAltText }.count,
            deviceDependentColorSpaceCount: colorSpaces.filter { $0.isDeviceDependent }.count,
            annotationsWithoutAccessibleNameCount: annotations.filter { !$0.hasAccessibleName }.count
        )
    }

    // MARK: - Feature Extraction

    /// Extracts features from a PDF document at the given URL.
    ///
    /// Since SwiftVerificar-biblioteca v0.1.0 has stub implementations, this
    /// method currently extracts features directly from PDFKit. When real
    /// biblioteca implementations are available, this will delegate to the
    /// validation service's feature extraction pipeline.
    ///
    /// - Parameter url: The file URL of the PDF document.
    func extractFeatures(from url: URL) async {
        isExtracting = true
        defer {
            isExtracting = false
            hasExtractedFeatures = true
        }

        guard let document = PDFDocument(url: url) else { return }
        extractFeaturesFromDocument(document)
    }

    /// Extracts features directly from a PDFDocument instance.
    ///
    /// - Parameter document: The PDFDocument to analyze.
    func extractFeaturesFromDocument(_ document: PDFDocument) {
        var extractedFonts: [String: FontFeature] = [:]
        var extractedImages: [ImageFeature] = []
        var extractedColorSpaces: [String: Int] = [:]
        var extractedAnnotations: [AnnotationFeature] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            // Extract annotations from this page
            for annotation in page.annotations {
                let annotationType = annotation.type ?? "Unknown"
                let hasName = annotation.fieldName != nil && !(annotation.fieldName?.isEmpty ?? true)
                    || annotation.toolTip != nil && !(annotation.toolTip?.isEmpty ?? true)

                extractedAnnotations.append(AnnotationFeature(
                    id: "annot-\(pageIndex)-\(extractedAnnotations.count)",
                    type: annotationType,
                    pageIndex: pageIndex,
                    hasAccessibleName: hasName
                ))
            }

            // Extract font and image info from the page string (basic heuristic)
            // Real extraction would use the biblioteca parser; for now we inspect
            // the page's attributed string for font references.
            if let pageString = page.attributedString {
                let fullRange = NSRange(location: 0, length: pageString.length)
                pageString.enumerateAttribute(.font, in: fullRange, options: []) { value, _, _ in
                    if let font = value as? NSFont {
                        let fontName = font.fontName
                        if var existing = extractedFonts[fontName] {
                            if !existing.usedOnPages.contains(pageIndex) {
                                let updatedPages = existing.usedOnPages + [pageIndex]
                                extractedFonts[fontName] = FontFeature(
                                    id: existing.id,
                                    name: existing.name,
                                    type: existing.type,
                                    isEmbedded: existing.isEmbedded,
                                    usedOnPages: updatedPages
                                )
                            }
                        } else {
                            let fontType = FeatureExtractionHelper.classifyFontType(fontName)
                            extractedFonts[fontName] = FontFeature(
                                id: "font-\(extractedFonts.count)",
                                name: fontName,
                                type: fontType,
                                isEmbedded: FeatureExtractionHelper.isFontLikelyEmbedded(fontName),
                                usedOnPages: [pageIndex]
                            )
                        }
                    }
                }
            }
        }

        // Build color space features from document (heuristic based on detected patterns)
        // Real extraction would inspect the /ColorSpace entries in the PDF dictionaries.
        // For now we add common color spaces as placeholders if the document has content.
        if document.pageCount > 0 {
            extractedColorSpaces["DeviceRGB"] = document.pageCount
        }

        fonts = Array(extractedFonts.values).sorted { $0.name < $1.name }
        images = extractedImages
        annotations = extractedAnnotations
        colorSpaces = extractedColorSpaces.map { name, count in
            ColorSpaceFeature(
                id: "cs-\(name)",
                name: name,
                type: FeatureExtractionHelper.classifyColorSpaceType(name),
                usageCount: count
            )
        }.sorted { $0.name < $1.name }
    }

    /// Clears all extracted feature data.
    func clearFeatures() {
        fonts = []
        images = []
        colorSpaces = []
        annotations = []
        hasExtractedFeatures = false
    }

    /// Updates features from pre-built arrays (useful for testing and when
    /// biblioteca provides real extraction results).
    func updateFeatures(
        fonts: [FontFeature] = [],
        images: [ImageFeature] = [],
        colorSpaces: [ColorSpaceFeature] = [],
        annotations: [AnnotationFeature] = []
    ) {
        self.fonts = fonts
        self.images = images
        self.colorSpaces = colorSpaces
        self.annotations = annotations
        self.hasExtractedFeatures = true
    }
}

// MARK: - Feature Extraction Helper

/// Testable helper with classification and formatting logic for feature extraction.
enum FeatureExtractionHelper {

    /// Classifies a font name into a FontType category.
    ///
    /// Uses common font naming conventions to infer the type. This is a heuristic
    /// approach; real classification would use the /Subtype entry from the PDF font dictionary.
    ///
    /// - Parameter name: The font name to classify.
    /// - Returns: The classified font type.
    static func classifyFontType(_ name: String) -> FontFeature.FontType {
        let lowered = name.lowercased()
        if lowered.contains("truetype") || lowered.contains("-tt") {
            return .trueType
        }
        if lowered.contains("opentype") || lowered.contains("-otf") {
            return .openType
        }
        if lowered.contains("type1") || lowered.contains("-t1") {
            return .type1
        }
        if lowered.contains("type3") {
            return .type3
        }
        if lowered.contains("identity-h") || lowered.contains("identity-v") || lowered.contains("cid") {
            return .cid
        }
        // Common system fonts are generally TrueType/OpenType on macOS
        if lowered.hasPrefix(".") || lowered.contains("sfsans") || lowered.contains("sfpro")
            || lowered.contains("helvetica") || lowered.contains("arial") || lowered.contains("times") {
            return .trueType
        }
        return .unknown
    }

    /// Heuristic check for whether a font is likely embedded.
    ///
    /// Fonts with custom/subset names (containing a "+" separator typical of
    /// subset prefixes like "ABCDEF+FontName") are likely embedded. System fonts
    /// starting with "." are not embedded.
    ///
    /// - Parameter name: The font name to check.
    /// - Returns: True if the font is likely embedded.
    static func isFontLikelyEmbedded(_ name: String) -> Bool {
        // Subset prefix pattern: "ABCDEF+FontName"
        if name.contains("+") {
            return true
        }
        // System fonts starting with "." are not embedded
        if name.hasPrefix(".") {
            return false
        }
        // Default assumption: unknown, report as not embedded to flag for review
        return false
    }

    /// Classifies a color space name into a ColorSpaceType.
    ///
    /// - Parameter name: The color space name from the PDF.
    /// - Returns: The classified color space type.
    static func classifyColorSpaceType(_ name: String) -> ColorSpaceFeature.ColorSpaceType {
        switch name {
        case "DeviceRGB": return .deviceRGB
        case "DeviceCMYK": return .deviceCMYK
        case "DeviceGray": return .deviceGray
        case "ICCBased": return .iccBased
        case "CalRGB": return .calRGB
        case "CalGray": return .calGray
        case "Lab": return .lab
        case "Indexed": return .indexed
        case "Separation": return .separation
        case "DeviceN": return .deviceN
        case "Pattern": return .pattern
        default: return .unknown
        }
    }

    /// Formats a list of page indices as a human-readable page range string.
    ///
    /// - Parameter pages: Zero-based page indices.
    /// - Returns: A formatted string like "1, 2, 3" (1-based).
    static func formatPageList(_ pages: [Int]) -> String {
        if pages.isEmpty { return "None" }
        if pages.count > 5 {
            let first = pages.prefix(5).map { String($0 + 1) }.joined(separator: ", ")
            return "\(first)... (+\(pages.count - 5) more)"
        }
        return pages.map { String($0 + 1) }.joined(separator: ", ")
    }
}
