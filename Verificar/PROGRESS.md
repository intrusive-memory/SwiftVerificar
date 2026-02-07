# Verificar Progress

## Current State
- Last completed sprint: 4
- Last commit hash: 2915141
- Build status: passing
- Total test count: 17 (13 unit tests + 4 UI tests from template)
- **App status: IN PROGRESS**

## Completed Sprints
- Sprint 1: Project Cleanup & PDF Document Type Configuration
- Sprint 2: PDF Document Model & File Opening
- Sprint 3: PDFKit View Integration & Basic Rendering
- Sprint 4: Three-Column Layout Shell

## Next Sprint
- Sprint 5: Page Thumbnails Sidebar

## Files Created (cumulative)
### Sources
- Verificar/App/VerificarApp.swift
- Verificar/Views/ContentView.swift
- Verificar/Views/PDF/PDFViewRepresentable.swift
- Verificar/Views/PDF/PDFRenderView.swift
- Verificar/Views/Sidebar/SidebarView.swift
- Verificar/Views/Inspector/InspectorView.swift
- Verificar/Models/PDFDocumentModel.swift
- Verificar/Info.plist (updated)

### Directories Created
- Verificar/App/
- Verificar/Models/
- Verificar/Views/
- Verificar/Views/PDF/
- Verificar/Views/Sidebar/
- Verificar/Views/Inspector/
- Verificar/Views/Toolbar/
- Verificar/ViewModels/
- Verificar/Services/
- Verificar/Utilities/

### Files Deleted
- Verificar/Item.swift (SwiftData model - not needed)
- Verificar/VerificarApp.swift (moved to App/VerificarApp.swift)
- Verificar/ContentView.swift (moved to Views/ContentView.swift)

### Tests
- VerificarTests/VerificarTests.swift (template - 1 test)
- VerificarTests/PDFDocumentModelTests.swift (8 tests)
- VerificarTests/PDFViewRepresentableTests.swift (4 tests)

## Notes
### Sprint 1
- Removed all SwiftData boilerplate (Item.swift, migration plan, versioned schema, @Query, modelContext)
- Removed SwiftData and UniformTypeIdentifiers imports from app entry point
- Simplified VerificarApp to use WindowGroup instead of DocumentGroup
- Replaced com.example.item-document UTType with com.adobe.pdf in Info.plist
- Removed UTImportedTypeDeclarations section from Info.plist
- Set CFBundleTypeRole to Viewer and LSHandlerRank to Alternate for PDF documents
- Created full directory structure for future sprints
- ContentView shows placeholder with SF Symbol and instructional text
- Build settings note: Project uses SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor and SWIFT_APPROACHABLE_CONCURRENCY = YES (Xcode 26.2 defaults)
- Project uses PBXFileSystemSynchronizedRootGroup so new files in the Verificar/ directory are auto-discovered by Xcode (no pbxproj edits needed for file additions)

### Sprint 2
- Created PDFDocumentModel (@Observable class wrapping PDFKit.PDFDocument)
  - Properties: pdfDocument, url, isLoading, error, currentPageIndex, pageCount, currentPage, title, isDocumentLoaded
  - Methods: open(url:), close(), goToPage(_:), nextPage(), previousPage()
  - goToPage clamps index to valid range [0, pageCount-1]
  - title falls back to filename when PDF metadata has no title
  - PDFDocumentError enum for typed load failures
- Updated VerificarApp with:
  - @State documentModel injected via .environment() into ContentView
  - .fileImporter with UTType.pdf filter for File > Open dialog
  - CommandGroup(replacing: .newItem) providing Cmd+O "Open..." menu item
  - Drag-and-drop support via .onDrop for PDF files and file URLs
  - Security-scoped resource access for sandboxed file opening
- Updated ContentView to:
  - Read PDFDocumentModel from @Environment
  - Show placeholder when no document loaded
  - Show loading spinner during document load
  - Show document title and page count when document loaded
- Added 8 unit tests in PDFDocumentModelTests using Swift Testing:
  - initialState, goToPageClamping, nextAndPreviousPage, pageCountReflectsDocument
  - currentPageReturnsCorrectPage, closeResetsState, titleFromFilename, goToPageNoDocument
  - Tests use programmatically created in-memory PDFDocuments (no test file dependencies)

### Sprint 3
- Created PDFViewRepresentable (NSViewRepresentable wrapping PDFKit.PDFView)
  - Configures PDFView: autoScales=true, displayMode=.singlePageContinuous, displayDirection=.vertical
  - Coordinator pattern with PDFViewDelegate for page-change notifications
  - Observes .PDFViewPageChanged notification to sync currentPageIndex back to model
  - updateNSView assigns document only when reference changes (identity check with !==)
  - Syncs model's currentPage to PDFView.go(to:) when page index differs
  - dismantleNSView removes notification observer to prevent leaks
- Created PDFRenderView (container view wrapping PDFViewRepresentable)
  - Shows loading overlay with ProgressView when documentModel.isLoading
  - Shows "No Document" overlay when no document is loaded
  - Shows PDFViewRepresentable when document is loaded and ready
- Updated ContentView:
  - Replaced Sprint 2 placeholder documentLoadedView with PDFRenderView
  - PDFRenderView handles both loading and loaded states
  - Placeholder view retained for no-document state
  - Removed unused loadingView and documentLoadedView subviews
- Added 4 unit tests in PDFViewRepresentableTests using Swift Testing:
  - makeNSViewCreatesPDFView: verifies PDFView is configured with correct autoScales, displayMode, displayDirection, and delegate
  - updateNSViewAssignsDocument: verifies PDFDocument is assigned to the PDFView after update
  - updateNSViewSkipsSameDocument: verifies no reassignment when document reference is unchanged
  - coordinatorUpdatesModelOnPageChange: verifies Coordinator syncs page index back to model on page change notification
  - Tests use a _PDFViewTestContext helper to bypass NSViewRepresentable.Context creation

### Sprint 4
- Replaced single-column ContentView with NavigationSplitView three-column layout
  - Sidebar column: SidebarView with min 180, ideal 220, max 300 width
  - Content column: PDFRenderView with min 400 width
  - Detail/Inspector column: InspectorView with min 280, ideal 320, max 450 width
  - Overall window min size: 800x500
  - @State sidebarVisibility controls sidebar show/hide via NavigationSplitViewVisibility
  - @State isInspectorPresented controls inspector show/hide
  - toggleSidebar() switches between .detailOnly and .all
  - toggleInspector() toggles isInspectorPresented boolean
- Created SidebarView (Views/Sidebar/SidebarView.swift)
  - Segmented Picker toggles between Thumbnails and Outline modes (SidebarMode enum)
  - Placeholder content for each mode with contextual text (loaded vs not loaded)
  - Reads PDFDocumentModel from @Environment
  - SidebarMode enum: .thumbnails, .outline with label and icon properties
- Created InspectorView (Views/Inspector/InspectorView.swift)
  - Segmented Picker toggles between four tabs (InspectorTab enum)
  - Tabs: Standards, Violations, Structure, Features
  - Each tab shows placeholder with icon, title, and contextual subtitle
  - Reads PDFDocumentModel from @Environment
  - InspectorTab enum: .standards, .violations, .structure, .features with label and icon properties
- Added keyboard shortcuts via menu commands:
  - Cmd+Opt+1: Toggle Sidebar
  - Cmd+Opt+2: Toggle Inspector
  - Menu items added under View > (after .sidebar CommandGroup)
- FocusedValues bridge for menu-to-view communication:
  - ToggleSidebarActionKey and ToggleInspectorActionKey FocusedValueKey types
  - ContentView publishes toggleSidebar/toggleInspector via .focusedSceneValue
  - VerificarApp reads focused values via @FocusedValue to forward menu actions
- No new tests added (Sprint 4 specifies "Build verification" only per execution plan)
- NavigationSplitViewVisibility is a struct, not an enum — used if/else instead of switch for toggle logic
