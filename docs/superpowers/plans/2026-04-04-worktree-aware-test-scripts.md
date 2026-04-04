# Worktree-Aware Test Scripts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository test scripts ignore `./.worktrees/`, commit the requested Docker/versioning and documentation changes, and remove the temporary worktree afterward.

**Architecture:** Keep the script fix minimal by adding explicit `grep -v '^./.worktrees/'` filters to the existing `find` pipelines. Then verify the main checkout only, create one commit containing the requested files, and remove the now-unneeded feature worktree from the main checkout.

**Tech Stack:** Bash, git, hadolint, shellcheck, jq

---

## File Structure

- Modify: `tests/lint-dockerfiles.sh`
  - Exclude `./.worktrees/` from Dockerfile discovery
- Modify: `tests/lint-scripts.sh`
  - Exclude `./.worktrees/` from shell script discovery
- Modify: `tests/validate-json.sh`
  - Exclude `./.worktrees/` from JSON and JSONC discovery
- Commit: `.gitignore`
- Commit: `base/Dockerfile`
- Commit: `oh-my-opencode/Dockerfile`
- Commit: `get-shit-done/Dockerfile`
- Commit: `docs/superpowers/specs/2026-04-04-docker-version-pinning-design.md`
- Commit: `docs/superpowers/plans/2026-04-04-docker-version-pinning.md`
- Commit: `docs/superpowers/specs/2026-04-04-worktree-aware-test-scripts-design.md`
- Commit: `docs/superpowers/plans/2026-04-04-worktree-aware-test-scripts.md`

### Task 1: Exclude `.worktrees` From Test File Discovery

**Files:**
- Modify: `tests/lint-dockerfiles.sh:17`
- Modify: `tests/lint-scripts.sh:17`
- Modify: `tests/validate-json.sh:17-18,29`

- [ ] **Step 1: Write the failing path-discovery checks**

Run these commands from the repo root to prove the current scripts still see
worktree files:

```bash
find . -name "Dockerfile" -type f | grep '^./.worktrees/'
find . -name "*.sh" -type f | grep '^./.worktrees/'
find . -name "*.json" -type f | grep '^./.worktrees/'
find . -name "*.jsonc" -type f | grep '^./.worktrees/'
```

Expected: each command prints at least one path under `./.worktrees/`.

- [ ] **Step 2: Apply the minimal script edits**

Update the file-discovery pipelines to exclude `./.worktrees/` while preserving
the existing filters:

```bash
# tests/lint-dockerfiles.sh
DOCKERFILES=$(find . -name "Dockerfile" -type f | grep -v '^./.worktrees/' | grep -v ".codenomad")

# tests/lint-scripts.sh
SCRIPTS=$(find . -name "*.sh" -type f | grep -v '^./.worktrees/' | grep -v ".git" | grep -v "^./tests/")

# tests/validate-json.sh
JSON_FILES=$(find . -name "*.json" -type f | grep -v '^./.worktrees/' | grep -v ".git" | grep -v ".codenomad")
JSONC_FILES=$(find . -name "*.jsonc" -type f | grep -v '^./.worktrees/' | grep -v ".git")
```

- [ ] **Step 3: Run the focused verification**

Run the same discovery commands again and verify the worktree paths are gone:

```bash
if find . -name "Dockerfile" -type f | grep '^./.worktrees/'; then exit 1; fi
if find . -name "*.sh" -type f | grep '^./.worktrees/'; then exit 1; fi
if find . -name "*.json" -type f | grep '^./.worktrees/'; then exit 1; fi
if find . -name "*.jsonc" -type f | grep '^./.worktrees/'; then exit 1; fi
```

Expected: all four commands exit successfully with no output.

- [ ] **Step 4: Run the repository verification scripts**

```bash
./tests/lint-dockerfiles.sh
./tests/run-all.sh
```

Expected:

- both commands exit successfully
- neither command output contains paths beginning with `./.worktrees/`

- [ ] **Step 5: Commit only if the user explicitly requested a commit**

```bash
git add tests/lint-dockerfiles.sh tests/lint-scripts.sh tests/validate-json.sh
git commit -m "test: ignore local worktrees in repo checks"
```

Expected: skip this step unless the user has explicitly requested a commit.

### Task 2: Commit The Requested Main-Checkout Changes

**Files:**
- Commit: `.gitignore`
- Commit: `base/Dockerfile`
- Commit: `oh-my-opencode/Dockerfile`
- Commit: `get-shit-done/Dockerfile`
- Commit: `tests/lint-dockerfiles.sh`
- Commit: `tests/lint-scripts.sh`
- Commit: `tests/validate-json.sh`
- Commit: `docs/superpowers/specs/2026-04-04-docker-version-pinning-design.md`
- Commit: `docs/superpowers/plans/2026-04-04-docker-version-pinning.md`
- Commit: `docs/superpowers/specs/2026-04-04-worktree-aware-test-scripts-design.md`
- Commit: `docs/superpowers/plans/2026-04-04-worktree-aware-test-scripts.md`

- [ ] **Step 1: Inspect the exact commit contents**

```bash
git status --short
git diff --stat
```

Expected: the status and diff show only the requested files.

- [ ] **Step 2: Stage the requested files**

```bash
git add .gitignore base/Dockerfile oh-my-opencode/Dockerfile get-shit-done/Dockerfile tests/lint-dockerfiles.sh tests/lint-scripts.sh tests/validate-json.sh docs/superpowers/specs/2026-04-04-docker-version-pinning-design.md docs/superpowers/plans/2026-04-04-docker-version-pinning.md docs/superpowers/specs/2026-04-04-worktree-aware-test-scripts-design.md docs/superpowers/plans/2026-04-04-worktree-aware-test-scripts.md
```

Expected: `git status --short` shows the requested files as staged.

- [ ] **Step 3: Create the commit**

```bash
git commit -m "chore: pin Docker tool versions and ignore local worktrees in checks"
```

Expected: commit succeeds with one commit containing the requested code, docs,
and `.gitignore` changes.

- [ ] **Step 4: Verify the post-commit status**

```bash
git status --short
git log --oneline -1
```

Expected:

- `git status --short` shows a clean working tree
- `git log --oneline -1` shows the new `chore:` commit

### Task 3: Remove The Temporary Worktree

**Files:**
- Remove worktree path: `.worktrees/docker-version-pinning`

- [ ] **Step 1: Confirm the worktree is still registered**

```bash
git worktree list
```

Expected: output includes `.worktrees/docker-version-pinning`.

- [ ] **Step 2: Remove the worktree from the main checkout**

```bash
git worktree remove ".worktrees/docker-version-pinning"
```

Expected: command succeeds and removes the worktree directory.

- [ ] **Step 3: Verify cleanup**

```bash
git worktree list
```

Expected: output no longer includes `.worktrees/docker-version-pinning`.
