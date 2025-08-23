import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 INTEGRATION TEST SUITE: End-to-end testing of the complete system
///
/// Tests the entire system working together including Agent, ToolExecutor,
/// ToolExecutorRegistry, and all components to ensure seamless integration.
void main() {
  group('Integration Tests', () {
    group('🤖 Complete Agent Workflow', () {
      MockApiClient mockApiClient = MockApiClient();
      TestToolExecutorRegistry toolRegistry = TestToolExecutorRegistry();
      Agent agent = Agent(
        apiClient: mockApiClient,
        toolRegistry: toolRegistry,
        messages: [],
        systemPrompt: 'You are a helpful weather assistant.',
      );

      setUp(() {
        mockApiClient = MockApiClient();
        toolRegistry = TestToolExecutorRegistry();
        agent = Agent(
          apiClient: mockApiClient,
          toolRegistry: toolRegistry,
          messages: [],
          systemPrompt: 'You are a helpful weather assistant.',
        );
      });

      test('✅ Complete conversation flow with tool execution', () async {
        // Mock API response requesting weather tool call
        mockApiClient.setMockResponse(Message.assistant(
          content: 'I will check the weather for you',
          toolCalls: [
            ToolCall(
              id: 'call_123',
              type: 'function',
              function: ToolCallFunction(
                name: 'get_weather',
                arguments: '{"location": "Hangzhou"}',
              ),
            ),
          ],
        ));

        // Mock final response after tool execution
        mockApiClient.setMockResponse(Message.assistant(
          content: 'The weather in Hangzhou is 24°C, Partly Cloudy',
        ));

        final response =
            await agent.sendMessage('What\'s the weather like in Hangzhou?');

        // Verify final response
        expect(response.content,
            equals('The weather in Hangzhou is 24°C, Partly Cloudy'));
        expect(response.role, equals('assistant'));

        // Verify conversation state
        expect(
            agent.messageCount,
            equals(
                5)); // System + User + Assistant + Tool Result + Final Assistant

        // Verify system message is first
        expect(agent.messages.first.role, equals('system'));
        expect(agent.messages.first.content,
            equals('You are a helpful weather assistant.'));

        // Verify user message
        expect(agent.messages[1].role, equals('user'));
        expect(agent.messages[1].content,
            equals('What\'s the weather like in Hangzhou?'));

        // Verify initial assistant response
        expect(agent.messages[2].role, equals('assistant'));
        expect(agent.messages[2].content,
            equals('I will check the weather for you'));
        expect(agent.messages[2].toolCalls, isNotNull);

        // Verify tool result
        expect(agent.messages[3].role, equals('tool'));
        expect(agent.messages[3].toolCallId, equals('call_123'));
        expect(agent.messages[3].content, equals('24°C, Partly Cloudy'));

        // Verify final assistant response
        expect(agent.messages[4].role, equals('assistant'));
        expect(agent.messages[4].content,
            equals('The weather in Hangzhou is 24°C, Partly Cloudy'));
      });

      test('✅ Multiple tool calls in sequence', () async {
        // Mock API response requesting multiple weather tool calls
        mockApiClient.setMockResponse(Message.assistant(
          content: 'I will check weather for both cities',
          toolCalls: [
            ToolCall(
              id: 'call_1',
              type: 'function',
              function: ToolCallFunction(
                name: 'get_weather',
                arguments: '{"location": "Tokyo"}',
              ),
            ),
            ToolCall(
              id: 'call_2',
              type: 'function',
              function: ToolCallFunction(
                name: 'get_weather',
                arguments: '{"location": "Paris"}',
              ),
            ),
          ],
        ));

        // Mock final response after tool execution
        mockApiClient.setMockResponse(Message.assistant(
          content: 'Tokyo: 28°C, Clear. Paris: 20°C, Cloudy.',
        ));

        final response =
            await agent.sendMessage('Compare weather in Tokyo and Paris');

        // Verify final response
        expect(response.content,
            equals('Tokyo: 28°C, Clear. Paris: 20°C, Cloudy.'));

        // Verify tool results were added
        final toolResults =
            agent.messages.where((msg) => msg.role == 'tool').toList();
        expect(toolResults.length, equals(2));
        expect(toolResults.any((msg) => msg.toolCallId == 'call_1'), isTrue);
        expect(toolResults.any((msg) => msg.toolCallId == 'call_2'), isTrue);
      });

      test('✅ Conversation history preservation across multiple messages',
          () async {
        // First message
        mockApiClient.setMockResponse(
            Message.assistant(content: 'Hello! How can I help you?'));
        await agent.sendMessage('Hello');

        // Second message
        mockApiClient.setMockResponse(
            Message.assistant(content: 'I remember you said hello!'));
        await agent.sendMessage('Do you remember our conversation?');

        // Verify conversation history
        expect(agent.messageCount,
            equals(5)); // System + User1 + Assistant1 + User2 + Assistant2

        // Verify first exchange
        expect(agent.messages[1].role, equals('user'));
        expect(agent.messages[1].content, equals('Hello'));
        expect(agent.messages[2].role, equals('assistant'));
        expect(agent.messages[2].content, equals('Hello! How can I help you?'));

        // Verify second exchange
        expect(agent.messages[3].role, equals('user'));
        expect(agent.messages[3].content,
            equals('Do you remember our conversation?'));
        expect(agent.messages[4].role, equals('assistant'));
        expect(agent.messages[4].content, equals('I remember you said hello!'));
      });

      test('✅ Tool execution error handling', () async {
        // Mock API response requesting weather tool call
        mockApiClient.setMockResponse(Message.assistant(
          content: 'I will check the weather',
          toolCalls: [
            ToolCall(
              id: 'call_error',
              type: 'function',
              function: ToolCallFunction(
                name: 'get_weather',
                arguments: '{"location": "InvalidLocation"}',
              ),
            ),
          ],
        ));

        // Mock final response after tool execution
        mockApiClient.setMockResponse(Message.assistant(
          content: 'I encountered an error checking the weather',
        ));

        await agent.sendMessage('Check weather for InvalidLocation');

        // Verify tool result was handled
        final toolResults =
            agent.messages.where((msg) => msg.role == 'tool').toList();
        expect(toolResults.length, equals(1));
        expect(toolResults.first.toolCallId, equals('call_error'));
        expect(toolResults.first.content, contains('Weather data unavailable'));
      });
    });

    group('🛠️ Tool System Integration', () {
      late McpToolExecutorRegistry toolRegistry;
      late WeatherToolExecutor weatherExecutor;
      late MockToolExecutor mockExecutor;

      setUp(() {
        toolRegistry =
            McpToolExecutorRegistry(mcpConfig: File("config/mcp_servers.json"));
        weatherExecutor = WeatherToolExecutor();
        mockExecutor = MockToolExecutor();
      });

      test('✅ Multiple tool types work together', () {
        toolRegistry.registerExecutor(weatherExecutor);
        toolRegistry.registerExecutor(mockExecutor);

        expect(toolRegistry.executorCount, equals(2));

        final tools = toolRegistry.getAllTools();
        expect(tools.length, equals(2));
        expect(
            tools.any((tool) => tool.function.name == 'get_weather'), isTrue);
        expect(tools.any((tool) => tool.function.name == 'mock_tool'), isTrue);
      });

      test('✅ Tool registry manages executor lifecycle', () {
        expect(toolRegistry.executorCount, equals(0));

        toolRegistry.registerExecutor(weatherExecutor);
        expect(toolRegistry.executorCount, equals(1));

        toolRegistry.registerExecutor(mockExecutor);
        expect(toolRegistry.executorCount, equals(2));

        toolRegistry.clear();
        expect(toolRegistry.executorCount, equals(0));
        expect(toolRegistry.getAllTools(), isEmpty);
      });

      test('✅ Tool execution through registry', () async {
        toolRegistry.registerExecutor(weatherExecutor);

        final toolCall = ToolCall(
          id: 'test_call',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "Hangzhou"}',
          ),
        );

        final result = await toolRegistry.executeTool(toolCall);
        expect(result, equals('24°C, Partly Cloudy'));
      });
    });

    group('🔧 Message and Tool Integration', () {
      test('✅ Tool calls are properly serialized in messages', () {
        final toolCall = ToolCall(
          id: 'call_123',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "Hangzhou"}',
          ),
        );

        final message = Message.assistant(
          content: 'I will check the weather',
          toolCalls: [toolCall],
        );

        final json = message.toJson();
        expect(json['tool_calls'], isList);
        expect(json['tool_calls'][0]['id'], equals('call_123'));
        expect(
            json['tool_calls'][0]['function']['name'], equals('get_weather'));
      });

      test('✅ Tool results are properly formatted', () {
        final toolResult = Message.toolResult(
          toolCallId: 'call_123',
          content: '24°C, Partly Cloudy',
        );

        final json = toolResult.toJson();
        expect(json['role'], equals('tool'));
        expect(json['tool_call_id'], equals('call_123'));
        expect(json['content'], equals('24°C, Partly Cloudy'));
      });

      test('✅ Complex message round-trip serialization', () {
        final originalMessage = Message.assistant(
          content: 'I will check the weather',
          toolCalls: [
            ToolCall(
              id: 'call_123',
              type: 'function',
              function: ToolCallFunction(
                name: 'get_weather',
                arguments: '{"location": "Hangzhou"}',
              ),
            ),
          ],
        );

        final json = originalMessage.toJson();
        final parsedMessage = Message.fromJson(json);

        expect(parsedMessage.role, equals(originalMessage.role));
        expect(parsedMessage.content, equals(originalMessage.content));
        expect(parsedMessage.toolCalls, isNotNull);
        expect(parsedMessage.toolCalls!.length, equals(1));
        expect(parsedMessage.toolCalls!.first.id, equals('call_123'));
        expect(parsedMessage.toolCalls!.first.function.name,
            equals('get_weather'));
      });
    });

    group('🎯 System Prompt Management', () {
      MockApiClient mockApiClient = MockApiClient();
      TestToolExecutorRegistry toolRegistry = TestToolExecutorRegistry();
      Agent agent = Agent(
        apiClient: mockApiClient,
        toolRegistry: toolRegistry,
        messages: [],
        systemPrompt: 'You are a helpful weather assistant.',
      );

      test('✅ System prompt is always first in conversation', () async {
        mockApiClient.setMockResponse(Message.assistant(content: 'Hello!'));
        await agent.sendMessage('Hello');

        expect(agent.messages.first.role, equals('system'));
        expect(agent.messages.first.content,
            equals('You are a helpful weather assistant.'));
      });

      test('✅ Only one system message is maintained', () async {
        mockApiClient
            .setMockResponse(Message.assistant(content: 'First response'));
        await agent.sendMessage('First message');

        mockApiClient
            .setMockResponse(Message.assistant(content: 'Second response'));
        await agent.sendMessage('Second message');

        final systemMessages =
            agent.messages.where((msg) => msg.role == 'system').toList();
        expect(systemMessages.length, equals(1));
      });

      test('✅ System prompt can be changed', () {
        final newAgent = Agent(
          apiClient: mockApiClient,
          toolRegistry: toolRegistry,
          messages: [],
          systemPrompt: 'You are a coding assistant.',
        );

        expect(newAgent.systemPrompt, equals('You are a coding assistant.'));
      });
    });

    group('🧹 Conversation Management', () {
      MockApiClient mockApiClient = MockApiClient();
      TestToolExecutorRegistry toolRegistry = TestToolExecutorRegistry();
      Agent agent = Agent(
        apiClient: mockApiClient,
        toolRegistry: toolRegistry,
        messages: [],
        systemPrompt: 'You are a helpful assistant.',
      );

      test('✅ Conversation can be cleared', () async {
        mockApiClient.setMockResponse(Message.assistant(content: 'Hello!'));
        await agent.sendMessage('Hello');

        expect(agent.messageCount, equals(3)); // System + User + Assistant

        agent.clearConversation();

        expect(agent.messageCount, equals(1)); // Only system message remains
        expect(agent.messages.first.role, equals('system'));
      });

      test('✅ Conversation history is immutable', () {
        final history = agent.conversationHistory;
        expect(
            history.length, equals(1)); // Only system message should be present
        expect(history.first.role, equals('system'));
        expect(history.first.content, equals('You are a helpful assistant.'));

        // Try to modify the history (should not affect original)
        expect(
          () => history.add(Message.user(content: 'Test')),
          throwsA(isA<UnsupportedError>()),
        );

        expect(agent.conversationHistory.length, equals(1));
        expect(agent.conversationHistory.first.role, equals('system'));
      });
    });
  });
}

/// 🧪 TEST TOOL EXECUTOR REGISTRY: Simple registry for testing without MCP initialization
class TestToolExecutorRegistry extends ToolExecutorRegistry {
  final Map<String, ToolExecutor> _executors = {};

  @override
  Map<String, ToolExecutor> get executors => _executors;

  @override
  int get executorCount => _executors.length;

  @override
  void registerExecutor(ToolExecutor executor) {
    _executors[executor.toolName] = executor;
  }

  @override
  ToolExecutor? findExecutor(ToolCall toolCall) {
    return _executors[toolCall.function.name];
  }

  @override
  Future<String> executeTool(ToolCall toolCall, {Duration? timeout}) async {
    final executor = findExecutor(toolCall);
    if (executor == null) {
      throw Exception('No executor found for tool: ${toolCall.function.name}');
    }
    return await executor.executeTool(toolCall);
  }

  @override
  List<Tool> getAllTools() {
    return _executors.values.map((executor) => executor.asTool).toList();
  }

  @override
  void clear() {
    _executors.clear();
  }
}

/// 🎭 MOCK API CLIENT: For integration testing without real API calls
class MockApiClient implements ApiClient {
  final List<Message> _mockResponses = [];

  void setMockResponse(Message response) {
    _mockResponses.add(response);
  }

  @override
  String get baseUrl => 'https://test.api.com';

  @override
  String get apiKey => 'test-key';

  @override
  ChatCompletionConfig get defaultConfig => const ChatCompletionConfig();

  @override
  Future<Message> sendMessage(
    List<Message> messages,
    List<Tool> tools, {
    ChatCompletionConfig? config,
  }) async {
    if (_mockResponses.isEmpty) {
      throw Exception('Mock response not set');
    }
    return _mockResponses.removeAt(0);
  }

  @override
  Future<void> close() async {
    // No cleanup needed for mock client
  }
}

/// 🎭 MOCK TOOL EXECUTOR: For integration testing
class MockToolExecutor implements ToolExecutor {
  @override
  String get toolName => 'mock_tool';

  @override
  String get toolDescription => 'A mock tool for testing';

  @override
  Map<String, dynamic> get toolParameters => {
        'type': 'object',
        'properties': {
          'param': {'type': 'string'}
        },
        'required': ['param']
      };

  @override
  bool canExecute(ToolCall toolCall) {
    return toolCall.function.name == toolName;
  }

  @override
  Future<String> executeTool(ToolCall toolCall, {Duration? timeout}) async {
    if (!canExecute(toolCall)) {
      throw ArgumentError('Cannot execute tool: ${toolCall.function.name}');
    }
    return 'Mock tool executed successfully';
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
