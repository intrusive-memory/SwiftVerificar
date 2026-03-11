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

### v0.1.0 — Released (2026-02-07)

All 5 packages tagged at v0.1.0 and published as GitHub releases.

| Package | Types | Tests | Status |
|---------|-------|-------|--------|
| SwiftVerificar-parser | 67+ | 1,968 | Released |
| SwiftVerificar-validation-profiles | 30 | 686 | Released |
| SwiftVerificar-wcag-algs | 72+ | 1,222 | Released |
| SwiftVerificar-validation | 190+ | 2,995 | Released |
| SwiftVerificar-biblioteca | 55+ | 1,400 | Released |

**Completed in v0.1.0:**
- PDF document loading, COS object model, structure tree parsing
- XMP metadata extraction
- XML validation profile parser (PDF/A and PDF/UA profiles)
- WCAG accessibility algorithms (contrast ratio, structure, links)
- Validation engine scaffolding with PDF/UA-1 and PDF/UA-2 validators
- Feature extraction panel (fonts, images, color spaces, annotations)
- Full CI/CD on `macos-26` runners with branch protection

### v0.2.0 — In Progress

Scope: parser core gap fixes, validation fully wired to real parser types, and complete feature extraction coverage.

| Task | Package | Status |
|------|---------|--------|
| Stream data reading (`ObjectParser.parseStream`) | parser | Complete |
| Trailer dictionary parsing (`XRefParser.parseTrailerDictionary`) | parser | Complete |
| ToUnicode CMap mapping in `PDFTextStripper` | parser | Complete |
| Single-quote and double-quote PDF text operators | parser | Complete |
| ICCBased color space from indirect reference streams | parser | Complete |
| Indirect object reference resolution in arrays | parser | Complete |
| TrueType font table parsing (cmap, head, hhea, hmtx) | parser | Complete |
| Wire `SwiftVerificarParser` as real dependency in validation | validation | Complete |
| XMP conformance detection (PDF/UA-1, PDF/UA-2, PDF/A-1–4) | validation | Complete |
| PDF/UA-1 validator — all 18 stub methods implemented | validation | Complete |
| PDF/UA-2 validator — all 24 stub methods implemented | validation | Complete |
| Feature extraction — all 19 `FeatureType` cases handled | biblioteca | Complete |
| Documentation update and cross-package integration verification | root | Complete |

**v0.2.0 Package Versions**: All 5 packages bump to `0.2.0`.

### Phase 1: Foundation (MVP) - PDF/UA-2 Focus

| Task | Package | Status |
|------|---------|--------|
| PDF document loading via PDFKit | parser | Complete (v0.1.0) |
| Tagged PDF structure tree parsing | parser | Complete (v0.1.0) |
| XMP metadata extraction | parser | Complete (v0.1.0) |
| Validation result model | biblioteca | Complete (v0.1.0) |

### Phase 2: Profile System

| Task | Package | Status |
|------|---------|--------|
| XML validation profile parser | validation-profiles | Complete (v0.1.0) |
| PDF/UA-2 profile import | validation-profiles | Complete (v0.1.0) |
| Rule expression evaluator | validation | Complete (v0.1.0) |

### Phase 3: Core Validation Engine

| Task | Package | Status |
|------|---------|--------|
| Structure tree validation | validation | Complete (v0.2.0) |
| Document metadata validation | validation | Complete (v0.2.0) |
| Tagged content validation | validation | Complete (v0.2.0) |
| Table structure validation | validation | Complete (v0.2.0) |

### Phase 4: WCAG Algorithms

| Task | Package | Status |
|------|---------|--------|
| Contrast ratio calculation | wcag-algs | Complete (v0.1.0) |
| Text accessibility checks | wcag-algs | Complete (v0.1.0) |
| List structure validation | wcag-algs | Complete (v0.1.0) |
| Link validation | wcag-algs | Complete (v0.1.0) |

### Phase 5: Extended Profiles (Post-MVP)

| Task | Package | Status |
|------|---------|--------|
| PDF/UA-1 profile | validation-profiles | Complete (v0.1.0) |
| PDF/A-1a/1b profiles | validation-profiles | Complete (v0.1.0) |
| PDF/A-2a/2b profiles | validation-profiles | Complete (v0.1.0) |
| PDF/A-3a/3b profiles | validation-profiles | Complete (v0.1.0) |

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
