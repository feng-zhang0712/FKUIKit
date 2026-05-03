# FKKit Refactoring Plan

This document captures the **architecture review outcomes** (see repository discussion around full-stack analysis of `FKKit`) and turns them into a **sequenced, one-item-at-a-time** backlog. Execute each item in its **own branch or commit series** to avoid destabilizing the library.

**Working branch:** `refactor/fkkit-sustainability` (or child branches `refactor/fkkit-sustainability/<topic>`).

**Rules:**

1. **One theme per change set** (one PR / one focused merge).
2. Prefer **documentation + mechanical refactors** before large API moves.
3. Every completed item updates **`CHANGELOG.md`** under `[Unreleased]` (or a release section when tagging).
4. After behavioral or distribution changes, run **`pod spec lint`** (maintainers) and **`swift build`** with an **iOS destination** where applicable.

---

## Completed (baseline on `refactor/fkkit-sustainability`)

| ID | Item | Notes |
|----|------|--------|
| R1 | **SPM platforms: iOS-only** | `Package.swift` declares **iOS 15+** only; aligns with UIKit-first code and removes unsupported macOS `swift build` expectations. |
| R2 | **README: requirements & badges** | iOS **15+**, Swift **6.3+**; requirements text matches `Package.swift`. |
| R3 | **CocoaPods** | Root **`FKCoreKit.podspec`**, **`FKEmptyStateCoreLite.podspec`**, **`FKUIKit.podspec`**, **`FKCompositeKit.podspec`**; README **Installation (CocoaPods)**. |
| R4 | **README: CompositeKit tree cleanup** | Removed **Filter** from the module tree and bullet list (no separate **AnchoredDropdown** prose existed in README). |

---

## Backlog (ordered by recommended execution)

### R5 — CI: minimal GitHub Actions workflow

**Goal:** Catch compile breaks on every push/PR using an **iOS Simulator** SDK (not macOS host default).

**Scope (single PR):**

- Add `.github/workflows/ci.yml` (name up to you, e.g. `ios-spm-build`).
- Steps: checkout, select Xcode if needed, `swift build` (or `xcodebuild -scheme` if you add an Xcode workspace later) for **`FKCoreKit`**, **`FKUIKit`**, **`FKCompositeKit`** against **iphonesimulator**.
- Document required **secrets** (if any) and **Xcode version** in workflow comments or `docs/REFACTOR_PLAN.md` appendix.

**Acceptance:** workflow is green on `develop` / `refactor/fkkit-sustainability` after merge.

**Risk:** Low.

---

### R6 — SPM: silence “unhandled README” warnings

**Goal:** Remove SwiftPM warnings about unhandled `README.md` files under `Sources/`.

**Scope (single PR):**

- For each target in `Package.swift`, add an **`exclude:`** list for `**/README.md` (or explicit paths per module), **or** declare them as resources if you intentionally ship them (unlikely).

**Acceptance:** `swift build` log has **no** unhandled-README warnings for FKKit targets.

**Risk:** Low.

---

### R7 — Tests: SwiftPM test target (smoke first)

**Goal:** Establish `Tests/` and a **minimal** test bundle before growing coverage.

**Scope (single PR):**

- Add `testTarget` in `Package.swift` (e.g. `FKCoreKitTests`).
- First tests: pure Swift, no UIKit if possible (e.g. **Extension** `String` / `URL` helpers, or **Utils** pure functions).
- Document how to run: `swift test` with iOS destination / Xcode test action.

**Acceptance:** `swift test` passes in CI (can be combined with R5 once both exist).

**Risk:** Medium (tooling + time).

---

### R8 — Swift 6 concurrency: systematic pass

**Goal:** Reduce `@Sendable` / isolation warnings for patterns like **`DispatchQueue.main.async`** capturing non-`Sendable` values.

**Scope (split by module if large):**

- Grep for `DispatchQueue.main.async`, `Task {`, `async` closures that capture UIKit / Foundation non-Sendable types.
- Apply patterns already used in **`NotificationCenter+FKCoreKit`** (boxing) or refactor to **`MainActor`** / typed payloads.

**Acceptance:** stricter Swift 6 build (or `SWIFT_STRICT_CONCURRENCY=complete` if adopted) shows **no new** issues in touched files.

**Risk:** Medium (subtle behavior changes if done hastily).

---

### R9 — API surface governance: `Extension` vs `FKUtils*`

**Goal:** Prevent duplicate concepts (`fk_*` extensions vs static `FKUtils*` helpers) and document the rule of thumb.

**Scope (can be two sub-items):**

1. **Docs only:** Add a short section to **`README.md`** (FKCoreKit) or a `docs/EXTENSION_VS_UTILS.md` describing when to add code to **`Extension/`** vs **`Utils/`**.
2. **Code (optional follow-up):** migrate **exact duplicates** from `Utils` into `Extension` only when call sites can be updated safely; otherwise keep and cross-link in docs.

**Acceptance:** written policy + optional dedup PR with CHANGELOG **Changed** notes.

**Risk:** Low (docs); Medium (code moves).

---

### R10 — CompositeKit: documentation vs directory truth

**Goal:** README and on-disk layout stay aligned; internal components without public marketing copy stay in **module READMEs** under `Sources/`.

**Scope (single PR):**

- If **AnchoredDropdown** (or other folders) should stay **undocumented in root README**, add **`Sources/FKCompositeKit/Components/AnchoredDropdownController/README.md`** (English) for integrators who need it.
- If **Filter** is deprecated or postponed, state that in **`CHANGELOG.md`** once; avoid reviving root README bullets until the feature ships.

**Acceptance:** no misleading empty folders in **root** README tree; deep docs live next to sources.

**Risk:** Low.

---

### R11 — Podspec / tag discipline (automation optional)

**Goal:** Keep **`s.version`** and **Git tags** in sync and reduce human error.

**Scope (single PR or script):**

- Add a **`scripts/bump-version.sh`** (or document a checklist) that edits all four `*.podspec` + `CHANGELOG` + tag instructions.
- Optionally: CI job that fails if tag ≠ podspec version when releasing.

**Acceptance:** documented release steps; optional script in repo.

**Risk:** Low.

---

### R12 — Optional future: split `FKCoreKit` for clarity (large)

**Goal:** If the library grows further, consider **separate SPM products** (e.g. `FKCoreKitExtensionOnly`) for apps that want extensions without networking.

**Scope:** design doc only until explicitly approved; **not** started by default.

**Risk:** High (API and dependency graph churn).

---

## Progress log

| Date | Item | PR / commit | Owner notes |
|------|------|-------------|-------------|
| 2026-05-03 | R1–R4 | Landed on `refactor/fkkit-sustainability` | iOS-only SPM, README, CocoaPods podspecs, Composite README trim |
| | R5–R12 | Pending | Execute in order unless risk assessment changes priority |

---

## Next action (single step)

Start with **R5 (CI)** unless product priorities dictate **R7 (Tests)** first. After each merge, update the **Progress log** table above.
