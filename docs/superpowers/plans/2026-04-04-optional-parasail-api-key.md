# Optional PARASAIL_API_KEY Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow the container to start without `PARASAIL_API_KEY` by printing a warning instead of exiting.

**Architecture:** Keep the change isolated to `base/entrypoint.sh`. Replace the current hard failure for a missing `PARASAIL_API_KEY` with a warning to stderr, while leaving the rest of the startup flow, provider config, and `GITHUB_TOKEN` enforcement unchanged.

**Tech Stack:** bash, Docker, shellcheck

---

### Task 1: Relax PARASAIL_API_KEY startup validation

**Files:**
- Modify: `base/entrypoint.sh:8-17`
- Verify: `tests/lint-scripts.sh`
- Verify: Docker image built from `base/`

- [ ] **Step 1: Reproduce the current failure without `PARASAIL_API_KEY`**

Run:

```bash
docker build -t opencode-base base/
docker run --rm \
  -e GITHUB_TOKEN="test-token" \
  opencode-base
```

Expected: The container exits non-zero and prints `Error: PARASAIL_API_KEY is required`.

- [ ] **Step 2: Update the validation block in `base/entrypoint.sh`**

Replace the current validation section with:

```bash
# 1. Validate required environment variables
if [ -z "$PARASAIL_API_KEY" ]; then
  echo "Warning: PARASAIL_API_KEY is not set; Parasail-backed requests may fail until it is provided." >&2
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is required"
  exit 1
fi
```

- [ ] **Step 3: Run shell lint after the edit**

Run:

```bash
make test-scripts
```

Expected: `All shell scripts passed linting`

- [ ] **Step 4: Rebuild the image with the updated entrypoint**

Run:

```bash
docker build -t opencode-base base/
```

Expected: Build succeeds.

- [ ] **Step 5: Verify startup continues and emits the warning**

Run:

```bash
docker run -d \
  --name optional-parasail-warning-test \
  -e GITHUB_TOKEN="test-token" \
  -e CLI_HOST="0.0.0.0" \
  -p 9898:9898 \
  opencode-base
docker logs optional-parasail-warning-test
curl --retry 5 --retry-delay 1 --retry-connrefused http://localhost:9898
docker rm -f optional-parasail-warning-test
```

Expected:
- Logs include `Warning: PARASAIL_API_KEY is not set; Parasail-backed requests may fail until it is provided.`
- Logs include `Starting opencode server...`
- `curl` returns an HTTP response instead of connection failure.

- [ ] **Step 6: Verify `GITHUB_TOKEN` is still required**

Run:

```bash
docker run --rm \
  -e PARASAIL_API_KEY="test-key" \
  opencode-base
```

Expected: The container exits non-zero and prints `Error: GITHUB_TOKEN is required`.

- [ ] **Step 7: Inspect the final worktree state**

Run:

```bash
git status --short
```

Expected: Only the planned `base/entrypoint.sh` change appears as modified for this task.
