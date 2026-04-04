# Docker Version Pinning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Docker builds deterministic by moving inline and floating external tool/package versions into top-of-file Docker `ARG`s and updating them to current stable releases.

**Architecture:** Keep version declarations local to the Dockerfile that consumes them. `base/Dockerfile` owns the shared toolchain pins, while variant Dockerfiles pin their own `npx` packages. Verification happens through existing repository lint/test scripts plus explicit image builds for the changed images.

**Tech Stack:** Docker, Ubuntu base image, npm/npx, GitHub release downloads, shell test scripts, hadolint

---

## File Structure

- Modify: `base/Dockerfile`
  - Add top-of-file `ARG`s for `nvm`, `hadolint`, `opencode-ai`, and `typescript`
  - Replace inline version literals with variable references
- Modify: `oh-my-opencode/Dockerfile`
  - Add a top-of-file `ARG` for the `oh-my-opencode` npm package version
  - Pin the `npx` invocation to that version
- Modify: `get-shit-done/Dockerfile`
  - Add a top-of-file `ARG` for the `get-shit-done-cc` npm package version
  - Replace `@latest` with the pinned version variable
- Verify with: `tests/lint-dockerfiles.sh`, `tests/run-all.sh`

Resolved stable versions for this change:

- `NVM_VERSION=0.40.4`
- `HADOLINT_VERSION=2.14.0`
- `OPENCODE_AI_VERSION=1.3.14`
- `TYPESCRIPT_VERSION=6.0.2`
- `OH_MY_OPENCODE_VERSION=3.15.0`
- `GET_SHIT_DONE_CC_VERSION=1.32.0`

## Task 1: Pin Shared Tool Versions In `base/Dockerfile`

**Files:**
- Modify: `base/Dockerfile:1-53`
- Test: `tests/lint-dockerfiles.sh`

- [ ] **Step 1: Write the failing policy check**

Run this command to prove the file still contains inline version literals that
must be removed:

```bash
if rg -n 'v2\.12\.0|v0\.40\.1|opencode-ai@1\.2\.1|typescript@5\.9\.3' base/Dockerfile; then
  echo "Inline version literals still present"
  exit 1
fi
```

Expected: the command fails because `rg` finds those literals in
`base/Dockerfile`.

- [ ] **Step 2: Re-run the check and inspect the exact failing lines**

```bash
rg -n 'v2\.12\.0|v0\.40\.1|opencode-ai@1\.2\.1|typescript@5\.9\.3' base/Dockerfile
```

Expected output includes matches for the hadolint download URL, the `nvm`
install script URL, and the global `npm install` command.

- [ ] **Step 3: Write the minimal Dockerfile change**

Update `base/Dockerfile` so the version values move to top-of-file `ARG`s and
the install commands reference them:

```dockerfile
FROM ubuntu:latest

ARG NVM_VERSION=0.40.4
ARG HADOLINT_VERSION=2.14.0
ARG OPENCODE_AI_VERSION=1.3.14
ARG TYPESCRIPT_VERSION=6.0.2

ENV DEBIAN_FRONTEND=noninteractive

# 1. System packages + GitHub CLI repository
RUN apt-get update && apt-get install -y \
    build-essential git curl jq make vim ca-certificates gnupg sudo postgresql-client wget zip unzip gnupg openssh-client ripgrep shellcheck \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL -o /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64 \
    && chmod +x /usr/local/bin/hadolint

# 4. Install nvm + Node.js LTS
ENV NVM_DIR=/home/opencode/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default node

# 9. Install OpenCode CLI and TypeScript
RUN . ~/.nvm/nvm.sh && npm install -g opencode-ai@${OPENCODE_AI_VERSION} typescript@${TYPESCRIPT_VERSION}
```

- [ ] **Step 4: Run the file-level verification**

```bash
rg -n 'ARG (NVM_VERSION|HADOLINT_VERSION|OPENCODE_AI_VERSION|TYPESCRIPT_VERSION)=' base/Dockerfile
if rg -n 'v2\.12\.0|v0\.40\.1|opencode-ai@1\.2\.1|typescript@5\.9\.3' base/Dockerfile; then
  echo "Inline version literals still present"
  exit 1
fi
hadolint base/Dockerfile
```

Expected:

- the first command prints four `ARG` declarations
- the second command succeeds with no matches
- `hadolint base/Dockerfile` exits cleanly

- [ ] **Step 5: Commit only if the user explicitly requested a commit**

```bash
git add base/Dockerfile
git commit -m "chore: pin base Docker tool versions"
```

Expected: skip this step unless the user has explicitly asked for a commit.

## Task 2: Pin Variant `npx` Package Versions

**Files:**
- Modify: `oh-my-opencode/Dockerfile:1-6`
- Modify: `get-shit-done/Dockerfile:1-7`
- Test: `tests/lint-dockerfiles.sh`

- [ ] **Step 1: Write the failing policy check**

Run this command to prove the variant Dockerfiles still contain floating package
usage:

```bash
if rg -n '@latest|npx oh-my-opencode install' oh-my-opencode/Dockerfile get-shit-done/Dockerfile; then
  echo "Floating package install still present"
  exit 1
fi
```

Expected: the command fails because at least one floating install pattern is
still present.

- [ ] **Step 2: Re-run the check and inspect the exact failing lines**

```bash
rg -n '@latest|npx oh-my-opencode install' oh-my-opencode/Dockerfile get-shit-done/Dockerfile
```

Expected output shows `get-shit-done-cc@latest` and the unpinned
`npx oh-my-opencode install` invocation.

- [ ] **Step 3: Write the minimal Dockerfile changes**

Update `oh-my-opencode/Dockerfile` to pin the package version with a top-of-file
`ARG`:

```dockerfile
ARG BASE_IMAGE=opencode-base
FROM ${BASE_IMAGE}

ARG OH_MY_OPENCODE_VERSION=3.15.0

USER opencode
COPY --chown=opencode:opencode oh-my-opencode.jsonc /home/opencode/.opencode/oh-my-opencode.jsonc
RUN . ~/.nvm/nvm.sh && npx oh-my-opencode@${OH_MY_OPENCODE_VERSION} install --no-tui --claude=no --gemini=no --copilot=no --openai=no
```

Update `get-shit-done/Dockerfile` to pin the package version with a top-of-file
`ARG`:

```dockerfile
ARG BASE_IMAGE=opencode-base
FROM ${BASE_IMAGE}

ARG GET_SHIT_DONE_CC_VERSION=1.32.0

USER opencode

RUN . ~/.nvm/nvm.sh && CLAUDE_CONFIG_DIR=/home/opencode/.config/opencode npx get-shit-done-cc@${GET_SHIT_DONE_CC_VERSION} --opencode --global
```

- [ ] **Step 4: Run the file-level verification**

```bash
rg -n 'ARG (OH_MY_OPENCODE_VERSION|GET_SHIT_DONE_CC_VERSION)=' oh-my-opencode/Dockerfile get-shit-done/Dockerfile
if rg -n '@latest|npx oh-my-opencode install' oh-my-opencode/Dockerfile get-shit-done/Dockerfile; then
  echo "Floating package install still present"
  exit 1
fi
hadolint oh-my-opencode/Dockerfile
hadolint get-shit-done/Dockerfile
```

Expected:

- the first command prints both new `ARG` declarations
- the second command succeeds with no matches
- both hadolint commands exit cleanly

- [ ] **Step 5: Commit only if the user explicitly requested a commit**

```bash
git add oh-my-opencode/Dockerfile get-shit-done/Dockerfile
git commit -m "chore: pin variant Docker package versions"
```

Expected: skip this step unless the user has explicitly asked for a commit.

## Task 3: Verify Dockerfile Quality And Build Behavior

**Files:**
- Verify: `base/Dockerfile`
- Verify: `oh-my-opencode/Dockerfile`
- Verify: `get-shit-done/Dockerfile`
- Test: `tests/lint-dockerfiles.sh`
- Test: `tests/run-all.sh`

- [ ] **Step 1: Lint all Dockerfiles through the repository script**

```bash
./tests/lint-dockerfiles.sh
```

Expected: the script ends with `All Dockerfiles passed linting`.

- [ ] **Step 2: Build the base image with the new pinned versions**

```bash
docker build -t opencode-base base/
```

Expected: Docker completes successfully and installs `hadolint`, `nvm`,
`opencode-ai`, and `typescript` using the pinned version variables.

- [ ] **Step 3: Build the `oh-my-opencode` variant image**

```bash
docker build -t opencode-oh-my-opencode oh-my-opencode/
```

Expected: Docker completes successfully and the `npx` install resolves
`oh-my-opencode@3.15.0`.

- [ ] **Step 4: Build the `get-shit-done` variant image**

```bash
docker build -t opencode-get-shit-done get-shit-done/
```

Expected: Docker completes successfully and the `npx` install resolves
`get-shit-done-cc@1.32.0`.

- [ ] **Step 5: Run the full repository test script**

```bash
./tests/run-all.sh
```

Expected: the script ends with `All tests PASSED`.

- [ ] **Step 6: Commit only if the user explicitly requested a commit**

```bash
git add base/Dockerfile oh-my-opencode/Dockerfile get-shit-done/Dockerfile
git commit -m "chore: pin Docker build package versions"
```

Expected: skip this step unless the user has explicitly asked for a commit.
