# MCP Server Dynamic Enable/Disable Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add logic to entrypoint.sh to dynamically enable/disable Context7 and Tavily MCP servers based on API keys provided at container startup.

**Architecture:** Use jq to parse and modify opencode.json in place, checking for environment variables CONTEXT7_API_KEY and TAVILY_API_KEY.

**Tech Stack:** bash, jq

---

### Task 1: Add MCP configuration step to entrypoint.sh

**Files:**
- Modify: `base/entrypoint.sh:19-22`

**Step 1: Add the MCP configuration block after environment validation**

Edit `base/entrypoint.sh` to add after line 18 (after the GITHUB_TOKEN check, before the GitHub auth section):

```bash
# 2. Configure MCP servers based on available API keys
jq --argjson context7_enabled "$([ -n "$CONTEXT7_API_KEY" ] && echo "true" || echo "false")" \
   --argjson tavily_enabled "$([ -n "$TAVILY_API_KEY" ] && echo "true" || echo "false")" \
   '.mcp.context7.enabled = $context7_enabled | .mcp.tavily.enabled = $tavily_enabled' \
   /home/opencode/workspace/opencode.json > /tmp/opencode.json && \
mv /tmp/opencode.json /home/opencode/workspace/opencode.json
```

**Step 2: Verify the file is valid JSON**

Run: `jq empty /home/opencode/workspace/opencode.json`
Expected: No output (valid JSON)

**Step 3: Commit**

```bash
git add base/entrypoint.sh
git commit -m "feat: dynamically enable MCP servers based on API keys"
```

---

### Task 2: Verify MCP enabled values are correct after script runs

**Files:**
- Test: manual docker test

**Step 1: Build the image**

Run: `docker build -t opencode-base base/`
Expected: Build succeeds

**Step 2: Test with both API keys**

Run:
```bash
docker run --rm \
  -e PARASAIL_API_KEY="test-key" \
  -e GITHUB_TOKEN="test-token" \
  -e CONTEXT7_API_KEY="test-context7" \
  -e TAVILY_API_KEY="test-tavily" \
  opencode-base sh -c 'cat /home/opencode/workspace/opencode.json | jq ".mcp.context7.enabled, .mcp.tavily.enabled"'
```
Expected: `true` then `true`

**Step 3: Test with only CONTEXT7_API_KEY**

Run:
```bash
docker run --rm \
  -e PARASAIL_API_KEY="test-key" \
  -e GITHUB_TOKEN="test-token" \
  -e CONTEXT7_API_KEY="test-context7" \
  opencode-base sh -c 'cat /home/opencode/workspace/opencode.json | jq ".mcp.context7.enabled, .mcp.tavily.enabled"'
```
Expected: `true` then `false`

**Step 4: Test with no MCP keys**

Run:
```bash
docker run --rm \
  -e PARASAIL_API_KEY="test-key" \
  -e GITHUB_TOKEN="test-token" \
  opencode-base sh -c 'cat /home/opencode/workspace/opencode.json | jq ".mcp.context7.enabled, .mcp.tavily.enabled"'
```
Expected: `false` then `false`

**Step 5: Commit**

```bash
git add docs/plans/
git commit -m "test: verify MCP enable logic works correctly"
```

---

Plan complete and saved to `docs/plans/2026-02-14-mcp-enable-implementation.md`. Two execution options:

1. **Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

2. **Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?