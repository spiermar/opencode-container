# MCP Server Dynamic Enable/Disable Design

## Overview
Dynamically enable or disable Context7 and Tavily MCP servers in `opencode.json` based on provided API keys at container startup.

## Implementation

### Location
- `base/entrypoint.sh` - Add new step after environment validation

### Approach
Use `jq` to update the JSON file in place:
1. Check if `CONTEXT7_API_KEY` env var is set → set `mcp.context7.enabled` accordingly
2. Check if `TAVILY_API_KEY` env var is set → set `mcp.tavily.enabled` accordingly
3. Write updated JSON back to `/home/opencode/workspace/opencode.json`

### Code
```bash
# 2. Configure MCP servers based on available API keys
jq --argjson context7_enabled "$([ -n "$CONTEXT7_API_KEY" ] && echo "true" || echo "false")" \
   --argjson tavily_enabled "$([ -n "$TAVILY_API_KEY" ] && echo "true" || echo "false")" \
   '.mcp.context7.enabled = $context7_enabled | .mcp.tavily.enabled = $tavily_enabled' \
   /home/opencode/workspace/opencode.json > /tmp/opencode.json && \
mv /tmp/opencode.json /home/opencode/workspace/opencode.json
```

## Files Modified
- `base/entrypoint.sh` - Add MCP configuration step

## Testing
- Build image with both keys → both enabled
- Build with only CONTEXT7_API_KEY → only context7 enabled
- Build with no MCP keys → both disabled