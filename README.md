# opencode-container

A Docker container for running [OpenCode](https://github.com/opencode-ai/opencode) with the [Superpowers](https://github.com/obra/superpowers) plugin.

## Building the Image

```bash
docker build -t opencode .
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PARASAIL_API_KEY` | Yes | - | API key for Parasail |
| `GITHUB_TOKEN` | Yes | - | GitHub token for `gh` CLI authentication |
| `CODENOMAD_SERVER_PASSWORD` | Server mode | - | Password for CodeNomad server access |
| `GIT_EMAIL` | No | `opencode@local` | Git commit email |
| `GIT_NAME` | No | `OpenCode` | Git commit author name |
| `MODE` | No | `server` | Run mode: `server` or `interactive` |
| `CLI_PORT` | No | `9898` | Server port (server mode only) |
| `CLI_HOST` | No | `127.0.0.1` | Interface to bind (server mode only) |

## Pre-installed Skills

The container comes with the following skill sets pre-installed:

### Superpowers (obra/superpowers)

Development workflow skills including brainstorming, TDD, debugging, code review, and more.

### Anthropic Agent Skills (anthropics/skills)

Official Anthropic skills for creative, technical, and enterprise tasks:

**Document Skills:**
- `xlsx` - Excel spreadsheet processing
- `docx` - Word document processing
- `pptx` - PowerPoint presentation processing
- `pdf` - PDF document processing

**Example Skills:**
- `algorithmic-art` - Generative art creation
- `brand-guidelines` - Brand consistency
- `canvas-design` - Visual design
- `doc-coauthoring` - Document collaboration
- `frontend-design` - UI/UX design
- `internal-comms` - Internal communications
- `mcp-builder` - MCP server development
- `skill-creator` - Custom skill creation
- `slack-gif-creator` - Slack GIF creation
- `theme-factory` - Theme styling
- `web-artifacts-builder` - Web artifact building
- `webapp-testing` - Web application testing

> **Note:** Some document skills (docx, pdf, pptx, xlsx) are source-available, not Apache 2.0.
> See [anthropics/skills](https://github.com/anthropics/skills) for licensing details.

## Running the Container

### Server Mode (Default)

Starts a CodeNomad server that exposes OpenCode over HTTP:

```bash
docker run -d \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e CODENOMAD_SERVER_PASSWORD="your-password" \
  -e CLI_HOST="0.0.0.0" \
  -p 9898:9898 \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode
```

### Interactive Mode

Starts a bash shell for direct interaction:

```bash
docker run -it \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e MODE=interactive \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode
```

Once inside the container, you can run `opencode` directly.

### Custom Port

```bash
docker run -d \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e CODENOMAD_SERVER_PASSWORD="your-password" \
  -e CLI_HOST="0.0.0.0" \
  -e CLI_PORT=8080 \
  -p 8080:8080 \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode
```
