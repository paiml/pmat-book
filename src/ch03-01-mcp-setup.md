# MCP Server Setup

**Chapter Status**: ✅ 100% Working

*Last updated: 2025-10-19*
*PMAT version: pmat 2.213.1*

## Overview

This chapter covers setting up and configuring the PMAT MCP server for AI-assisted development workflows. The MCP server provides 19 tools accessible via standardized JSON-RPC protocol.

## Quick Start

### Start the Server

```bash
# Start with default configuration (localhost:3000)
pmat mcp-server

# Start with custom bind address
pmat mcp-server --bind 127.0.0.1:8080

# Enable verbose logging
RUST_LOG=debug pmat mcp-server
```

### Verify Server is Running

```bash
# Check server health
curl http://localhost:3000/health

# List available tools
curl -X POST http://localhost:3000 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "tools/list"
  }'
```

## Server Configuration

### Default Configuration

The server uses the following defaults (from `server/src/mcp_integration/server.rs:31`):

```rust
ServerConfig {
    name: "PMAT MCP Server",
    version: env!("CARGO_PKG_VERSION"),
    bind_address: "127.0.0.1:3000",
    unix_socket: None,
    max_connections: 100,
    request_timeout: Duration::from_secs(30),
    enable_logging: true,

    // Semantic search (local embeddings - no API key required)
    semantic_enabled: false,
    semantic_db_path: Some("~/.pmat/embeddings.db"),
    semantic_workspace: Some(cwd),
}
```

### Environment Variables

```bash
# Enable semantic search tools
export PMAT_SEMANTIC_ENABLED=true
export PMAT_VECTOR_DB_PATH="~/.pmat/embeddings.db"
export PMAT_WORKSPACE="/path/to/workspace"

# Logging configuration
export RUST_LOG=info  # Options: error, warn, info, debug, trace
```

### Custom Configuration

```bash
# Custom bind address
pmat mcp-server --bind 0.0.0.0:8080

# Unix socket (for local IPC)
pmat mcp-server --unix-socket /tmp/pmat.sock

# Enable verbose logging
RUST_LOG=debug pmat mcp-server
```

## Connection Examples

### TypeScript/JavaScript Client

```typescript
import { McpClient } from '@modelcontextprotocol/sdk';

async function connectToPMAT() {
  const client = new McpClient({
    endpoint: 'http://localhost:3000',
    protocolVersion: '2024-11-05',
    timeout: 30000 // 30 seconds
  });

  try {
    await client.connect();

    // Initialize the connection
    const initResponse = await client.initialize({
      clientInfo: {
        name: "my-ai-agent",
        version: "1.0.0"
      }
    });

    console.log('Connected to PMAT MCP Server:', initResponse.serverInfo);

    return client;
  } catch (error) {
    console.error('Connection failed:', error);
    throw error;
  }
}
```

### Python Client

```python
from mcp import Client

async def connect_to_pmat():
    client = Client(
        endpoint="http://localhost:3000",
        protocol_version="2024-11-05",
        timeout=30.0
    )

    await client.connect()

    # Initialize
    init_response = await client.initialize({
        "clientInfo": {
            "name": "my-ai-agent",
            "version": "1.0.0"
        }
    })

    print(f"Connected to: {init_response['serverInfo']['name']}")

    return client
```

## Authentication

**Current Status**: No authentication required for local connections.

**Future Considerations** (when deploying to production):
- API key authentication
- OAuth 2.0
- mTLS for service-to-service

## Troubleshooting

### Server Won't Start

```bash
# Check if port is already in use
lsof -i :3000

# Check logs
RUST_LOG=debug pmat mcp-server

# Check firewall
sudo ufw status
```

### Connection Timeouts

```javascript
// Increase timeout for slow operations
const client = new McpClient({
  endpoint: 'http://localhost:3000',
  timeout: 120000 // 2 minutes for large projects
});
```

### Semantic Search Not Available

```bash
# Enable semantic search in config
pmat config --set semantic.enabled=true

# Or via environment variable
export PMAT_SEMANTIC_ENABLED=true

# Check server logs for semantic tool registration
RUST_LOG=info pmat mcp-server | grep semantic
```

**Note**: Semantic search uses local TF-IDF embeddings via the aprender library. No API keys required.

## Best Practices

### 1. Connection Management

```javascript
// Use connection pooling for multiple requests
class PMATClient {
  constructor(endpoint) {
    this.endpoint = endpoint;
    this.client = null;
  }

  async connect() {
    if (!this.client) {
      this.client = new McpClient({ endpoint: this.endpoint });
      await this.client.connect();
      await this.client.initialize({
        clientInfo: { name: "pmat-client", version: "1.0.0" }
      });
    }
    return this.client;
  }

  async disconnect() {
    if (this.client) {
      await this.client.disconnect();
      this.client = null;
    }
  }
}
```

### 2. Health Checks

```javascript
async function checkServerHealth(client) {
  try {
    // List tools as a health check
    const tools = await client.listTools();
    return {
      healthy: true,
      toolCount: tools.tools.length,
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    return {
      healthy: false,
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}
```

### 3. Logging and Monitoring

```javascript
// Wrap client calls with logging
async function loggedToolCall(client, toolName, params) {
  const startTime = Date.now();

  try {
    console.log(`[MCP] Calling ${toolName}...`);
    const result = await client.callTool(toolName, params);
    const duration = Date.now() - startTime;
    console.log(`[MCP] ${toolName} completed in ${duration}ms`);
    return result;
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`[MCP] ${toolName} failed after ${duration}ms:`, error.message);
    throw error;
  }
}
```

## Production Deployment Considerations

**Note**: The current MCP server is designed for local development. For production deployment, consider:

1. **Security**: Add authentication and authorization
2. **Scalability**: Use load balancing and horizontal scaling
3. **Monitoring**: Implement comprehensive logging and metrics
4. **Resource Limits**: Configure request timeouts and rate limiting
5. **High Availability**: Deploy redundant instances with health checks

## Next Steps

- [**Available Tools**](ch03-02-mcp-tools.md) - Explore the 19 MCP tools
- [**Claude Integration**](ch03-03-claude-integration.md) - Connect with Claude Desktop
- [**Chapter 15: Complete Reference**](ch15-00-mcp-tools.md) - Advanced workflows and patterns
