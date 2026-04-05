#!/bin/bash
set -e

# Load nvm (required for npx in non-interactive shells)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# 1. Validate required environment variables
if [ -z "$PARASAIL_API_KEY" ]; then
  echo "Warning: PARASAIL_API_KEY is not set; Parasail-backed requests may fail until it is provided." >&2
fi

if [ -z "$OPENAI_API_KEY" ]; then
  echo "Warning: OPENAI_API_KEY is not set; OpenAI-backed requests may fail until it is provided." >&2
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is required"
  exit 1
fi

# 2. Configure MCP servers based on available API keys
jq --argjson context7_enabled "$([ -n "$CONTEXT7_API_KEY" ] && echo "true" || echo "false")" \
   --argjson tavily_enabled "$([ -n "$TAVILY_API_KEY" ] && echo "true" || echo "false")" \
   '.mcp.context7.enabled = $context7_enabled | .mcp.tavily.enabled = $tavily_enabled' \
   /home/opencode/.config/opencode/opencode.json > /tmp/opencode.json && \
mv /tmp/opencode.json /home/opencode/.config/opencode/opencode.json

# 3. Configure GitHub authentication
gh auth setup-git
git config --global user.email "${GIT_EMAIL:-opencode@local}"
git config --global user.name "${GIT_NAME:-OpenCode}"

# 3. Switch based on MODE
case "${MODE:-server}" in
  server)
    echo "Starting opencode server..."
    SERVER_ARGS=()

    PORT="${CLI_PORT:-9898}"
    SERVER_ARGS+=(--port "$PORT")

    HOSTNAME="${CLI_HOST:-127.0.0.1}"
    SERVER_ARGS+=(--hostname "$HOSTNAME")

    if [ -n "$CORS" ]; then
      SERVER_ARGS+=(--cors "$CORS")
    fi

    exec opencode serve "${SERVER_ARGS[@]}"
    ;;
  codenomad)
    if [ -z "$CODENOMAD_SERVER_PASSWORD" ]; then
      echo "Error: CODENOMAD_SERVER_PASSWORD is required in codenomad mode"
      exit 1
    fi
    echo "Starting CodeNomad server on port ${CLI_PORT:-9898}..."
    exec npx @neuralnomads/codenomad --https true --http false --https-port "${CLI_PORT:-9898}"
    ;;
  interactive)
    echo "Starting interactive shell..."
    exec /bin/bash
    ;;
  *)
    echo "Unknown MODE: $MODE (use 'server', 'codenomad', or 'interactive')"
    exit 1
    ;;
esac
