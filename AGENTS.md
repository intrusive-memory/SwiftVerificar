# SwiftVerificar Package Collection — Agent Instructions

This document is the canonical source of project context for all AI agents (Claude, Gemini, Codex, etc.) working on the SwiftVerificar ecosystem.

## Project Overview

**SwiftVerificar** is a Swift port of the [veraPDF](https://github.com/veraPDF) ecosystem for PDF/A and PDF/UA validation. The goal is to provide native validation capabilities for the Apple ecosystem, eliminating the Java runtime dependency.

**Primary Consumer:** [Lazarillo](https://github.com/intrusive-memory/Lazarillo) - PDF accessibility remediation engine for macOS.

## Package Collection

| Package | Ports | Description |
|---------|-------|-------------|
| **SwiftVerificar-biblioteca** | [veraPDF-library](https://github.com/veraPDF/veraPDF-library) | Main integration library |
| **SwiftVerificar-parser** | [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser) | PDF parsing, structure tree, XMP metadata |
| **SwiftVerificar-validation** | [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation) | Validation engine, feature reporting |
| **SwiftVerificar-validation-profiles** | [veraPDF-validation-profiles](https://github.com/veraPDF/veraPDF-validation-profiles) | XML validation rules for PDF/A and PDF/UA |
| **SwiftVerificar-wcag-algs** | [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs) | WCAG accessibility algorithms |

## Porting Priority

For Lazarillo's PDF/UA-2 validation needs:

| Priority | Package | Why |
|----------|---------|-----|
| **Critical** | SwiftVerificar-parser | PDF structure/tagged PDF parsing |
| **Critical** | SwiftVerificar-validation | Rule execution engine |
| **Critical** | SwiftVerificar-validation-profiles | XML rule definitions (can import) |
| **High** | SwiftVerificar-wcag-algs | Accessibility checks (contrast, structure) |
| **Medium** | SwiftVerificar-biblioteca | Integration layer |

## General Guidelines

### Code Style

- Follow Swift API Design Guidelines
- Use Swift 6.0+ features including strict concurrency
- Prefer value types (structs, enums) over reference types where appropriate
- Use async/await for asynchronous operations
- Mark types as `Sendable` for concurrency safety

### Architecture

When porting from the Java veraPDF ecosystem:

1. **Study the original**: Understand the Java implementation
2. **Swift idioms**: Convert Java patterns to Swift idioms:
   - Java interfaces → Swift protocols
   - Java abstract classes → Swift protocols with default implementations
   - Java static factories → Swift static methods or initializers
   - Java streams → Swift sequences and higher-order functions
3. **Memory safety**: Leverage Swift's memory safety features
4. **Concurrency**: Use Swift's structured concurrency model (actors for validators)

### Build System

- **NEVER use `swift build` or `swift test`** - always use `xcodebuild`
- Use XcodeBuildMCP tools when available
- All CI/CD uses GitHub Actions with `macos-26` runners

### Testing

- Write tests using Swift Testing framework (`import Testing`)
- Ensure all tests pass before submitting pull requests
- Target test coverage for critical validation logic
- Use reference PDFs from veraPDF test corpus when available

### Branch Workflow

All packages follow the same workflow:

1. Create feature branches from `development`
2. Submit pull requests to `development`
3. `development` merges to `main` only after CI passes
4. `main` branch is protected and requires passing tests

## Implementation Roadmap

### Phase 1: Foundation (MVP) - PDF/UA-2 Focus

| Task | Package | Status |
|------|---------|--------|
| PDF document loading via PDFKit | parser | Pending |
| Tagged PDF structure tree parsing | parser | Pending |
| XMP metadata extraction | parser | Pending |
| Validation result model | biblioteca | Pending |

### Phase 2: Profile System

| Task | Package | Status |
|------|---------|--------|
| XML validation profile parser | validation-profiles | Pending |
| PDF/UA-2 profile import | validation-profiles | Pending |
| Rule expression evaluator | validation | Pending |

### Phase 3: Core Validation Engine

| Task | Package | Status |
|------|---------|--------|
| Structure tree validation | validation | Pending |
| Document metadata validation | validation | Pending |
| Tagged content validation | validation | Pending |
| Table structure validation | validation | Pending |

### Phase 4: WCAG Algorithms

| Task | Package | Status |
|------|---------|--------|
| Contrast ratio calculation | wcag-algs | Pending |
| Text accessibility checks | wcag-algs | Pending |
| List structure validation | wcag-algs | Pending |
| Link validation | wcag-algs | Pending |

### Phase 5: Extended Profiles (Post-MVP)

| Task | Package | Status |
|------|---------|--------|
| PDF/UA-1 profile | validation-profiles | Pending |
| PDF/A-1a/1b profiles | validation-profiles | Pending |
| PDF/A-2a/2b profiles | validation-profiles | Pending |
| PDF/A-3a/3b profiles | validation-profiles | Pending |

## Reference Materials

### veraPDF Source Repositories
- [veraPDF-library](https://github.com/veraPDF/veraPDF-library) - Main integration
- [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser) - PDF parsing
- [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation) - Validation engine
- [veraPDF-validation-profiles](https://github.com/veraPDF/veraPDF-validation-profiles) - XML rule definitions
- [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs) - Accessibility algorithms

### Standards
- [PDF/UA-2 (ISO 14289-2:2024)](https://www.pdfa.org/resource/iso-14289-pdfua/)
- [PDF 2.0 (ISO 32000-2:2020)](https://www.pdfa.org/resource/iso-32000-2/)
- [WCAG 2.1](https://www.w3.org/TR/WCAG21/)
- [Tagged PDF Reference](https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf) (Section 14.8)

### Apple Frameworks
- [PDFKit](https://developer.apple.com/documentation/pdfkit)
- [Core Graphics PDF](https://developer.apple.com/documentation/coregraphics/cgpdfdocument)

### Swift Guidelines
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
