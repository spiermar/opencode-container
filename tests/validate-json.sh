#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "Validating JSON files..."

if ! command -v jq &> /dev/null; then
    echo "Error: jq not installed"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

JSON_FILES=$(find . -name "*.json" -type f | grep -v ".git" | grep -v ".codenomad")

FAILED=0

for json_file in $JSON_FILES; do
    echo "Validating: $json_file"
    if ! jq empty "$json_file" 2>/dev/null; then
        echo "FAILED: $json_file is not valid JSON"
        FAILED=1
    fi
done

JSONC_FILES=$(find . -name "*.jsonc" -type f | grep -v ".git")
for jsonc_file in $JSONC_FILES; do
    echo "Validating: $jsonc_file (stripping comments)"
    TEMP_FILE=$(mktemp)
    grep -v '^\s*//' "$jsonc_file" | grep -v '^\s*#' > "$TEMP_FILE"
    if ! jq empty "$TEMP_FILE" 2>/dev/null; then
        echo "FAILED: $jsonc_file is not valid JSON (after stripping comments)"
        FAILED=1
    fi
    rm -f "$TEMP_FILE"
done

if [ $FAILED -eq 1 ]; then
    echo "One or more JSON files failed validation"
    exit 1
fi

echo "All JSON files passed validation"
exit 0