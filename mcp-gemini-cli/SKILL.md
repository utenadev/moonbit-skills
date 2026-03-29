# mcp-gemini-cli Skills

## Overview
mcp-gemini-cli is a Model Context Protocol (MCP) server that provides access to Google Gemini AI.

## Installation
```bash
# Install via npm
npm install -g @google/gemini-cli

# Or use MCP server configuration
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "@google/gemini-cli"]
    }
  }
}
```

## Authentication
```bash
# Login with Google account
gemini login

# Or set API key
export GEMINI_API_KEY="your-api-key"
export GOOGLE_API_KEY="your-api-key"
```

## Available Tools

### 1. google-search
Search Google and get structured results.

**Usage**:
```moonbit
// Via MCP
mcp.call("gemini", "google-search", {
  "query": "MoonBit YAML parser",
  "limit": 5
})
```

**Parameters**:
- `query: String` - Search query
- `limit: Int` - Maximum results (default: 10)

**Returns**:
```json
{
  "results": [
    {
      "title": "Page title",
      "url": "https://example.com",
      "snippet": "Search result snippet"
    }
  ]
}
```

### 2. chat
Chat with Gemini AI.

**Usage**:
```moonbit
mcp.call("gemini", "chat", {
  "prompt": "Explain MoonBit for Go programmers",
  "model": "gemini-2.5-pro"
})
```

**Parameters**:
- `prompt: String` - User prompt
- `model: String` - Model name (default: gemini-2.5-pro)
- `yolo: Bool` - Auto-accept actions (optional)
- `sandbox: Bool` - Run in sandbox mode (optional)

**Returns**:
```json
{
  "response": "AI response text",
  "sources": ["source URLs if any"]
}
```

### 3. analyzeFile
Analyze files using Gemini AI.

**Usage**:
```moonbit
mcp.call("gemini", "analyzeFile", {
  "filePath": "/path/to/file.mbt",
  "prompt": "Explain this code"
})
```

**Parameters**:
- `filePath: String` - Absolute path to file
- `prompt: String` - Analysis prompt
- `model: String` - Model name (optional)

**Returns**:
```json
{
  "analysis": "File analysis result"
}
```

## Models

Available Gemini models:
- `gemini-2.5-pro` - Default, balanced
- `gemini-2.5-flash` - Fast, cheaper
- `gemini-2.5-flash-lite` - Fastest, cheapest

## Rate Limits (2026/03)

**Free Tier**:
- Gemini 2.5 Pro: 5 RPM, 250,000 TPM, 100 RPD
- Gemini 2.5 Flash: 10 RPM, 250,000 TPM, 250 RPD
- Gemini 2.5 Flash-Lite: 15 RPM, 250,000 TPM, 1,000 RPD

**Note**: As of March 2026, Google reduced free tier quotas by 50-80%.
429 errors (RESOURCE_EXHAUSTED) are common.

## Error Handling

### 429 Rate Limit
```moonbit
match mcp.call("gemini", "chat", {...}) {
  Ok(response) => println(response)
  Err(e) => {
    if e.contains("429") {
      println("Rate limited. Wait and retry.")
      // Implement exponential backoff
    }
  }
}
```

### MODEL_CAPACITY_EXHAUSTED
```moonbit
// Switch to different model
let model = if e.contains("pro") {
  "flash-lite"
} else {
  "pro"
}
```

## Best Practices

1. **Use appropriate model**
   - Complex tasks: `gemini-2.5-pro`
   - Simple queries: `gemini-2.5-flash`
   - High volume: `gemini-2.5-flash-lite`

2. **Implement retry logic**
   ```moonbit
   fn call_with_retry(tool: String, params: Map[String, Any]) -> Result[String, String] {
     let mut attempts = 0
     while attempts < 5 {
       match mcp.call("gemini", tool, params) {
         Ok(result) => return Ok(result)
         Err(e) if e.contains("429") => {
           attempts = attempts + 1
           sleep(pow(2, attempts) * 1000)  // Exponential backoff
         }
         Err(e) => return Err(e)
       }
     }
     Err("Max retries exceeded")
   }
   ```

3. **Cache responses**
   - Cache identical queries
   - Use file-based or in-memory cache

4. **Monitor usage**
   - Track API calls per day
   - Stay within rate limits

## Integration Example

```moonbit
// beads_mbt integration
import mcp

fn search_gemini(query: String) -> Result[String, String] {
  let result = mcp.call("gemini", "google-search", {
    "query": query,
    "limit": 5
  })
  
  match result {
    Ok(response) => {
      let results = response["results"]
      let summary = List::map(results, fn(r) {
        r["title"] + ": " + r["url"]
      })
      Ok(String::join(summary, "\n"))
    }
    Err(e) => Err("Search failed: " + e)
  }
}
```

## Troubleshooting

### 429 Errors
- Wait 5-10 minutes
- Switch to flash-lite model
- Use API key instead of OAuth

### Slow Response (30+ seconds)
- Server capacity issue
- Try different model
- Check network connection

### Authentication Errors
```bash
# Re-authenticate
gemini logout
gemini login

# Or use API key
export GEMINI_API_KEY="your-key"
```

## References
- [Gemini CLI GitHub](https://github.com/google-gemini/gemini-cli)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Gemini API Pricing 2026](https://aicostcheck.com/blog/google-gemini-pricing-guide-2026)
