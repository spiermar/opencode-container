# Testing Without Docker Build - Design

## Overview

Add a test suite that validates the repository without building Docker images. The tests use static analysis tools (hadolint, shellcheck, jq) to verify Dockerfile syntax, shell script quality, and JSON configuration validity.

## Goals

- Provide fast feedback during development
- Catch errors before building Docker images
- Enable local and CI testing with a consistent experience

## Directory Structure

```
opencode-container/
├── .github/
│   └── workflows/
│       └── test.yml           # GitHub Actions workflow
├── tests/
│   ├── lint-dockerfiles.sh    # Lint all Dockerfiles with hadolint
│   ├── lint-scripts.sh        # Lint shell scripts with shellcheck
│   ├── validate-json.sh       # Validate JSON config files
│   ├── Makefile               # Test runner Makefile
│   └── run-all.sh             # Master test runner
└── (existing files...)
```

## Test Components

### 1. Dockerfile Linting (`lint-dockerfiles.sh`)

- Uses `hadolint` to validate all Dockerfiles
- Runs against: `base/Dockerfile`, `superpowers/Dockerfile`, `ralph/Dockerfile`, `oh-my-opencode/Dockerfile`
- Configuration: Uses `.hadolint.yaml` for project-specific rules

### 2. Shell Script Linting (`lint-scripts.sh`)

- Uses `shellcheck` to validate bash scripts
- Runs against: `base/entrypoint.sh`
- Validates: syntax, best practices, common errors

### 3. JSON Validation (`validate-json.sh`)

- Uses `jq` to validate JSON syntax
- Runs against: `base/opencode.json`, `oh-my-opencode/oh-my-opencode.jsonc`
- Note: `.jsonc` files need preprocessing to strip comments

## GitHub Actions Workflow

```yaml
name: Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint-dockerfiles:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./tests/lint-dockerfiles.sh

  lint-scripts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./tests/lint-scripts.sh

  validate-json:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./tests/validate-json.sh
```

## Makefile Integration

Add `test` target to root Makefile:

```makefile
test:
	./tests/run-all.sh
```

## Tool Installation

### For Local Testing

```bash
# macOS
brew install hadolint shellcheck jq

# Linux (Ubuntu/Debian)
apt-get install hadolint shellcheck jq
```

### For CI

GitHub Actions uses Ubuntu runners which have these tools pre-installed.

## Exit Codes

- Exit 0: All tests passed
- Exit 1: One or more tests failed

## Success Criteria

1. All Dockerfiles pass hadolint validation
2. All shell scripts pass shellcheck validation
3. All JSON files are valid and parseable
4. Tests can run locally without Docker
5. GitHub Actions provides clear feedback on failures