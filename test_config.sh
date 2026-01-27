#!/bin/bash
# Test script for opencode.json configuration
# This script validates the configuration file and ensures the default model is correctly set

set -e

CONFIG_FILE="opencode.json"
EXPECTED_MODEL="parasail/parasail-glm47"
TESTS_PASSED=0
TESTS_FAILED=0

echo "============================================"
echo "  OpenCode Configuration Test Suite"
echo "============================================"
echo ""

# Test 1: Check if config file exists
echo "Test 1: Checking if $CONFIG_FILE exists..."
if [ -f "$CONFIG_FILE" ]; then
    echo "  ✅ PASS: $CONFIG_FILE exists"
    ((TESTS_PASSED++))
else
    echo "  ❌ FAIL: $CONFIG_FILE not found"
    ((TESTS_FAILED++))
    exit 1
fi

# Test 2: Validate JSON syntax
echo ""
echo "Test 2: Validating JSON syntax..."
if cat "$CONFIG_FILE" | python3 -m json.tool > /dev/null 2>&1; then
    echo "  ✅ PASS: JSON syntax is valid"
    ((TESTS_PASSED++))
else
    echo "  ❌ FAIL: JSON syntax is invalid"
    ((TESTS_FAILED++))
fi

# Test 3: Check default model value
echo ""
echo "Test 3: Checking default model configuration..."
ACTUAL_MODEL=$(jq -r '.model' "$CONFIG_FILE")
if [ "$ACTUAL_MODEL" == "$EXPECTED_MODEL" ]; then
    echo "  ✅ PASS: Default model is correctly set to '$EXPECTED_MODEL'"
    ((TESTS_PASSED++))
else
    echo "  ❌ FAIL: Default model is '$ACTUAL_MODEL', expected '$EXPECTED_MODEL'"
    ((TESTS_FAILED++))
fi

# Test 4: Verify model exists in provider configuration
echo ""
echo "Test 4: Verifying model exists in provider configuration..."
MODEL_NAME=$(echo "$EXPECTED_MODEL" | cut -d'/' -f2)
MODEL_EXISTS=$(jq -r ".provider.parasail.models[\"$MODEL_NAME\"] // empty" "$CONFIG_FILE")
if [ -n "$MODEL_EXISTS" ]; then
    MODEL_LABEL=$(jq -r ".provider.parasail.models[\"$MODEL_NAME\"].name" "$CONFIG_FILE")
    echo "  ✅ PASS: Model '$MODEL_NAME' exists with label '$MODEL_LABEL'"
    ((TESTS_PASSED++))
else
    echo "  ❌ FAIL: Model '$MODEL_NAME' not found in provider.parasail.models"
    ((TESTS_FAILED++))
fi

# Test 5: Verify model has required properties
echo ""
echo "Test 5: Verifying model has required properties..."
HAS_CONTEXT=$(jq -r ".provider.parasail.models[\"$MODEL_NAME\"].contextLength // empty" "$CONFIG_FILE")
HAS_OUTPUT=$(jq -r ".provider.parasail.models[\"$MODEL_NAME\"].maxOutput // empty" "$CONFIG_FILE")
if [ -n "$HAS_CONTEXT" ] && [ -n "$HAS_OUTPUT" ]; then
    echo "  ✅ PASS: Model has contextLength ($HAS_CONTEXT) and maxOutput ($HAS_OUTPUT)"
    ((TESTS_PASSED++))
else
    echo "  ❌ FAIL: Model missing required properties"
    ((TESTS_FAILED++))
fi

# Test 6: Verify provider configuration
echo ""
echo "Test 6: Verifying provider configuration..."
PROVIDER_NAME=$(jq -r '.provider.parasail.name // empty' "$CONFIG_FILE")
BASE_URL=$(jq -r '.provider.parasail.options.baseURL // empty' "$CONFIG_FILE")
if [ -n "$PROVIDER_NAME" ] && [ -n "$BASE_URL" ]; then
    echo "  ✅ PASS: Provider '$PROVIDER_NAME' configured with baseURL"
    ((TESTS_PASSED++))
else
    echo "  ❌ FAIL: Provider configuration incomplete"
    ((TESTS_FAILED++))
fi

# Summary
echo ""
echo "============================================"
echo "  Test Summary"
echo "============================================"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "============================================"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed!"
    exit 0
else
    echo ""
    echo "💥 Some tests failed!"
    exit 1
fi
