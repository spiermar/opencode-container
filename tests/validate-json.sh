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
    # Use node to strip JSONC comments if available, otherwise use sed
    if command -v node &> /dev/null; then
        node -e "
const fs = require('fs');
let content = fs.readFileSync('$jsonc_file', 'utf8');
// Remove multi-line comments first (/* ... */)
content = content.replace(/\/\*[\s\S]*?\*\//g, '');
// Remove single-line comments (// ...) but NOT when preceded by : (for URLs)
content = content.replace(/(?<!:)\/\/.*$/gm, '');
// Remove empty lines and trim whitespace
content = content.split('\n').map(line => line.trim()).filter(line => line !== '').join('\n');
console.log(content);
" > "$TEMP_FILE"
    else
        # Fallback: use sed to handle basic comments
        # Remove // comments but not :// URLs
        sed -e 's/\/\/.*$//' -e 's/\/\*.*\*\///g' -e '/^\s*\/\//d' -e '/^\s*$/d' "$jsonc_file" > "$TEMP_FILE"
    fi
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