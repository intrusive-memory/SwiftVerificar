# Claude Code Instructions — Verificar

See [../EXECUTION_PLAN.md](../EXECUTION_PLAN.md) for the sprint plan and component specifications.
See [../TODO.md](../TODO.md) for detailed property names, method signatures, and view layouts.
See [../PROGRESS.md](../PROGRESS.md) for current sprint progress.

## Build Commands
- Build: `xcodebuild build -scheme Verificar -destination 'platform=macOS'`
- Test: `xcodebuild test -scheme Verificar -destination 'platform=macOS'`
- NEVER use `swift build` or `swift test`

## Key Rules
- Swift 6.0 with strict concurrency
- SwiftUI for all views
- NSViewRepresentable for PDFKit (PDFView is AppKit)
- Swift Testing (`import Testing`, `@Test`) for unit tests
- XCTest for UI tests only
- PDFKit for rendering — SwiftVerificar for validation analysis
- All `@Observable` types must be `@MainActor` when they touch UI state
