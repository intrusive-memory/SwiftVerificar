# SwiftVerificar Execution Plan

This document is the canonical instruction set for porting the veraPDF Java ecosystem to Swift. It is designed to be consumed by autonomous Claude Code agents operating with minimal human intervention. Every section is prescriptive. If a step is ambiguous, the agent MUST stop and ask rather than guess.

---

## Table of Contents

1. [Global Rules](#1-global-rules)
2. [Dependency Graph and Execution Order](#2-dependency-graph-and-execution-order)
3. [Sprint Execution Model](#3-sprint-execution-model)
4. [Sprint Supervisor](#4-sprint-supervisor)
5. [Git Workflow](#5-git-workflow)
6. [Build and Test Standards](#6-build-and-test-standards)
7. [Shared Type Contracts](#7-shared-type-contracts)
8. [Package Sprints: SwiftVerificar-parser](#8-package-swiftverificar-parser)
9. [Package Sprints: SwiftVerificar-validation-profiles](#9-package-swiftverificar-validation-profiles)
10. [Package Sprints: SwiftVerificar-wcag-algs](#10-package-swiftverificar-wcag-algs)
11. [Package Sprints: SwiftVerificar-validation](#11-package-swiftverificar-validation)
12. [Package Sprints: SwiftVerificar-biblioteca](#12-package-swiftverificar-biblioteca)
13. [Reconciliation Passes](#13-reconciliation-passes)
14. [Error Recovery](#14-error-recovery)

---

## 1. Global Rules

These rules apply to every agent, every package, and every sprint. They are non-negotiable.

### 1.1 Language and Platform

- Swift 6.0+ with strict concurrency checking enabled.
- Platforms: macOS 14.0+ (`macOS(.v14)`), iOS 17.0+ (`iOS(.v17)`).
- Use Swift idioms: protocols over abstract classes, enums with associated values over class hierarchies, actors for shared mutable state, `Sendable` conformance on all public types.

### 1.2 Build System

- **NEVER** use `swift build` or `swift test`.
- **ALWAYS** use `xcodebuild` for building and testing.
- Build command: `xcodebuild build -scheme <SchemeName> -destination 'platform=macOS'`
- Test command: `xcodebuild test -scheme <SchemeName> -destination 'platform=macOS'`
- If XcodeBuildMCP tools are available, prefer `swift_package_build` and `swift_package_test`.

### 1.3 Testing Standards

- **Minimum 90% code coverage** on all new code. Measure with `xcodebuild test -enableCodeCoverage YES`.
- **All tests must pass** before any commit.
- **Use Swift Testing framework** (`import Testing`, `@Test`, `#expect`). Do NOT use XCTest.
- **No flaky tests**: No `Task.sleep`, no `Thread.sleep`, no `DispatchQueue.asyncAfter`, no timeouts, no real network calls, no file system race conditions. If async behavior must be tested, use deterministic patterns (e.g., pass in a clock, use `AsyncStream`, or mock the dependency).
- **No test pollution**: Each test must be independent. No shared mutable state between tests. No reliance on test execution order.
- Test file naming: `<TypeName>Tests.swift` in the package's `Tests/` target.
- One test file per major type or logical grouping.

### 1.4 Code Style

- All public types and methods must have doc comments (`///`).
- No force unwraps (`!`) in production code. Use `guard let`, `if let`, or `throws`.
- No `print()` statements in production code. Use `os.Logger` if logging is needed.
- Prefer value types (`struct`, `enum`) over reference types (`class`).
- Use `actor` for types that manage shared mutable state.
- All public types must conform to `Sendable`.
- All model types must conform to `Codable` where feasible.

### 1.5 File Organization

- One primary type per file. Supporting types (small enums, typealiases) may share a file with their parent type.
- File naming: `<TypeName>.swift` (e.g., `COSValue.swift`, `PDFToken.swift`).
- Group files in subdirectories by logical module within `Sources/<TargetName>/`:
  ```
  Sources/SwiftVerificarParser/
  ├── COS/
  │   ├── COSValue.swift
  │   ├── COSStream.swift
  │   └── ASAtom.swift
  ├── Parser/
  │   ├── PDFTokenizer.swift
  │   └── PDFDocumentParser.swift
  └── PD/
      ├── PDFDocument.swift
      └── PDFPage.swift
  ```

### 1.6 Dependency and Sandbox Compliance

**App Store Sandbox Rule**: This code must be eligible for App Store distribution under macOS and iOS sandboxing. The entire purpose of this port is to eliminate Java/Python runtime dependencies that prevent App Store submission.

**Allowed dependencies**:
- Apple first-party frameworks: Foundation, CoreGraphics, PDFKit, CryptoKit, os, Security, Accelerate, CoreText.
- SPM packages that are pure Swift source code with no binary artifacts, no embedded executables, and no shell scripts that run at build time. If in doubt, do NOT add the dependency.
- Inter-package dependencies declared in `Package.swift` as local path dependencies using `path: "../SwiftVerificar-<name>"`.

**Forbidden**:
- Any dependency that bundles executable binaries (Java JARs, Python scripts, native CLI tools).
- Any use of `Process()`, `NSTask`, `posix_spawn`, `exec*`, `system()`, or `dlopen()` in production code.
- Any dependency that uses `@_implementationOnly import` of system libraries not available in the App Store sandbox.
- Any dependency that requires entitlements not available to sandboxed apps.

**Every sprint exit check must verify**: no forbidden API usage has been introduced. See Section 3.4 for the exact check.

---

## 2. Dependency Graph and Execution Order

### 2.1 The Graph

```
SwiftVerificar-parser             (Layer 0 — no dependencies)
SwiftVerificar-validation-profiles (Layer 0 — no dependencies)
SwiftVerificar-wcag-algs          (Layer 0 — no dependencies)

SwiftVerificar-validation          (Layer 1 — depends on: validation-profiles)
SwiftVerificar-biblioteca          (Layer 2 — depends on: parser, validation, validation-profiles, wcag-algs)
```

### 2.2 Allowed Imports Per Package

This table is the law. An agent MUST NOT add an import that is not listed here.

| Package | May Import |
|---------|-----------|
| SwiftVerificar-parser | Apple frameworks only |
| SwiftVerificar-validation-profiles | Apple frameworks only |
| SwiftVerificar-wcag-algs | Apple frameworks only |
| SwiftVerificar-validation | Apple frameworks + `SwiftVerificarValidationProfiles` |
| SwiftVerificar-biblioteca | Apple frameworks + `SwiftVerificarParser` + `SwiftVerificarValidation` + `SwiftVerificarValidationProfiles` + `SwiftVerificarWCAGAlgs` |

**Violation protocol**: If an agent discovers it needs a type from a package not in its allowed imports, it MUST NOT import that package. Instead:
1. Define a local protocol or type that captures the needed interface.
2. Document the need in PROGRESS.md under a `## Cross-Package Needs` section.
3. The reconciliation pass (Section 13) will resolve this by either moving the type to a shared location or adding a sanctioned dependency.

### 2.3 Execution Rules

1. **Layer 0**: Launch three agents in parallel, one per package. Each agent works through its sprints sequentially.
2. **Layer 1**: Begin ONLY after `SwiftVerificar-validation-profiles` has completed ALL sprints, all tests pass, and its PR is created.
3. **Layer 2**: Begin ONLY after ALL four other packages have completed ALL sprints, all tests pass, and their PRs are created.
4. A Layer 0 agent MUST NOT wait for other Layer 0 agents.
5. No circular dependencies. The dependency graph is a DAG. If an agent's work would create a cycle, STOP and document the issue.

---

## 3. Sprint Execution Model

### 3.1 What Is a Sprint

A Sprint is the atomic unit of work. Each Sprint:
- Runs in a **single, fresh agent context window**. When a Sprint completes, the agent context is discarded.
- Creates a **bounded set of types** (target: 6-10 types per Sprint, never more than 12).
- Produces a **single commit** on the `development` branch.
- Has **entry checks** that must pass before work begins.
- Has **exit checks** that must pass before the commit.

### 3.2 PROGRESS.md — The Handoff Document

Every package has a `PROGRESS.md` file in its root directory. This is the sole mechanism for state transfer between Sprint agents. An agent starting a Sprint reads this file FIRST. An agent finishing a Sprint updates this file LAST (before committing).

**Format** (agents must follow this exactly):

```markdown
# <PackageName> Progress

## Current State
- Last completed sprint: <N>
- Last commit hash: <hash>
- Build status: passing | failing
- Total test count: <N>
- Cumulative coverage: <N>%

## Completed Sprints
- Sprint 1: <Name> — <N> types, <N> tests ✅
- Sprint 2: <Name> — <N> types, <N> tests ✅
- ...

## Next Sprint
- Sprint <N+1>: <Name>
- Types to create: <list>
- Reference: TODO.md section <X>

## Files Created (cumulative)
### Sources
- Sources/<Target>/<Subdir>/<File>.swift
- ...

### Tests
- Tests/<Target>Tests/<File>.swift
- ...

## Cross-Package Needs
- <description of any type or interface needed from another package>
- ...
```

### 3.3 Sprint Entry Checks

Before writing any code, the agent MUST:

1. **Read PROGRESS.md**. If it does not exist, this is Sprint 1 — create it.
2. **Verify previous sprint is complete**. If PROGRESS.md shows the previous sprint as incomplete, do NOT start a new sprint. Finish the incomplete one first.
3. **Run the build** (`xcodebuild build`). It must succeed. If it fails, fix the issue before starting new work.
4. **Run all existing tests** (`xcodebuild test`). They must all pass. If any fail, fix them before starting new work.
5. **Verify dependency compliance**. Run:
   ```bash
   grep -r "^import " Sources/<TargetName>/ | grep -v "Foundation\|CoreGraphics\|PDFKit\|CryptoKit\|os\|Security\|Accelerate\|CoreText\|Testing" | sort -u
   ```
   Every import in the output must be in the "May Import" table (Section 2.2). If there is a violation, fix it before proceeding.
6. **Read the Sprint definition** from this document (Sections 8-12) to know exactly what types to create.
7. **Read the corresponding section of TODO.md** for detailed type mappings, field names, and consolidation logic.

### 3.4 Sprint Exit Checks

After completing all types and tests for the sprint, the agent MUST verify ALL of the following:

```
[ ] All new source files are under Sources/<TargetName>/
[ ] All new test files are under Tests/<TargetNameTests>/
[ ] xcodebuild build succeeds with zero errors
[ ] xcodebuild build produces zero warnings (or only pre-existing warnings from earlier sprints)
[ ] xcodebuild test passes — zero failures, zero skipped
[ ] Code coverage on new code is ≥ 90%
[ ] No flaky test patterns (grep for: Task.sleep, Thread.sleep, DispatchQueue.asyncAfter, XCTWaiter)
[ ] All public types have doc comments
[ ] All public types conform to Sendable
[ ] No force unwraps in production code (grep for: [^?]! excluding test files)
[ ] Dependency compliance check passes (Section 3.3, step 5)
[ ] Sandbox compliance check passes:
    grep -rn "Process()\|NSTask\|posix_spawn\|dlopen\|system(" Sources/<TargetName>/
    (must return zero results)
[ ] PROGRESS.md is updated with this sprint's results
[ ] Commit message follows the format in Section 5.2
[ ] Only files created/modified in this sprint are staged
```

### 3.5 Sprint Dispatch Protocol

The orchestrating agent (or human) dispatches sprints using this prompt template:

```
You are working on package <PackageName> in /Users/stovak/Projects/SwiftVerificar/<PackageName>/.

Read EXECUTION_PLAN.md at /Users/stovak/Projects/SwiftVerificar/EXECUTION_PLAN.md.
Read PROGRESS.md in the package root (if it exists).
Read the TODO.md in the package root for detailed type mappings.

Execute Sprint <N>: <Name>.

Follow the Sprint Entry Checks (Section 3.3), build all types and tests listed for this sprint,
then follow the Sprint Exit Checks (Section 3.4). Commit when all checks pass.
```

---

## 4. Sprint Supervisor

The Sprint Supervisor is an orchestrating agent that coordinates all sprint execution across all packages. It does NOT write production code. It dispatches sprint agents, monitors progress, resolves cross-package questions, and gates layer transitions.

### 4.1 Supervisor Responsibilities

1. **Dispatch sprints**: Launch sprint agents using the prompt template in Appendix D. One sprint per agent. One agent per sprint. The supervisor dispatches the next sprint for a package only after the current sprint commits successfully.

2. **Parallel dispatch for Layer 0**: The supervisor launches sprints for parser, validation-profiles, and wcag-algs concurrently. Each package's sprints run sequentially within that package, but the three packages advance independently in parallel.

3. **Monitor completion**: After dispatching a sprint, the supervisor reads the package's `PROGRESS.md` to confirm the sprint completed. It checks:
   - Did the sprint commit? (check `Last completed sprint` field)
   - Did tests pass? (check `Build status` field)
   - Are there cross-package needs? (check `Cross-Package Needs` section)
   - Was the sprint partial? (check for `(partial)` in sprint status)

4. **Gate layer transitions**: The supervisor enforces layer prerequisites:
   - Layer 1 (`SwiftVerificar-validation`) starts ONLY when `SwiftVerificar-validation-profiles` shows all 7 sprints complete in PROGRESS.md.
   - Layer 2 (`SwiftVerificar-biblioteca`) starts ONLY when all four other packages show all sprints complete in their PROGRESS.md files.

5. **Handle cross-package questions**: When a sprint agent documents a need in PROGRESS.md `Cross-Package Needs`, the supervisor decides:
   - If the needed type exists in an allowed dependency: instruct the next sprint to import it.
   - If the needed type is in a non-allowed package: instruct the sprint agent to define a local protocol. Log the need for reconciliation.
   - If two packages are defining conflicting versions of the same concept: log it for reconciliation. Do NOT stop either package's progress.

6. **Handle sprint failures**: If a sprint agent:
   - Commits partial work: dispatch a continuation sprint to complete the remainder.
   - Fails to build: dispatch a new agent to fix the build, then continue.
   - Exhausts context without committing: dispatch a new agent that reads the uncommitted files and PROGRESS.md, then restarts or completes the sprint.

7. **Coordinate reconciliation**: After all packages complete all sprints, the supervisor:
   - Reads all five PROGRESS.md files.
   - Collects all `Cross-Package Needs` entries.
   - Determines which reconciliation actions are needed (per Section 13 — Reconciliation Passes).
   - Dispatches reconciliation sprints in dependency order.

### 4.2 Supervisor State — SUPERVISOR_STATE.md

The supervisor maintains its own state file at the project root: `/Users/stovak/Projects/SwiftVerificar/SUPERVISOR_STATE.md`. This file is the supervisor's equivalent of PROGRESS.md — it allows a new supervisor context to pick up where the previous one left off.

**Format** (supervisor must follow this exactly):

```markdown
# Sprint Supervisor State

## Last Updated
<ISO 8601 timestamp>

## Layer 0 Status

### SwiftVerificar-parser
- Current sprint: <N> of 14
- Status: in_progress | complete | blocked
- Last commit: <hash>
- Cross-package needs: <count>
- Notes: <any issues>

### SwiftVerificar-validation-profiles
- Current sprint: <N> of 7
- Status: in_progress | complete | blocked
- Last commit: <hash>
- Cross-package needs: <count>
- Notes: <any issues>

### SwiftVerificar-wcag-algs
- Current sprint: <N> of 10
- Status: in_progress | complete | blocked
- Last commit: <hash>
- Cross-package needs: <count>
- Notes: <any issues>

## Layer 1 Status

### SwiftVerificar-validation
- Prerequisite met: yes | no (validation-profiles complete?)
- Current sprint: <N> of 16 | not started
- Status: not_started | in_progress | complete | blocked
- Last commit: <hash>
- Cross-package needs: <count>
- Notes: <any issues>

## Layer 2 Status

### SwiftVerificar-biblioteca
- Prerequisites met: yes | no (all 4 packages complete?)
- Current sprint: <N> of 11 | not started
- Status: not_started | in_progress | complete | blocked
- Last commit: <hash>
- Cross-package needs: <count>
- Notes: <any issues>

## Cross-Package Needs Registry
| # | Source Package | Need Description | Target Package | Resolution | Status |
|---|---------------|-----------------|---------------|------------|--------|
| 1 | <package> | <what is needed> | <where it lives> | pending / local_protocol / reconciliation | open / resolved |

## Decisions Log
| # | Date | Question | Decision | Rationale |
|---|------|----------|----------|-----------|
| 1 | <date> | <question from sprint agent> | <what was decided> | <why> |

## Reconciliation Status
- Pass 1: not_started | in_progress | complete
- Pass 2: not_started | in_progress | complete
- ...
- All packages build: yes | no
- All tests pass: yes | no
- Cross-package needs resolved: <N> of <M>
```

### 4.3 Supervisor Operating Rules

1. **The supervisor never writes production code.** It only reads PROGRESS.md files, updates SUPERVISOR_STATE.md, and dispatches sprint agents.

2. **The supervisor never overrides the execution plan.** All sprint definitions, entry/exit checks, dependency rules, and sandbox rules come from this document. The supervisor enforces them — it does not change them.

3. **The supervisor is stateless between contexts.** When a supervisor context is exhausted or restarted, the new supervisor reads SUPERVISOR_STATE.md to reconstruct the full picture. It does NOT rely on memory from a previous context.

4. **The supervisor reads, then acts.** On startup (or restart), the supervisor MUST:
   a. Read `SUPERVISOR_STATE.md` (if it exists).
   b. Read all five `PROGRESS.md` files (if they exist).
   c. Reconcile any differences (PROGRESS.md is ground truth; SUPERVISOR_STATE.md is the supervisor's view).
   d. Determine what action to take next.
   e. Update SUPERVISOR_STATE.md.
   f. Dispatch the next sprint(s).

5. **The supervisor dispatches sprints one at a time per package.** It does NOT dispatch Sprint N+1 for a package until Sprint N's PROGRESS.md confirms completion. It MAY dispatch sprints for different packages in parallel.

6. **The supervisor logs all decisions.** Any judgment call (e.g., "parser and wcag-algs both defined BoundingBox — reconcile later") goes in the Decisions Log table in SUPERVISOR_STATE.md.

7. **The supervisor gates layer transitions with verification.** Before starting Layer 1, the supervisor MUST:
   - Read `SwiftVerificar-validation-profiles/PROGRESS.md`.
   - Confirm `Last completed sprint: 7` and `Build status: passing`.
   - Run `xcodebuild build` on validation-profiles to verify independently.
   - Only then dispatch validation Sprint 1.

   The same verification applies before starting Layer 2 (all four prerequisite packages).

### 4.4 Supervisor Dispatch Protocol

The supervisor is started (or restarted) using this prompt:

```
You are the Sprint Supervisor for the SwiftVerificar project at /Users/stovak/Projects/SwiftVerificar/.

Your role is to orchestrate sprint execution across 5 packages. You do NOT write production code.

FIRST, read these files in order:
1. /Users/stovak/Projects/SwiftVerificar/EXECUTION_PLAN.md (the master plan — your operating manual)
2. /Users/stovak/Projects/SwiftVerificar/SUPERVISOR_STATE.md (your state — if it exists)
3. All five PROGRESS.md files (if they exist):
   - SwiftVerificar-parser/PROGRESS.md
   - SwiftVerificar-validation-profiles/PROGRESS.md
   - SwiftVerificar-wcag-algs/PROGRESS.md
   - SwiftVerificar-validation/PROGRESS.md
   - SwiftVerificar-biblioteca/PROGRESS.md

Follow Section 4 of EXECUTION_PLAN.md. Determine the current state of all packages.
Dispatch the next sprint(s) that should run. Update SUPERVISOR_STATE.md after every action.

Continue dispatching sprints until all packages are complete or you need human input.
```

### 4.5 Supervisor Context Exhaustion

The supervisor itself will exhaust its context over the course of 58+ sprints. When this happens:

1. The supervisor updates SUPERVISOR_STATE.md with its current view of all packages.
2. The supervisor terminates.
3. A new supervisor is launched using the dispatch prompt in Section 4.4.
4. The new supervisor reads SUPERVISOR_STATE.md and all PROGRESS.md files to reconstruct state.
5. The new supervisor continues dispatching from where the previous one left off.

Because the supervisor's state is fully externalized in SUPERVISOR_STATE.md, there is no loss of continuity between supervisor instances. The supervisor should proactively update SUPERVISOR_STATE.md after every dispatch and every status check — not just at context exhaustion.

---

## 5. Git Workflow

### 5.1 Branch Strategy

Each package is its own git repository. Each has its own git history.

For each package, Sprint 1 must:
1. `cd` into the package directory.
2. Create and checkout a `development` branch from `main`:
   ```bash
   git checkout -b development
   ```
3. All subsequent sprints work on `development`.

### 5.2 Commit Discipline

- **One commit per Sprint.** Not after every file — after every Sprint.
- Commit message format (use HEREDOC):
  ```bash
  git commit -m "$(cat <<'EOF'
  Sprint N: <Sprint Name>

  - Types added: <list>
  - Tests added: <count> tests in <count> files
  - Coverage: <X>%
  - All tests passing: yes
  - Dependency check: clean
  - Sandbox check: clean

  Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
  EOF
  )"
  ```
- Before committing: run the full test suite. If any test fails, fix it before committing.
- Stage specific files by name. Do NOT use `git add -A` or `git add .`.
- ALWAYS stage PROGRESS.md along with source and test files.

### 5.3 Pull Request Creation

After ALL sprints for a package are complete and committed on `development`:

1. Push the `development` branch:
   ```bash
   git push -u origin development
   ```
2. Create a PR:
   ```bash
   gh pr create --base main --head development --title "<PackageName>: Complete Java-to-Swift port" --body "$(cat <<'EOF'
   ## Summary
   - Ported <N> Java classes to <M> Swift types (<X>% reduction)
   - <Total> unit tests with <Y>% code coverage
   - All tests passing
   - Dependency graph: compliant (no circular dependencies)
   - Sandbox compliance: verified (no forbidden APIs)

   ## Sprints Completed
   - Sprint 1: <name>
   - Sprint 2: <name>
   - ...

   ## Cross-Package Needs (for reconciliation)
   - <any items from PROGRESS.md Cross-Package Needs section>

   ## Test Plan
   - [ ] CI passes all unit tests
   - [ ] Code coverage meets 90% threshold
   - [ ] No compiler warnings
   - [ ] No sandbox-violating APIs

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   EOF
   )"
   ```

---

## 6. Build and Test Standards

### 6.1 Verification Commands

```bash
# Build (must produce zero errors)
xcodebuild build -scheme <SchemeName> -destination 'platform=macOS' 2>&1

# Test with coverage (must produce zero failures)
xcodebuild test -scheme <SchemeName> -destination 'platform=macOS' -enableCodeCoverage YES 2>&1
```

### 6.2 What Counts Toward Coverage

- All `public` and `internal` functions and methods with logic.
- All code paths in `switch` statements and `if/else` branches.
- Error paths (`throw`, `catch`).
- Edge cases: empty collections, nil optionals, boundary values.

### 6.3 What Does NOT Need Tests

- Simple stored property access (getters/setters with no logic).
- `Codable` conformance synthesized by the compiler.
- Private helpers thoroughly exercised by public API tests.

---

## 7. Shared Type Contracts

### 7.1 Type Ownership Table

The **defining package** is the source of truth. Consuming packages import the type — they do NOT redefine it.

| Type Name | Defining Package | Consumed By |
|-----------|-----------------|-------------|
| `PDFFlavour` (enum) | validation-profiles | validation, biblioteca |
| `Specification` (enum) | validation-profiles | validation, biblioteca |
| `PDFObjectType` (enum, 188 cases) | validation-profiles | validation |
| `ValidationProfile` (struct) | validation-profiles | validation, biblioteca |
| `ValidationRule` (struct) | validation-profiles | validation, biblioteca |
| `RuleID` (struct) | validation-profiles | validation, biblioteca |
| `ErrorDetails` (struct) | validation-profiles | validation, biblioteca |
| `ProfileVariable` (struct) | validation-profiles | validation |
| `RuleTag` (enum) | validation-profiles | validation |
| `StructureElementType` (enum, 41+ cases) | validation | biblioteca |
| `ValidatedOperator` (enum, ~50 cases) | validation | biblioteca |
| `PDFDocument` (class/actor) | parser | biblioteca |
| `StructureElement` (struct) | parser | biblioteca |
| `COSValue` (enum) | parser | biblioteca |
| `SemanticType` (enum, 44 cases) | wcag-algs | biblioteca |
| `ContrastCalculator` (struct) | wcag-algs | biblioteca |
| `ValidationResult` (struct) | biblioteca | (top-level consumer) |

### 7.2 Contract Rules

1. **Layer 0 packages define types independently.** They do not import from each other. If two Layer 0 packages need a similar concept (e.g., both parser and wcag-algs have a "structure element" concept), each defines its own version. Reconciliation happens later.

2. **Layer 1 packages import from their dependencies only.** `SwiftVerificar-validation` imports from `SwiftVerificarValidationProfiles` and uses its types directly. It does NOT duplicate `PDFFlavour`, `ValidationProfile`, etc.

3. **Layer 2 imports from all dependencies.** `SwiftVerificar-biblioteca` imports all four packages and acts as the integration point. If there are type conflicts (e.g., parser's `StructureElement` vs wcag-algs' semantic nodes), biblioteca resolves them with adapter types or protocols.

4. **No cross-layer imports in the wrong direction.** validation-profiles MUST NOT import from validation. parser MUST NOT import from biblioteca. The dependency graph is a strict DAG.

---

## 8. Package: SwiftVerificar-parser

**Source**: [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser)
**Scope**: ~200 Java classes → ~100 Swift types (50% reduction)
**Layer**: 0 (no dependencies)
**Detailed reference**: `SwiftVerificar-parser/TODO.md`
**Total Sprints**: 14

For each sprint below, consult the corresponding section of `SwiftVerificar-parser/TODO.md` for exact field names, method signatures, and Java-to-Swift consolidation mappings.

| Sprint | Name | Types to Create | Type Count |
|--------|------|----------------|------------|
| 1 | COS Value Types | `COSValue` enum (null/bool/int/real/string/name/array/dict cases), `COSObjectKey` struct, `ASAtom` struct (string interning), `COSString` struct | 4 |
| 2 | COS Containers | `COSStream` struct, `COSReference` struct, `PDFHeader` struct, `PDFTrailer` struct, `PDFCharacterSet` enum | 5 |
| 3 | Stream Protocols | `PDFInputStream` protocol, `PDFOutputStream` protocol, `DataInputStream` struct, `ConcatenatedInputStream` struct, `SeekableStream` protocol, `PDFFilterFactory` protocol, `DefaultFilterFactory` struct, `FilterRegistry` actor | 8 |
| 4 | Filter Implementations | `FlateDecodeFilter`, `LZWDecodeFilter`, `ASCII85Filter`, `ASCIIHexFilter`, `AESDecryptFilter`, `RC4DecryptFilter`, `PredictorFilter`, `RunLengthFilter` | 8 |
| 5 | Parser Infrastructure | `PDFToken` enum, `PDFKeyword` enum, `PDFTokenizer` struct, `COSParser` protocol, `PDFDocumentParser` struct, `ContentStreamParser` struct | 6 |
| 6 | XRef and Document Loading | `XRefParser` struct, `XRefTable` struct, `XRefEntry` enum | 3 |
| 7 | PD Layer Core | `PDObject` protocol, `PDFDocument` class/actor, `PDFCatalog` struct, `PDFPage` struct, `PDFPageTree` struct, `PDFResources` struct, `PDFContentStream` struct, `LazyLoaded` property wrapper | 8 |
| 8 | PD Layer Structure and Metadata | `XMPMetadata` struct, `StructureTreeRoot` struct, `StructureNode` protocol, `StructureElement` struct, `StructureNamespace` struct, `StructureType` enum, `NameTree<T>` struct, `NumberTree<T>` struct | 8 |
| 9 | Font Core | `FontProgram` protocol, `PDFFont` protocol, `SimpleFont` protocol, `FontDescriptor` struct, `FontEncoding` enum, `Type1Font` struct, `TrueTypeFont` struct, `Type3Font` struct | 8 |
| 10 | Font Advanced | `Type0Font` struct, `CIDFont` struct, `CFFProgram` struct, `OpenTypeProgram` struct, `Type1Program` struct, `TrueTypeProgram` struct, `CMap` struct, `PDFCMap` struct | 8 |
| 11 | Font Tables and Metrics | `CMapParser` struct, `CodeSpaceRange` struct, `CIDMapping` enum, `UnicodeMapping` struct, `TrueTypeParser` struct, `TrueTypeTable` protocol, `CmapTable` struct, `HeadTable` struct, `HheaTable` struct, `HmtxTable` struct, `AFMParser` struct, `StandardMetrics` struct | 12 |
| 12 | Color Spaces | `PDFColorSpace` protocol, `DeviceGrayColorSpace`, `DeviceRGBColorSpace`, `DeviceCMYKColorSpace`, `CalGrayColorSpace`, `CalRGBColorSpace`, `LabColorSpace`, `ICCBasedColorSpace`, `IndexedColorSpace`, `SeparationColorSpace`, `DeviceNColorSpace` | 11 |
| 13 | XObjects, Patterns, Graphics, Annotations | `PDFXObject` protocol, `ImageXObject`, `FormXObject`, `InlineImage`, `PDFPattern` protocol, `TilingPattern`, `ShadingPattern`, `ExtendedGraphicsState`, `PDFOperator` enum, `PDFAnnotation` struct, `PDFAction` enum | 11 |
| 14 | Encryption, External Objects, Utilities | `EncryptionDict`, `StandardSecurity`, `AccessPermissions` OptionSet, `ICCProfile`, `JPEG2000Image`, `ParserContext` actor, `PDFEncoding` enum, `PageLabelParser`, `RoleMapResolver` | 9 |

### Parser-Specific Notes

- **Sprint 1**: `COSValue` is the foundational enum replacing 15 Java COS classes. This is the most important type in the package. Each case carries associated values matching the PDF object types.
- **Sprint 4**: Use Apple's `CryptoKit` for AES and RC4 decryption in `AESDecryptFilter` and `RC4DecryptFilter`. Do NOT implement crypto from scratch.
- **Sprint 7**: Implement `@LazyLoaded` as a simple property wrapper that defers computation until first access.
- **Sprint 11**: This is the largest sprint (12 types) but the types are small structs. If context is tight, the agent may split this into two commits: Sprint 11a (CMapParser through UnicodeMapping) and Sprint 11b (TrueTypeParser through StandardMetrics).

---

## 9. Package: SwiftVerificar-validation-profiles

**Source**: [veraPDF-validation-profiles](https://github.com/veraPDF/veraPDF-validation-profiles)
**Scope**: 733 XML files + ~30 Swift types
**Layer**: 0 (no dependencies)
**Detailed reference**: `SwiftVerificar-validation-profiles/TODO.md`
**Total Sprints**: 7

| Sprint | Name | Types to Create | Type Count |
|--------|------|----------------|------------|
| 1 | XML Profile Import | No Swift types. Download XML profiles from veraPDF GitHub repo. Create `Resources/Profiles/` directory structure. Priority: PDF/UA-2 (91 files), PDF/UA-1 (106 files), WCAG-2-2, then PDF/A. Include `validationProfile.xsd`. Verify `Package.swift` has `resources: [.copy("Resources/Profiles")]`. | 0 |
| 2 | Core Enums | `PDFFlavour` enum (16 cases), `Specification` enum (11 cases), `PDFObjectType` enum (188 cases), `RuleTag` enum (22 cases) | 4 |
| 3 | Profile Model Types | `ValidationProfile` struct, `ProfileDetails` struct, `ProfileVariable` struct, `ValidationRule` struct (Identifiable), `RuleID` struct, `ErrorDetails` struct, `ErrorArgument` struct, `Reference` struct | 8 |
| 4 | XML Parser | `ProfileXMLParser` struct, `ProfileXMLDelegate` class (XMLParserDelegate), `ProfileLoader` actor (singleton, caching) | 3 |
| 5 | Expression AST | `PropertyValue` enum (null/bool/int/double/string/array), `Expression` indirect enum (literal/identifier/binary/unary/call/member/index/ternary), `BinaryOperator` enum, `UnaryOperator` enum, `ExpressionParser` struct (recursive descent) | 5 |
| 6 | Expression Evaluator | `RuleExpressionEvaluator` struct — evaluate parsed expressions against property values. Must handle: equality, comparison, boolean logic, null checks, string methods (split, filter, test), regex, arithmetic. Heavy test sprint. | 1 |
| 7 | Profile Directory | `ProfileDirectory` actor — query rules by PDFObjectType, by RuleTag, filter machine-checkable rules, list profiles by flavour | 1 |

### Profiles-Specific Notes

- **Sprint 1**: This is a file-import sprint with no Swift code. Clone or download from `https://github.com/veraPDF/veraPDF-validation-profiles`. Only import the XML rule files under `PDF_UA/` and `PDF_A/` directories plus the XSD schema. Do NOT import Java source code, build files, or other non-XML artifacts.
- **Sprint 2**: `PDFObjectType` has exactly 188 cases covering all `object` attribute values across all bundled XML profiles (COS, PD, SE, SA, XMP, External, and Operator layers). Copy them from `TODO.md` — they must match the `object` attribute values in the XML profiles exactly.
- **Sprint 5-6**: The expression evaluator is the most complex and critical component. The XML rules contain JavaScript-like test expressions. Examples:
  - `containsStructTreeRoot == true`
  - `Alt != null || ActualText != null`
  - `kidsStandardTypes.split('&').filter(elem => elem == 'Figure').length == 0`
  - `/^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$/.test(unicodeValue)`
  - `Math.abs(widthFromFontProgram - widthFromDictionary) <= 1`
  Build a recursive descent parser. Test exhaustively — the correctness of the entire validation system depends on this evaluator.
- **Sprint 4**: Use Foundation `XMLParser` exclusively. No third-party XML parsers.

---

## 10. Package: SwiftVerificar-wcag-algs

**Source**: [veraPDF-wcag-algs](https://github.com/veraPDF/veraPDF-wcag-algs)
**Scope**: ~140 Java classes → ~45 Swift types (68% reduction)
**Layer**: 0 (no dependencies)
**Detailed reference**: `SwiftVerificar-wcag-algs/TODO.md`
**Total Sprints**: 10

| Sprint | Name | Types to Create | Type Count |
|--------|------|----------------|------------|
| 1 | Geometry | `BoundingBox` struct (with pageIndex), `MultiBoundingBox` struct, `ContentChunk` protocol | 3 |
| 2 | Text Content | `TextChunk` struct, `TextLine` struct, `TextBlock` struct, `TextColumn` struct, `TextType` enum (regular/large/logo), `TextFormat` enum (normal/subscript/superscript) | 6 |
| 3 | Non-Text Content | `ImageChunk` struct, `LineChunk` struct, `LineArtChunk` struct, `LinesCollection` struct | 4 |
| 4 | Semantic Types and Nodes | `SemanticType` enum (44 cases), `SemanticNode` protocol, `ContentNode` struct, `FigureNode` struct, `TableNode` struct, `ListNode` struct | 6 |
| 5 | Semantic Tree | `SemanticTree` struct, `SemanticTreeIterator` struct (DFS traversal, Sequence/IteratorProtocol) | 2 |
| 6 | Contrast Calculation | `ContrastCalculator` struct (preserve existing implementation), `ContrastAnalyzer` struct (PDFKit page rendering), `WCAGLevel` enum (aa/aaa) | 3 |
| 7 | Table Types | `Table` struct, `TableRow` struct, `TableCell` struct, `TableToken` struct, `TableBorder` struct, `TableBorderBuilder`, `TableBorderCell` struct, `TableBorderRow` struct, `TableError` enum (9 cases) | 9 |
| 8 | Table Validation | `TableValidator` struct, `TableRecognizer` struct, `TableCluster` struct | 3 |
| 9 | List Detection | `PDFList` struct, `ListItem` struct, `ListLabel` struct, `ListBody` struct, `ListType` enum, `LabelPattern` enum (7 patterns), `ListLabelDetector` struct (consolidates 12 Java algorithms), `DetectedLabel` struct, `ListInterval` struct | 9 |
| 10 | Semantic Checker | `SemanticChecker` struct (orchestrator, one method per phase), `CheckingPhase` enum (10 phases), `CheckingContext` struct, `WCAGContext` actor | 4 |

### WCAG-Specific Notes

- **Sprint 1**: `BoundingBox` must include `pageIndex: Int` alongside its rect. Use `CGRect` for the geometric component.
- **Sprint 4**: This is the major consolidation. 20+ Java semantic node subclasses become `SemanticNode` protocol + 4 concrete structs. `SemanticType` enum carries the type identity — it has 44 cases covering document, paragraph, heading, list, table, figure, etc.
- **Sprint 6**: The existing `ContrastRatioCalculator` in the stub file has a correct WCAG 2.1 luminance implementation. Rename it to `ContrastCalculator` and preserve the logic. `ContrastAnalyzer` adds PDFKit page rendering for extracting background colors.
- **Sprint 9**: 12 separate Java list label detection algorithm classes become a single `ListLabelDetector` struct using `LabelPattern` enum to select the algorithm.
- **Sprint 10**: 12 Java consumer pipeline classes become `SemanticChecker` struct with `CheckingPhase` enum. `WCAGContext` actor replaces Java's `ThreadLocal` static storage pattern.

---

## 11. Package: SwiftVerificar-validation

**Source**: [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation)
**Scope**: ~452 Java classes → ~191 Swift types (58% reduction)
**Layer**: 1 (depends on validation-profiles)
**Detailed reference**: `SwiftVerificar-validation/TODO.md`
**Total Sprints**: 16

**PREREQUISITE**: SwiftVerificar-validation-profiles must have ALL sprints complete, all tests passing, and its PR created before starting Sprint 1 of this package.

| Sprint | Name | Types to Create | Type Count |
|--------|------|----------------|------------|
| 1 | Dependency Setup + Foundry | Update `Package.swift` to depend on `SwiftVerificar-validation-profiles`. Create `ValidationFoundry` actor, `ModelParser` struct, `ValidationContext` actor. Import and use `PDFFlavour`, `ValidationProfile`, `RuleID`, `PDFObjectType` from validation-profiles. | 3 |
| 2 | COS Wrapper Layer | `CosObjectWrapper` generic struct, `CosDocument` struct, `CosTrailer` struct, `CosStream` struct, `CosString` struct | 5 |
| 3 | Operator Enum Part 1 | `ValidatedOperator` enum — graphics state cases (~15: setLineWidth, setLineCap, setGrayFill, setRGBFill, etc.), color cases (~10), path cases (~10) | 1 (partial) |
| 4 | Operator Enum Part 2 | `ValidatedOperator` enum — text cases (~10: beginText, endText, showText, etc.), image cases, marked content cases, operator parsing logic, complete tests | 1 (completion) |
| 5 | PD Validation Core | `PDValidationObject` protocol, `ValidatedDocument` struct, `ValidatedPage` struct, `ValidatedResource` protocol, `ValidatedContentStream` struct | 5 |
| 6 | Structure Validation | `ValidatedStructTreeRoot` struct, `ValidatedStructElem` struct, `StructureElementType` enum (41+ cases), `ValidatedStructureElement` struct | 4 |
| 7 | Annotation Validation | `ValidatedAnnotation` struct, `AnnotationType` enum (15 cases), `ValidatedAcroForm` struct, `ValidatedExtGState` struct | 4 |
| 8 | Font Validation | `FontValidation` protocol, `Type0FontValidation`, `Type1FontValidation`, `TrueTypeFontValidation`, `CIDFontValidation`, `FontProgramValidation`, `CMapValidation` | 7 |
| 9 | Color Space Validation | Color space validation protocol + `DeviceGrayValidation`, `DeviceRGBValidation`, `DeviceCMYKValidation`, `ICCBasedValidation`, `CalGrayValidation`, `CalRGBValidation`, `IndexedValidation`, `SeparationValidation` | 9 |
| 10 | External Object Validation | `ICCProfileValidation`, `JPEG2000Validation`, `EmbeddedFileValidation`, `PKCSValidation`, `ValidatedMetadata` | 5 |
| 11 | Remaining PD Types | Any remaining validation-model types not covered in Sprints 5-10. Consolidate and close out the validation-model module. | ~8 |
| 12 | Feature Extraction | `FeatureExtractor` struct, `FeatureAdapter` protocol, `GenericFeatureAdapter<T>` struct, `FeatureType` enum, helper extensions | 5 |
| 13 | Metadata Fixer | `MetadataFixer` struct, `InfoDictionary` struct, `XMPMetadataModel` struct, `XMPSchema` protocol, `AdobePDFSchema`, `DublinCoreSchema`, `XMPBasicSchema` | 7 |
| 14 | SA Layer Core | `SAObject` protocol, `SADocument` struct, `SAPage` struct, `SAStructureRoot` struct, `SANode` struct | 5 |
| 15 | SA Layer Extended | `SAStructureElement` struct, `ContentChunkContainer` struct, `ContentChunkFactory` struct, `ContentChunkParser` struct, `WCAGValidationContext` actor | 5 |
| 16 | SA Serialization | `SADocumentEncoder` struct (Codable), remaining SA helper types, integration tests | 3 |

### Validation-Specific Notes

- **Sprint 1**: This sprint MUST update `Package.swift` to add the dependency on `SwiftVerificar-validation-profiles` before creating any types. Import `SwiftVerificarValidationProfiles` and use its types. Do NOT redefine `PDFFlavour`, `ValidationProfile`, etc.
- **Sprints 3-4**: 97 Java operator classes → 1 `ValidatedOperator` enum with ~50 cases. Split across two sprints because the enum is large and needs exhaustive tests. Each case carries operands as associated values: `case setGrayFill(Double)`, `case beginText`, `case showText(Data)`.
- **Sprint 6**: `StructureElementType` enum (41+ cases) is a critical shared type. Biblioteca will import and use it.
- **Sprint 13**: Jackson JSON serializers → Swift `Codable`. Do NOT port Jackson.
- **Sprints 14-16**: SA (Structured Accessibility) layer. The 55 Java SA structure element classes reuse the `StructureElementType` enum from Sprint 6 + a single `SAStructureElement` struct.

---

## 12. Package: SwiftVerificar-biblioteca

**Source**: [veraPDF-library](https://github.com/veraPDF/veraPDF-library)
**Scope**: ~250 Java classes → ~72 Swift types (71% reduction)
**Layer**: 2 (depends on ALL other packages)
**Detailed reference**: `SwiftVerificar-biblioteca/TODO.md` and `REQUIREMENTS.md`
**Total Sprints**: 11

**PREREQUISITE**: ALL four other packages must have ALL sprints complete, all tests passing, and their PRs created before starting Sprint 1 of this package.

| Sprint | Name | Types to Create | Type Count |
|--------|------|----------------|------------|
| 1 | Dependency Setup + Core Errors | Update `Package.swift` with all 4 dependencies. Create `ValidatorComponent` protocol, `ComponentInfo` struct, `ValidationDuration` struct, `VerificarError` enum (6 cases consolidating Java exceptions) | 4 |
| 2 | Foundry System | `ValidationFoundry` protocol, `Foundry` actor, `SwiftFoundry` struct (default implementation) | 3 |
| 3 | Validation Results Core | `ValidationResult` struct, `TestAssertion` struct (Identifiable), `AssertionStatus` enum (passed/failed/unknown), `PDFLocation` struct | 4 |
| 4 | Validation Results Extended | `MetadataFixerResult` struct, `MetadataFix` struct, `RepairStatus` enum | 3 |
| 5 | Validators | `PDFValidator` protocol, `ValidatorConfig` struct, `SwiftPDFValidator` struct (main implementation) | 3 |
| 6 | Parsers | `PDFParser` protocol, `ParsedDocument` protocol, `SwiftPDFParser` struct | 3 |
| 7 | Feature Extraction | `FeatureConfig` struct, `FeatureExtractionResult` struct, `FeatureReporter` struct, `FeatureType` enum, `FeatureNode` indirect enum, `FeatureData` protocol | 6 |
| 8 | Metadata + Processor | `MetadataFixer` protocol, `FixerConfig` struct, `ProcessorConfig` struct, `PDFProcessor` struct, `ProcessorResult` struct, `ProcessorTask` enum, `OutputFormat` enum | 7 |
| 9 | XMP Model | `XMPMetadata` struct, `XMPParser` struct, `XMPProperty` struct, `XMPValidator` struct, `MainXMPPackage` struct, `PDFAIdentification` struct, `PDFUAIdentification` struct | 7 |
| 10 | Reports | `ValidationReport` struct, `RuleSummary` struct, `FeatureReport` struct, `ReportGenerator` enum | 4 |
| 11 | Main Public API | `SwiftVerificar` struct (singleton `shared`), methods: `validateAccessibility(_:progress:)`, `validate(_:profile:config:progress:)`, `process(_:config:progress:)`, `validateBatch(_:profile:maxConcurrency:progress:)` | 1 |

### Biblioteca-Specific Notes

- **Sprint 1**: This sprint MUST update `Package.swift` to add ALL four dependencies before creating any types. Verify that all four dependency packages build successfully from their `development` branches. `VerificarError` consolidates 6 Java exception classes into one enum.
- **Sprint 3**: `ValidationResult` is the top-level type that Lazarillo consumes. Its shape must match the API described in `REQUIREMENTS.md`.
- **Sprint 5**: `SwiftPDFValidator` is the main implementation that orchestrates parser + validation engine + profiles + wcag-algs. It delegates to the other packages.
- **Sprint 11**: `SwiftVerificar.shared` is the main entry point for Lazarillo:
  ```swift
  let result = try await SwiftVerificar.shared.validateAccessibility(pdfURL)
  ```
- This package is the integration layer. Most types here are thin wrappers or protocols delegating to the other packages. Keep it lean. Do NOT re-implement logic that exists in dependency packages.

---

## 13. Reconciliation Passes

After all packages have their PRs created, one or more reconciliation passes are needed to achieve ecosystem-wide type agreement. The goal is not to minimize the number of passes — it is to get cross-package communication right.

### 13.1 When to Reconcile

A reconciliation pass is needed when:
- Any package's PROGRESS.md has entries under `## Cross-Package Needs`.
- A Layer 1/2 package created adapter types because a dependency's types didn't match expectations.
- Two Layer 0 packages defined similar concepts differently and those concepts need alignment for the integration layer.

### 13.2 Reconciliation Process

Each reconciliation pass is itself a series of sprints:

1. **Audit**: Read all five PROGRESS.md files. Read all PR descriptions. Collect every cross-package need and type mismatch into a single list.

2. **Propose**: For each item, decide one of:
   - **Move**: Move the type to the package that should own it per the Type Ownership Table (Section 7.1).
   - **Align**: Modify the type's definition in the owning package to match what consumers need. Update consumers accordingly.
   - **Adapt**: Keep both definitions and add a conversion/adapter in the consuming package (last resort).
   - **Extract**: If a type is needed by multiple Layer 0 packages, consider whether it should move to a new shared package or be duplicated with a protocol-based abstraction.

3. **Implement**: Make the changes, one package at a time, in dependency order (Layer 0 first, then Layer 1, then Layer 2). Each change is a sprint with entry/exit checks.

4. **Verify**: After all changes, every package must build and pass all tests. Run builds in dependency order to catch breakage.

5. **Repeat**: If the changes introduced new mismatches, do another pass. Continue until all packages build cleanly, all tests pass, and no PROGRESS.md has unresolved cross-package needs.

### 13.3 Rules During Reconciliation

- The dependency graph (Section 2) MUST remain a strict DAG. No reconciliation action may introduce a circular dependency.
- If moving a type would create a circular dependency, the type must be duplicated or extracted into a new shared package.
- Every reconciliation sprint follows the same entry/exit checks as a regular sprint (Section 3.3, 3.4).
- Reconciliation commits use this message format:
  ```
  Reconciliation Pass N, Sprint M: <description>
  ```

---

## 14. Error Recovery

### 14.1 Build Failure

1. Read the full error output.
2. Fix the compilation error in the source or test file.
3. Re-run `xcodebuild build`. Repeat until zero errors.
4. Do NOT commit until the build succeeds.

### 14.2 Test Failure

1. Read the full test failure output.
2. Determine if the bug is in production code or test code.
3. Fix the bug.
4. Re-run ALL tests (not just the failing one).
5. Do NOT commit until all tests pass.

### 14.3 Coverage Below 90%

1. Identify uncovered lines (use `xcrun xccov` or Xcode coverage report).
2. Write additional tests targeting those lines.
3. Re-run tests with coverage.
4. Do NOT commit until coverage meets threshold.

### 14.4 Context Exhaustion Mid-Sprint

If an agent is running out of context before finishing a sprint:

1. Assess what is complete and what remains.
2. If the completed work builds and tests pass:
   - Update PROGRESS.md with a partial sprint status: `Sprint N: <Name> (partial — types A, B, C complete; D, E, F remain)`.
   - Commit with message: `Sprint N: <Name> (partial)`
   - The orchestrating agent dispatches a new agent to finish the sprint. The new agent reads PROGRESS.md and completes the remaining types.
3. If the completed work does NOT build:
   - Do NOT commit.
   - Update PROGRESS.md with: `Sprint N: <Name> (incomplete — context exhausted, no commit)`
   - Write the PROGRESS.md update to disk (but do not git commit).
   - The orchestrating agent dispatches a new agent that reads PROGRESS.md and the uncommitted files, and either completes or restarts the sprint.

### 14.5 Dependency Package Not Ready

If an agent for a Layer 1/2 package starts and discovers its dependency is not complete:

1. Do NOT proceed with the sprint.
2. Report the issue: "Dependency <PackageName> is not complete. Cannot start Sprint N."
3. Wait for the dependency to complete.

### 14.6 Sandbox Violation Detected

If the exit check finds a forbidden API (`Process()`, `NSTask`, `dlopen`, etc.):

1. Remove the offending code immediately.
2. Replace with a sandbox-compatible alternative.
3. Re-run the build and tests.
4. Do NOT commit until the sandbox check passes.

### 14.7 Dependency Graph Violation Detected

If the exit check finds an import not in the allowed imports table:

1. Remove the offending import.
2. If the type is genuinely needed, define a local protocol or type.
3. Document the need in PROGRESS.md under `## Cross-Package Needs`.
4. Re-run the build and tests.
5. Do NOT commit until the dependency check passes.

---

## Appendix A: Package Metadata Quick Reference

| Package | Target | Test Target | Scheme |
|---------|--------|-------------|--------|
| SwiftVerificar-parser | SwiftVerificarParser | SwiftVerificarParserTests | SwiftVerificarParser |
| SwiftVerificar-validation-profiles | SwiftVerificarValidationProfiles | SwiftVerificarValidationProfilesTests | SwiftVerificarValidationProfiles |
| SwiftVerificar-wcag-algs | SwiftVerificarWCAGAlgs | SwiftVerificarWCAGAlgsTests | SwiftVerificarWCAGAlgs |
| SwiftVerificar-validation | SwiftVerificarValidation | SwiftVerificarValidationTests | SwiftVerificarValidation |
| SwiftVerificar-biblioteca | SwiftVerificarBiblioteca | SwiftVerificarBibliotecaTests | SwiftVerificarBiblioteca |

## Appendix B: Sprint Count Summary

| Package | Layer | Sprints | Types |
|---------|-------|---------|-------|
| SwiftVerificar-parser | 0 | 14 | ~100 |
| SwiftVerificar-validation-profiles | 0 | 7 | ~30 |
| SwiftVerificar-wcag-algs | 0 | 10 | ~45 |
| SwiftVerificar-validation | 1 | 16 | ~191 |
| SwiftVerificar-biblioteca | 2 | 11 | ~72 |
| **Total** | | **58** | **~438** |
| + Reconciliation passes | | **TBD** | |

## Appendix C: Java-to-Swift Idiom Translations

| Java Pattern | Swift Equivalent |
|-------------|-----------------|
| Abstract class | Protocol with default extension |
| Class hierarchy (15+ subclasses) | Enum with associated values |
| Interface | Protocol |
| Static factory | Static method or init |
| ThreadLocal | Actor |
| HashMap | Dictionary |
| ArrayList | Array |
| Optional (Java) | Optional (Swift) |
| Checked exceptions | Throws + Error enum |
| Unchecked exceptions | `fatalError` or `preconditionFailure` (programmer errors only) |
| Synchronized block | Actor |
| Iterator pattern | Sequence/IteratorProtocol conformance |
| Builder pattern | Struct with default values + memberwise init |
| Visitor pattern | Protocol with method per case, or switch over enum |
| Jackson JSON | Codable |
| JUnit | Swift Testing (@Test, #expect) |
| Mockito | Protocol-based dependency injection + manual test doubles |

## Appendix D: Sprint Dispatch Prompt Template

Use this exact prompt when dispatching a sprint agent:

```
You are working on package <PACKAGE_NAME> located at /Users/stovak/Projects/SwiftVerificar/<PACKAGE_DIR>/.

FIRST, read these files in order:
1. /Users/stovak/Projects/SwiftVerificar/EXECUTION_PLAN.md (the master execution plan)
2. /Users/stovak/Projects/SwiftVerificar/<PACKAGE_DIR>/PROGRESS.md (if it exists)
3. /Users/stovak/Projects/SwiftVerificar/<PACKAGE_DIR>/TODO.md (detailed type mappings)

You are executing Sprint <N>: <SPRINT_NAME>.

Follow Section 3.3 (Entry Checks) before writing any code.
Create all types and tests listed for Sprint <N> in Section <8|9|10|11|12> of EXECUTION_PLAN.md.
Consult TODO.md for exact field names, method signatures, and Java-to-Swift mappings.
Follow Section 3.4 (Exit Checks) before committing.
Update PROGRESS.md and commit when all checks pass.

Do NOT start the next sprint. Your context ends after this sprint's commit.
```
