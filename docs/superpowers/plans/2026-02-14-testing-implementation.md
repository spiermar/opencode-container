# Testing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a test suite that validates the repository without building Docker images using hadolint, shellcheck, and jq.

**Architecture:** Create shell-based test scripts that can run locally and integrate with GitHub Actions for CI. Each test type (Dockerfiles, shell scripts, JSON) runs as a separate job.

**Tech Stack:** hadolint, shellcheck, jq, bash, GitHub Actions

---

### Task 1: Create .hadolint.yaml config file

**Files:**
- Create: `.hadolint.yaml`

**Step 1: Create hadolint configuration**

```yaml
# hadolint configuration for opencode-container
ignored:
  - DL3008  # Pin versions in apt-get install - we intentionally use latest
  - DL3015  # Avoid additional packages - we want recommended packages
  - DL3059  # Multiple consecutive RUN - we chain for efficiency
  - SC1091  # Not following - shellcheck can't follow sourced files

trustedRegistries:
  - docker.io
  - ghcr.io

label-schema:
  version: semver
  maintainer: text
```

**Step 2: Verify file is valid YAML**

```bash
python3 -c "import yaml; yaml.safe_load(open('.hadolint.yaml'))"
```

**Step 3: Commit**

```bash
git add .hadolint.yaml
git commit -m "test: add hadolint configuration"
```

---

### Task 2: Create lint-dockerfiles.sh test script

**Files:**
- Create: `tests/lint-dockerfiles.sh`

**Step 1: Create the test script**

```bash
#!/bin/bash
# Lint all Dockerfiles using hadolint
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Linting Dockerfiles..."

# Check if hadolint is installed
if ! command -v hadolint &> /dev/null; then
    echo "Error: hadolint not installed"
    echo "Install with: brew install hadolint (macOS) or apt-get install hadolint (Linux)"
    exit 1
fi

# Find all Dockerfiles
DOCKERFILES=$(find . -name "Dockerfile" -type f | grep -v ".codenomad")

FAILED=0

for df in $DOCKERFILES; do
    echo "Linting: $df"
    if ! hadolint "$df"; then
        echo "FAILED: $df"
        FAILED=1
    fi
done

if [ $FAILED -eq 1 ]; then
    echo "One or more Dockerfiles failed linting"
    exit 1
fi

echo "All Dockerfiles passed linting"
exit 0
```

**Step 2: Make script executable**

```bash
chmod +x tests/lint-dockerfiles.sh
```

**Step 3: Test the script runs without errors**

```bash
./tests/lint-dockerfiles.sh
```

**Step 4: Commit**

```bash
git add tests/lint-dockerfiles.sh
git commit -m "test: add Dockerfile linting script"
```

---

### Task 3: Create lint-scripts.sh test script

**Files:**
- Create: `tests/lint-scripts.sh`

**Step 1: Create the test script**

```bash
#!/bin/bash
# Lint shell scripts using shellcheck
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Linting shell scripts..."

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo "Error: shellcheck not installed"
    echo "Install with: brew install shellcheck (macOS) or apt-get install shellcheck (Linux)"
    exit 1
fi

# Find all shell scripts (excluding .git and tests directories)
SCRIPTS=$(find . -name "*.sh" -type f | grep -v ".git" | grep -v "^./tests/")

FAILED=0

for script in $SCRIPTS; do
    echo "Linting: $script"
    # Use SC1090 for dynamic variable access and SC2086 for quoting
    if ! shellcheck -s bash -e SC1090,SC2086 "$script"; then
        echo "FAILED: $script"
        FAILED=1
    fi
done

if [ $FAILED -eq 1 ]; then
    echo "One or more scripts failed linting"
    exit 1
fi

echo "All shell scripts passed linting"
exit 0
```

**Step 2: Make script executable**

```bash
chmod +x tests/lint-scripts.sh
```

**Step 3: Test the script runs without errors**

```bash
./tests/lint-scripts.sh
```

**Step 4: Commit**

```bash
git add tests/lint-scripts.sh
git commit -m "test: add shell script linting script"
```

---

### Task 4: Create validate-json.sh test script

**Files:**
- Create: `tests/validate-json.sh`

**Step 1: Create the test script**

```bash
#!/bin/bash
# Validate JSON configuration files
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Validating JSON files..."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq not installed"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Find JSON files (not in .git)
JSON_FILES=$(find . -name "*.json" -type f | grep -v ".git" | grep -v ".codenomad")

FAILED=0

for json_file in $JSON_FILES; do
    echo "Validating: $json_file"
    if ! jq empty "$json_file" 2>/dev/null; then
        echo "FAILED: $json_file is not valid JSON"
        FAILED=1
    fi
done

# Handle JSONC files (JSON with comments)
JSONC_FILES=$(find . -name "*.jsonc" -type f | grep -v ".git")
for jsonc_file in $JSONC_FILES; do
    echo "Validating: $jsonc_file (stripping comments)"
    # Strip comments and validate as JSON
    TEMP_FILE=$(mktemp)
    grep -v '^\s*//' "$jsonc_file" | grep -v '^\s*#' > "$TEMP_FILE"
    if ! jq empty "$TEMP_FILE" 2>/dev/null; then
        echo "FAILED: $jsonc_file is not valid JSON (after stripping comments)"
        FAILED=1
    fi
    rm -f "$TEMP_FILE"
done

if [ $FAILED -eq 1 ]; then
    echo "One or more JSON files failed validation"
    exit 1
fi

echo "All JSON files passed validation"
exit 0
```

**Step 2: Make script executable**

```bash
chmod +x tests/validate-json.sh
```

**Step 3: Test the script runs without errors**

```bash
./tests/validate-json.sh
```

**Step 4: Commit**

```bash
git add tests/validate-json.sh
git commit -m "test: add JSON validation script"
```

---

### Task 5: Create tests/run-all.sh master runner

**Files:**
- Create: `tests/run-all.sh`

**Step 1: Create the master test runner**

```bash
#!/bin/bash
# Run all tests
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "========================================"
echo "Running all tests..."
echo "========================================"

FAILED=0

echo ""
echo "--- Linting Dockerfiles ---"
if ! ./tests/lint-dockerfiles.sh; then
    FAILED=1
fi

echo ""
echo "--- Linting Shell Scripts ---"
if ! ./tests/lint-scripts.sh; then
    FAILED=1
fi

echo ""
echo "--- Validating JSON Files ---"
if ! ./tests/validate-json.sh; then
    FAILED=1
fi

echo ""
echo "========================================"
if [ $FAILED -eq 1 ]; then
    echo "Some tests FAILED"
    exit 1
else
    echo "All tests PASSED"
    exit 0
fi
```

**Step 2: Make script executable**

```bash
chmod +x tests/run-all.sh
```

**Step 3: Test the script runs without errors**

```bash
./tests/run-all.sh
```

**Step 4: Commit**

```bash
git add tests/run-all.sh
git commit -m "test: add master test runner"
```

---

### Task 6: Create tests/Makefile

**Files:**
- Create: `tests/Makefile`

**Step 1: Create the Makefile**

```makefile
.PHONY: all test lint-dockerfiles lint-scripts validate-json clean

all: test

test:
	./run-all.sh

lint-dockerfiles:
	../lint-dockerfiles.sh

lint-scripts:
	../lint-scripts.sh

validate-json:
	../validate-json.sh

clean:
	@echo "Nothing to clean"
```

**Step 2: Commit**

```bash
git add tests/Makefile
git commit -m "test: add tests Makefile"
```

---

### Task 7: Create .github/workflows/test.yml

**Files:**
- Create: `.github/workflows/test.yml`

**Step 1: Create GitHub Actions workflow**

```yaml
name: Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint-dockerfiles:
    name: Lint Dockerfiles
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install hadolint
        run: |
          sudo apt-get update
          sudo apt-get install -y hadolint

      - name: Run hadolint
        run: ./tests/lint-dockerfiles.sh

  lint-scripts:
    name: Lint Shell Scripts
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install shellcheck
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck

      - name: Run shellcheck
        run: ./tests/lint-scripts.sh

  validate-json:
    name: Validate JSON Files
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install jq
        run: |
          sudo apt-get update
          sudo apt-get install -y jq

      - name: Validate JSON
        run: ./tests/validate-json.sh
```

**Step 2: Commit**

```bash
git add .github/workflows/test.yml
git commit -m "test: add GitHub Actions workflow"
```

---

### Task 8: Update root Makefile with test target

**Files:**
- Modify: `Makefile`

**Step 1: Add test target to Makefile**

Add to end of Makefile:

```makefile
# Test targets
test:
	./tests/run-all.sh

test-dockerfiles:
	./tests/lint-dockerfiles.sh

test-scripts:
	./tests/lint-scripts.sh

test-json:
	./tests/validate-json.sh
```

**Step 2: Commit**

```bash
git add Makefile
git commit -m "test: add test targets to Makefile"
```

---

### Task 9: Test locally and verify all scripts work

**Step 1: Install test tools**

```bash
# macOS
brew install hadolint shellcheck jq

# Ubuntu/Debian
sudo apt-get install hadolint shellcheck jq
```

**Step 2: Run all tests**

```bash
make test
```

Expected output:
```
========================================
Running all tests...
========================================

--- Linting Dockerfiles ---
Linting Dockerfiles...
Linting: ./base/Dockerfile
All Dockerfiles passed linting

--- Linting Shell Scripts ---
Linting shell scripts...
Linting: ./base/entrypoint.sh
All shell scripts passed linting

--- Validating JSON Files ---
Validating JSON files...
Validating: ./base/opencode.json
All JSON files passed validation

========================================
All tests PASSED
```

**Step 3: Test failure case (optional verification)**

Create a temporary test file with intentional error to verify script catches it:

```bash
# This is just for verification, do not commit
echo "invalid json" > /tmp/bad.json
jq empty /tmp/bad.json  # Should fail
```

---

### Task 10: Commit all remaining changes

**Step 1: Check git status**

```bash
git status
```

**Step 2: Commit any uncommitted changes**

```bash
git add -A
git commit -m "test: add full test suite without Docker build"
```

---

## Plan Complete

Two execution options:

1. **Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

2. **Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?