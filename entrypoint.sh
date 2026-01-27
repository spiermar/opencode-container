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
