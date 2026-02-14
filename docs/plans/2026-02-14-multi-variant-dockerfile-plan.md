# Multi-Variant Dockerfile Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the monolithic Dockerfile into a base image and 3 plugin-specific variant images.

**Architecture:** A shared `opencode-base` image contains system deps, Node, Playwright, OpenCode CLI, shared skills, config, and entrypoint. Three thin variant Dockerfiles layer a single plugin each on top. A Makefile orchestrates builds.

**Tech Stack:** Docker, Make, bash

---

### Task 1: Create base directory and base Dockerfile

**Files:**
- Create: `base/Dockerfile`

**Step 1: Create `base/` directory**

Run: `mkdir -p base`

**Step 2: Write `base/Dockerfile`**

Create `base/Dockerfile` with the following content — this is the current `Dockerfile` with the superpowers install (step 10, lines 53-59) removed:

```dockerfile
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# 1. System packages + GitHub CLI repository
RUN apt-get update && apt-get install -y \
    build-essential git curl jq make vim ca-certificates gnupg sudo postgresql-client wget zip unzip gnupg openssh-client ripgrep \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# 2. Create non-root user with uid/gid 1000
#    Remove any existing user/group with uid/gid 1000 first (ubuntu image may have 'ubuntu' user)
RUN (getent passwd 1000 | cut -d: -f1 | xargs -r userdel -r 2>/dev/null || true) \
    && (getent group 1000 | cut -d: -f1 | xargs -r groupdel 2>/dev/null || true) \
    && groupadd -g 1000 opencode \
    && useradd -u 1000 -g 1000 -m -s /bin/bash opencode \
    && mkdir -p /home/opencode/workspace \
    && chown opencode:opencode /home/opencode/workspace

# 3. Switch to opencode user for nvm setup
USER opencode
WORKDIR /home/opencode
ENV HOME=/home/opencode

# 4. Install nvm + Node.js LTS
ENV NVM_DIR=/home/opencode/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default node

# 5. Playwright system dependencies and browser (as root, using opencode's node)
USER root
RUN bash -c 'export NVM_DIR="/home/opencode/.nvm" && . "$NVM_DIR/nvm.sh" && npx playwright install chromium --with-deps'

# 6. Fix cache ownership (root's npx created root-owned files)
RUN chown -R opencode:opencode /home/opencode/.npm /home/opencode/.cache

# 7. Switch back to opencode user for remaining setup
USER opencode

# 8. Add GitHub to known_hosts for non-interactive git operations
RUN mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# 9. Install OpenCode CLI
RUN . ~/.nvm/nvm.sh && npm install -g opencode-ai@latest

# 10. Install Anthropic Agent Skills
# NOTE: Some skills (docx, pdf, pptx, xlsx) are source-available, not Apache 2.0.
#       See https://github.com/anthropics/skills for licensing details.
RUN git clone https://github.com/anthropics/skills.git ~/.config/opencode/anthropics-skills \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/anthropics-skills/skills \
             ~/.config/opencode/skills/anthropics

# 11. Install spiermar skills and agents
RUN git clone https://github.com/spiermar/oh-no-claudecode.git ~/.config/opencode/oh-no-claudecode \
    && mkdir -p ~/.config/opencode/skills ~/.config/opencode/agents \
    && ln -s ~/.config/opencode/oh-no-claudecode/skills \
             ~/.config/opencode/skills/spiermar \
    && ln -s ~/.config/opencode/oh-no-claudecode/agents \
             ~/.config/opencode/agents/spiermar

# 12. Install Vercel Labs skills
RUN git clone https://github.com/vercel-labs/skills.git ~/.config/opencode/vercel-labs-skills \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/vercel-labs-skills/skills \
             ~/.config/opencode/skills/vercel-labs

# 13. Copy provider configuration
COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json

# 14. Copy entrypoint
COPY --chown=opencode:opencode entrypoint.sh /home/opencode/entrypoint.sh
RUN chmod +x /home/opencode/entrypoint.sh

# Environment defaults
ENV CLI_PORT=9898
ENV MODE=server

WORKDIR /home/opencode/workspace
EXPOSE 9898

ENTRYPOINT ["/home/opencode/entrypoint.sh"]
```

**Step 3: Commit**

```bash
git add base/Dockerfile
git commit -m "feat: add base Dockerfile without plugin-specific steps"
```

---

### Task 2: Move shared files into base directory

**Files:**
- Move: `entrypoint.sh` -> `base/entrypoint.sh`
- Move: `opencode.json` -> `base/opencode.json`

**Step 1: Move entrypoint.sh to base/**

Run: `git mv entrypoint.sh base/entrypoint.sh`

**Step 2: Move opencode.json to base/**

Run: `git mv opencode.json base/opencode.json`

**Step 3: Commit**

```bash
git add base/entrypoint.sh base/opencode.json
git commit -m "refactor: move entrypoint.sh and opencode.json into base/"
```

---

### Task 3: Create superpowers variant Dockerfile

**Files:**
- Create: `superpowers/Dockerfile`

**Step 1: Create `superpowers/` directory**

Run: `mkdir -p superpowers`

**Step 2: Write `superpowers/Dockerfile`**

```dockerfile
FROM opencode-base

USER opencode
RUN git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers \
    && mkdir -p ~/.config/opencode/plugins ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js \
             ~/.config/opencode/plugins/superpowers.js \
    && ln -s ~/.config/opencode/superpowers/skills \
             ~/.config/opencode/skills/superpowers
```

**Step 3: Commit**

```bash
git add superpowers/Dockerfile
git commit -m "feat: add superpowers variant Dockerfile"
```

---

### Task 4: Create oh-my-opencode variant Dockerfile and config

**Files:**
- Create: `oh-my-opencode/Dockerfile`
- Create: `oh-my-opencode/oh-my-opencode.jsonc` (placeholder — user must populate with their config)

**Step 1: Create `oh-my-opencode/` directory**

Run: `mkdir -p oh-my-opencode`

**Step 2: Write `oh-my-opencode/Dockerfile`**

```dockerfile
FROM opencode-base

USER opencode
COPY --chown=opencode:opencode oh-my-opencode.jsonc /home/opencode/.opencode/oh-my-opencode.jsonc
RUN . ~/.nvm/nvm.sh && npx oh-my-opencode install --no-tui --claude=no --gemini=no --copilot=no --openai=no
```

**Step 3: Write placeholder `oh-my-opencode/oh-my-opencode.jsonc`**

Create an empty JSONC config file. The user will populate this with their oh-my-opencode configuration before building.

```jsonc
// oh-my-opencode configuration
// See https://github.com/code-yeongyu/oh-my-opencode for details
{}
```

**Step 4: Commit**

```bash
git add oh-my-opencode/Dockerfile oh-my-opencode/oh-my-opencode.jsonc
git commit -m "feat: add oh-my-opencode variant Dockerfile and config placeholder"
```

---

### Task 5: Create ralph variant Dockerfile

**Files:**
- Create: `ralph/Dockerfile`

**Step 1: Create `ralph/` directory**

Run: `mkdir -p ralph`

**Step 2: Write `ralph/Dockerfile`**

```dockerfile
FROM opencode-base

USER opencode
RUN git clone https://github.com/snarktank/ralph.git ~/.config/opencode/ralph \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/ralph/skills \
             ~/.config/opencode/skills/ralph
```

**Step 3: Commit**

```bash
git add ralph/Dockerfile
git commit -m "feat: add ralph variant Dockerfile"
```

---

### Task 6: Create Makefile

**Files:**
- Create: `Makefile`

**Step 1: Write `Makefile`**

```makefile
.PHONY: base superpowers oh-my-opencode ralph all

base:
	docker build -t opencode-base base/

superpowers: base
	docker build -t opencode-superpowers superpowers/

oh-my-opencode: base
	docker build -t opencode-oh-my-opencode oh-my-opencode/

ralph: base
	docker build -t opencode-ralph ralph/

all: superpowers oh-my-opencode ralph
```

**Step 2: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile for multi-variant Docker builds"
```

---

### Task 7: Remove old root-level Dockerfile

**Files:**
- Delete: `Dockerfile`

**Step 1: Remove old Dockerfile**

Run: `git rm Dockerfile`

**Step 2: Commit**

```bash
git commit -m "refactor: remove monolithic Dockerfile in favor of base + variant structure"
```

---

### Task 8: Verify file structure

**Step 1: Verify the final directory layout**

Run: `find base superpowers oh-my-opencode ralph Makefile -type f | sort`

Expected output:
```
Makefile
base/Dockerfile
base/entrypoint.sh
base/opencode.json
oh-my-opencode/Dockerfile
oh-my-opencode/oh-my-opencode.jsonc
ralph/Dockerfile
superpowers/Dockerfile
```

**Step 2: Verify no stale files remain in root**

Confirm that `Dockerfile`, `entrypoint.sh`, and `opencode.json` no longer exist at the project root.

Run: `ls Dockerfile entrypoint.sh opencode.json 2>&1`

Expected: all three should report "No such file or directory".
