# GSD Variant Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add get-shit-done container variant following existing multi-variant pattern

**Architecture:** Create new get-shit-done/ directory with Dockerfile, update Makefile to include the new variant

**Tech Stack:** Docker, Make

---

### Task 1: Create get-shit-done/Dockerfile

**Files:**
- Create: `get-shit-done/Dockerfile`

**Step 1: Create the Dockerfile**

```dockerfile
FROM opencode-base

USER opencode
RUN CLAUDE_CONFIG_DIR=/home/opencode/.config/opencode npx get-shit-done-cc@latest --opencode --global
```

**Step 2: Commit**

```bash
git add get-shit-done/Dockerfile
git commit -m "feat: add GSD variant Dockerfile"
```

---

### Task 2: Update Makefile with new variant

**Files:**
- Modify: `Makefile:1-30`

**Step 1: Read current Makefile**

Run: `cat Makefile`

**Step 2: Add get-shit-done target**

Add after the ralph target:
```makefile
get-shit-done: base
	docker build -t opencode-get-shit-done get-shit-done/
```

**Step 3: Add get-shit-done to all target**

Update the `all` target to include `get-shit-done`.

**Step 4: Commit**

```bash
git add Makefile
git commit -m "feat: add get-shit-done to Makefile"
```

---

### Task 3: Verify the build works

**Step 1: Build the base image**

Run: `make base`
Expected: Builds successfully

**Step 2: Build the GSD variant**

Run: `make get-shit-done`
Expected: Builds successfully with GSD installed

**Step 3: Commit**

```bash
git add Makefile
git commit -m "chore: update Makefile with get-shit-done"
```