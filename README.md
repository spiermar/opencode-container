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
| `PORT` | No | `9898` | Server port (server mode only) |

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
  -e PORT=8080 \
  -p 8080:8080 \
  -v /path/to/workspace:/home/opencode/workspace \
  opencode
```
