# Context7 MCP Integration Design

## Overview

Add Context7 MCP server to the OpenCode Container, allowing users to provide their own API key at container startup for up-to-date code documentation retrieval.

## Requirements

- User can provide `CONTEXT7_API_KEY` when starting the container
- Context7 MCP is optional - container works without it
- Use remote MCP connection (`https://mcp.context7.com/mcp`)

## Changes

### 1. opencode.json

Add `mcp` section with Context7 remote configuration:

```json
{
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"
      },
      "enabled": true
    }
  }
}
```

The `{env:CONTEXT7_API_KEY}` placeholder allows OpenCode to read the API key from environment variable at runtime.

### 2. entrypoint.sh

No changes needed - OpenCode handles env var interpolation natively.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| CONTEXT7_API_KEY | No | - | API key from context7.com for higher rate limits |

## Testing

1. Build container without CONTEXT7_API_KEY - should start successfully
2. Build container with CONTEXT7_API_KEY - Context7 MCP should be available
3. Verify MCP tools are accessible via `opencode mcp list`

## Risks

- OpenCode env var interpolation may not work as expected - test fallback to jq injection
- API key in env var may be logged - verify OpenCode handles this securely