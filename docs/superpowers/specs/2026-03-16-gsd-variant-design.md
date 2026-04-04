# GSD Variant Design

## Overview

Add get-shit-done (GSD) as a new container variant following the existing multi-variant pattern.

## Integration

Use `npx get-shit-done-cc@latest --opencode --global` with `CLAUDE_CONFIG_DIR` set for proper container path resolution.

## File Layout

```
get-shit-done/
└── Dockerfile           # FROM opencode-base, npx install GSD
```

## Dockerfile

```dockerfile
FROM opencode-base

USER opencode
RUN CLAUDE_CONFIG_DIR=/home/opencode/.config/opencode npx get-shit-done-cc@latest --opencode --global
```

## Makefile

Add to the existing Makefile:

```makefile
get-shit-done: base
	docker build -t opencode-get-shit-done get-shit-done/
```

Add `get-shit-done` to the `all` target.

## Image Name

- `opencode-get-shit-done`