# Optional PARASAIL_API_KEY Design

## Overview

Make `PARASAIL_API_KEY` optional at container startup. When the variable is not set, the entrypoint should print a warning and continue normal startup instead of exiting.

## Goals

- Remove the hard startup dependency on `PARASAIL_API_KEY`
- Preserve current behavior when `PARASAIL_API_KEY` is set
- Keep `GITHUB_TOKEN` as a required variable
- Limit the change to the smallest safe surface area

## Non-Goals

- Disabling or rewriting the Parasail provider configuration in `base/opencode.json`
- Changing provider selection behavior inside OpenCode
- Adding a new automated shell test harness

## Affected Files

- `base/entrypoint.sh`

## Design

### Startup Validation

Replace the current `PARASAIL_API_KEY` required check in `base/entrypoint.sh` with a warning path:

- If `PARASAIL_API_KEY` is set, continue exactly as today
- If `PARASAIL_API_KEY` is unset, print a warning to stderr and continue startup
- If `GITHUB_TOKEN` is unset, still exit with an error

The warning text should clearly state that Parasail-backed requests may fail until the key is provided.

### Scope Control

Leave `base/opencode.json` unchanged. The config should continue to reference `{env:PARASAIL_API_KEY}`. This keeps the change aligned with the requested behavior: continue startup normally and only warn when the variable is absent.

## Error Handling

- Missing `PARASAIL_API_KEY`: warning only, no exit
- Missing `GITHUB_TOKEN`: existing hard failure remains
- Unknown `MODE`: existing hard failure remains

## Testing

Use manual smoke verification consistent with the repository's current testing style:

1. Build the image
2. Run the container without `PARASAIL_API_KEY` and with `GITHUB_TOKEN` set
3. Confirm startup continues instead of exiting immediately
4. Confirm the warning is printed
5. Run the container without `GITHUB_TOKEN` and confirm it still fails fast

## Expected Outcome

Users can start the container for non-Parasail workflows without setting `PARASAIL_API_KEY`, while still getting a clear warning that Parasail requests may not work until the key is configured.
