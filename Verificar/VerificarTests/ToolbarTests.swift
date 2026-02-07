//
//  ToolbarTests.swift
//  VerificarTests
//
//  Created by TOM STOVALL on 2/7/26.
//

import Testing
import PDFKit
@testable import Verificar

@Suite("Toolbar & Navigation Controls")
struct ToolbarTests {

    // MARK: - Zoom Level Clamping

    @Test("zoomIn increments zoom by 0.25")
    @MainActor
    func zoomInIncrements() {
        let model = PDFDocumentModel()
        model.zoomLevel = 1.0
        model.autoScalesEnabled = false

        model.zoomIn()

        #expect(model.zoomLevel == 1.25)
        #expect(model.autoScalesEnabled == false)
    }

    @Test("zoomOut decrements zoom by 0.25")
    @MainActor
    func zoomOutDecrements() {
        let model = PDFDocumentModel()
        model.zoomLevel = 1.0
        model.autoScalesEnabled = false

        model.zoomOut()

        #expect(model.zoomLevel == 0.75)
        #expect(model.autoScalesEnabled == false)
    }

    @Test("zoom level is clamped to minimum 0.25")
    @MainActor
    func zoomClampedToMin() {
        let model = PDFDocumentModel()

        model.setZoom(0.1)
        #expect(model.zoomLevel == PDFDocumentModel.minZoom)
        #expect(model.zoomLevel == 0.25)

        model.setZoom(-1.0)
        #expect(model.zoomLevel == 0.25)
    }

    @Test("zoom level is clamped to maximum 8.0")
    @MainActor
    func zoomClampedToMax() {
        let model = PDFDocumentModel()

        model.setZoom(10.0)
        #expect(model.zoomLevel == PDFDocumentModel.maxZoom)
        #expect(model.zoomLevel == 8.0)
    }

    @Test("zoomOut does not go below minimum")
    @MainActor
    func zoomOutDoesNotGoBelowMin() {
        let model = PDFDocumentModel()
        model.zoomLevel = 0.25

        model.zoomOut()

        // 0.25 - 0.25 = 0.0, clamped to 0.25
        #expect(model.zoomLevel == 0.25)
    }

    @Test("zoomIn does not exceed maximum")
    @MainActor
    func zoomInDoesNotExceedMax() {
        let model = PDFDocumentModel()
        model.zoomLevel = 8.0

        model.zoomIn()

        // 8.0 + 0.25 = 8.25, clamped to 8.0
        #expect(model.zoomLevel == 8.0)
    }

    @Test("zoomToActualSize resets to 100%")
    @MainActor
    func zoomToActualSize() {
        let model = PDFDocumentModel()
        model.zoomLevel = 2.5
        model.autoScalesEnabled = true

        model.zoomToActualSize()

        #expect(model.zoomLevel == 1.0)
        #expect(model.autoScalesEnabled == false)
        #expect(model.fitWidthRequested == false)
    }

    @Test("zoomToFit enables autoScales")
    @MainActor
    func zoomToFitEnablesAutoScales() {
        let model = PDFDocumentModel()
        model.autoScalesEnabled = false
        model.fitWidthRequested = true

        model.zoomToFit()

        #expect(model.autoScalesEnabled == true)
        #expect(model.fitWidthRequested == false)
    }

    @Test("zoomToWidth sets fitWidthRequested")
    @MainActor
    func zoomToWidthSetsFlag() {
        let model = PDFDocumentModel()
        model.autoScalesEnabled = true
        model.fitWidthRequested = false

        model.zoomToWidth()

        #expect(model.autoScalesEnabled == false)
        #expect(model.fitWidthRequested == true)
    }

    @Test("zoomPercentage computes correct integer")
    @MainActor
    func zoomPercentage() {
        let model = PDFDocumentModel()

        model.zoomLevel = 1.0
        #expect(model.zoomPercentage == 100)

        model.zoomLevel = 1.25
        #expect(model.zoomPercentage == 125)

        model.zoomLevel = 0.5
        #expect(model.zoomPercentage == 50)

        model.zoomLevel = 2.0
        #expect(model.zoomPercentage == 200)
    }

    // MARK: - Display Mode

    @Test("displayMode defaults to singlePageContinuous")
    @MainActor
    func defaultDisplayMode() {
        let model = PDFDocumentModel()
        #expect(model.displayMode == .singlePageContinuous)
    }

    @Test("displayMode can be changed to all supported modes")
    @MainActor
    func displayModeChanges() {
        let model = PDFDocumentModel()

        model.displayMode = .singlePage
        #expect(model.displayMode == .singlePage)

        model.displayMode = .twoUpContinuous
        #expect(model.displayMode == .twoUpContinuous)

        model.displayMode = .singlePageContinuous
        #expect(model.displayMode == .singlePageContinuous)
    }

    // MARK: - Search

    @Test("search sets searchText")
    @MainActor
    func searchSetsText() {
        let model = PDFDocumentModel()

        model.search("hello")

        #expect(model.searchText == "hello")
    }

    @Test("clearSearch resets search state")
    @MainActor
    func clearSearchResetsState() {
        let model = PDFDocumentModel()
        model.searchText = "hello"
        model.isSearching = true

        model.clearSearch()

        #expect(model.searchText == "")
        #expect(model.searchResults.isEmpty)
        #expect(model.isSearching == false)
    }

    @Test("search with empty string clears search")
    @MainActor
    func searchWithEmptyStringClears() {
        let model = PDFDocumentModel()
        model.searchText = "hello"
        model.isSearching = true

        model.search("")

        #expect(model.searchText == "")
        #expect(model.isSearching == false)
    }

    // MARK: - Close Resets New Properties

    @Test("close resets zoom, display mode, and search state")
    @MainActor
    func closeResetsNewProperties() {
        let model = PDFDocumentModel()

        // Set non-default values
        model.zoomLevel = 2.5
        model.autoScalesEnabled = false
        model.fitWidthRequested = true
        model.displayMode = .twoUpContinuous
        model.isSearching = true
        model.searchText = "test"

        model.close()

        #expect(model.zoomLevel == 1.0)
        #expect(model.autoScalesEnabled == true)
        #expect(model.fitWidthRequested == false)
        #expect(model.displayMode == .singlePageContinuous)
        #expect(model.isSearching == false)
        #expect(model.searchText == "")
        #expect(model.searchResults.isEmpty)
    }

    // MARK: - ViewModeOption

    @Test("ViewModeOption maps to correct PDFDisplayMode")
    func viewModeOptionMapping() {
        #expect(ViewModeOption.singlePage.pdfDisplayMode == .singlePage)
        #expect(ViewModeOption.continuous.pdfDisplayMode == .singlePageContinuous)
        #expect(ViewModeOption.twoUp.pdfDisplayMode == .twoUpContinuous)
    }

    @Test("ViewModeOption initializes from PDFDisplayMode")
    func viewModeOptionFromDisplayMode() {
        #expect(ViewModeOption(from: .singlePage) == .singlePage)
        #expect(ViewModeOption(from: .singlePageContinuous) == .continuous)
        #expect(ViewModeOption(from: .twoUpContinuous) == .twoUp)
        #expect(ViewModeOption(from: .twoUp) == .twoUp)
    }
}
