# Git hooks (local pre-push)

This repository ships an **optional** Git hook: before **`git push`** actually talks to the remote, it runs **`scripts/verify-podspec-versions.sh`** so the four root **`*.podspec`** files share the same **`s.version`**. If they differ, the **push is blocked** (same check as CI, failing earlier locally).

It does **not** run **`scripts/bump-version.sh`** on push (that script edits versions and is for manual release use only).

---

## One-time setup (per clone)

**`core.hooksPath`** is **local to this machine and this clone**; it is **not** pushed with **`git push`**. Each collaborator runs this once in their own clone.

From the repository root:

```bash
chmod +x scripts/install-git-hooks.sh .githooks/pre-push
./scripts/install-git-hooks.sh
```

Or manually:

```bash
git config core.hooksPath .githooks
```

Verify:

```bash
git config --get core.hooksPath
# should print: .githooks
```

After that, **`git push`** in this clone runs **`.githooks/pre-push`**.

---

## How to confirm it works

Temporarily mismatch one podspec’s **`s.version`** and try to push (you can use **`git push --no-verify`** to skip hooks for comparison—**not recommended**):

```bash
./scripts/verify-podspec-versions.sh   # should fail and print the mismatch
```

Restore versions and push again; it should pass.

---

## Disable hooks (this clone only)

```bash
git config --unset core.hooksPath
```

Git then uses the default **`.git/hooks/`** again (if you never added custom scripts there, that is effectively no pre-push).

---

## Notes and limitations

1. **Relationship to CI**  
   CI already runs **`verify-podspec-versions.sh`** before the build. Local pre-push is an **extra** layer; it does not replace CI.

2. **What `core.hooksPath` means**  
   When set, **all** hook types for this clone are resolved under **`.githooks/`** first. This repo only ships **`pre-push`**; if you need **`pre-commit`** or others, add them under **`.githooks/`** and commit them.

3. **`--no-verify`**  
   **`git push --no-verify`** skips pre-push (emergency escape hatch). Do not rely on skipping for normal releases.

4. **Execute bit**  
   If the hook does nothing after clone, ensure **`.githooks/pre-push`** is executable: **`chmod +x .githooks/pre-push`**.

---

## Related docs

- Releases and versions: **`docs/RELEASING.md`**
- Verification script: **`scripts/verify-podspec-versions.sh`**
