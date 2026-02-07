# Verificar macOS App — Execution Plan

> A native macOS PDF viewer and accessibility validator powered by SwiftVerificar.
> Replicates core Preview.app functionality with an integrated accessibility analysis panel.

---

## Section 1: Overview

**Verificar** is a document-based macOS application that:

1. Opens and renders PDFs using Apple's **PDFKit** framework
2. Provides a Preview.app-like viewing experience (zoom, scroll, search, thumbnails, outline)
3. Integrates **SwiftVerificar-biblioteca** to validate PDFs against PDF/A, PDF/UA, and WCAG standards
4. Displays an **Accessibility Inspector** panel showing standards compliance, violations, structure tree, and feature inventory

### Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Verificar.app                                │
├─────────────┬─────────────────────────┬──────────────────────────────┤
│  Sidebar    │     Content Area        │    Inspector Panel           │
│             │                         │                              │
│ Thumbnails  │   PDFKit PDFView        │  Standards Compliance        │
│    or       │   (NSViewRepresentable) │  Violations List             │
│ Outline     │                         │  Structure Tree              │
│             │                         │  Feature Inventory           │
├─────────────┴─────────────────────────┴──────────────────────────────┤
│                    SwiftVerificar-biblioteca                          │
│         ┌────────────┬──────────────┬───────────────┐                │
│         │  parser    │  validation  │  wcag-algs    │                │
│         │            │  profiles    │               │                │
│         └────────────┴──────────────┴───────────────┘                │
└──────────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

- **PDFKit for rendering** — Apple's native framework handles display, zoom, search, annotations. We do NOT use SwiftVerificar-parser for rendering.
- **SwiftVerificar for analysis** — biblioteca orchestrates parsing and validation in the background. Results feed the Inspector panel.
- **SwiftUI + NSViewRepresentable** — SwiftUI for layout and state management; NSViewRepresentable wraps PDFKit's PDFView (AppKit).
- **No SwiftData** — The template's SwiftData/Item model is removed. PDF documents are read-only; validation results are transient in-memory state.
- **macOS only** — Target macOS 14.0+ to match SwiftVerificar platform requirements. PDFKit on macOS is more capable than iOS.

---

## Section 2: Package & Dependency Graph

### 2.1 Target

| Target | Type | Directory | Scheme |
|--------|------|-----------|--------|
| Verificar | macOS App (.xcodeproj) | `Verificar/` | `Verificar` |

### 2.2 External Dependencies

| Dependency | Source | Version | Import Names |
|------------|--------|---------|-------------|
| SwiftVerificar-biblioteca | `https://github.com/intrusive-memory/SwiftVerificar-biblioteca.git` | `from: "0.1.0"` | `SwiftVerificarBiblioteca` |

> biblioteca transitively brings in parser, validation, validation-profiles, and wcag-algs. The app may directly import sub-packages for specific types.

### 2.3 Apple Frameworks Used

| Framework | Purpose |
|-----------|---------|
| PDFKit | PDF rendering, thumbnails, search, outline, annotations |
| SwiftUI | Application UI framework |
| UniformTypeIdentifiers | PDF document type registration |
| Combine | Reactive state management for validation pipeline |
| QuartzCore | PDF page thumbnail generation |

### 2.4 Sprint Layers

Since Verificar is a single target, sprints execute **sequentially** (each builds on the previous). Layers represent logical groupings:

| Layer | Sprints | Description |
|-------|---------|-------------|
| 0 — Foundation | 1–3 | Project setup, PDF rendering, layout shell |
| 1 — Core Viewer | 4–7 | Thumbnails, outline, toolbar, navigation |
| 2 — Validation Integration | 8–10 | SwiftVerificar wiring, validation state, standards panel |
| 3 — Inspector Views | 11–14 | Violations, structure tree, features, highlighting |
| 4 — Polish | 15–16 | Export, settings, tests |

---

## Section 3: Sprint Rules

### 3.1 Build & Test Commands

```bash
# Build
cd Verificar && xcodebuild build -scheme Verificar -destination 'platform=macOS'

# Test
cd Verificar && xcodebuild test -scheme Verificar -destination 'platform=macOS'
```

**CRITICAL**: NEVER use `swift build` or `swift test`. Always use `xcodebuild`.

### 3.2 Code Standards

- **Swift 6.0** with strict concurrency (`Sendable`, `@MainActor` for UI)
- **SwiftUI** for all views — no storyboards, no xibs
- **NSViewRepresentable** for PDFKit integration (PDFView is AppKit)
- **Swift Testing** (`import Testing`, `@Test`, `@Suite`) for unit tests — NOT XCTest
- **XCTest** for UI tests only (VerificarUITests target)
- All `@Observable` or `@ObservableObject` types for state
- No force-unwraps in production code
- Prefer `async/await` over completion handlers

### 3.3 Entry Checks (Before Writing Code)

1. Read `EXECUTION_PLAN.md` to understand the current sprint's requirements
2. Read `PROGRESS.md` (if it exists) to understand what's been completed
3. Read `TODO.md` for detailed component specifications
4. Verify the previous sprint's build passes:
   ```bash
   cd $PROJECT_ROOT/Verificar && xcodebuild build -scheme Verificar -destination 'platform=macOS' 2>&1 | tail -5
   ```
5. If the build fails, fix it before starting new work

### 3.4 Exit Checks (Before Committing)

1. **Build passes**: `xcodebuild build -scheme Verificar -destination 'platform=macOS'` exits 0
2. **Tests pass**: `xcodebuild test -scheme Verificar -destination 'platform=macOS'` exits 0
3. **No warnings**: Build has zero warnings (or only expected framework warnings)
4. **PROGRESS.md updated**: Record sprint completion, files created/modified, test count
5. **Commit**: Stage all new/modified files and commit with descriptive message

### 3.5 File Naming Conventions

| Category | Pattern | Example |
|----------|---------|---------|
| SwiftUI Views | `<Name>View.swift` | `PDFRenderView.swift` |
| View Models | `<Name>ViewModel.swift` | `ValidationViewModel.swift` |
| Models | `<Name>.swift` | `ValidationResult.swift` |
| NSViewRepresentable | `<Name>Representable.swift` | `PDFViewRepresentable.swift` |
| Coordinators | `<Name>Coordinator.swift` | `PDFViewCoordinator.swift` |
| Tests | `<Name>Tests.swift` | `ValidationViewModelTests.swift` |

### 3.6 Source Directory Structure

```
Verificar/Verificar/
├── App/
│   └── VerificarApp.swift              (app entry point)
├── Models/
│   ├── PDFDocumentModel.swift          (PDF document wrapper)
│   └── ValidationState.swift           (validation result state)
├── Views/
│   ├── ContentView.swift               (three-column layout root)
│   ├── PDF/
│   │   ├── PDFViewRepresentable.swift  (PDFKit NSViewRepresentable)
│   │   └── PDFRenderView.swift         (PDF display + controls)
│   ├── Sidebar/
│   │   ├── ThumbnailSidebarView.swift  (page thumbnails)
│   │   ├── OutlineSidebarView.swift    (document outline tree)
│   │   └── SidebarView.swift           (sidebar container with tab)
│   ├── Inspector/
│   │   ├── InspectorView.swift         (inspector container)
│   │   ├── StandardsPanel.swift        (compliance overview)
│   │   ├── ViolationsListView.swift    (violation list)
│   │   ├── ViolationDetailView.swift   (single violation detail)
│   │   ├── StructureTreeView.swift     (PDF structure tree)
│   │   └── FeaturePanel.swift          (feature extraction display)
│   └── Toolbar/
│       └── ToolbarContent.swift        (toolbar items)
├── ViewModels/
│   ├── DocumentViewModel.swift         (document state management)
│   └── ValidationViewModel.swift       (validation orchestration)
├── Services/
│   └── ValidationService.swift         (SwiftVerificar integration)
├── Utilities/
│   └── PDFKitExtensions.swift          (PDFKit convenience extensions)
└── Assets.xcassets/
```

---

## Section 4: Sprint Supervisor Configuration

### 4.1 Supervisor Parameters

```
max_retries: 3
max_turns: 50
subagent_type: general-purpose
packages: 1 (Verificar)
total_sprints: 16
```

### 4.2 Dispatch Template

```
You are working on the Verificar macOS app located at $PROJECT_ROOT/Verificar/.

FIRST, read these files in order:
1. $PROJECT_ROOT/Verificar/EXECUTION_PLAN.md (this plan)
2. $PROJECT_ROOT/Verificar/PROGRESS.md (if it exists)
3. $PROJECT_ROOT/Verificar/TODO.md (detailed component specs)

You are executing Sprint <N>: <SPRINT_NAME>.

Follow Section 3.3 (Entry Checks) before writing any code.
Create all views, models, and tests listed for Sprint <N> in Section 5.
Consult TODO.md for exact view layouts, property names, and SwiftVerificar API usage.
Follow Section 3.4 (Exit Checks) before committing.
Update PROGRESS.md and commit when all checks pass.

Build command: cd $PROJECT_ROOT/Verificar && xcodebuild build -scheme Verificar -destination 'platform=macOS'
Test command: cd $PROJECT_ROOT/Verificar && xcodebuild test -scheme Verificar -destination 'platform=macOS'

Do NOT start the next sprint. Your context ends after this sprint's commit.
```

---

## Section 5: Sprint Definitions

---

### Sprint 1: Project Cleanup & PDF Document Type Configuration

**Goal**: Remove Xcode template boilerplate, configure the project to open PDF files, and verify the clean build.

**Tasks**:
1. Delete `Verificar/Item.swift` (SwiftData model — not needed)
2. Create directory structure: `App/`, `Models/`, `Views/`, `Views/PDF/`, `Views/Sidebar/`, `Views/Inspector/`, `Views/Toolbar/`, `ViewModels/`, `Services/`, `Utilities/`
3. Rewrite `VerificarApp.swift`:
   - Remove SwiftData imports and migration plan
   - Remove `VerificarMigrationPlan` and `VerificarVersionedSchema`
   - Use `WindowGroup` (not DocumentGroup for now — we'll add document opening in Sprint 2)
   - Move to `App/VerificarApp.swift`
4. Update `Info.plist`:
   - Remove `com.example.item-document` UTType
   - Remove `UTImportedTypeDeclarations`
   - Add `CFBundleDocumentTypes` for PDF: `com.adobe.pdf` UTType, role `Viewer`
   - Add `NSDocumentClass` if needed
5. Rewrite `ContentView.swift`:
   - Remove SwiftData imports and `@Query`
   - Simple placeholder: `Text("Open a PDF to begin")`
   - Move to `Views/ContentView.swift`
6. Verify clean build passes

**Files Created/Modified**:
- `Verificar/App/VerificarApp.swift` (moved + rewritten)
- `Verificar/Views/ContentView.swift` (moved + rewritten)
- `Verificar/Info.plist` (updated)
- Delete: `Verificar/Item.swift`, `Verificar/VerificarApp.swift`, `Verificar/ContentView.swift`

**Tests**: Build verification only (no unit tests yet)

**Exit Criteria**: `xcodebuild build` passes with zero errors. App launches and shows placeholder text.

---

### Sprint 2: PDF Document Model & File Opening

**Goal**: Create a document model that can open PDF files, and wire file opening into the app.

**Tasks**:
1. Create `Models/PDFDocumentModel.swift`:
   - `@Observable class PDFDocumentModel` wrapping `PDFKit.PDFDocument`
   - Properties: `pdfDocument: PDFDocument?`, `url: URL?`, `pageCount: Int`, `currentPageIndex: Int`, `title: String`, `isLoading: Bool`
   - Method: `func open(url: URL) async throws`
   - Method: `func goToPage(_ index: Int)`
   - Computed: `var currentPage: PDFPage?`
2. Update `App/VerificarApp.swift`:
   - Add `@State var documentModel = PDFDocumentModel()`
   - Use `.fileImporter` modifier for Open dialog (PDF UTType filter)
   - Add File > Open menu command (`CommandGroup(replacing: .newItem)`)
   - Support opening PDFs via drag-and-drop
   - Pass documentModel into ContentView via environment
3. Update `Views/ContentView.swift`:
   - Accept `PDFDocumentModel` from environment
   - Show "Open a PDF" placeholder when no document loaded
   - Show document title when loaded
4. Add unit test: `VerificarTests/PDFDocumentModelTests.swift`
   - Test creating model
   - Test page count property
   - Test currentPageIndex bounds

**Files Created**:
- `Verificar/Models/PDFDocumentModel.swift`
- `VerificarTests/PDFDocumentModelTests.swift`

**Files Modified**:
- `Verificar/App/VerificarApp.swift`
- `Verificar/Views/ContentView.swift`

**Tests**: 3+ unit tests for PDFDocumentModel

**Exit Criteria**: Build passes. App can open a PDF file via File > Open. Tests pass.

---

### Sprint 3: PDFKit View Integration & Basic Rendering

**Goal**: Render PDF pages using PDFKit's PDFView wrapped in NSViewRepresentable.

**Tasks**:
1. Create `Views/PDF/PDFViewRepresentable.swift`:
   - `struct PDFViewRepresentable: NSViewRepresentable`
   - Configure `PDFView`: `autoScales = true`, `displayMode = .singlePageContinuous`, `displayDirection = .vertical`
   - Coordinator pattern for delegate callbacks (page change notifications)
   - Binding for `currentPageIndex` — sync PDFView page changes back to model
   - Accept `PDFDocument?` and set it on the view
2. Create `Views/PDF/PDFRenderView.swift`:
   - Container view wrapping `PDFViewRepresentable`
   - Overlay for loading state
   - Overlay for "No document" state
   - Pass through document model
3. Update `Views/ContentView.swift`:
   - Replace placeholder with `PDFRenderView` when document is loaded
   - Basic single-column layout (three-column comes in Sprint 4)
4. Add unit test: `VerificarTests/PDFViewRepresentableTests.swift`
   - Test NSView creation
   - Test document assignment

**Files Created**:
- `Verificar/Views/PDF/PDFViewRepresentable.swift`
- `Verificar/Views/PDF/PDFRenderView.swift`

**Files Modified**:
- `Verificar/Views/ContentView.swift`

**Tests**: 2+ unit tests

**Exit Criteria**: Build passes. Opening a PDF displays the rendered pages. Scrolling works.

---

### Sprint 4: Three-Column Layout Shell

**Goal**: Establish the NavigationSplitView three-column layout with sidebar, content, and inspector areas.

**Tasks**:
1. Update `Views/ContentView.swift`:
   - `NavigationSplitView` with three columns
   - Sidebar column: placeholder `SidebarView`
   - Content column: `PDFRenderView`
   - Detail/Inspector column: placeholder `InspectorView`
   - Column width constraints: sidebar min 180, inspector min 280
   - `@State` for sidebar visibility and inspector visibility
2. Create `Views/Sidebar/SidebarView.swift`:
   - Container with `Picker` to toggle between Thumbnails and Outline modes
   - Placeholder content for each mode
   - Accept `PDFDocumentModel` from environment
3. Create `Views/Inspector/InspectorView.swift`:
   - Container with tab bar for different inspector panels
   - Tabs: Standards, Violations, Structure, Features
   - Placeholder content for each tab
   - Accept document model from environment
4. Add keyboard shortcuts:
   - `Cmd+Opt+1` toggle sidebar
   - `Cmd+Opt+2` toggle inspector
5. Add menu items for View > Show/Hide Sidebar, Show/Hide Inspector

**Files Created**:
- `Verificar/Views/Sidebar/SidebarView.swift`
- `Verificar/Views/Inspector/InspectorView.swift`

**Files Modified**:
- `Verificar/Views/ContentView.swift`
- `Verificar/App/VerificarApp.swift` (menu commands)

**Tests**: Build verification

**Exit Criteria**: Build passes. Three-column layout visible. Sidebar and inspector toggle.

---

### Sprint 5: Page Thumbnails Sidebar

**Goal**: Display page thumbnails in the sidebar with selection sync.

**Tasks**:
1. Create `Views/Sidebar/ThumbnailSidebarView.swift`:
   - `ScrollViewReader` + `LazyVStack` of page thumbnails
   - Each thumbnail: page number label, rendered thumbnail image
   - Use `PDFPage.thumbnail(of:for:)` for thumbnail generation
   - Thumbnail size: ~120pt wide, aspect ratio preserved
   - Selected page highlighted with accent color border
   - Click thumbnail → update `currentPageIndex` on model
   - Auto-scroll to current page when page changes in PDFView
2. Create `Utilities/PDFKitExtensions.swift`:
   - Extension on `PDFPage` for convenient thumbnail generation
   - Extension on `PDFDocument` for page iteration
3. Update `Views/Sidebar/SidebarView.swift`:
   - Wire `ThumbnailSidebarView` into the Thumbnails tab
4. Add unit test: `VerificarTests/ThumbnailSidebarTests.swift`
   - Test thumbnail generation from PDFPage
   - Test page selection callback

**Files Created**:
- `Verificar/Views/Sidebar/ThumbnailSidebarView.swift`
- `Verificar/Utilities/PDFKitExtensions.swift`
- `VerificarTests/ThumbnailSidebarTests.swift`

**Files Modified**:
- `Verificar/Views/Sidebar/SidebarView.swift`

**Tests**: 2+ unit tests

**Exit Criteria**: Build passes. Thumbnails render for all pages. Click syncs with PDF view.

---

### Sprint 6: Document Outline Sidebar

**Goal**: Display the PDF document outline (bookmarks/table of contents) as a collapsible tree.

**Tasks**:
1. Create `Models/OutlineNode.swift`:
   - `struct OutlineNode: Identifiable` wrapping `PDFOutline`
   - Properties: `label: String`, `destination: PDFDestination?`, `children: [OutlineNode]`
   - Static method: `func buildTree(from outline: PDFOutline) -> [OutlineNode]`
2. Create `Views/Sidebar/OutlineSidebarView.swift`:
   - Recursive `OutlineDisclosureGroup` or SwiftUI `List` with `DisclosureGroup`
   - Each node shows label text
   - Click navigates to the outline destination (page + position)
   - Show "No outline available" when PDF has no outline
   - Expand first level by default
3. Update `Views/Sidebar/SidebarView.swift`:
   - Wire `OutlineSidebarView` into the Outline tab
   - Show/hide based on whether PDF has an outline
4. Update `PDFDocumentModel`:
   - Add `var outlineRoot: PDFOutline?` computed from document
   - Add `func navigateToDestination(_ destination: PDFDestination)`
5. Add unit test: `VerificarTests/OutlineNodeTests.swift`
   - Test tree building from PDFOutline
   - Test empty outline handling

**Files Created**:
- `Verificar/Models/OutlineNode.swift`
- `Verificar/Views/Sidebar/OutlineSidebarView.swift`
- `VerificarTests/OutlineNodeTests.swift`

**Files Modified**:
- `Verificar/Views/Sidebar/SidebarView.swift`
- `Verificar/Models/PDFDocumentModel.swift`

**Tests**: 3+ unit tests

**Exit Criteria**: Build passes. Outline tree renders. Click navigates to destination. Empty outline handled.

---

### Sprint 7: Toolbar & Navigation Controls

**Goal**: Add zoom, page navigation, search, and view mode controls to the toolbar.

**Tasks**:
1. Create `Views/Toolbar/ToolbarContent.swift`:
   - `struct VerificarToolbar: ToolbarContent`
   - **Navigation group**: Back/Forward page buttons, page number indicator ("Page 3 of 12"), Go To Page text field
   - **Zoom group**: Zoom In (+), Zoom Out (-), Fit Width, Fit Page, zoom percentage display
   - **View mode group**: Segmented control for Single Page / Continuous / Two-Up
   - **Search**: Search field using PDFView's built-in search (toggle)
2. Update `Models/PDFDocumentModel.swift`:
   - Add `var zoomLevel: CGFloat`
   - Add `var displayMode: PDFDisplayMode` (.singlePage, .singlePageContinuous, .twoUp, .twoUpContinuous)
   - Add `var isSearching: Bool`
   - Add `var searchText: String`
   - Add `func zoomIn()`, `func zoomOut()`, `func zoomToFit()`, `func zoomToWidth()`
   - Add `func nextPage()`, `func previousPage()`
   - Add `func search(_ text: String)`
3. Update `Views/PDF/PDFViewRepresentable.swift`:
   - React to zoom level changes
   - React to display mode changes
   - Wire search functionality through PDFView
4. Wire toolbar into `ContentView` or `VerificarApp`
5. Add keyboard shortcuts:
   - `Cmd+=` zoom in, `Cmd+-` zoom out, `Cmd+0` actual size
   - `Cmd+F` search, `Opt+Cmd+P` go to page
   - Arrow keys for page navigation (when not in continuous mode)
6. Add menu bar items: View > Zoom In/Out/Actual Size, Go > Next/Previous Page

**Files Created**:
- `Verificar/Views/Toolbar/ToolbarContent.swift`

**Files Modified**:
- `Verificar/Models/PDFDocumentModel.swift`
- `Verificar/Views/PDF/PDFViewRepresentable.swift`
- `Verificar/Views/ContentView.swift`
- `Verificar/App/VerificarApp.swift`

**Tests**: Build verification + manual toolbar interaction

**Exit Criteria**: Build passes. Zoom controls work. Page navigation works. Search highlights matches. View modes switch correctly.

---

### Sprint 8: SwiftVerificar Package Dependency & Validation Service

**Goal**: Add SwiftVerificar-biblioteca as an SPM dependency and create the validation service layer.

**Tasks**:
1. Add SPM dependency to `Verificar.xcodeproj`:
   - Add `XCRemoteSwiftPackageReference` for `https://github.com/intrusive-memory/SwiftVerificar-biblioteca.git` version `0.1.0`
   - Add `XCSwiftPackageProductDependency` for `SwiftVerificarBiblioteca` to the Verificar target
   - Run `xcodebuild -resolvePackageDependencies` to verify resolution
   - NOTE: This requires editing `project.pbxproj` — add the package reference sections
2. Create `Services/ValidationService.swift`:
   - `@Observable class ValidationService`
   - Properties: `isValidating: Bool`, `progress: Double`, `lastResult: ValidationResult?`, `error: Error?`
   - Method: `func validate(url: URL) async` — calls `SwiftVerificar.shared.validateAccessibility(url)`
   - Method: `func validate(url: URL, profile: String) async` — validates with specific profile
   - Method: `func extractFeatures(url: URL) async` — calls feature extraction
   - Method: `func cancelValidation()` — cancels in-progress validation via Task
   - Publishes state changes for UI consumption
3. Create `Models/ValidationState.swift`:
   - `struct ValidationSummary` — aggregated summary (total rules, passed, failed, warnings)
   - `struct ViolationItem: Identifiable` — UI-friendly violation with id, severity, message, page, criterion
   - `enum ViolationSeverity: String, CaseIterable` — error, warning, info
   - `enum ComplianceStatus` — conformant, nonConformant, unknown, inProgress
   - Helper to map SwiftVerificar types to UI models
4. Add unit test: `VerificarTests/ValidationServiceTests.swift`
   - Test service initialization
   - Test validation state transitions
   - Test summary computation from mock results

**Files Created**:
- `Verificar/Services/ValidationService.swift`
- `Verificar/Models/ValidationState.swift`
- `VerificarTests/ValidationServiceTests.swift`

**Files Modified**:
- `Verificar.xcodeproj/project.pbxproj` (add package dependency)

**Tests**: 4+ unit tests

**Exit Criteria**: Build passes with SwiftVerificar-biblioteca imported. ValidationService compiles and can be instantiated. Tests pass.

---

### Sprint 9: Validation Orchestration & State Management

**Goal**: Wire validation to document opening and create the view model that coordinates document + validation state.

**Tasks**:
1. Create `ViewModels/DocumentViewModel.swift`:
   - `@Observable class DocumentViewModel`
   - Owns `PDFDocumentModel` and `ValidationService`
   - Method: `func openDocument(at url: URL) async` — opens PDF, then kicks off validation
   - Properties: `validationSummary: ValidationSummary`, `violations: [ViolationItem]`, `complianceStatus: ComplianceStatus`
   - Properties: `selectedProfile: String` (default "PDF/UA-2")
   - Method: `func revalidate()` — re-run validation with current profile
   - Method: `func selectViolation(_ violation: ViolationItem)` — navigates PDF to violation page
2. Create `ViewModels/ValidationViewModel.swift`:
   - `@Observable class ValidationViewModel`
   - Manages filtered/sorted violation list
   - Properties: `filterSeverity: ViolationSeverity?`, `searchText: String`, `groupBy: GroupingMode`
   - Computed: `var filteredViolations: [ViolationItem]`
   - `enum GroupingMode: String, CaseIterable` — none, severity, category, page
3. Update `App/VerificarApp.swift`:
   - Create `DocumentViewModel` as `@State` and inject via environment
   - Wire `.fileImporter` to `documentViewModel.openDocument(at:)`
4. Update `Views/ContentView.swift`:
   - Pull `DocumentViewModel` from environment
   - Pass sub-models to sidebar, content, and inspector
5. Update `Views/Inspector/InspectorView.swift`:
   - Show validation progress indicator when `isValidating`
   - Show "Not validated" when no results available
6. Add unit tests: `VerificarTests/DocumentViewModelTests.swift`
   - Test document open flow
   - Test validation trigger on open
   - Test violation filtering

**Files Created**:
- `Verificar/ViewModels/DocumentViewModel.swift`
- `Verificar/ViewModels/ValidationViewModel.swift`
- `VerificarTests/DocumentViewModelTests.swift`

**Files Modified**:
- `Verificar/App/VerificarApp.swift`
- `Verificar/Views/ContentView.swift`
- `Verificar/Views/Inspector/InspectorView.swift`

**Tests**: 5+ unit tests

**Exit Criteria**: Build passes. Opening a PDF triggers validation automatically. Validation state flows to inspector placeholder. Tests pass.

---

### Sprint 10: Accessibility Standards Panel

**Goal**: Build the first inspector tab showing compliance status and standards identification.

**Tasks**:
1. Create `Views/Inspector/StandardsPanel.swift`:
   - **Compliance Badge**: Large pass/fail/unknown indicator at top
   - **Profile Info**: Which profile was validated against (e.g., "PDF/UA-2")
   - **Summary Stats**: Horizontal bar showing rules passed/failed/not-applicable
     - Green: passed count
     - Red: failed count
     - Gray: not applicable count
   - **Standards Identification Section**:
     - PDF/A identification (part, conformance level, amendment) or "Not declared"
     - PDF/UA identification (part) or "Not declared"
     - WCAG conformance level or "Not assessed"
   - **Metadata Section**:
     - Title, Author, Subject, Keywords (from XMP/info dict)
     - Creation date, Modification date
     - Producer, Creator tool
     - PDF version
   - **Re-validate Button**: Triggers `documentViewModel.revalidate()`
   - **Profile Picker**: Dropdown to select validation profile
2. Wire into `InspectorView` as the first tab
3. Add unit test: `VerificarTests/StandardsPanelTests.swift`
   - Test summary computation
   - Test compliance badge state mapping

**Files Created**:
- `Verificar/Views/Inspector/StandardsPanel.swift`
- `VerificarTests/StandardsPanelTests.swift`

**Files Modified**:
- `Verificar/Views/Inspector/InspectorView.swift`

**Tests**: 3+ unit tests

**Exit Criteria**: Build passes. Standards panel displays with mock/real validation data. Profile picker works.

---

### Sprint 11: Violations List View

**Goal**: Build the violations list inspector tab with filtering, grouping, and search.

**Tasks**:
1. Create `Views/Inspector/ViolationsListView.swift`:
   - **Filter Bar**: Segmented control for severity (All / Errors / Warnings / Info) + search field
   - **Violations Count**: "42 violations (28 errors, 10 warnings, 4 info)"
   - **Grouped List** (based on `ValidationViewModel.groupBy`):
     - Group headers with disclosure triangles
     - Each violation row:
       - Severity icon (red circle, yellow triangle, blue circle)
       - Rule ID badge
       - Short description (truncated to 2 lines)
       - Page number badge
       - WCAG criterion tag (e.g., "1.1.1")
   - **Empty State**: "No violations found" with checkmark when clean
   - **Click**: Selects violation, navigates PDF to that page
   - **Context Menu**: Copy violation details, group by options
2. Update `ViewModels/ValidationViewModel.swift`:
   - Implement `filteredViolations` with combined filter + search
   - Implement grouping logic
   - Add `var selectedViolation: ViolationItem?`
3. Wire into `InspectorView` as the Violations tab
4. Add badge count on the Violations tab showing error count
5. Add unit test: `VerificarTests/ViolationsListViewModelTests.swift`
   - Test filtering by severity
   - Test search filtering
   - Test grouping

**Files Created**:
- `Verificar/Views/Inspector/ViolationsListView.swift`
- `VerificarTests/ViolationsListViewModelTests.swift`

**Files Modified**:
- `Verificar/ViewModels/ValidationViewModel.swift`
- `Verificar/Views/Inspector/InspectorView.swift`

**Tests**: 4+ unit tests

**Exit Criteria**: Build passes. Violations list renders with filtering and grouping. Click navigates to page.

---

### Sprint 12: Violation Detail View

**Goal**: Build the expandable detail view for individual violations.

**Tasks**:
1. Create `Views/Inspector/ViolationDetailView.swift`:
   - Shown when a violation is selected in the list (inline expansion or sheet)
   - **Header**: Severity badge + Rule ID + short description
   - **Specification Reference**: Standard name, clause number, requirement text
   - **Location**: Page number, object type, object path in structure tree
   - **WCAG Mapping** (if applicable):
     - Principle (Perceivable/Operable/Understandable/Robust)
     - Success Criterion number and name (e.g., "1.1.1 Non-text Content")
     - Level (A/AA/AAA)
   - **Details**: Full description of the violation
   - **Context**: Excerpt from the PDF showing the problematic content (text near the violation)
   - **Remediation Suggestion**: What to fix (if provided by the rule)
   - **Navigate Button**: "Show in PDF" — scrolls PDF view to the violation page/location
2. Update `ViolationsListView`:
   - Expand violation inline when clicked (disclosure style)
   - Or show detail in a secondary view
3. Add unit test: `VerificarTests/ViolationDetailTests.swift`
   - Test WCAG criterion display formatting
   - Test remediation text generation

**Files Created**:
- `Verificar/Views/Inspector/ViolationDetailView.swift`
- `VerificarTests/ViolationDetailTests.swift`

**Files Modified**:
- `Verificar/Views/Inspector/ViolationsListView.swift`

**Tests**: 3+ unit tests

**Exit Criteria**: Build passes. Violation detail expands inline with all information. "Show in PDF" navigates correctly.

---

### Sprint 13: Structure Tree Visualization

**Goal**: Display the PDF's tagged structure tree in the inspector.

**Tasks**:
1. Create `Models/StructureNodeModel.swift`:
   - `struct StructureNodeModel: Identifiable` — UI-friendly structure tree node
   - Properties: `type: String` (H1, P, Figure, Table, etc.), `title: String?`, `altText: String?`, `language: String?`, `children: [StructureNodeModel]`, `pageIndex: Int?`
   - Map from SwiftVerificar's `PDStructElement` / `ValidatedStructElem` types
   - Computed: `var icon: String` — SF Symbol name for each element type (e.g., "text.heading" for headings, "photo" for figures)
2. Create `Views/Inspector/StructureTreeView.swift`:
   - Recursive `List` with `DisclosureGroup` or `OutlineGroup`
   - Each node shows: icon + type label + title/alt text (if present)
   - Color coding: elements with violations shown in red
   - Click node → navigate to its page in PDFView
   - **Info bar**: Total elements count, heading count, figure count, table count
   - **Empty state**: "No structure tree found — this PDF is not tagged"
   - **Search**: Filter tree nodes by type or content
3. Create `ViewModels/StructureTreeViewModel.swift`:
   - `@Observable class StructureTreeViewModel`
   - Builds tree from validation/parser results
   - Properties: `rootNodes: [StructureNodeModel]`, `searchText: String`, `selectedNode: StructureNodeModel?`
   - Statistics: element counts by type
4. Wire into `InspectorView` as the Structure tab
5. Add unit test: `VerificarTests/StructureTreeViewModelTests.swift`
   - Test tree building
   - Test node statistics
   - Test search filtering

**Files Created**:
- `Verificar/Models/StructureNodeModel.swift`
- `Verificar/Views/Inspector/StructureTreeView.swift`
- `Verificar/ViewModels/StructureTreeViewModel.swift`
- `VerificarTests/StructureTreeViewModelTests.swift`

**Files Modified**:
- `Verificar/Views/Inspector/InspectorView.swift`

**Tests**: 4+ unit tests

**Exit Criteria**: Build passes. Structure tree renders for tagged PDFs. Empty state shows for untagged PDFs. Statistics accurate.

---

### Sprint 14: Feature Extraction Panel

**Goal**: Display extracted PDF features (fonts, images, color spaces, annotations) in the inspector.

**Tasks**:
1. Create `Views/Inspector/FeaturePanel.swift`:
   - Tabbed/segmented sub-panel with sections:
   - **Fonts Tab**:
     - Table: Font Name | Type (Type1, TrueType, CID) | Embedded (Yes/No) | Used on Pages
     - Highlight non-embedded fonts (accessibility concern)
   - **Images Tab**:
     - Grid or list: Thumbnail | Dimensions | Color Space | Has Alt Text (Yes/No) | Page
     - Highlight images without alt text
   - **Color Spaces Tab**:
     - List: Color Space Name | Type (DeviceRGB, ICCBased, etc.) | Usage Count
     - Highlight device-dependent color spaces (PDF/A concern)
   - **Annotations Tab**:
     - List: Type (Link, Widget, Text, etc.) | Page | Has Accessible Name
   - **Summary Stats** at top: total fonts, images, color spaces, annotations
2. Create `ViewModels/FeatureViewModel.swift`:
   - `@Observable class FeatureViewModel`
   - Processes feature extraction results from ValidationService
   - Properties for each feature category
   - Method: `func extractFeatures(from url: URL) async`
3. Wire into `InspectorView` as the Features tab
4. Add unit test: `VerificarTests/FeatureViewModelTests.swift`
   - Test feature categorization
   - Test summary statistics

**Files Created**:
- `Verificar/Views/Inspector/FeaturePanel.swift`
- `Verificar/ViewModels/FeatureViewModel.swift`
- `VerificarTests/FeatureViewModelTests.swift`

**Files Modified**:
- `Verificar/Views/Inspector/InspectorView.swift`

**Tests**: 3+ unit tests

**Exit Criteria**: Build passes. Feature panel shows font, image, color space, and annotation inventories. Statistics accurate.

---

### Sprint 15: Violation Highlighting & Report Export

**Goal**: Overlay violation markers on the PDF view and add report export functionality.

**Tasks**:
1. Update `Views/PDF/PDFViewRepresentable.swift`:
   - Add violation annotation overlay
   - Create `PDFAnnotation` instances for each violation with a page location
   - Color-code by severity: red border for errors, yellow for warnings, blue for info
   - Add/remove annotations when validation results change
   - Configurable highlight toggle
2. Create `Views/PDF/ViolationAnnotation.swift`:
   - Custom `PDFAnnotation` subclass for violation markers
   - Tooltip showing violation summary on hover
   - Click to select violation in the list
3. Add highlight sync:
   - Select violation in list → highlight annotation in PDF and scroll to it
   - Click annotation in PDF → select violation in list and scroll to it
4. Create `Services/ReportExporter.swift`:
   - `struct ReportExporter`
   - Method: `func exportJSON(results: ValidationResult) -> Data` — structured JSON report
   - Method: `func exportHTML(results: ValidationResult) -> String` — styled HTML report with summary table and violation details
   - Method: `func exportText(results: ValidationResult) -> String` — plain text summary
5. Add menu items: File > Export Report > JSON / HTML / Text
   - Uses `NSSavePanel` for file destination
6. Add unit test: `VerificarTests/ReportExporterTests.swift`
   - Test JSON export structure
   - Test HTML export contains expected sections
   - Test text export formatting

**Files Created**:
- `Verificar/Views/PDF/ViolationAnnotation.swift`
- `Verificar/Services/ReportExporter.swift`
- `VerificarTests/ReportExporterTests.swift`

**Files Modified**:
- `Verificar/Views/PDF/PDFViewRepresentable.swift`
- `Verificar/App/VerificarApp.swift` (export menu items)
- `Verificar/ViewModels/DocumentViewModel.swift`

**Tests**: 4+ unit tests

**Exit Criteria**: Build passes. Violations highlighted in PDF. Click-to-navigate works bidirectionally. Export produces valid JSON/HTML/text files.

---

### Sprint 16: Settings, Polish & Final Tests

**Goal**: Add preferences, keyboard shortcuts, app polish, and comprehensive tests.

**Tasks**:
1. Create `Views/SettingsView.swift`:
   - macOS Settings window (`.settings` scene)
   - **Validation tab**:
     - Default validation profile picker
     - Auto-validate on open toggle
     - Max violations to display slider
   - **Display tab**:
     - Default zoom level
     - Default view mode
     - Show page numbers in thumbnails toggle
     - Highlight color customization
   - Store preferences in `@AppStorage`
2. Update `App/VerificarApp.swift`:
   - Add `Settings { SettingsView() }` scene
   - Add `Cmd+,` shortcut for Settings
   - Add complete keyboard shortcuts table:
     - `Cmd+O` open, `Cmd+W` close
     - `Cmd+Shift+V` toggle validation panel
     - `Cmd+Shift+S` export report
3. Update window title bar:
   - Show document name + compliance badge in title
   - Show validation progress in subtitle
4. Add comprehensive tests:
   - `VerificarTests/IntegrationTests.swift`:
     - Test full open → validate → display pipeline with a test PDF
     - Test re-validation with different profiles
     - Test export pipeline
   - `VerificarTests/AccessibilityTests.swift`:
     - Verify app's own VoiceOver accessibility
     - All interactive elements have accessibility labels
     - Navigation landmarks are properly set
5. Final polish:
   - Loading animations for validation
   - Empty state illustrations
   - Error alerts for failed validation
   - Window restoration (reopen last document)
6. Update `.gitignore` if needed
7. Ensure all tests pass

**Files Created**:
- `Verificar/Views/SettingsView.swift`
- `VerificarTests/IntegrationTests.swift`
- `VerificarTests/AccessibilityTests.swift`

**Files Modified**:
- `Verificar/App/VerificarApp.swift`
- `Verificar/Views/ContentView.swift`

**Tests**: 8+ unit tests (total project: 40+)

**Exit Criteria**: Build passes. All tests pass. Settings window works. Keyboard shortcuts functional. App is polished and usable.

---

## Section 6: PROGRESS.md Template

Each sprint agent should update `$PROJECT_ROOT/Verificar/PROGRESS.md` using this format:

```markdown
# Verificar Progress

## Current State
- Last completed sprint: <N>
- Last commit hash: [hash]
- Build status: passing/failing
- Total test count: <count>
- **App status: IN PROGRESS / COMPLETE**

## Completed Sprints
- Sprint 1: Project Cleanup & PDF Document Type Configuration ✅
- Sprint 2: ...
- ...

## Next Sprint
- Sprint <N+1>: <Name>

## Files Created (cumulative)
### Sources
- Verificar/App/VerificarApp.swift
- ...

### Tests
- VerificarTests/...

## Notes
- [Any implementation notes, decisions, or issues per sprint]
```

---

## Section 7: SwiftVerificar API Quick Reference

### Biblioteca (Main Entry Point)

```swift
import SwiftVerificarBiblioteca

// Accessibility validation
let result = try await SwiftVerificar.shared.validateAccessibility(pdfURL)

// Profile-specific validation
let result = try await SwiftVerificar.shared.validate(pdfURL, profile: "PDF/UA-2")

// Full processing
let processorResult = try await SwiftVerificar.shared.process(pdfURL, config: .all)
```

### Key Result Types

```swift
// ValidationResult — from biblioteca
result.passedCount      // Int
result.failedCount      // Int
result.assertions       // [TestAssertion]
result.duration         // ValidationDuration

// TestAssertion — individual test
assertion.status        // AssertionStatus (.passed, .failed, ...)
assertion.message       // String
assertion.location      // PDFLocation (page, object, context)
assertion.ruleID        // String

// PDFLocation
location.pageNumber     // Int?
location.objectType     // String?
location.context        // String?
```

### WCAG Types (from wcag-algs)

```swift
import SwiftVerificarWCAGAlgs

// SemanticType — structure element types
SemanticType.h1, .paragraph, .figure, .table, .list, ...
type.isHeading          // Bool
type.headingLevel       // Int?
type.requiresAlternativeText // Bool

// WCAGSuccessCriterion
criterion.number        // String ("1.1.1")
criterion.name          // String ("Non-text Content")
criterion.level         // WCAGLevel (.a, .aa, .aaa)
criterion.principle     // WCAGPrinciple (.perceivable, .operable, ...)
```

### Validation Profiles (from validation-profiles)

```swift
import SwiftVerificarValidationProfiles

// PDFFlavour — available validation profiles
PDFFlavour.pdfUA1, .pdfUA2
PDFFlavour.pdfA1a, .pdfA1b, .pdfA2a, .pdfA2b, .pdfA2u, .pdfA3a, .pdfA3b, .pdfA3u, .pdfA4

// Profile loading
let profile = try await ProfileLoader.shared.loadProfile(for: .pdfUA2)
profile.rules           // [ValidationRule]
```

---

## Appendix A: Sprint Summary Table

| Sprint | Name | Layer | Key Deliverables | Est. Tests |
|--------|------|-------|-----------------|-----------|
| 1 | Project Cleanup & PDF Document Type Configuration | 0 | Clean project, PDF UTType | 0 |
| 2 | PDF Document Model & File Opening | 0 | PDFDocumentModel, file open | 3 |
| 3 | PDFKit View Integration & Basic Rendering | 0 | PDFViewRepresentable, rendering | 2 |
| 4 | Three-Column Layout Shell | 1 | NavigationSplitView, sidebar/inspector | 0 |
| 5 | Page Thumbnails Sidebar | 1 | ThumbnailSidebarView, page sync | 2 |
| 6 | Document Outline Sidebar | 1 | OutlineSidebarView, navigation | 3 |
| 7 | Toolbar & Navigation Controls | 1 | Zoom, page nav, search, view modes | 0 |
| 8 | SwiftVerificar Dependency & Validation Service | 2 | SPM dep, ValidationService | 4 |
| 9 | Validation Orchestration & State Management | 2 | DocumentViewModel, auto-validate | 5 |
| 10 | Accessibility Standards Panel | 2 | StandardsPanel, compliance display | 3 |
| 11 | Violations List View | 3 | ViolationsListView, filter/group | 4 |
| 12 | Violation Detail View | 3 | ViolationDetailView, WCAG mapping | 3 |
| 13 | Structure Tree Visualization | 3 | StructureTreeView, tree browser | 4 |
| 14 | Feature Extraction Panel | 3 | FeaturePanel, inventory views | 3 |
| 15 | Violation Highlighting & Report Export | 3 | PDF overlays, JSON/HTML export | 4 |
| 16 | Settings, Polish & Final Tests | 4 | Preferences, tests, polish | 8 |
| **Total** | | | | **48+** |

---

## Appendix B: Test PDF Resources

Sprint agents that need test PDFs should:
1. Create a minimal test PDF programmatically using PDFKit (`PDFDocument` + `PDFPage` with `draw()`)
2. Or use the system's built-in PDFs at `/System/Library/Frameworks/Quartz.framework/` or similar locations
3. Or create a `TestResources/` directory with small sample PDFs committed to the repo

---

## Appendix C: Build Settings Reference

| Setting | Value |
|---------|-------|
| Scheme | `Verificar` |
| Destination | `platform=macOS` |
| Swift Version | 6.0 |
| Deployment Target | macOS 14.0 |
| Bundle ID | `io.intrusive-memory.Verificar` |
| Team | H3EJ6Y8VJ6 |
| Sandbox | Enabled |
| Hardened Runtime | Enabled |
| User Selected Files | Read/Write |
