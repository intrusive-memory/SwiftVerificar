---
feature_name: OPERATION FRANKENSTEIN'S TOOLBOX
starting_point_commit: c9a523e45a1966efb8c7e3d7c639548a472d7fba
mission_branch: mission/frankensteins-toolbox/1
iteration: 1
---

# EXECUTION_PLAN.md — SwiftVerificar v0.2.0

> Source: `TODOLIST.md` — 69 actionable items extracted from all SwiftVerificar-* subpackages.

## Terminology

> **Mission** — A definable, testable scope of work. Defines scope, acceptance criteria, and dependency structure.

> **Sortie** — An atomic, testable unit of work executed by a single autonomous AI agent in one dispatch. One aircraft, one mission, one return.

> **Work Unit** — A grouping of sorties (package, component, phase).

---

## Work Units

| Work Unit | Directory | Sorties | Layer | Dependencies |
|-----------|-----------|---------|-------|--------------|
| parser | SwiftVerificar-parser | 4 | 1 | none |
| validation | SwiftVerificar-validation | 4 | 2 | parser |
| biblioteca | SwiftVerificar-biblioteca | 1 | 2 | parser |
| root | SwiftVerificar (root) | 1 | 3 | parser, validation, biblioteca |

---

## Work Unit: parser

**Directory**: `SwiftVerificar-parser`
**Build**: `cd SwiftVerificar-parser && xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'`

### Sortie 1: Stream Data Reading & Trailer Dictionary Parsing

**Priority**: 19.75 — Critical foundation; blocks all downstream work units and 5+ sorties transitively.

**Entry criteria**:
- [ ] First sortie — no prerequisites

**Tasks**:
1. In `Sources/SwiftVerificarParser/Parser/ObjectParser.swift:327`, replace `let streamData = Data()` with code that reads exactly `length` bytes from the tokenizer's underlying input stream into a `Data` buffer. The length is already extracted from the stream dictionary at line 320.
2. In `Sources/SwiftVerificarParser/Parser/XRefParser.swift:214`, implement `parseTrailerDictionary()` to parse a COS dictionary from the input data (using `<<` ... `>>` delimiters) and return the parsed `[ASAtom: COSValue]` dictionary. Reuse existing COS dictionary parsing logic from `ObjectParser` if available.
3. In `Tests/SwiftVerificarParserTests/PDFDocumentParserTests.swift`, re-enable 6 disabled tests at lines 139, 155, 161, 187, 192, 197 by removing the `.disabled` trait. Update test expectations if the implementations surface new data.
4. Run `xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'` and verify all tests pass, including the 6 re-enabled tests.

**Exit criteria**:
- [ ] `ObjectParser.parseStream()` reads `length` bytes from input — grep for `Data()` at the stream reading site in ObjectParser.swift returns 0 matches
- [ ] `XRefParser.parseTrailerDictionary()` has a non-stub body — grep for `return \[:\]` as sole implementation returns 0 matches
- [ ] 6 previously-disabled tests in PDFDocumentParserTests are enabled — grep for `.disabled` on those test names returns 0 matches
- [ ] `xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'` exits 0
- [ ] No existing tests regressed (test count >= previous count)

---

### Sortie 2: Text Extraction — ToUnicode & Quote Operators

**Priority**: 2.75 — Leaf sortie; no downstream dependents within parser. Independent of Sortie 3-4.

**Entry criteria**:
- [ ] Sortie 1 exit criteria met (stream data reading works — needed for font stream access)

**Tasks**:
1. In `Sources/SwiftVerificarParser/PD/PDFTextStripper.swift:249`, implement ToUnicode CMap mapping. When a font has a `/ToUnicode` stream, parse the CMap and use it to map character codes to Unicode values instead of raw byte-to-char conversion.
2. In the tokenizer (find the token/keyword enum), add support for the single-quote (`'`) PDF text operator (move to next line and show text — equivalent to T* followed by Tj).
3. In the tokenizer, add support for the double-quote (`"`) PDF text operator (set word/char spacing, move to next line, show text — equivalent to Tw, Tc, T*, Tj).
4. In `Tests/SwiftVerificarParserTests/PDFTextStripperTests.swift`, re-enable 2 disabled tests at lines 404 and 420.
5. Run `xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'` and verify all tests pass.

**Exit criteria**:
- [ ] `PDFTextStripper` applies ToUnicode CMap — grep for `ToUnicode` or `CMap` in PDFTextStripper.swift confirms mapping logic exists
- [ ] Tokenizer recognizes `'` as a valid PDF operator — grep for single-quote operator handling in tokenizer source confirms support
- [ ] Tokenizer recognizes `"` as a valid PDF operator — grep for double-quote operator handling in tokenizer source confirms support
- [ ] 2 previously-disabled tests in PDFTextStripperTests are enabled — grep for `.disabled` on those test names returns 0 matches
- [ ] `xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'` exits 0

---

### Sortie 3: Object Resolution — ICCBased Color Spaces & Indirect References in Arrays

**Priority**: 2.75 — Enables correct color space handling and array parsing. Independent of Sortie 2.

**Entry criteria**:
- [ ] Sortie 1 exit criteria met (stream data reading works — needed for ICC stream resolution)

**Tasks**:
1. Implement ICCBased color space creation from indirect reference streams. When `PDFColorSpace.create()` encounters an ICCBased array where the stream is an indirect reference, resolve the reference before creating the color space.
2. In `ObjectParser`, when parsing arrays, resolve indirect object references (N G R patterns) within array elements rather than treating them as raw tokens.
3. In `Tests/SwiftVerificarParserTests/PDFColorSpaceTests.swift:88`, re-enable the disabled ICCBased test.
4. In `Tests/SwiftVerificarParserTests/ObjectParserTests.swift:474`, re-enable the disabled indirect refs test.
5. Run `xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'` and verify all tests pass.

**Exit criteria**:
- [ ] ICCBased color space test re-enabled and passing — grep for `.disabled` on ICCBased test in PDFColorSpaceTests.swift returns 0 matches
- [ ] Indirect refs test re-enabled and passing — grep for `.disabled` on indirect refs test in ObjectParserTests.swift returns 0 matches
- [ ] `xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'` exits 0

---

### Sortie 4: TrueType Font Table Parsing

**Priority**: 6 — Foundation for font metrics; enables correct text positioning and glyph mapping.

**Entry criteria**:
- [ ] Sortie 1 exit criteria met (stream data reading works — needed for reading TrueType font data from streams)

**Tasks**:
1. In `Sources/SwiftVerificarParser/PD/Font/TrueTypeFont.swift`, implement a TrueType table directory parser to locate tables by tag within font data.
2. Implement `cmap` table parsing (character-to-glyph mapping) — at minimum Format 4 (segment mapping to delta values).
3. Implement `head` table parsing (font header) — extract unitsPerEm, indexToLocFormat, font bounding box.
4. Implement `hhea` table parsing (horizontal header) — extract ascent, descent, lineGap, numberOfHMetrics.
5. Implement `hmtx` table parsing (horizontal metrics) — extract advance widths and left side bearings.
6. Add unit tests in `Tests/SwiftVerificarParserTests/TrueTypeParserTests.swift` for table parsing: verify each table type parses from sample binary data.
7. Run `xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'` and verify all tests pass.

**Exit criteria**:
- [ ] `TrueTypeFont` exposes parsed `cmap`, `head`, `hhea`, `hmtx` table data — grep for these property names in TrueTypeFont.swift confirms they exist
- [ ] At least 4 unit tests exist for TrueType table parsing — grep for `@Test` in TrueTypeParserTests.swift returns >= 4 matches
- [ ] `xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'` exits 0
- [ ] No existing tests regressed

---

## Work Unit: validation

**Directory**: `SwiftVerificar-validation`
**Build**: `cd SwiftVerificar-validation && xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'`

### Sortie 1: Replace Parser Type Stubs with Real Imports

**Priority**: 13.5 — Gateway sortie; blocks all other validation sorties. High integration risk.

**Entry criteria**:
- [ ] parser Sortie 1 exit criteria met (parser can read streams and trailer dictionaries)

**Tasks**:
1. In `SwiftVerificar-validation/Package.swift`, add `SwiftVerificarParser` as a local path dependency (`path: "../SwiftVerificar-parser"`) for development. Add a comment: `// Release: switch to .package(url: "https://github.com/intrusive-memory/SwiftVerificar-parser.git", from: "0.2.0")`.
2. Verify that all 51 source files containing `#if canImport(SwiftVerificarParser)` / `import SwiftVerificarParser` compile correctly with the real parser types (not the stubs in `ParserTypes.swift`).
3. Confirm that the stub types in `Sources/SwiftVerificarValidation/ObjectModel/ParserTypes.swift` are correctly gated behind `#if !canImport(SwiftVerificarParser)` and do NOT compile when the real parser is available.
4. Run `xcodebuild build -scheme SwiftVerificarValidation -destination 'platform=macOS'` and resolve any type mismatches between stub types and real parser types.
5. Run `xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'` and verify all existing tests still pass.

**Exit criteria**:
- [ ] `Package.swift` lists `SwiftVerificarParser` as a dependency — grep for `SwiftVerificarParser` in Package.swift confirms `.package` entry
- [ ] `xcodebuild build -scheme SwiftVerificarValidation -destination 'platform=macOS'` exits 0
- [ ] `xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'` exits 0
- [ ] No existing tests regressed

---

### Sortie 2: XMP Conformance Detection & Profile Loading

**Priority**: 3 — Enables correct conformance identification. Parallel with S3/S4.

**Entry criteria**:
- [ ] validation Sortie 1 exit criteria met — `xcodebuild build -scheme SwiftVerificarValidation` exits 0

**Tasks**:
1. Implement `detectClaimedConformance()` in `Validators/PDFUA1Validator.swift:122` — parse XMP metadata from the document to find `pdfuaid:part` property. Return `.pdfua1` when `part == "1"`.
2. Implement `detectClaimedConformance()` in `Validators/PDFUA2Validator.swift:142` — parse XMP metadata for `pdfuaid:part == "2"`. Return `.pdfua2`.
3. Implement `detectClaimedConformance()` in `Validators/PDFA1Validator.swift:113` — parse XMP for `pdfaid:part` and `pdfaid:conformance` to identify PDF/A-1a or PDF/A-1b.
4. Implement `detectClaimedConformance()` in `Validators/PDFA2Validator.swift:118` — same pattern for PDF/A-2.
5. Implement `detectClaimedConformance()` in `Validators/PDFA3Validator.swift:119` — same pattern for PDF/A-3.
6. Implement `detectClaimedConformance()` in `Validators/PDFA4Validator.swift:93` — same pattern for PDF/A-4.
7. Implement `loadProfile()` in `Validators/PDFA1Validator.swift:221` — use `ValidationProfileLoader` to load the real PDF/A-1 profile from the validation-profiles package instead of creating a minimal stub profile.

**Exit criteria**:
- [ ] All 6 `detectClaimedConformance()` methods have non-stub bodies — grep for `TODO` or `return nil` as sole implementation in those methods returns 0 matches
- [ ] Each method references XMP metadata parsing — grep for `pdfuaid` or `pdfaid` in the 6 validator files confirms XMP namespace handling
- [ ] `PDFA1Validator.loadProfile()` calls `ValidationProfileLoader` — grep confirms the call exists (not a stub profile construction)
- [ ] `xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'` exits 0

---

### Sortie 3: PDF/UA-1 Validator — Wire All 18 Stub Methods

**Priority**: 3.25 — Major feature implementation. Parallel with S2 and S4.

**Entry criteria**:
- [ ] validation Sortie 1 exit criteria met — `xcodebuild build -scheme SwiftVerificarValidation` exits 0

**Tasks**:
1. **Structure tree validation**: Implement `validateStructure()` (line 158), `validateGeneralRequirements()` (line 275), and `validateLogicalStructure()` (line 313) — verify structure tree exists and is well-formed using parsed PDF structure tree data.
2. **Tagged content & alt text**: Implement `validateTaggedContent()` (line 176), `validateAlternativeText()` (line 185), and `validateAlternativeDescriptions()` (line 288) — ensure all content is tagged or marked as artifact; check alt text on figures and non-text content.
3. **Language & reading order**: Implement `validateLanguage()` (line 194), `validateReadingOrder()` (line 203), and `validateNaturalLanguage()` (line 300) — verify Lang entry in document catalog; validate logical reading order in structure tree.
4. **Navigation & annotations**: Implement `validateNavigationAids()` (line 212) and `validateAnnotations()` (line 248) — check bookmarks, links; verify Contents or alt text on annotations.
5. **Tables & lists**: Implement `validateTableStructure()` (line 221), `validateListStructure()` (line 230), `validateTables()` (line 327), and `validateLists()` (line 341) — validate Table/TR/TH/TD and L/LI/Lbl/LBody element structures.
6. **Forms & features**: Implement `validateFormFields()` (line 239) and `extractAccessibilityFeatures()` (line 256) — check form field accessibility; return real accessibility features instead of empty set.

**Exit criteria**:
- [ ] All 18 methods in `PDFUA1Validator.swift` have non-stub implementations — grep for `// TODO` in method bodies returns 0 matches
- [ ] No method returns an empty array unconditionally — grep for `return \[\]` as sole method body returns 0 matches
- [ ] `extractAccessibilityFeatures()` references real document properties (not hardcoded empty values)
- [ ] `xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'` exits 0

---

### Sortie 4: PDF/UA-2 Validator — Wire All 24 Stub Methods

**Priority**: 3.5 — Major feature implementation. Parallel with S2 and S3.

**Entry criteria**:
- [ ] validation Sortie 1 exit criteria met — `xcodebuild build -scheme SwiftVerificarValidation` exits 0

**Tasks**:
1. **Structure & semantics**: Implement `validateStructure()` (lines 178, 188), `validateSemanticElements()` (line 201), `validateGeneralRequirements()` (line 357), and `validateEnhancedSemantics()` (line 371) — verify PDF 2.0 version, structure tree, semantic elements (Em, Strong, Sub, Title).
2. **Tagged content & alt text**: Implement `validateTaggedContent()` (line 211) and `validateAlternativeText()` (line 221) — all content tagged or artifact; alt text on figures and formulas.
3. **Language, reading order, navigation**: Implement `validateLanguage()` (line 231), `validateReadingOrder()` (line 241), and `validateNavigationAids()` (line 251) — Lang entry, logical reading order, bookmarks/links.
4. **Tables, lists, headings**: Implement `validateTableStructure()` (line 261), `validateListStructure()` (line 271), `validateHeadingHierarchy()` (line 281), `validateEnhancedTables()` (line 384), and `validateHeadings()` (line 397) — Table/TR/TH/TD with scope/headers, L/LI/Lbl/LBody, H1-H6 nesting.
5. **Forms, annotations, files**: Implement `validateFormFields()` (line 291), `validateAnnotations()` (line 301), `validateAssociatedFiles()` (line 311), `validateAFEntries()` (line 410), and `validateEnhancedAnnotations()` (line 423) — form labels, annotation alt text, AF entries for accessible attachments.
6. **Multimedia, math, features**: Implement `validateMultimedia()` (line 320), `validateMathematicalContent()` (line 330), and `extractAccessibilityFeatures()` (line 338) — captions/transcripts, math alt text, real feature extraction.

**Exit criteria**:
- [ ] All 24 methods in `PDFUA2Validator.swift` have non-stub implementations — grep for `// TODO` in method bodies returns 0 matches
- [ ] No method returns an empty array unconditionally — grep for `return \[\]` as sole method body returns 0 matches
- [ ] PDF/UA-2-specific features referenced: grep for `pdfVersion` or `2.0` confirms version check, grep for `associatedFiles` or `AF` confirms AF handling
- [ ] `extractAccessibilityFeatures()` references real document properties (not hardcoded empty values)
- [ ] `xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'` exits 0

---

## Work Unit: biblioteca

**Directory**: `SwiftVerificar-biblioteca`
**Build**: `cd SwiftVerificar-biblioteca && xcodebuild test -scheme SwiftVerificarBiblioteca -destination 'platform=macOS'`

### Sortie 1: Feature Extraction — Implement 11 Missing Feature Types

**Priority**: 3 — Completes feature extraction coverage. Parallel with validation work unit.

**Entry criteria**:
- [ ] parser Sortie 1 exit criteria met (parser can read streams — needed for extracting ICC profiles, embedded files, etc.)

**Tasks**:
1. In `Sources/SwiftVerificarBiblioteca/Adapters/FeatureExtractorAdapter.swift`, add extraction logic for **signatures** — enumerate digital signature dictionaries from the PDF document's AcroForm `/SigFlags` and signature fields.
2. Add extraction for **embeddedFiles** and **iccProfiles** — enumerate `/EmbeddedFiles` name tree entries and ICC profile streams from `/OutputIntents` and color space definitions.
3. Add extraction for **outputIntents** and **graphicsStates** — enumerate `/OutputIntents` array from the document catalog and `/ExtGState` entries from page resources.
4. Add extraction for **colorSpaces**, **patterns**, and **shadings** — enumerate `/ColorSpace`, `/Pattern`, and `/Shading` entries from page resource dictionaries.
5. Add extraction for **xObjects**, **properties**, and **interactiveFormFields** — enumerate `/XObject` entries (images, forms), `/Properties` entries (marked content), and `/AcroForm` fields from the document catalog.
6. Remove the "silently skipped" comment block at lines 103-106 and add `isEnabled(...)` checks for each new feature type, following the same pattern as the existing 8 types.
7. Run `xcodebuild test -scheme SwiftVerificarBiblioteca -destination 'platform=macOS'` and verify all tests pass.

**Exit criteria**:
- [ ] `SwiftFeatureExtractor.extract(from:)` handles all 19 `FeatureType` cases — grep for `case` in the extraction switch/if chain shows 19 feature types handled
- [ ] The "silently skipped" comment is removed — grep for `silently skipped` in FeatureExtractorAdapter.swift returns 0 matches
- [ ] `xcodebuild test -scheme SwiftVerificarBiblioteca -destination 'platform=macOS'` exits 0

---

## Work Unit: root

**Directory**: `SwiftVerificar` (project root)

### Sortie 1: Documentation Update & Integration Verification

**Priority**: 1.75 — Final verification and documentation. No downstream dependents.

**Entry criteria**:
- [ ] All parser sorties (S1-S4) completed — `xcodebuild test -scheme SwiftVerificarParser` exits 0
- [ ] All validation sorties (S1-S4) completed — `xcodebuild test -scheme SwiftVerificarValidation` exits 0
- [ ] biblioteca Sortie 1 completed — `xcodebuild test -scheme SwiftVerificarBiblioteca` exits 0

**Tasks**:
1. Update `AGENTS.md` roadmap section to reflect v0.1.0 as completed and define v0.2.0 scope (parser core gaps fixed, validation wired, feature extraction complete).
2. Update `collection.json` — bump revision number, update package versions to v0.2.0 for all 5 packages.
3. Verify cross-package integration by running build and test commands for all packages in dependency order:
   - `cd SwiftVerificar-parser && xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'`
   - `cd SwiftVerificar-validation-profiles && xcodebuild test -scheme SwiftVerificarValidationProfiles -destination 'platform=macOS'`
   - `cd SwiftVerificar-wcag-algs && xcodebuild test -scheme SwiftVerificarWCAGAlgs -destination 'platform=macOS'`
   - `cd SwiftVerificar-validation && xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'`
   - `cd SwiftVerificar-biblioteca && xcodebuild test -scheme SwiftVerificarBiblioteca -destination 'platform=macOS'`

**Exit criteria**:
- [ ] `AGENTS.md` contains v0.2.0 scope — grep for `v0.2.0` or `0.2.0` in AGENTS.md confirms presence
- [ ] `collection.json` has updated versions — grep for `0.2.0` in collection.json confirms version strings
- [ ] All 5 `xcodebuild test` commands listed above exit 0

---

## Parallelism Structure

**Critical Path**: parser S1 → validation S1 → validation S4 (3 sorties, longest chain by method count)

**Parallel Execution Groups**:

- **Group 1** (sequential — must go first):
  - parser S1 (Supervising Agent)

- **Group 2** (after parser S1 completes — up to 5 concurrent):
  - parser S2 (Agent 1 — worktree isolation, same package)
  - parser S3 (Agent 2 — worktree isolation, same package)
  - parser S4 (Agent 3 — worktree isolation, same package)
  - validation S1 (Agent 4 — different package, no isolation needed)
  - biblioteca S1 (Agent 5 — different package, no isolation needed)
  - **Note**: parser S2/S3/S4 modify disjoint files; worktree isolation prevents build conflicts. Merge back to development branch before Group 3.

- **Group 3** (after validation S1 completes — up to 3 concurrent):
  - validation S2 (Agent 1 — worktree isolation, same package)
  - validation S3 (Agent 2 — worktree isolation, same package)
  - validation S4 (Agent 3 — worktree isolation, same package)
  - **Note**: S2/S3/S4 modify different validator files. Worktree isolation required for same-package parallel work.

- **Group 4** (after all Groups 1-3):
  - root S1 (Supervising Agent)

**Agent Constraints**:
- All sorties include build/compile steps — each runs as a primary sortie agent
- Same-package parallel sorties require worktree isolation to avoid build conflicts
- Cross-package parallel sorties (validation S1 ∥ biblioteca S1) are naturally isolated

---

## Open Questions & Missing Documentation

### Resolved by Refinement

| Sortie | Issue Type | Original | Resolution |
|--------|-----------|----------|------------|
| validation S1 | Open question | "GitHub URL or local path" — v0.2.0 tag won't exist yet | Use local path dependency (`path: "../SwiftVerificar-parser"`) during development. Switch to GitHub URL at release. Task updated. |
| validation S2 | Vague criterion | "return correct conformance values (not nil)" | Replaced with: grep for TODO/return nil; grep for XMP namespace handling |
| validation S3 | Vague criterion | "produces PDFUAIssue results when given non-compliant input" | Replaced with: grep for TODO in method bodies; grep for unconditional `return []` |
| validation S4 | Vague criterion | "produces PDFUAIssue results when given non-compliant input" | Same as S3 |
| validation S3-S4 | Vague criterion | "function correctly" / "populated AccessibilityFeatures struct" | Replaced with specific grep checks for document property references |
| root S1 | Missing specifics | "All 5 packages build and test successfully" without commands | Added all 5 explicit xcodebuild commands with schemes and destinations |
| parser S3 (original) | Non-atomic | Combined ICCBased + indirect refs + TrueType tables (3 concerns) | Split into S3 (object resolution) + S4 (TrueType tables) |

### No Blocking Issues Remain

All open questions have been resolved during refinement. Plan is ready for execution.

---

## Summary

| Metric | Value |
|--------|-------|
| Work units | 4 |
| Total sorties | 10 |
| Dependency structure | 3 layers |
| Critical path length | 3 sorties (parser S1 → validation S1 → validation S4) |
| Maximum parallelism | 5 concurrent agents (Group 2) |

### Layer Dependency Map

```
Layer 1:  [parser S1] ──► [parser S2]  (sequential within parser)
                    ├──► [parser S3]  (parallel with S2, S4)
                    └──► [parser S4]  (parallel with S2, S3)

Layer 2:  [validation S1] ──► [validation S2]  (sequential)
                         ├──► [validation S3]  (parallel with S2, S4)
                         └──► [validation S4]  (parallel with S2, S3)
          [biblioteca S1]                       (parallel with validation)

Layer 3:  [root S1]                             (after all Layer 1-2)
```

### Priority Rankings

| Rank | Sortie | Priority | Rationale |
|------|--------|----------|-----------|
| 1 | parser S1 | 19.75 | Blocks everything; highest dependency depth |
| 2 | validation S1 | 13.5 | Gateway for all validation work |
| 3 | parser S4 | 6.0 | Foundation for font metrics; complex binary parsing |
| 4 | validation S4 | 3.5 | 24-method implementation; largest single sortie |
| 5 | validation S3 | 3.25 | 18-method implementation |
| 6 | validation S2 | 3.0 | XMP detection across 6 validators |
| 7 | biblioteca S1 | 3.0 | 11 feature types to implement |
| 8 | parser S2 | 2.75 | Text extraction enhancements |
| 9 | parser S3 | 2.75 | Object resolution fixes |
| 10 | root S1 | 1.75 | Documentation only; no downstream impact |
