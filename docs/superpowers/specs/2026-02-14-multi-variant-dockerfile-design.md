# Multi-Variant Dockerfile Design

## Overview

Split the monolithic Dockerfile into a base image (`opencode-base`) and 3 plugin-specific variant images that build on top of it.

## Variants

1. **superpowers** — [obra/superpowers](https://github.com/obra/superpowers)
2. **oh-my-opencode** — [code-yeongyu/oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)
3. **ralph** — [snarktank/ralph](https://github.com/snarktank/ralph)

## File Layout

```
opencode-container/
├── base/
│   ├── Dockerfile           # Base image
│   ├── entrypoint.sh        # Shared entrypoint
│   └── opencode.json        # Shared provider config (single source of truth)
├── superpowers/
│   └── Dockerfile           # FROM opencode-base, clones + symlinks obra/superpowers
├── oh-my-opencode/
│   ├── Dockerfile           # FROM opencode-base, npx oh-my-opencode install
│   └── oh-my-opencode.jsonc # Config copied to ~/.opencode/oh-my-opencode.jsonc
├── ralph/
│   └── Dockerfile           # FROM opencode-base, clones + symlinks snarktank/ralph
├── Makefile                 # Build orchestration
├── README.md
└── docs/plans/
```

The existing root `Dockerfile`, `opencode.json`, and `entrypoint.sh` are removed in favor of the subdirectory structure.

## Base Image (`opencode-base`)

Contains everything from the current Dockerfile except the superpowers plugin install:

- System packages + GitHub CLI
- Non-root `opencode` user (uid/gid 1000)
- NVM + Node.js LTS
- Playwright + Chromium
- SSH known_hosts for GitHub
- OpenCode CLI
- anthropics/skills (shared)
- spiermar/oh-no-claudecode (shared)
- vercel-labs/skills (shared)
- `opencode.json` provider config
- `entrypoint.sh` + ENV defaults + EXPOSE

## Variant Dockerfiles

### superpowers/Dockerfile

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

### oh-my-opencode/Dockerfile

```dockerfile
FROM opencode-base

USER opencode
COPY --chown=opencode:opencode oh-my-opencode.jsonc /home/opencode/.opencode/oh-my-opencode.jsonc
RUN . ~/.nvm/nvm.sh && npx oh-my-opencode install --no-tui --claude=no --gemini=no --copilot=no --openai=no
```

### ralph/Dockerfile

```dockerfile
FROM opencode-base

USER opencode
RUN git clone https://github.com/snarktank/ralph.git ~/.config/opencode/ralph \
    && mkdir -p ~/.config/opencode/skills \
    && ln -s ~/.config/opencode/ralph/skills \
             ~/.config/opencode/skills/ralph
```

## Makefile

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

## Image Names

- `opencode-base`
- `opencode-superpowers`
- `opencode-oh-my-opencode`
- `opencode-ralph`

## Key Decisions

- **Single `opencode.json`** in the base image, shared by all variants.
- **Shared skills** (anthropics, spiermar, vercel-labs) live in the base image.
- **oh-my-opencode** uses `npx` install with `--no-tui` for non-interactive setup; all subscription flags set to `no` since Parasail is the provider.
- **ralph** and **superpowers** use the standard git clone + symlink pattern.
