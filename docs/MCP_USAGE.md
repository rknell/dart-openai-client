# 🚀 MCP (Model Context Protocol) Integration Guide

## 🎯 Overview

The MCP integration allows you to use external tools and services through the Model Context Protocol. This enables your AI agents to interact with web browsers, file systems, databases, and other external systems.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Agent      │    │  MCP Client     │    │  MCP Server     │
│                 │◄──►│                 │◄──►│                 │
│ • Tool Registry │    │ • Process Mgmt  │    │ • Tool Discovery│
│ • Conversation  │    │ • JSON-RPC      │    │ • Tool Execution│
│ • API Client    │    │ • Tool Discovery│    │ • Results       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Configuration

### MCP Servers Configuration File

Create `config/mcp_servers.json` with your MCP server configurations:

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "puppeteer-mcp-server"],
      "env": {},
      "description": "Puppeteer MCP server for web automation and scraping"
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"],
      "env": {},
      "description": "Filesystem MCP server for file operations"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your-github-token-here"
      },
      "description": "GitHub MCP server for repository operations"
    }
  }
}
```

### Configuration Options

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `command` | string | ✅ | Command to execute (e.g., "npx", "node", "python") |
| `args` | array | ✅ | Command line arguments |
| `env` | object | ❌ | Environment variables for the process |
| `workingDirectory` | string | ❌ | Working directory for the process |
| `description` | string | ❌ | Human-readable description of the server |

## 🚀 Usage

### 1. Basic MCP Integration

```dart
import 'package:dart_openai_client/dart_openai_client.dart';

// Load MCP configuration
final configFile = File('config/mcp_servers.json');
final configData = jsonDecode(await configFile.readAsString());
final mcpServers = configData['mcpServers'] as Map<String, dynamic>;

// Initialize tool registry
final toolRegistry = ToolExecutorRegistry();

// Initialize MCP servers
for (final entry in mcpServers.entries) {
  final serverName = entry.key;
  final serverConfig = entry.value as Map<String, dynamic>;
  
  final config = McpServerConfig.fromJson(serverConfig);
  final mcpClient = McpClient(config);
  await mcpClient.initialize();
  
  // Register tools from MCP server
  for (final tool in mcpClient.tools) {
    final executor = McpToolExecutor(mcpClient, tool);
    toolRegistry.registerExecutor(executor);
  }
}

// Create agent with MCP tools
final agent = Agent(
  apiClient: apiClient,
  toolRegistry: toolRegistry,
  messages: [],
  systemPrompt: 'You have access to MCP tools for various tasks.',
);
```

### 2. Tool Discovery

```dart
// Get all available tools
final allTools = toolRegistry.getAllTools();
print('Available tools: ${allTools.length}');

for (final tool in allTools) {
  print('• ${tool.function.name}: ${tool.function.description}');
}
```

### 3. Tool Execution

```dart
// Send message to agent (tools are called automatically)
final response = await agent.sendMessage(
  "Can you scrape the todos from https://jsonplaceholder.typicode.com/todos?"
);

print('Response: ${response.content}');
```

## 🛠️ Available MCP Servers

### Puppeteer MCP Server
- **Purpose**: Web automation and scraping
- **Installation**: `npm install -g puppeteer-mcp-server`
- **Tools**: Page navigation, content scraping, screenshot capture
- **Use Case**: Extract data from websites, automate web interactions

### Filesystem MCP Server
- **Purpose**: File and directory operations
- **Installation**: `npm install -g @modelcontextprotocol/server-filesystem`
- **Tools**: File listing, reading, writing, directory operations
- **Use Case**: File management, data processing, log analysis

### GitHub MCP Server
- **Purpose**: GitHub repository operations
- **Installation**: `npm install -g @modelcontextprotocol/server-github`
- **Tools**: Repository info, issue management, pull requests
- **Use Case**: Code review, issue tracking, repository management

## 🔧 Custom MCP Servers

### Creating Your Own MCP Server

1. **Follow MCP Specification**: Implement the MCP protocol
2. **Tool Discovery**: Provide `list_tools` method
3. **Tool Execution**: Implement `call_tool` method
4. **JSON-RPC 2.0**: Use standard JSON-RPC format

### Example MCP Server Response

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "scrape_webpage",
        "description": "Scrape content from a webpage",
        "inputSchema": {
          "type": "object",
          "properties": {
            "url": {
              "type": "string",
              "description": "URL to scrape"
            }
          },
          "required": ["url"]
        }
      }
    ]
  }
}
```

## 🧪 Testing

### Run Simplified Demo
```bash
dart run bin/mcp_demo_simple.dart
```

### Run Full MCP Demo
```bash
# Set API key
export DEEPSEEK_API_KEY="your-api-key-here"

# Run demo
dart run bin/mcp_function_call.dart
```

## 🚨 Troubleshooting

### Common Issues

1. **MCP Server Not Found**
   - Ensure the command is available in PATH
   - Check if the package is installed globally
   - Verify working directory permissions

2. **Tool Discovery Fails**
   - Check MCP server logs for errors
   - Verify JSON-RPC protocol compliance
   - Ensure server is fully initialized before discovery

3. **Tool Execution Errors**
   - Check tool parameter validation
   - Verify MCP server is still running
   - Review server error logs

### Debug Mode

Enable debug logging by setting environment variable:
```bash
export MCP_DEBUG=true
```

## 🔒 Security Considerations

- **Process Isolation**: MCP servers run in separate processes
- **Environment Variables**: Sensitive data should use environment variables
- **Working Directory**: Restrict working directory access when possible
- **Tool Validation**: Validate tool parameters before execution

## 📚 Additional Resources

- [MCP Specification](https://modelcontextprotocol.io/)
- [MCP Server Examples](https://github.com/modelcontextprotocol)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)

## 🎯 Best Practices

1. **Tool Naming**: Use descriptive, unique tool names
2. **Parameter Validation**: Implement robust parameter validation
3. **Error Handling**: Provide clear error messages and recovery options
4. **Resource Management**: Properly dispose of MCP clients
5. **Configuration Management**: Use environment variables for sensitive data
6. **Testing**: Test MCP tools thoroughly before production use
