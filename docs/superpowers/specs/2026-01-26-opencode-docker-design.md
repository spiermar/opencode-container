# OpenCode Docker Container Design

## Overview

A Docker container for running OpenCode with CodeNomad, pre-configured with the Parasail provider and essential development tools.

## Files

```
opencode-container/
├── Dockerfile           # Main container definition
├── entrypoint.sh        # Startup script handling mode switching
├── opencode.json        # Provider configuration (already exists)
└── docs/plans/          # This design document
```

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `PARASAIL_API_KEY` | API key for the Parasail provider | (required) |
| `GITHUB_TOKEN` | GitHub token for git/gh authentication | (required) |
| `GIT_EMAIL` | Git commit email | `opencode@container.local` |
| `GIT_NAME` | Git commit author name | `OpenCode User` |
| `MODE` | `server` or `interactive` | `server` |
| `PORT` | CodeNomad server port | `9898` |

## Installed Components

- **Base:** Ubuntu latest
- **System tools:** git, gh (GitHub CLI), vim, curl
- **Node.js:** Latest LTS via nvm
- **OpenCode:** `npm install -g opencode-ai@latest`
- **CodeNomad:** `npx @neuralnomads/codenomad`
- **Playwright:** System dependencies via `npx playwright install-deps`
- **Superpowers:** Cloned and symlinked per documentation

## Container Configuration

- **User:** Non-root `opencode` user
- **Workspace:** `/workspace` mount point
- **Port:** 9898 (configurable)
- **Default mode:** Server (CodeNomad web UI)

## Dockerfile

```dockerfile
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# 1. System packages + GitHub CLI repository
RUN apt-get update && apt-get install -y \
    git curl vim ca-certificates gnupg sudo \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# 2. Create non-root user
RUN useradd -m -s /bin/bash opencode \
    && mkdir -p /workspace \
    && chown opencode:opencode /workspace

# 3. Playwright system dependencies (as root)
RUN npx playwright install-deps

# 4. Switch to opencode user for remaining setup
USER opencode
WORKDIR /home/opencode

# 5. Install nvm + Node.js LTS
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . ~/.nvm/nvm.sh \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default node

# 6. Install OpenCode CLI
RUN . ~/.nvm/nvm.sh && npm install -g opencode-ai@latest

# 7. Install Superpowers
RUN git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers \
    && mkdir -p ~/.config/opencode/plugins ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/superpowers/.opencode/plugins/superpowers.js \
             ~/.config/opencode/plugins/superpowers.js \
    && ln -s ~/.config/opencode/superpowers/skills \
             ~/.config/opencode/skills/superpowers

# 8. Copy provider configuration
COPY --chown=opencode:opencode opencode.json /home/opencode/.config/opencode/opencode.json

# 9. Copy entrypoint
COPY --chown=opencode:opencode entrypoint.sh /home/opencode/entrypoint.sh
RUN chmod +x /home/opencode/entrypoint.sh

# Environment defaults
ENV PORT=9898
ENV MODE=server

WORKDIR /workspace
EXPOSE 9898

ENTRYPOINT ["/home/opencode/entrypoint.sh"]
```

## Entrypoint Script

```bash
#!/bin/bash
set -e

# 1. Validate required environment variables
if [ -z "$PARASAIL_API_KEY" ]; then
  echo "Error: PARASAIL_API_KEY is required"
  exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is required"
  exit 1
fi

# 2. Configure GitHub authentication
gh auth setup-git
git config --global user.email "${GIT_EMAIL:-opencode@container.local}"
git config --global user.name "${GIT_NAME:-OpenCode User}"

# 3. Switch based on MODE
case "${MODE:-server}" in
  server)
    echo "Starting CodeNomad server on port ${PORT:-9898}..."
    exec npx @neuralnomads/codenomad --launch --port "${PORT:-9898}"
    ;;
  interactive)
    echo "Starting interactive shell..."
    exec /bin/bash
    ;;
  *)
    echo "Unknown MODE: $MODE (use 'server' or 'interactive')"
    exit 1
    ;;
esac
```

## Usage

### Build
```bash
docker build -t opencode .
```

### Server Mode (default)
```bash
docker run -p 9898:9898 \
  -e PARASAIL_API_KEY=your-key \
  -e GITHUB_TOKEN=your-token \
  -v $(pwd):/workspace \
  opencode
```
Access CodeNomad at http://localhost:9898

### Interactive Mode
```bash
docker run -it \
  -e PARASAIL_API_KEY=your-key \
  -e GITHUB_TOKEN=your-token \
  -e MODE=interactive \
  -v $(pwd):/workspace \
  opencode
```

### With Custom Git Identity
```bash
docker run -p 9898:9898 \
  -e PARASAIL_API_KEY=your-key \
  -e GITHUB_TOKEN=your-token \
  -e GIT_NAME="Your Name" \
  -e GIT_EMAIL="you@example.com" \
  -v $(pwd):/workspace \
  opencode
```
