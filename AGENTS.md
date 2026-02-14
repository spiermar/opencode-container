# AGENTS.md

This document guides agentic coding assistants working on the OpenCode Container repository.

## Project Overview

The OpenCode Container is a Docker image for running OpenCode with CodeNomad, pre-configured with the Parasail provider and development tools.

## Build Commands

### Build Docker Image
```bash
docker build -t opencode .
```

### Test Container - Server Mode
```bash
docker run -d \
  -e PARASAIL_API_KEY="test-key" \
  -e GITHUB_TOKEN="test-token" \
  -e CODENOMAD_SERVER_PASSWORD="test-password" \
  -e CLI_HOST="0.0.0.0" \
  -p 9898:9898 \
  -v $(pwd)/test-workspace:/home/opencode/workspace \
  opencode
```

Verify: `curl http://localhost:9898` or access CodeNomad UI in browser

### Test Container - Interactive Mode
```bash
docker run -it \
  -e PARASAIL_API_KEY="test-key" \
  -e GITHUB_TOKEN="test-token" \
  -e MODE=interactive \
  -v $(pwd):/workspace \
  opencode
```

### Test with Single Command
```bash
docker run --rm \
  -e PARASAIL_API_KEY="test-key" \
  -e GITHUB_TOKEN="test-token" \
  opencode sh -c "opencode --version"
```

## Code Style Guidelines

### Dockerfile
- **Section comments**: Use `# N. Description` format for major sections
- **Indentation**: 2 spaces for line continuations
- **Chain RUN commands**: Combine related operations with `&&` to reduce layers
- **Cleanup**: Always `rm -rf /var/lib/apt/lists/*` after apt operations
- **User switching**: Minimize root usage, switch to non-root user ASAP
- **Permissions**: Use `--chown=opencode:opencode` when copying files
- **Numeric sections**: Number each major step sequentially (1, 2, 3...)

Example:
```dockerfile
# 1. Install system packages
RUN apt-get update && apt-get install -y \
    package1 package2 \
    && rm -rf /var/lib/apt/lists/*
```

### Shell Scripts (entrypoint.sh, others)
- **Error handling**: Always start with `#!/bin/bash` and `set -e`
- **Validation**: Validate required env vars at top with descriptive errors
- **Exit on error**: Use `exit 1` with clear error message
- **Defaults**: Use `${VAR:-default}` syntax for optional variables
- **Indentation**: 2 spaces within case statements and conditionals
- **Comments**: Section comments `# 1. Description` for logical blocks
- **Execution**: Always use `exec` for final command (no extra shell)

Example:
```bash
#!/bin/bash
set -e

# 1. Validate required environment variables
if [ -z "$REQUIRED_VAR" ]; then
  echo "Error: REQUIRED_VAR is required"
  exit 1
fi

exec npx some-command
```

### JSON (opencode.json)
- **Formatting**: 2 space indentation
- **Structure**: Follow existing schema pattern
- **Order**: Top-level sections: schema, model, provider

### Markdown (README.md, docs/)
- **Headers**: Use ATX style (`# Header`)
- **Code blocks**: Specify language (e.g., ```bash, ```dockerfile)
- **Lists**: Use `-` for bulleted lists
- **Links**: Use descriptive link text
- **Line length**: Wrap at ~80-100 characters when possible

## File Organization

```
opencode-container/
├── Dockerfile              # Container definition
├── entrypoint.sh           # Startup script (must be executable)
├── opencode.json           # Provider config
├── README.md               # User documentation
└── docs/
    └── plans/              # Design documents (YYYY-MM-DD-name.md)
```

## Common Patterns

### Adding New Skills
Clone to `~/.config/opencode/` and symlink to skills directory:
```dockerfile
RUN git clone <repo> ~/.config/opencode/repo-name \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/repo-name/skills \
             ~/.config/opencode/skills/skill-name
```

### Installing npm Packages Globally
```dockerfile
RUN . ~/.nvm/nvm.sh && npm install -g package-name@latest
```

### Managing File Ownership After Root Operations
```dockerfile
USER root
RUN some-root-command
RUN chown -R opencode:opencode /home/opencode/.npm /home/opencode/.cache
USER opencode
```

## Environment Variables

Required:
- `PARASAIL_API_KEY` - API key for Parasail provider
- `GITHUB_TOKEN` - GitHub token for gh CLI

Optional (with defaults):
- `GIT_EMAIL` - Default: `opencode@local`
- `GIT_NAME` - Default: `OpenCode`
- `MODE` - `server` or `interactive`, default: `server`
- `CLI_PORT` - Server port, default: `9898`
- `CLI_HOST` - Bind address, default: `127.0.0.1`
- `CODENOMAD_SERVER_PASSWORD` - Required in server mode

## Testing Strategy

1. **Build verification**: Image builds without errors
2. **Basic smoke test**: `docker run --rm ... opencode --version`
3. **Server mode**: Verify CodeNomad starts and is accessible on configured port
4. **Interactive mode**: Verify shell starts and commands work
5. **Workspace mount**: Verify user can access mounted workspace

## Git Conventions

- **Commit messages**: Conventional Commits format (feat:, fix:, docs:, etc.)
- **Branch naming**: `feature/short-description` or `fix/short-description`
