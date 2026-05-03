# Releasing FKKit (SPM + CocoaPods)

This checklist keeps **Git tags**, **podspec `s.version`**, and **changelog** aligned.

## 1. Version bump (podspecs)

From the repository root:

```bash
chmod +x scripts/bump-version.sh scripts/verify-podspec-versions.sh   # once
./scripts/bump-version.sh X.Y.Z
./scripts/verify-podspec-versions.sh
```

That updates **`s.version`** in all four root podspecs:

- `FKCoreKit.podspec`
- `FKEmptyStateCoreLite.podspec`
- `FKUIKit.podspec`
- `FKCompositeKit.podspec`

## 2. Changelog

Edit **`CHANGELOG.md`**:

- Add a dated section `## [X.Y.Z] - YYYY-MM-DD`.
- Move relevant items out of **`[Unreleased]`** into that release.

## 3. Documentation literals (optional but recommended)

Search for the **old** version string and update consumer-facing examples if you maintain explicit pins:

- **`README.md`**: SPM `from: "…"` and CocoaPods `:tag => '…'` examples.

## 4. Tag rule

**The Git tag for a CocoaPods release must equal** the **`s.version`** string in every podspec (CocoaPods resolves `s.source` with `:tag => s.version.to_s`).

```bash
git add -A
git commit -m "Release X.Y.Z"
git tag -a X.Y.Z -m "Release X.Y.Z"
git push origin main          # or your release branch
git push origin X.Y.Z
```

## 5. Validate podspecs (maintainers)

After the tag exists on the remote (so `:git` + `:tag` resolve):

```bash
pod spec lint FKCoreKit.podspec --allow-warnings
pod spec lint FKEmptyStateCoreLite.podspec --allow-warnings
pod spec lint FKUIKit.podspec --allow-warnings
pod spec lint FKCompositeKit.podspec --allow-warnings
```

See also **`README.md`** → **Installation (CocoaPods)** → **Linting podspecs**.

## 6. Swift Package Manager

SPM consumers pin versions via **Git tags**; no podspec step. Ensure **`Package.swift`** / toolchain expectations in **`README.md`** still match what you support.

## CI note

The repository may run **`scripts/verify-podspec-versions.sh`** in CI to catch accidental podspec drift. Full **`pod spec lint`** on every PR is optional (network + clone cost).

## Local pre-push (optional)

To run the same podspec version check **before** every `git push` on your machine, enable hooks — see **`docs/GIT_HOOKS.md`** and **`scripts/install-git-hooks.sh`**.
