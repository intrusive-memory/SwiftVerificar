import Testing
import Foundation
@testable import Verificar

// MARK: - FeatureViewModel Tests

@Suite("FeatureViewModel")
struct FeatureViewModelTests {

    // MARK: - Test Data

    private static func makeSampleFonts() -> [FontFeature] {
        [
            FontFeature(
                id: "font-0",
                name: "Helvetica",
                type: .trueType,
                isEmbedded: false,
                usedOnPages: [0, 1, 2]
            ),
            FontFeature(
                id: "font-1",
                name: "ABCDEF+CustomFont",
                type: .type1,
                isEmbedded: true,
                usedOnPages: [0]
            ),
            FontFeature(
                id: "font-2",
                name: "TimesNewRoman",
                type: .trueType,
                isEmbedded: true,
                usedOnPages: [1, 2]
            ),
        ]
    }

    private static func makeSampleImages() -> [ImageFeature] {
        [
            ImageFeature(id: "img-0", width: 640, height: 480, colorSpace: "DeviceRGB", hasAltText: true, pageIndex: 0),
            ImageFeature(id: "img-1", width: 1920, height: 1080, colorSpace: "ICCBased", hasAltText: false, pageIndex: 1),
            ImageFeature(id: "img-2", width: 100, height: 100, colorSpace: "DeviceGray", hasAltText: false, pageIndex: 2),
        ]
    }

    private static func makeSampleColorSpaces() -> [ColorSpaceFeature] {
        [
            ColorSpaceFeature(id: "cs-0", name: "DeviceRGB", type: .deviceRGB, usageCount: 5),
            ColorSpaceFeature(id: "cs-1", name: "ICCBased", type: .iccBased, usageCount: 3),
            ColorSpaceFeature(id: "cs-2", name: "DeviceCMYK", type: .deviceCMYK, usageCount: 1),
        ]
    }

    private static func makeSampleAnnotations() -> [AnnotationFeature] {
        [
            AnnotationFeature(id: "annot-0", type: "Link", pageIndex: 0, hasAccessibleName: true),
            AnnotationFeature(id: "annot-1", type: "Widget", pageIndex: 1, hasAccessibleName: false),
            AnnotationFeature(id: "annot-2", type: "Text", pageIndex: 0, hasAccessibleName: true),
            AnnotationFeature(id: "annot-3", type: "Link", pageIndex: 2, hasAccessibleName: false),
        ]
    }

    // MARK: - Initial State Tests

    @Test("FeatureViewModel initializes with empty state")
    func initialState() {
        let vm = FeatureViewModel()

        #expect(vm.fonts.isEmpty)
        #expect(vm.images.isEmpty)
        #expect(vm.colorSpaces.isEmpty)
        #expect(vm.annotations.isEmpty)
        #expect(!vm.isExtracting)
        #expect(!vm.hasExtractedFeatures)
    }

    // MARK: - Summary Statistics Tests

    @Test("Summary computes correct totals from all categories")
    func summaryComputesCorrectTotals() {
        let vm = FeatureViewModel()
        vm.updateFeatures(
            fonts: Self.makeSampleFonts(),
            images: Self.makeSampleImages(),
            colorSpaces: Self.makeSampleColorSpaces(),
            annotations: Self.makeSampleAnnotations()
        )

        let summary = vm.summary

        #expect(summary.totalFonts == 3)
        #expect(summary.totalImages == 3)
        #expect(summary.totalColorSpaces == 3)
        #expect(summary.totalAnnotations == 4)
    }

    @Test("Summary computes correct warning counts")
    func summaryComputesCorrectWarnings() {
        let vm = FeatureViewModel()
        vm.updateFeatures(
            fonts: Self.makeSampleFonts(),
            images: Self.makeSampleImages(),
            colorSpaces: Self.makeSampleColorSpaces(),
            annotations: Self.makeSampleAnnotations()
        )

        let summary = vm.summary

        // 1 non-embedded font (Helvetica)
        #expect(summary.nonEmbeddedFontCount == 1)
        // 2 images without alt text
        #expect(summary.imagesWithoutAltTextCount == 2)
        // 2 device-dependent color spaces (DeviceRGB, DeviceCMYK)
        #expect(summary.deviceDependentColorSpaceCount == 2)
        // 2 annotations without accessible name
        #expect(summary.annotationsWithoutAccessibleNameCount == 2)
    }

    @Test("Summary produces zero counts when no features")
    func summaryZeroWhenEmpty() {
        let vm = FeatureViewModel()

        let summary = vm.summary

        #expect(summary.totalFonts == 0)
        #expect(summary.totalImages == 0)
        #expect(summary.totalColorSpaces == 0)
        #expect(summary.totalAnnotations == 0)
        #expect(summary.nonEmbeddedFontCount == 0)
        #expect(summary.imagesWithoutAltTextCount == 0)
        #expect(summary.deviceDependentColorSpaceCount == 0)
        #expect(summary.annotationsWithoutAccessibleNameCount == 0)
    }

    // MARK: - Update & Clear Tests

    @Test("updateFeatures sets data and marks hasExtractedFeatures")
    func updateFeaturesSetsData() {
        let vm = FeatureViewModel()

        vm.updateFeatures(
            fonts: Self.makeSampleFonts(),
            images: Self.makeSampleImages()
        )

        #expect(vm.fonts.count == 3)
        #expect(vm.images.count == 3)
        #expect(vm.colorSpaces.isEmpty)
        #expect(vm.annotations.isEmpty)
        #expect(vm.hasExtractedFeatures)
    }

    @Test("clearFeatures resets all data and hasExtractedFeatures")
    func clearFeaturesResetsAll() {
        let vm = FeatureViewModel()
        vm.updateFeatures(
            fonts: Self.makeSampleFonts(),
            images: Self.makeSampleImages(),
            colorSpaces: Self.makeSampleColorSpaces(),
            annotations: Self.makeSampleAnnotations()
        )

        vm.clearFeatures()

        #expect(vm.fonts.isEmpty)
        #expect(vm.images.isEmpty)
        #expect(vm.colorSpaces.isEmpty)
        #expect(vm.annotations.isEmpty)
        #expect(!vm.hasExtractedFeatures)
    }

    // MARK: - Feature Categorization Tests

    @Test("FontFeature.FontType covers expected PDF font types")
    func fontTypeCoverage() {
        let allTypes = FontFeature.FontType.allCases
        #expect(allTypes.count == 6)
        #expect(allTypes.contains(.type1))
        #expect(allTypes.contains(.trueType))
        #expect(allTypes.contains(.cid))
        #expect(allTypes.contains(.type3))
        #expect(allTypes.contains(.openType))
        #expect(allTypes.contains(.unknown))
    }

    @Test("ColorSpaceFeature.ColorSpaceType device-dependency detection")
    func colorSpaceDeviceDependency() {
        #expect(ColorSpaceFeature.ColorSpaceType.deviceRGB.isDeviceDependent)
        #expect(ColorSpaceFeature.ColorSpaceType.deviceCMYK.isDeviceDependent)
        #expect(ColorSpaceFeature.ColorSpaceType.deviceGray.isDeviceDependent)
        #expect(!ColorSpaceFeature.ColorSpaceType.iccBased.isDeviceDependent)
        #expect(!ColorSpaceFeature.ColorSpaceType.calRGB.isDeviceDependent)
        #expect(!ColorSpaceFeature.ColorSpaceType.lab.isDeviceDependent)
        #expect(!ColorSpaceFeature.ColorSpaceType.indexed.isDeviceDependent)
        #expect(!ColorSpaceFeature.ColorSpaceType.unknown.isDeviceDependent)
    }

    @Test("ImageFeature dimensionsLabel formats correctly")
    func imageDimensionsLabel() {
        let image = ImageFeature(id: "i1", width: 1920, height: 1080, colorSpace: "RGB", hasAltText: true, pageIndex: 0)
        #expect(image.dimensionsLabel == "1920 x 1080")
    }

    // MARK: - FeatureExtractionHelper Tests

    @Test("classifyFontType identifies TrueType fonts")
    func classifyFontTypeTrueType() {
        #expect(FeatureExtractionHelper.classifyFontType("ArialMT-TrueType") == .trueType)
        #expect(FeatureExtractionHelper.classifyFontType("Helvetica") == .trueType)
        #expect(FeatureExtractionHelper.classifyFontType(".SFUI-Regular") == .trueType)
    }

    @Test("classifyFontType identifies Type1 fonts")
    func classifyFontTypeType1() {
        #expect(FeatureExtractionHelper.classifyFontType("CourierNew-Type1") == .type1)
    }

    @Test("classifyFontType returns unknown for unrecognized names")
    func classifyFontTypeUnknown() {
        #expect(FeatureExtractionHelper.classifyFontType("MyCustomFont") == .unknown)
    }

    @Test("isFontLikelyEmbedded detects subset prefix")
    func isFontEmbeddedSubsetPrefix() {
        #expect(FeatureExtractionHelper.isFontLikelyEmbedded("ABCDEF+MyFont"))
        #expect(!FeatureExtractionHelper.isFontLikelyEmbedded(".SFNSText"))
        #expect(!FeatureExtractionHelper.isFontLikelyEmbedded("Helvetica"))
    }

    @Test("classifyColorSpaceType maps known names correctly")
    func classifyColorSpaceType() {
        #expect(FeatureExtractionHelper.classifyColorSpaceType("DeviceRGB") == .deviceRGB)
        #expect(FeatureExtractionHelper.classifyColorSpaceType("DeviceCMYK") == .deviceCMYK)
        #expect(FeatureExtractionHelper.classifyColorSpaceType("DeviceGray") == .deviceGray)
        #expect(FeatureExtractionHelper.classifyColorSpaceType("ICCBased") == .iccBased)
        #expect(FeatureExtractionHelper.classifyColorSpaceType("CalRGB") == .calRGB)
        #expect(FeatureExtractionHelper.classifyColorSpaceType("Lab") == .lab)
        #expect(FeatureExtractionHelper.classifyColorSpaceType("SomethingElse") == .unknown)
    }

    @Test("formatPageList formats page numbers correctly")
    func formatPageList() {
        #expect(FeatureExtractionHelper.formatPageList([]) == "None")
        #expect(FeatureExtractionHelper.formatPageList([0]) == "1")
        #expect(FeatureExtractionHelper.formatPageList([0, 1, 2]) == "1, 2, 3")
        #expect(FeatureExtractionHelper.formatPageList([0, 2, 4]) == "1, 3, 5")
    }

    @Test("formatPageList truncates long lists")
    func formatPageListTruncation() {
        let pages = [0, 1, 2, 3, 4, 5, 6, 7]
        let result = FeatureExtractionHelper.formatPageList(pages)
        #expect(result.contains("..."))
        #expect(result.contains("+3 more"))
    }

    // MARK: - FeatureTab Tests

    @Test("FeatureTab has correct cases and labels")
    func featureTabCases() {
        let tabs = FeatureTab.allCases
        #expect(tabs.count == 4)
        #expect(FeatureTab.fonts.label == "Fonts")
        #expect(FeatureTab.images.label == "Images")
        #expect(FeatureTab.colorSpaces.label == "Colors")
        #expect(FeatureTab.annotations.label == "Annots")
    }

    @Test("FeatureTab icons are non-empty")
    func featureTabIcons() {
        for tab in FeatureTab.allCases {
            #expect(!tab.icon.isEmpty)
        }
    }
}
