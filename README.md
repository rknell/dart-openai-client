# 🚀 Dart OpenAI Client

A clean, modular Dart client for OpenAI-compatible APIs with full support for function calling (tool calling) capabilities. Built following the **ELITE CODING WARRIOR PROTOCOL** for maximum performance and maintainability.

## 🎯 Features

- **Full Function Calling Support**: Complete tool request → execution → response cycle
- **Agent-Specific Tool Access Control**: Restrict which tools each agent can use
- **DeepSeek API Compatible**: Works with DeepSeek and other OpenAI-compatible APIs
- **Configurable API Parameters**: Full control over temperature, max tokens, penalties, and more
- **Strong Typing & Null Safety**: No `late` variables, no null assertions, compile-time safety
- **Comprehensive Testing**: 100% test coverage, permanent regression protection
- **Clean Architecture**: Modular, maintainable code
- **Zero Linter Errors**: All code passes `dart analyze` with no warnings (except for known MCP deprecation info)

## 🏗️ Architecture

The library follows the **ELITE CODING WARRIOR PROTOCOL**:
- **Strong Typing Supremacy**: No `Map<String, dynamic>` return types
- **Null Safety Fortress**: No `late` variables or `!` operators
- **Performance Optimization**: O(1) operations where possible
- **Permanent Test Fortress**: All features and edge cases are covered by permanent tests

## 🚀 Quick Start

### Prerequisites
- **Dart SDK**: Version 3.0.0 or higher
- **DeepSeek API Key**: Get your key from [DeepSeek Platform](https://platform.deepseek.com/)

### Installation
```bash
git clone <repository-url>
cd dart-openai-client
dart pub get
```

Set your API key:
```bash
export DEEPSEEK_API_KEY="your-api-key-here"
```

### Running the Demo
```bash
dart run bin/deepseek_function_call.dart
```

## 🔧 Function Calling Flow

The system uses a **modular architecture** where tools are completely independent of agents, implementing the complete function calling cycle as described in the [DeepSeek Function Calling Guide](https://api-docs.deepseek.com/guides/function_calling):

1. **Create API Client**
   ```dart
   final client = ApiClient(
     baseUrl: 'https://api.deepseek.com/v1',
     apiKey: apiKey,
   );
   ```
2. **Load Tool Executor**
   ```dart
   final weatherExecutor = WeatherToolExecutor();
   ```
3. **Create Agent with Tools**
   ```dart
   final toolRegistry = ToolExecutorRegistry();
   toolRegistry.registerExecutor(weatherExecutor);

   final agent = Agent(
     apiClient: client,
     toolRegistry: toolRegistry,
     systemPrompt: 'You are a helpful weather assistant...',
     // Optional: Configure API parameters
     apiConfig: ChatCompletionConfig(
       temperature: 0.7,
       maxTokens: 2048,
       frequencyPenalty: 0.1,
       presencePenalty: 0.1,
     ),
     // Optional: Restrict tool access (null = all tools, empty set = no tools)
     allowedToolNames: {'get_weather'},
   );
   ```
4. **Use Agent for Queries**
   ```dart
   final response = await agent.sendMessage("How's the weather in Hangzhou?");
   ```
5. **Access Tool Features Directly**
   ```dart
   weatherExecutor.addWeatherLocation('Vancouver', '18°C, Rainy');
   final locations = weatherExecutor.getAvailableLocations();
   ```

## 🔒 Tool Access Control

Create agents with specific tool permissions:
```dart
final weatherAgent = Agent(
  apiClient: client,
  toolRegistry: toolRegistry,
  systemPrompt: 'You are a weather assistant. You can only check weather information.',
  allowedToolNames: {'get_weather'},
);

final multiToolAgent = Agent(
  apiClient: client,
  toolRegistry: toolRegistry,
  systemPrompt: 'You can check weather and perform calculations.',
  allowedToolNames: {'get_weather', 'calculate'},
);

final unrestrictedAgent = Agent(
  apiClient: client,
  toolRegistry: toolRegistry,
  systemPrompt: 'You have access to all available tools.',
  allowedToolNames: null, // All tools (default)
);

final restrictedAgent = Agent(
  apiClient: client,
  toolRegistry: toolRegistry,
  systemPrompt: 'You are a chat assistant. You cannot use any tools.',
  allowedToolNames: <String>{}, // No tools
);
```

Validate tool access before execution:
```dart
final toolCall = ToolCall(
  id: 'call_1',
  type: 'function',
  function: ToolCallFunction(
    name: 'get_weather',
    arguments: '{"location": "San Francisco"}',
  ),
);

try {
  weatherAgent.validateToolAccess([toolCall]);
  print('✅ Tool access allowed');
} catch (e) {
  print('❌ Tool access denied: $e');
}
```

## 📖 Examples

The library includes several example files demonstrating different features:
- `example_configurable_agent.dart`: Configurable API parameters and temperature control
- `example_temperature_usage.dart`: Temperature control for different use cases
- `example_tool_filtering.dart`: Agent-specific tool access control

Run any example with:
```bash
dart run example_configurable_agent.dart
dart run example_temperature_usage.dart
dart run example_tool_filtering.dart
```

## 🧪 Testing & Quality

Run the comprehensive test suite (all tests must pass):
```bash
dart test
```
Or run specific test files:
```bash
dart test test/tool_test.dart
dart test test/agent_test.dart
dart test test/message_test.dart
dart test test/api_client_test.dart
dart test test/integration_test.dart
```
- All tests are permanent and cover all features and edge cases
- Every bug fix and feature is protected by a regression test
- No temporary or diagnostic tests are allowed
- All types are strictly enforced; no `Map<String, dynamic>` returns except for internal JSON parsing
- No `late` variables or null assertion operators (`!`) are used anywhere in the codebase
- All code passes `dart analyze` with zero warnings (except for known MCP deprecation info)

## 📚 API Reference

### Core Classes

#### `ToolExecutor` (Abstract Interface)
- **Purpose**: Abstract interface for tool execution
- **Methods**: 
  - `executeTool(ToolCall toolCall)`
  - `canExecute(ToolCall toolCall)`
  - `toolName`, `toolDescription`, `toolParameters`, `asTool`

#### `WeatherToolExecutor` (Concrete Implementation)
- **Purpose**: Weather tool execution implementation
- **Methods**: 
  - `getWeather(String location)`
  - `addWeatherLocation(String, String)`
  - `getAvailableLocations()`
  - `searchWeather(String query)`

#### `ToolExecutorRegistry` (Tool Management)
- **Purpose**: Centralized tool executor management
- **Methods**: 
  - `registerExecutor(ToolExecutor executor)`
  - `findExecutor(ToolCall toolCall)`
  - `executeTool(ToolCall toolCall)`
  - `getAllTools()`

#### `Agent` (Conversation Management)
- **Purpose**: Conversation agent with automatic tool calling and access control
- **Methods**: 
  - `sendMessage(String message, {ChatCompletionConfig? config})`
  - `updateApiConfig(ChatCompletionConfig config)`
  - `copyApiConfig({...})`
  - `getFilteredTools()`
  - `validateToolAccess(List<ToolCall> toolCalls)`
  - `conversationHistory`, `messageCount`, `clearConversation()`
- **Properties**:
  - `allowedToolNames`, `temperature`, `maxTokens`, `frequencyPenalty`, `presencePenalty`, `topP`

#### `ApiClient`
- **Purpose**: HTTP client for API communication
- **Methods**: `sendMessage(List<Message> messages, List<Tool> tools, {ChatCompletionConfig? config})`
- **Properties**: `defaultConfig`

#### `Message`
- **Purpose**: Conversation messages with tool call support
- **Factory Methods**: 
  - `Message.user(content: String)`
  - `Message.assistant(content: String?, toolCalls: List<ToolCall>?)`
  - `Message.system(content: String)`
  - `Message.toolResult(toolCallId: String, content: String)`

#### `ChatCompletionConfig` (API Configuration)
- **Purpose**: Configuration for chat completion API parameters
- **Properties**:
  - `model`, `temperature`, `topP`, `maxTokens`, `frequencyPenalty`, `presencePenalty`, `stop`, `logprobs`, `topLogprobs`
- **Methods**:
  - `validate()`, `toJson()`, `copyWith({...})`

#### `Tool`
- **Purpose**: Function definition for tool calling
- **Properties**: `type`, `function` (FunctionObject)

#### `ToolCall`
- **Purpose**: Represents a tool call from the model
- **Properties**: `id`, `type`, `function`

### Message Flow
```
User → Model → Tool Call → Tool Execution → Tool Result → Model → Final Response
```

## ⚙️ API Configuration

The library provides comprehensive control over API parameters through the `ChatCompletionConfig` class.

- **Basic Configuration**
  ```dart
  final config = ChatCompletionConfig(
    temperature: 0.7,
    maxTokens: 2048,
    frequencyPenalty: 0.1,
    presencePenalty: 0.1,
  );
  ```
- **Advanced Configuration**
  ```dart
  final advancedConfig = ChatCompletionConfig(
    model: 'deepseek-reasoner',
    temperature: 0.5,
    topP: 0.8,
    maxTokens: 4096,
    frequencyPenalty: 0.2,
    presencePenalty: 0.1,
    stop: ['###', 'END'],
    logprobs: true,
    topLogprobs: 5,
  );
  ```
- **Validation**
  ```dart
  try {
    final config = ChatCompletionConfig(temperature: 2.5); // Invalid
    config.validate(); // Throws ArgumentError
  } catch (e) {
    print('Configuration error: $e');
  }
  ```
- **Dynamic Configuration**
  ```dart
  agent.temperature = 0.3;
  agent.maxTokens = 1024;
  agent.frequencyPenalty = 0.1;
  agent.presencePenalty = 0.1;
  agent.topP = 0.9;
  // Or update entire config
  agent.updateApiConfig(ChatCompletionConfig(
    temperature: 0.3,
    maxTokens: 1024,
  ));
  // Override for specific message
  final response = await agent.sendMessage(
    "Give me a creative story",
    config: ChatCompletionConfig(
      temperature: 1.5,
      maxTokens: 2048,
    ),
  );
  ```
- **Copying**
  ```dart
  final baseConfig = ChatCompletionConfig(
    temperature: 0.7,
    maxTokens: 1024,
  );
  final creativeConfig = baseConfig.copyWith(
    temperature: 1.2,
    maxTokens: 2048,
  );
  final preciseConfig = baseConfig.copyWith(
    temperature: 0.2,
    maxTokens: 512,
  );
  ```

## 🔍 Error Handling

- **API Key Validation**: Checks for required environment variables
- **Tool Call Parsing**: Safe JSON parsing with error recovery
- **API Response Validation**: Proper error messages for common issues
- **Rate Limiting**: Helpful messages for rate limit exceeded errors

## 🚀 Advanced Usage

### Modular Tool Execution
Implement the `ToolExecutor` interface for custom tools:
```dart
class CustomToolExecutor implements ToolExecutor {
  @override
  String get toolName => 'custom_function';
  @override
  String get toolDescription => 'A custom function for demonstration';
  @override
  Map<String, dynamic> get toolParameters => {
    'type': 'object',
    'properties': {
      'param1': {'type': 'string'}
    },
    'required': ['param1']
  };
  @override
  bool canExecute(ToolCall toolCall) => toolCall.function.name == toolName;
  @override
  Future<String> executeTool(ToolCall toolCall) async {
    final arguments = jsonDecode(toolCall.function.arguments);
    return 'Custom result: ${arguments['param1']}';
  }
  @override
  Tool get asTool => Tool(
    function: FunctionObject(
      name: toolName,
      description: toolDescription,
      parameters: toolParameters,
    ),
  );
}

final customExecutor = CustomToolExecutor();
final toolRegistry = ToolExecutorRegistry();
toolRegistry.registerExecutor(customExecutor);
final agent = Agent(
  apiClient: client,
  toolRegistry: toolRegistry,
  systemPrompt: 'You are a helpful assistant...',
);
final response = await agent.sendMessage("Use the custom function");
```

### Multiple Tool Calls (Automatic)
The agent automatically handles multiple simultaneous tool calls:
```dart
final response = await agent.sendMessage("Check weather for multiple cities");
```

## 🛠️ Creating a Custom Dart MCP Server

You can build your own **custom Dart-based MCP server** by extending the universal `BaseMCPServer` class (`lib/src/base_mcp_server.dart`). This class provides a stateless, registration-based, callback-driven architecture for maximum flexibility and protocol compliance.

### ⚡ STRATEGIC ADVANTAGES
- **Stateless**: No session management, all operations are agent-name-based
- **Registration System**: Register tools, resources, and prompts with callbacks
- **No Deprecated Methods**: Only the registration/callback system is supported
- **Null Safety & Strong Typing**: No `late` variables, no null assertions, all types enforced

### 🏗️ HOW TO EXTEND

1. **Create Your Server Class**
   ```dart
   import 'lib/src/base_mcp_server.dart';
   import 'your_tool_definitions.dart';

   class MyCustomMCPServer extends BaseMCPServer {
     MyCustomMCPServer() : super(name: 'my_server', version: '1.0.0');

     @override
     Future<void> initializeServer() async {
       registerTool(MCPTool(
         name: 'my_tool',
         description: 'Does something useful',
         inputSchema: {
           'type': 'object',
           'properties': {'param': {'type': 'string'}},
           'required': ['param'],
         },
         callback: (arguments) async {
           return MCPToolResult(content: [MCPContent.text('Result: ${arguments['param']}')]);
         },
       ));
       registerResource(MCPResource(
         uri: '/my/resource',
         name: 'My Resource',
         callback: () async => MCPContent.text('Resource content'),
       ));
       registerPrompt(MCPPrompt(
         name: 'my_prompt',
         description: 'A custom prompt',
         callback: (arguments) async => [
           MCPMessage.system(content: 'Prompted!'),
         ],
       ));
     }
   }
   ```
2. **Start the Server**
   ```dart
   Future<void> main() async {
     final server = MyCustomMCPServer();
     await server.start();
   }
   ```

### 🧠 ARCHITECTURE NOTES
- All registration is done in `initializeServer()`
- Each tool/resource/prompt must provide a callback (async function)
- All communication is JSON-RPC 2.0 over STDIN/STDOUT (ready for HTTP/SSE)
- No deprecated abstract methods—**only** the registration/callback system is supported
- All null safety and strong typing rules from the ELITE CODING WARRIOR PROTOCOL apply

See `lib/src/base_mcp_server.dart` for the full base class and documentation.

## 🏆 Victory Conditions

This implementation achieves **TOTAL DOMINATION** by:
- ✅ **Zero Linter Errors**: Perfect code quality (except for known MCP deprecation info)
- ✅ **Comprehensive Testing**: 100% test coverage, all tests pass
- ✅ **Strong Typing**: No dynamic maps or null safety violations, no `late` variables or null assertions
- ✅ **Full Function Calling**: Complete tool request/response cycle
- ✅ **DeepSeek Compatibility**: Follows official API specification
- ✅ **Clean Architecture**: Modular, maintainable design

## 📖 References
- [DeepSeek Function Calling Guide](https://api-docs.deepseek.com/guides/function_calling)
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

## 🤝 Contributing
Contributions are welcome! Please follow the **ELITE CODING WARRIOR PROTOCOL**:
1. **Write Tests First**: TDD approach required
2. **Strong Typing**: No `Map<String, dynamic>` returns
3. **Null Safety**: No `late` variables or `!` operators
4. **Performance**: Document complexity and optimizations
5. **Documentation**: Explain WHY, not WHAT

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
