#!/bin/bash
set -e

# Load nvm (required for npx in non-interactive shells)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

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
git config --global user.email "${GIT_EMAIL:-opencode@local}"
git config --global user.name "${GIT_NAME:-OpenCode}"

# 3. Switch based on MODE
case "${MODE:-server}" in
  server)
    if [ -z "$CODENOMAD_SERVER_PASSWORD" ]; then
      echo "Error: CODENOMAD_SERVER_PASSWORD is required in server mode"
      exit 1
    fi
    echo "Starting CodeNomad server on port ${CLI_PORT:-9898}..."
    exec npx @neuralnomads/codenomad --http-port "${CLI_PORT:-9898}"
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
