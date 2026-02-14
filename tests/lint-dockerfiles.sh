#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Linting Dockerfiles..."

if ! command -v hadolint &> /dev/null; then
    echo "Error: hadolint not installed"
    echo "Install with: brew install hadolint (macOS) or apt-get install hadolint (Linux)"
    exit 1
fi

DOCKERFILES=$(find . -name "Dockerfile" -type f | grep -v ".codenomad")

FAILED=0

for df in $DOCKERFILES; do
    echo "Linting: $df"
    if ! hadolint "$df"; then
        echo "FAILED: $df"
        FAILED=1
    fi
done

if [ $FAILED -eq 1 ]; then
    echo "One or more Dockerfiles failed linting"
    exit 1
fi

echo "All Dockerfiles passed linting"
exit 0