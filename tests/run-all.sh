#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "========================================"
echo "Running all tests..."
echo "========================================"

FAILED=0

echo ""
echo "--- Linting Dockerfiles ---"
if ! ./tests/lint-dockerfiles.sh; then
    FAILED=1
fi

echo ""
echo "--- Linting Shell Scripts ---"
if ! ./tests/lint-scripts.sh; then
    FAILED=1
fi

echo ""
echo "--- Validating JSON Files ---"
if ! ./tests/validate-json.sh; then
    FAILED=1
fi

echo ""
echo "========================================"
if [ $FAILED -eq 1 ]; then
    echo "Some tests FAILED"
    exit 1
else
    echo "All tests PASSED"
    exit 0
fi