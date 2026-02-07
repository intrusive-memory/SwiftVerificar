# Verificar — Detailed Component Specifications

This file provides exact property names, method signatures, view layouts, and SwiftVerificar API usage patterns for each component. Sprint agents should consult this alongside EXECUTION_PLAN.md.

---

## Models

### PDFDocumentModel

```swift
import PDFKit
import Observation

@Observable
@MainActor
final class PDFDocumentModel {
    // MARK: - Document State
    var pdfDocument: PDFDocument?
    var url: URL?
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Navigation
    var currentPageIndex: Int = 0
    var zoomLevel: CGFloat = 1.0
    var displayMode: PDFDisplayMode = .singlePageContinuous

    // MARK: - Search
    var isSearching: Bool = false
    var searchText: String = ""
    var searchResults: [PDFSelection] = []

    // MARK: - Computed
    var pageCount: Int { pdfDocument?.pageCount ?? 0 }
    var currentPage: PDFPage? { pdfDocument?.page(at: currentPageIndex) }
    var title: String { /* from document attributes or filename */ }
    var outlineRoot: PDFOutline? { pdfDocument?.outlineRoot }
    var hasOutline: Bool { outlineRoot != nil && (outlineRoot?.numberOfChildren ?? 0) > 0 }

    // MARK: - Document Operations
    func open(url: URL) async throws
    func close()

    // MARK: - Navigation
    func goToPage(_ index: Int)
    func nextPage()
    func previousPage()
    func navigateToDestination(_ destination: PDFDestination)

    // MARK: - Zoom
    func zoomIn()       // increment by 0.25
    func zoomOut()      // decrement by 0.25
    func zoomToFit()    // autoScales = true
    func zoomToWidth()  // scale to fit width
    func setZoom(_ level: CGFloat)

    // MARK: - Search
    func search(_ text: String)
    func clearSearch()
}
```

### OutlineNode

```swift
struct OutlineNode: Identifiable {
    let id = UUID()
    let label: String
    let destination: PDFDestination?
    let children: [OutlineNode]
    var isExpanded: Bool = false

    static func buildTree(from outline: PDFOutline) -> [OutlineNode]
}
```

### ValidationState

```swift
struct ValidationSummary: Sendable {
    let totalRules: Int
    let passedCount: Int
    let failedCount: Int
    let warningCount: Int
    let notApplicableCount: Int
    let profileName: String
    let duration: TimeInterval

    var passRate: Double { /* passedCount / totalRules */ }
    var complianceStatus: ComplianceStatus
}

struct ViolationItem: Identifiable, Sendable {
    let id: String           // rule ID + location hash
    let ruleID: String
    let severity: ViolationSeverity
    let message: String
    let description: String
    let pageIndex: Int?
    let objectType: String?
    let context: String?
    let wcagCriterion: String?    // e.g., "1.1.1"
    let wcagPrinciple: String?    // e.g., "Perceivable"
    let wcagLevel: String?        // e.g., "A", "AA", "AAA"
    let specification: String?    // e.g., "PDF/UA-2 clause 7.1"
    let remediation: String?
}

enum ViolationSeverity: String, CaseIterable, Sendable {
    case error = "Error"
    case warning = "Warning"
    case info = "Info"

    var icon: String {
        switch self {
        case .error: "xmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .error: .red
        case .warning: .orange
        case .info: .blue
        }
    }
}

enum ComplianceStatus: Sendable {
    case conformant
    case nonConformant(errors: Int)
    case unknown
    case inProgress
    case notValidated
}
```

### StructureNodeModel

```swift
struct StructureNodeModel: Identifiable {
    let id = UUID()
    let type: String          // "H1", "P", "Figure", "Table", etc.
    let title: String?
    let altText: String?
    let language: String?
    let pageIndex: Int?
    let children: [StructureNodeModel]
    let hasViolation: Bool

    var icon: String {
        switch type.lowercased() {
        case "h1", "h2", "h3", "h4", "h5", "h6": "text.heading"
        case "p", "span":                          "text.alignleft"
        case "figure":                              "photo"
        case "table":                               "tablecells"
        case "list", "l":                           "list.bullet"
        case "link":                                "link"
        case "form":                                "rectangle.and.pencil.and.ellipsis"
        case "document":                            "doc"
        case "section", "div", "part", "article":   "rectangle.split.3x1"
        default:                                    "tag"
        }
    }

    var displayLabel: String {
        if let title { return "\(type) — \(title)" }
        if let altText { return "\(type) [alt: \(altText)]" }
        return type
    }
}
```

---

## ViewModels

### DocumentViewModel

```swift
@Observable
@MainActor
final class DocumentViewModel {
    let documentModel = PDFDocumentModel()
    let validationService = ValidationService()
    let validationViewModel = ValidationViewModel()
    let structureTreeViewModel = StructureTreeViewModel()
    let featureViewModel = FeatureViewModel()

    var selectedProfile: String = "PDF/UA-2"
    var autoValidateOnOpen: Bool = true

    func openDocument(at url: URL) async {
        try? await documentModel.open(url: url)
        if autoValidateOnOpen {
            await validate()
        }
    }

    func validate() async {
        guard let url = documentModel.url else { return }
        await validationService.validate(url: url, profile: selectedProfile)
        // Map results to view models
        validationViewModel.updateViolations(from: validationService.lastResult)
        structureTreeViewModel.buildTree(from: validationService.lastResult)
        featureViewModel.extractFeatures(from: validationService.lastResult)
    }

    func revalidate() async { await validate() }

    func selectViolation(_ violation: ViolationItem) {
        if let pageIndex = violation.pageIndex {
            documentModel.goToPage(pageIndex)
        }
        validationViewModel.selectedViolation = violation
    }
}
```

### ValidationViewModel

```swift
@Observable
@MainActor
final class ValidationViewModel {
    var violations: [ViolationItem] = []
    var selectedViolation: ViolationItem?
    var filterSeverity: ViolationSeverity?
    var searchText: String = ""
    var groupBy: GroupingMode = .severity

    enum GroupingMode: String, CaseIterable {
        case none = "None"
        case severity = "Severity"
        case category = "Category"
        case page = "Page"
    }

    var filteredViolations: [ViolationItem] {
        violations
            .filter { item in
                if let severity = filterSeverity { return item.severity == severity }
                return true
            }
            .filter { item in
                if searchText.isEmpty { return true }
                return item.message.localizedCaseInsensitiveContains(searchText)
                    || item.ruleID.localizedCaseInsensitiveContains(searchText)
            }
    }

    var groupedViolations: [(String, [ViolationItem])] { /* group by groupBy mode */ }

    var summary: ValidationSummary? { /* computed from violations */ }

    func updateViolations(from result: ValidationResult?) { /* map SwiftVerificar types */ }
}
```

### StructureTreeViewModel

```swift
@Observable
@MainActor
final class StructureTreeViewModel {
    var rootNodes: [StructureNodeModel] = []
    var selectedNode: StructureNodeModel?
    var searchText: String = ""
    var isTreeAvailable: Bool = false

    // Statistics
    var totalElements: Int { /* count recursively */ }
    var headingCount: Int { /* count H1-H6 */ }
    var figureCount: Int { /* count Figure */ }
    var tableCount: Int { /* count Table */ }

    func buildTree(from result: ValidationResult?) { /* map structure tree */ }

    var filteredNodes: [StructureNodeModel] {
        if searchText.isEmpty { return rootNodes }
        // Filter tree keeping matching nodes and their ancestors
    }
}
```

### FeatureViewModel

```swift
@Observable
@MainActor
final class FeatureViewModel {
    var fonts: [FontFeature] = []
    var images: [ImageFeature] = []
    var colorSpaces: [ColorSpaceFeature] = []
    var annotations: [AnnotationFeature] = []

    struct FontFeature: Identifiable {
        let id = UUID()
        let name: String
        let type: String        // "Type1", "TrueType", "CID", "Type0"
        let isEmbedded: Bool
        let usedOnPages: [Int]
    }

    struct ImageFeature: Identifiable {
        let id = UUID()
        let width: Int
        let height: Int
        let colorSpace: String
        let hasAltText: Bool
        let pageIndex: Int
    }

    struct ColorSpaceFeature: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let usageCount: Int
    }

    struct AnnotationFeature: Identifiable {
        let id = UUID()
        let type: String
        let pageIndex: Int
        let hasAccessibleName: Bool
    }

    func extractFeatures(from result: ValidationResult?) { /* map feature data */ }
}
```

---

## Services

### ValidationService

```swift
import SwiftVerificarBiblioteca

@Observable
final class ValidationService: Sendable {
    var isValidating: Bool = false
    var progress: Double = 0.0
    var lastResult: ValidationResult?
    var error: Error?

    private var validationTask: Task<Void, Never>?

    func validate(url: URL) async {
        isValidating = true
        progress = 0.0
        error = nil
        do {
            let result = try await SwiftVerificar.shared.validateAccessibility(url)
            lastResult = result
        } catch {
            self.error = error
        }
        isValidating = false
        progress = 1.0
    }

    func validate(url: URL, profile: String) async {
        isValidating = true
        do {
            let result = try await SwiftVerificar.shared.validate(url, profile: profile)
            lastResult = result
        } catch {
            self.error = error
        }
        isValidating = false
    }

    func cancelValidation() {
        validationTask?.cancel()
        validationTask = nil
        isValidating = false
    }
}
```

### ReportExporter

```swift
struct ReportExporter {
    func exportJSON(summary: ValidationSummary, violations: [ViolationItem]) throws -> Data {
        // Structured JSON with summary + violations array
        // Use JSONEncoder with .prettyPrinted
    }

    func exportHTML(summary: ValidationSummary, violations: [ViolationItem]) -> String {
        // Styled HTML report:
        // - Header with document name and date
        // - Summary table (pass/fail/warning counts)
        // - Standards identification
        // - Violations table grouped by severity
        // - Footer with tool version
    }

    func exportText(summary: ValidationSummary, violations: [ViolationItem]) -> String {
        // Plain text summary:
        // Document: filename.pdf
        // Profile: PDF/UA-2
        // Result: 42 violations (28 errors, 10 warnings, 4 info)
        // ...violations list...
    }
}
```

---

## View Layouts

### ContentView (Three-Column)

```
┌─────────────┬─────────────────────────┬──────────────────────┐
│  Sidebar    │     Content             │   Inspector          │
│  (180-250)  │     (flexible)          │   (280-400)          │
│             │                         │                      │
│ [Thumbnails]│  ┌───────────────────┐  │ [Standards|Violations│
│ [Outline  ] │  │                   │  │  |Structure|Features]│
│             │  │   PDFView         │  │                      │
│ ┌─────────┐ │  │                   │  │  Tab content here    │
│ │ Page 1  │ │  │   (scrollable,    │  │                      │
│ │ [thumb] │ │  │    zoomable)      │  │                      │
│ ├─────────┤ │  │                   │  │                      │
│ │ Page 2  │ │  │                   │  │                      │
│ │ [thumb] │ │  └───────────────────┘  │                      │
│ ├─────────┤ │                         │                      │
│ │ Page 3  │ │  ┌───────────────────┐  │                      │
│ │ [thumb] │ │  │ Page 3 of 12      │  │                      │
│ └─────────┘ │  │ Zoom: 125%        │  │                      │
│             │  └───────────────────┘  │                      │
└─────────────┴─────────────────────────┴──────────────────────┘
```

### Toolbar Layout

```
[◀ ▶] [Page 3 of 12] [GoTo] | [🔍-] [100%] [🔍+] [Fit] | [Single|Continuous|2-Up] | [🔍 Search...] | [Validate]
```

### Standards Panel Layout

```
┌─────────────────────────────────┐
│  ✅ Conformant / ❌ Non-conformant  │
│  Profile: PDF/UA-2              │
│                                 │
│  ═══════════════════════════    │
│  ████████░░░░  75% passed       │
│  Passed: 150 | Failed: 12      │
│  Warnings: 8 | N/A: 30         │
│                                 │
│  ── Standards Identification ── │
│  PDF/A: 2b (ISO 19005-2)       │
│  PDF/UA: 2 (ISO 14289-2)       │
│  WCAG: 2.1 Level AA            │
│                                 │
│  ── Document Metadata ──────── │
│  Title: Annual Report 2025     │
│  Author: Jane Doe              │
│  Created: 2025-01-15           │
│  Producer: Adobe Acrobat       │
│  PDF Version: 2.0              │
│                                 │
│  [▼ Select Profile] [Validate] │
└─────────────────────────────────┘
```

### Violations List Layout

```
┌─────────────────────────────────┐
│ [All|Errors|Warnings|Info] 🔍   │
│ 42 violations (28/10/4)         │
│                                 │
│ ▼ Errors (28)                   │
│ ┌─────────────────────────────┐ │
│ │ 🔴 Rule 7.1-001      p.3   │ │
│ │ Figure missing alt text     │ │
│ │ WCAG 1.1.1 · Level A       │ │
│ ├─────────────────────────────┤ │
│ │ 🔴 Rule 7.2-003      p.5   │ │
│ │ Table missing headers       │ │
│ │ WCAG 1.3.1 · Level A       │ │
│ └─────────────────────────────┘ │
│                                 │
│ ▼ Warnings (10)                 │
│ ┌─────────────────────────────┐ │
│ │ 🟡 Rule 8.1-002      p.1   │ │
│ │ Low contrast ratio (3.8:1)  │ │
│ │ WCAG 1.4.3 · Level AA      │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Structure Tree Layout

```
┌─────────────────────────────────┐
│ 🔍 Search structure tree...     │
│ Elements: 245 | H: 12 | Fig: 8 │
│                                 │
│ ▼ 📄 Document                   │
│   ▼ 📑 Section                  │
│     ▶ 🔤 H1 — "Introduction"   │
│     ▶ 📝 P                      │
│     ▶ 📝 P                      │
│     ▼ 📑 Section                │
│       ▶ 🔤 H2 — "Background"   │
│       ▶ 📝 P                    │
│       ▼ 🖼️ Figure [alt: ...]    │
│       ▶ 📊 Table                │
│     ▶ 📑 Section                │
│       ▶ 🔤 H2 — "Results"      │
│       ▶ 📝 P                    │
│                                 │
└─────────────────────────────────┘
```

---

## PDFViewRepresentable Details

```swift
struct PDFViewRepresentable: NSViewRepresentable {
    @Bindable var documentModel: PDFDocumentModel
    var violationAnnotations: [ViolationAnnotationData] = []
    var showViolationHighlights: Bool = true
    var onPageChange: ((Int) -> Void)?

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator

        // Register for page change notifications
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Update document
        if pdfView.document !== documentModel.pdfDocument {
            pdfView.document = documentModel.pdfDocument
        }

        // Update display mode
        pdfView.displayMode = documentModel.displayMode

        // Update zoom
        pdfView.scaleFactor = documentModel.zoomLevel

        // Update page
        if let page = documentModel.currentPage,
           pdfView.currentPage !== page {
            pdfView.go(to: page)
        }

        // Update violation annotations
        // (add/remove PDFAnnotation objects on pages)
    }

    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFViewRepresentable

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            parent.documentModel.currentPageIndex = pageIndex
        }
    }
}
```

---

## Info.plist — PDF Document Type Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>com.adobe.pdf</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

---

## Keyboard Shortcuts Reference

| Shortcut | Action |
|----------|--------|
| `Cmd+O` | Open PDF |
| `Cmd+W` | Close document |
| `Cmd+=` / `Cmd++` | Zoom in |
| `Cmd+-` | Zoom out |
| `Cmd+0` | Actual size (100%) |
| `Cmd+9` | Zoom to fit |
| `Cmd+F` | Find/Search |
| `Cmd+G` | Find next |
| `Cmd+Shift+G` | Find previous |
| `Opt+Cmd+P` | Go to page |
| `Cmd+Opt+1` | Toggle sidebar |
| `Cmd+Opt+2` | Toggle inspector |
| `Cmd+Shift+V` | Re-validate |
| `Cmd+Shift+E` | Export report |
| `Cmd+,` | Preferences |
| `Left/Right Arrow` | Previous/Next page (single page mode) |
| `Home` | Go to first page |
| `End` | Go to last page |
