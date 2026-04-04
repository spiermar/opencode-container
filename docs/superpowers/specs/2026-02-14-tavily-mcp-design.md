# Tavily MCP Integration Design

## Overview

Add Tavily MCP server to the OpenCode Container, allowing users to provide their own API key at container startup for real-time web search capabilities.

## Requirements

- User can provide `TAVILY_API_KEY` when starting the container
- Tavily MCP is optional - container works without it
- Use remote MCP connection (`https://mcp.tavily.com/mcp`)
- Use Authorization header for authentication

## Changes

### opencode.json

Add `tavily` to the existing `mcp` section:

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
    },
    "tavily": {
      "type": "remote",
      "url": "https://mcp.tavily.com/mcp",
      "headers": {
        "Authorization": "Bearer {env:TAVILY_API_KEY}"
      },
      "enabled": true
    }
  }
}
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| TAVILY_API_KEY | No | API key from tavily.com |
| CONTEXT7_API_KEY | No | API key from context7.com |

## Usage

```bash
docker run -e TAVILY_API_KEY=your-key -e CONTEXT7_API_KEY=your-key ... opencode
```

## Testing

1. Build container without TAVILY_API_KEY - should start successfully
2. Build container with TAVILY_API_KEY - Tavily MCP should be available
3. Verify MCP tools are accessible via `opencode mcp list`