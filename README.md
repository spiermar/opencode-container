# opencode-container

Docker containers for running [OpenCode](https://github.com/opencode-ai/opencode) with different plugin and agent configurations.

The project uses a **base + variant** architecture: a shared base image (`opencode-base`) provides all common dependencies and skills, and each variant adds its own specific plugins, skills, or agent frameworks on top.

## Image Variants

| Image | Description | Added On Top of Base |
|-------|-------------|----------------------|
| `opencode-superpowers` | [Superpowers](https://github.com/obra/superpowers) plugin & skills | Development workflow skills (brainstorming, TDD, debugging, code review) |
| `opencode-ralph` | [Ralph](https://github.com/snarktank/ralph) skills | Ralph-specific skills |
| `opencode-oh-my-opencode` | [Oh-My-OpenCode](https://github.com/code-yeongyu/oh-my-opencode) agent framework | Specialized sub-agents (sisyphus, prometheus, oracle, librarian, and more) |
| `opencode-get-shit-done` | [Get-Shit-Done](https://github.com/gsd-build/get-shit-done) (GSD) | Meta-prompting, context engineering, and spec-driven development |

## Building the Images

A `Makefile` is provided to build the base and variant images.

```bash
# Build all variants (automatically builds base first)
make all

# Build a specific variant
make superpowers
make ralph
make oh-my-opencode
make get-shit-done

# Build only the base image
make base
```

The build dependency chain is:

```
opencode-base
  ├── opencode-superpowers
  ├── opencode-ralph
  ├── opencode-oh-my-opencode
  └── opencode-get-shit-done
```

## Using Published Images

Images are published to the GitHub Container Registry. You can pull and use them directly without building:

```bash
# Pull the base image
docker pull ghcr.io/spiermar/opencode-container-base:latest

# Pull a specific variant
docker pull ghcr.io/spiermar/opencode-container-superpowers:latest
docker pull ghcr.io/spiermar/opencode-container-ralph:latest
docker pull ghcr.io/spiermar/opencode-container-oh-my-opencode:latest
docker pull ghcr.io/spiermar/opencode-container-get-shit-done:latest
```

Run using the ghcr.io image name:

```bash
docker run -d \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e CLI_HOST="0.0.0.0" \
  -p 9898:9898 \
  -v /path/to/workspace:/home/opencode/workspace \
  ghcr.io/spiermar/opencode-container-superpowers:latest
```

> **Note:** Replace `opencode-superpowers` with your chosen variant as needed.

## Base Image

All variants share the `opencode-base` image, which includes:

- **OS:** Ubuntu (latest)
- **Tools:** git, curl, jq, make, vim, ripgrep, wget, zip, openssh-client, postgresql-client, GitHub CLI
- **Runtime:** Node.js LTS (via nvm), Playwright Chromium
- **OpenCode CLI:** `opencode-ai@latest`
- **Provider:** Parasail (pre-configured), Context7, or Tavily (via `opencode.json`)

### Pre-installed Skills (all variants)

The base image comes with the following skill sets:

**[Anthropic Skills](https://github.com/anthropics/skills)** - Document processing and creative/technical skills:
- `xlsx` - Excel spreadsheet processing
- `docx` - Word document processing
- `pptx` - PowerPoint presentation processing
- `pdf` - PDF document processing
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

**[Spiermar Skills & Agents](https://github.com/spiermar/oh-no-claudecode)** - Custom skills and agents.

**[Vercel Labs Skills](https://github.com/vercel-labs/skills)** - Utility skills.

## Variant Details

### Superpowers

Adds the [Superpowers](https://github.com/obra/superpowers) plugin and skills. Includes development workflow skills such as brainstorming, TDD, debugging, code review, and more.

### Ralph

Adds [Ralph](https://github.com/snarktank/ralph) skills for specialized workflows.

### Oh-My-OpenCode

Adds the [Oh-My-OpenCode](https://github.com/code-yeongyu/oh-my-opencode) agent framework with specialized sub-agents, each mapped to a Parasail model:

| Agent | Model | Role |
|-------|-------|------|
| sisyphus | GLM-5 | Plans, delegates, and executes complex tasks with parallel execution |
| prometheus | GLM-5 | Strategic planner with interview mode |
| metis | GLM-5 | Pre-planning analysis and ambiguity detection |
| momus | GLM-5 | Plan validation and review |
| oracle | GLM-5 | Architecture decisions, code review, debugging |
| librarian | GLM-4.7 | Multi-repo analysis and documentation lookup |
| explore | GLM-4.6V | Fast codebase exploration |
| multimodal-looker | GLM-4.6V | Visual content analysis (PDFs, images, diagrams) |

### Get-Shit-Done (GSD)

Adds [Get-Shit-Done](https://github.com/gsd-build/get-shit-done) (GSD) - a meta-prompting, context engineering, and spec-driven development system for OpenCode. Includes commands like:

- `/gsd:new-project` - Initialize a new project with questions, research, requirements, and roadmap
- `/gsd:discuss-phase [N]` - Capture implementation decisions before planning
- `/gsd:plan-phase [N]` - Research and plan a phase
- `/gsd:execute-phase [N]` - Execute all plans in a phase
- `/gsd:verify-work [N]` - Manual user acceptance testing
- `/gsd:quick` - Execute ad-hoc tasks with GSD guarantees
- `/gsd:progress` - Show current progress and next steps

GSD solves context rot by keeping your session fast and responsive through multi-agent orchestration and fresh context windows per task.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PARASAIL_API_KEY` | If using Parasail | - | API key for Parasail provider |
| `OPENAI_API_KEY` | If using OpenAI | - | API key for OpenAI provider |
| `CONTEXT7_API_KEY` | If using Context7 | - | API key for Context7 provider |
| `TAVILY_API_KEY` | If using Tavily | - | API key for Tavily provider |
| `GITHUB_TOKEN` | Yes | - | GitHub token for `gh` CLI authentication |
| `CODENOMAD_SERVER_PASSWORD` | CodeNomad mode | - | Password for CodeNomad server access |
| `GIT_EMAIL` | No | `opencode@local` | Git commit email |
| `GIT_NAME` | No | `OpenCode` | Git commit author name |
| `MODE` | No | `server` | Run mode: `server`, `codenomad`, or `interactive` |
| `CLI_PORT` | No | `9898` | Server port (server/codenomad mode) |
| `CLI_HOST` | No | `127.0.0.1` | Interface to bind (server/codenomad mode) |
| `CORS` | No | - | CORS origin for server mode |

## Provider Configuration

The container comes pre-configured with Parasail as the default provider. You can switch to Context7 or Tavily by creating an `opencode.json` file in your workspace:

### Context7

```json
{
  "schema": "https://opencode.ai/schemas/opencode.json",
  "model": "claude-sonnet-4-20250514",
  "provider": "context7"
}
```

Then run with:
```bash
docker run -d \
  -e CONTEXT7_API_KEY="your-context7-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode-superpowers
```

### Tavily

```json
{
  "schema": "https://opencode.ai/schemas/opencode.json",
  "model": "claude-sonnet-4-20250514",
  "provider": "tavily"
}
```

Then run with:
```bash
docker run -d \
  -e TAVILY_API_KEY="your-tavily-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode-superpowers
```

## Running the Container

Replace `opencode-superpowers` below with your chosen variant (`opencode-ralph`, `opencode-oh-my-opencode`).

### Server Mode (Default)

Starts an OpenCode server:

```bash
docker run -d \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e CLI_HOST="0.0.0.0" \
  -p 9898:9898 \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode-superpowers
```

Optionally set CORS origin:
```bash
docker run -d \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e CLI_HOST="0.0.0.0" \
  -e CORS="https://your-domain.com" \
  -p 9898:9898 \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode-superpowers
```

### CodeNomad Mode

Starts a CodeNomad server that exposes OpenCode over HTTPS:

```bash
docker run -d \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e CODENOMAD_SERVER_PASSWORD="your-password" \
  -e CLI_HOST="0.0.0.0" \
  -p 9898:9898 \
  -v /path/to/workspace:/home/opencode/workspace \
  -e MODE=codenomad \
  opencode-superpowers
```

### Interactive Mode

Starts a bash shell for direct interaction:

```bash
docker run -it \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e MODE=interactive \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode-superpowers
```

Once inside the container, you can run `opencode` directly.

### Custom Port

```bash
docker run -d \
  -e PARASAIL_API_KEY="your-api-key" \
  -e GITHUB_TOKEN="your-github-token" \
  -e CLI_HOST="0.0.0.0" \
  -e CLI_PORT=8080 \
  -p 8080:8080 \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode-superpowers
```
