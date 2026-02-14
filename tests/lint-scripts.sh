#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Linting shell scripts..."

if ! command -v shellcheck &> /dev/null; then
    echo "Error: shellcheck not installed"
    echo "Install with: brew install shellcheck (macOS) or apt-get install shellcheck (Linux)"
    exit 1
fi

SCRIPTS=$(find . -name "*.sh" -type f | grep -v ".git" | grep -v "^./tests/")

FAILED=0

for script in $SCRIPTS; do
    echo "Linting: $script"
    if ! shellcheck -s bash -e SC1090,SC1091,SC2086 "$script"; then
        echo "FAILED: $script"
        FAILED=1
    fi
done

if [ $FAILED -eq 1 ]; then
    echo "One or more scripts failed linting"
    exit 1
fi

echo "All shell scripts passed linting"
exit 0