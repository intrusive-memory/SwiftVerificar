# Verificar Progress

## Current State
- Last completed sprint: 2
- Last commit hash: a9b1b7f
- Build status: passing
- Total test count: 13 (9 unit tests + 4 UI tests from template)
- **App status: IN PROGRESS**

## Completed Sprints
- Sprint 1: Project Cleanup & PDF Document Type Configuration
- Sprint 2: PDF Document Model & File Opening

## Next Sprint
- Sprint 3: PDFKit View Integration & Basic Rendering

## Files Created (cumulative)
### Sources
- Verificar/App/VerificarApp.swift
- Verificar/Views/ContentView.swift
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
