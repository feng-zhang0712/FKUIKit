# FKCoreKit: `Extension/` vs `Utils/` (`FKUtils.*`)

This document is the **governance policy** for new APIs in `FKCoreKit`. It complements the high-level module description in the root **`README.md`**.

## Roles

### `Sources/FKCoreKit/Extension/`

- **What:** `public` extensions on **Foundation**, **CoreGraphics**, and **UIKit** types (UIKit files are behind `#if canImport(UIKit)`).
- **Naming:** Members use the **`fk_`** prefix (or `fk_`-prefixed typealiases / nested names where applicable) to reduce collisions with app code and future SDK APIs.
- **When to use:** Operations that are naturally expressed as **“something you do *on* a value”** — chaining, small transforms, predicates, and ergonomic shims on `String`, `Date`, `Optional`, `URL`, `UIView`, etc.
- **Discoverability:** Call sites benefit from **autocomplete on the receiver** (`value.fk_*`).

### `Sources/FKCoreKit/Utils/` (`FKUtils` namespace)

- **What:** Static helpers grouped as **`FKUtilsString`**, **`FKUtilsDate`**, **`FKUtilsDevice`**, **`FKUtilsUI`**, **`FKUtilsCollection`**, etc., exposed under the **`FKUtils`** enum (e.g. `FKUtils.String.trim(_:)`, `FKUtils.Date.*`).
- **Naming:** Types are **`FKUtils*`**; functions are **not** `fk_`-prefixed on the receiver (there is no receiver).
- **When to use:** Logic that fits **free functions** or **multi-argument pipelines** (e.g. masking with several parameters, formatting with explicit options structs), or utilities that **do not** map cleanly to a single stdlib/UIKit type.
- **Discoverability:** Call sites are grouped under **`FKUtils.*`** — good for “toolbox” APIs and shared demo snippets.

## Rules of thumb (for contributors)

1. **Prefer one obvious home for new surface area.**  
   Ask: *“Is this primarily a property/method on `T`?”* → **`Extension/`**.  
   *“Is this a named operation with several inputs or a cross-type workflow?”* → **`Utils/`** (`FKUtils*`).

2. **Do not add parallel semantics** in both places without a strong reason. If an extension already exposes `String.fk_trimmed`, avoid adding `FKUtilsString.trim` unless there is a material difference (different normalization rules, performance contract, etc.). Historical duplicates may remain until a semver-major cleanup is planned.

3. **UIKit / MainActor.**  
   Extension files under **`Extension/UIKit/`** should respect Swift concurrency rules for UIKit (see R8 / strict concurrency notes in **`CHANGELOG.md`**). **`FKUtilsUI`** is **`@MainActor`** as a whole; do not use `FKUtils.UI.runOnMain` for closures that capture non-`Sendable` UIKit state — use **`Task { @MainActor in … }`** or assume the caller is already on the main actor.

4. **Breaking changes.**  
   Moving an API from `Utils` to `Extension` (or vice versa) is usually **source-breaking** for integrators. Prefer **documentation + deprecation** in minor releases; batch removals in **major** versions with **`CHANGELOG.md`** **Breaking** entries.

5. **Tests.**  
   Pure Foundation / non-UIKit helpers should get **`Tests/FKCoreKitTests`** coverage when practical; UIKit-heavy paths may stay example-driven until a host harness exists.

## Related paths

- Root overview: **`README.md`** → **Core Components** → **FKCoreKit**.
- Release and versioning: **`docs/RELEASING.md`**; history: **`CHANGELOG.md`**.
