# SwiftVerificar v0.2.0 — Master TODO List

> Extracted 2026-03-11 from all SwiftVerificar-* subpackages.
> Items sourced from: TODO comments in source, disabled tests, stub implementations, and documented gaps.

---

## Legend

- **[P]** = Parallelizable (no dependency on other items)
- **[S]** = Sequential (depends on prior items completing)
- **Package**: parser | validation | profiles | wcag | biblioteca
- **Priority**: P0 (critical path) | P1 (important) | P2 (nice to have)

---

## TRACK A — Parser Core Gaps (SwiftVerificar-parser)

These are foundational — validation wiring (Track C) depends on some of these.

### A1. Stream Data Reading [P] [P0]
- **File**: `Sources/SwiftVerificarParser/Parser/ObjectParser.swift:327`
- **Issue**: `let streamData = Data() // TODO: Read length bytes from stream` — stream data reading returns empty `Data()` instead of reading actual bytes
- **Impact**: All stream-based content (page content, fonts, images) returns empty data
- **Tests disabled**: 6 tests in `PDFDocumentParserTests.swift` (lines 139, 155, 161, 187, 192, 197) — all require full integration

### A2. Trailer Dictionary Parsing [P] [P0]
- **File**: `Sources/SwiftVerificarParser/Parser/XRefParser.swift:215`
- **Issue**: `parseTrailerDictionary()` returns empty `[:]` instead of parsing the trailer
- **Impact**: Document-level metadata (root object ref, info dict ref, ID array) unavailable

### A3. ToUnicode CMap Mapping [P] [P1]
- **File**: `Sources/SwiftVerificarParser/PD/PDFTextStripper.swift:249`
- **Issue**: `let unicode = char // TODO: Apply ToUnicode mapping` — uses raw byte instead of CMap
- **Impact**: Text extraction produces incorrect Unicode for fonts with non-standard encodings

### A4. Single-Quote Text Operator (') [P] [P1]
- **File**: Tokenizer (not yet supporting `'` operator)
- **Issue**: Move-to-next-line-and-show-text operator not tokenizable
- **Disabled test**: `PDFTextStripperTests.swift:404` — "Single-quote operator not tokenizable in v0.1.0"

### A5. Double-Quote Text Operator (") [P] [P1]
- **File**: Tokenizer (not yet supporting `"` operator)
- **Issue**: Set-spacing-and-show-text operator not tokenizable
- **Disabled test**: `PDFTextStripperTests.swift:420` — "Double-quote operator not tokenizable in v0.1.0"

### A6. ICCBased Color Space from Reference [P] [P2]
- **File**: Color space creation
- **Issue**: Cannot create ICCBased color space from indirect reference streams
- **Disabled test**: `PDFColorSpaceTests.swift:88` — "ICCBased from reference not implemented in v0.1.0"

### A7. Indirect References in Arrays [P] [P2]
- **File**: Object parser
- **Issue**: Arrays containing indirect object references not resolved
- **Disabled test**: `ObjectParserTests.swift:474` — "Indirect references in arrays not implemented in v0.1.0"

### A8. TrueType Table Parsing [P] [P2]
- **File**: `Sources/SwiftVerificarParser/PD/Font/TrueTypeFont.swift:31`
- **Issue**: Does not parse TrueType tables (cmap, head, hhea, hmtx) from embedded font programs
- **Impact**: Font metrics/glyph mapping unavailable for TrueType fonts

### Parser Disabled Tests Summary
| # | Test File | Line | Test Name | Blocked By |
|---|-----------|------|-----------|------------|
| 1 | PDFDocumentParserTests | 139 | Parse minimal PDF document | A1, A2 |
| 2 | PDFDocumentParserTests | 155 | getObject retrieves cached object | A1, A2 |
| 3 | PDFDocumentParserTests | 161 | getObject returns nil for missing | A1, A2 |
| 4 | PDFDocumentParserTests | 187 | COSParser header access | A1, A2 |
| 5 | PDFDocumentParserTests | 192 | COSParser xrefTable access | A1, A2 |
| 6 | PDFDocumentParserTests | 197 | COSParser trailer access | A1, A2 |
| 7 | PDFColorSpaceTests | 88 | ICCBased from array | A6 |
| 8 | PDFTextStripperTests | 404 | Single-quote operator | A4 |
| 9 | PDFTextStripperTests | 420 | Double-quote operator | A5 |
| 10 | ObjectParserTests | 474 | Complex nested structure | A7 |

---

## TRACK B — Parser Type Stubs in Validation (SwiftVerificar-validation)

### B1. Replace ParserTypes.swift Stubs with Real Imports [S → A1, A2] [P0]
- **File**: `Sources/SwiftVerificarValidation/ObjectModel/ParserTypes.swift:8`
- **Issue**: Contains placeholder `ASAtom`, `COSObjectKey`, `COSValue` behind `#if !canImport(SwiftVerificarParser)`
- **Action**: Once parser is stable at v0.2.0, update Package.swift to depend on parser package directly (not just via biblioteca), removing the need for stubs
- **Note**: 51 source files use `#if canImport(SwiftVerificarParser)` conditional imports

---

## TRACK C — Validation Wiring: PDF/UA Validators (SwiftVerificar-validation)

All items below are stub methods that return empty results. They need real implementations using parsed PDF data.

### C1. PDF/UA-1 Validator — 18 TODOs [S → B1] [P0]
**File**: `Sources/SwiftVerificarValidation/Validators/PDFUA1Validator.swift`

| # | Line | Method | What It Should Do |
|---|------|--------|-------------------|
| C1.1 | 122 | `detectClaimedConformance()` | Parse XMP for `pdfuaid:part` property |
| C1.2 | 158 | `validateStructure()` | Verify structure tree exists and is valid |
| C1.3 | 176 | `validateTaggedContent()` | Ensure all content tagged or marked artifact |
| C1.4 | 185 | `validateAlternativeText()` | Check alt text on figures, formulas, non-text |
| C1.5 | 194 | `validateLanguage()` | Verify Lang in document catalog |
| C1.6 | 203 | `validateReadingOrder()` | Validate logical reading order in structure tree |
| C1.7 | 212 | `validateNavigationAids()` | Check bookmarks, links, navigation |
| C1.8 | 221 | `validateTableStructure()` | Validate Table/TR/TH/TD elements |
| C1.9 | 230 | `validateListStructure()` | Validate L/LI/Lbl/LBody elements |
| C1.10 | 239 | `validateFormFields()` | Check structure, labels, descriptions |
| C1.11 | 248 | `validateAnnotations()` | Verify Contents or alt text on annotations |
| C1.12 | 256 | `extractAccessibilityFeatures()` | Return real features (currently empty set) |
| C1.13 | 275 | `validateGeneralRequirements()` | Private — general PDF/UA-1 checks |
| C1.14 | 288 | `validateAlternativeDescriptions()` | Private — alt description validation |
| C1.15 | 300 | `validateNaturalLanguage()` | Private — natural language spec |
| C1.16 | 313 | `validateLogicalStructure()` | Private — logical structure validation |
| C1.17 | 327 | `validateTables()` | Private — table validation |
| C1.18 | 341 | `validateLists()` | Private — list validation |

### C2. PDF/UA-2 Validator — 24 TODOs [S → B1] [P0]
**File**: `Sources/SwiftVerificarValidation/Validators/PDFUA2Validator.swift`

| # | Line | Method | What It Should Do |
|---|------|--------|-------------------|
| C2.1 | 142 | `detectClaimedConformance()` | Parse XMP for `pdfuaid:part="2"` |
| C2.2 | 178 | `validateStructure()` | Check PDF version ≥ 2.0 |
| C2.3 | 188 | `validateStructure()` | Verify structure tree exists |
| C2.4 | 201 | `validateSemanticElements()` | Check Em, Strong, Sub, Title, etc. |
| C2.5 | 211 | `validateTaggedContent()` | All content tagged or artifact |
| C2.6 | 221 | `validateAlternativeText()` | Alt text on figures, formulas |
| C2.7 | 231 | `validateLanguage()` | Document catalog Lang entry |
| C2.8 | 241 | `validateReadingOrder()` | Logical reading order |
| C2.9 | 251 | `validateNavigationAids()` | Bookmarks, links |
| C2.10 | 261 | `validateTableStructure()` | Table/TR/TH/TD with scope/headers |
| C2.11 | 271 | `validateListStructure()` | L/LI/Lbl/LBody elements |
| C2.12 | 281 | `validateHeadingHierarchy()` | H1-H6 nesting, sequential order |
| C2.13 | 291 | `validateFormFields()` | Structure, labels, descriptions |
| C2.14 | 301 | `validateAnnotations()` | Contents or alt text required |
| C2.15 | 311 | `validateAssociatedFiles()` | AF entries for accessible attachments |
| C2.16 | 320 | `validateMultimedia()` | Captions, transcripts, descriptions |
| C2.17 | 330 | `validateMathematicalContent()` | Alt text and markup |
| C2.18 | 338 | `extractAccessibilityFeatures()` | Real features (currently empty) |
| C2.19 | 357 | `validateGeneralRequirements()` | Private — general checks |
| C2.20 | 371 | `validateEnhancedSemantics()` | Private — semantic validation |
| C2.21 | 384 | `validateEnhancedTables()` | Private — enhanced table checks |
| C2.22 | 397 | `validateHeadings()` | Private — heading validation |
| C2.23 | 410 | `validateAFEntries()` | Private — associated files |
| C2.24 | 423 | `validateEnhancedAnnotations()` | Private — annotation checks |

---

## TRACK D — Validation Wiring: PDF/A Validators (SwiftVerificar-validation)

### D1. PDF/A-1 XMP Metadata Parsing [S → B1] [P1]
- **File**: `PDFA1Validator.swift:113`
- **Issue**: `detectClaimedConformance()` — needs XMP parsing for PDF/A-1 identification

### D2. PDF/A-1 Profile Loading [S → B1] [P1]
- **File**: `PDFA1Validator.swift:221`
- **Issue**: `loadProfile()` — creates minimal test profile instead of loading from validation-profiles

### D3. PDF/A-2 XMP Metadata Parsing [S → B1] [P1]
- **File**: `PDFA2Validator.swift:118`
- **Issue**: `detectClaimedConformance()` — needs XMP parsing

### D4. PDF/A-3 XMP Metadata Parsing [S → B1] [P1]
- **File**: `PDFA3Validator.swift:119`
- **Issue**: `detectClaimedConformance()` — needs XMP parsing

### D5. PDF/A-4 XMP Metadata Parsing [S → B1] [P1]
- **File**: `PDFA4Validator.swift:93`
- **Issue**: `detectClaimedConformance()` — needs XMP parsing

---

## TRACK E — Biblioteca Feature Gaps (SwiftVerificar-biblioteca)

### E1. Feature Extraction — 11 of 19 Types Not Extracted [P] [P1]
- **File**: `Sources/SwiftVerificarBiblioteca/Features/FeatureExtractorAdapter.swift`
- **Issue**: Only 8 of 19 feature types implemented (informationDictionary, metadata, pages, fonts, annotations, documentSecurity, outlines, lowLevelInfo). The remaining 11 are silently skipped:
  1. signatures
  2. embeddedFiles
  3. iccProfiles
  4. outputIntents
  5. graphicsStates
  6. colorSpaces
  7. patterns
  8. shadings
  9. xObjects
  10. properties
  11. interactiveFormFields
- **Action**: Implement extraction adapters for each, using parser data

---

## TRACK F — Documentation & Coordination

### F1. Update Root AGENTS.md Roadmap [P] [P2]
- **File**: `/Users/stovak/Projects/SwiftVerificar/AGENTS.md`
- **Issue**: Shows all phases as "Pending" — stale vs actual v0.1.0 state
- **Action**: Update to reflect completed v0.1.0 work and define v0.2.0 scope

### F2. Update collection.json for v0.2.0 [S → all tracks] [P2]
- **File**: `/Users/stovak/Projects/SwiftVerificar/collection.json`
- **Action**: Bump revision, update versions once v0.2.0 tags exist

---

## Dependency Graph

```
Track A (Parser Core)
  ├── A1 Stream Data ──┐
  ├── A2 Trailer Dict ─┤
  ├── A3 ToUnicode     │ (independent)
  ├── A4 ' operator    │ (independent)
  ├── A5 " operator    │ (independent)
  ├── A6 ICCBased      │ (independent)
  ├── A7 Indirect refs │ (independent)
  └── A8 TrueType      │ (independent)
                       │
                       ▼
              Track B (Stub Replacement)
                  B1 ──────────┐
                               │
                    ┌──────────┼──────────┐
                    ▼          ▼          ▼
              Track C      Track D    Track E
              (PDF/UA)     (PDF/A)    (Features)
              C1, C2       D1–D5     E1
                    │          │          │
                    └──────────┼──────────┘
                               ▼
                         Track F (Docs)
                         F1, F2
```

---

## Summary Counts

| Track | Package | Items | Priority | Parallelizable? |
|-------|---------|-------|----------|-----------------|
| A | parser | 8 items + 10 disabled tests | P0–P2 | Yes (all independent) |
| B | validation | 1 item | P0 | No (needs A1, A2) |
| C | validation | 42 stub methods | P0 | Yes (C1 ∥ C2, after B1) |
| D | validation | 5 items | P1 | Yes (all independent, after B1) |
| E | biblioteca | 11 feature types | P1 | Yes (independent) |
| F | root | 2 items | P2 | Yes |

**Total: 69 actionable items** (49 validation TODOs + 8 parser TODOs + 10 disabled tests + 2 doc items)

---

## Suggested Sprint Plan

### Sprint 1: Parser Foundations (Track A — P0 items)
- A1: Stream data reading
- A2: Trailer dictionary parsing
- Re-enable 6 disabled PDFDocumentParser tests
- **Gate**: Parser can parse a real PDF document end-to-end

### Sprint 2: Parser Completeness (Track A — P1/P2 items)
- A3: ToUnicode CMap
- A4, A5: Quote text operators
- A6: ICCBased from reference
- A7: Indirect refs in arrays
- A8: TrueType tables
- Re-enable remaining 4 disabled tests

### Sprint 3: Validation Wiring (Tracks B + C + D)
- B1: Replace stubs with real parser imports
- C1 + C2: Wire PDF/UA-1 and PDF/UA-2 validators (parallelizable)
- D1–D5: Wire PDF/A XMP detection (parallelizable)

### Sprint 4: Feature Extraction + Polish (Tracks E + F)
- E1: Implement 11 missing feature type extractors
- F1: Update AGENTS.md roadmap
- F2: Update collection.json
- **Gate**: Full end-to-end validation of a real PDF
