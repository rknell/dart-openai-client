import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 AGENT TEST SUITE: Comprehensive testing for Agent class
///
/// Tests conversation management, tool execution, and message handling
/// to ensure the Agent class works correctly in all scenarios.
void main() {
  group('Agent Tool Filtering Tests', () {
    late ApiClient mockApiClient;
    late ToolExecutorRegistry toolRegistry;
    late WeatherToolExecutor weatherTool;
    late MockToolExecutor mockTool;

    setUp(() {
      // Create mock API client
      mockApiClient = ApiClient(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'test-key',
      );

      // Create tool registry
      toolRegistry =
          McpToolExecutorRegistry(mcpConfig: File("config/mcp_servers.json"));

      // Create weather tool
      weatherTool = WeatherToolExecutor();
      toolRegistry.registerExecutor(weatherTool);

      // Create mock tool
      mockTool = MockToolExecutor('mock_tool', 'Mock tool for testing');
      toolRegistry.registerExecutor(mockTool);
    });

    group('🛡️ REGRESSION: Agent tool filtering respects allowedToolNames', () {
      test('Agent with no restrictions can access all tools', () {
        final agent = Agent(
          apiClient: mockApiClient,
          toolRegistry: toolRegistry,
          systemPrompt: 'Test agent',
        );

        final filteredTools = agent.getFilteredTools();
        expect(filteredTools.length, equals(2));
        expect(filteredTools.map((t) => t.function.name).toSet(),
            containsAll(['get_weather', 'mock_tool']));
      });

      test(
          'Agent with specific tool restrictions can only access allowed tools',
          () {
        final agent = Agent(
          apiClient: mockApiClient,
          toolRegistry: toolRegistry,
          systemPrompt: 'Test agent',
          allowedToolNames: {'get_weather'},
        );

        final filteredTools = agent.getFilteredTools();
        expect(filteredTools.length, equals(1));
        expect(filteredTools.first.function.name, equals('get_weather'));
      });

      test('Agent with empty allowed tools gets no tools', () {
        final agent = Agent(
          apiClient: mockApiClient,
          toolRegistry: toolRegistry,
          systemPrompt: 'Test agent',
          allowedToolNames: <String>{},
        );

        final filteredTools = agent.getFilteredTools();
        expect(filteredTools, isEmpty);
      });
    });

    group('🔍 VALIDATION: Agent constructor validates tool names', () {
      test('Agent with invalid tool names throws ArgumentError', () {
        expect(() {
          Agent(
            apiClient: mockApiClient,
            toolRegistry: toolRegistry,
            systemPrompt: 'Test agent',
            allowedToolNames: {'nonexistent_tool'},
          );
        }, throwsA(isA<ArgumentError>()));
      });

      test('Agent with valid tool names creates successfully', () {
        expect(() {
          Agent(
            apiClient: mockApiClient,
            toolRegistry: toolRegistry,
            systemPrompt: 'Test agent',
            allowedToolNames: {'get_weather', 'mock_tool'},
          );
        }, returnsNormally);
      });

      test('Agent with null allowedToolNames creates successfully', () {
        expect(() {
          Agent(
            apiClient: mockApiClient,
            toolRegistry: toolRegistry,
            systemPrompt: 'Test agent',
            allowedToolNames: null,
          );
        }, returnsNormally);
      });
    });

    group('🛠️ VALIDATION: Tool access validation works correctly', () {
      late Agent restrictedAgent;

      setUp(() {
        restrictedAgent = Agent(
          apiClient: mockApiClient,
          toolRegistry: toolRegistry,
          systemPrompt: 'Test agent',
          allowedToolNames: {'get_weather'},
        );
      });

      test('validateToolAccess allows authorized tools', () {
        final authorizedToolCall = ToolCall(
          id: 'call_1',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "San Francisco"}',
          ),
        );

        expect(() {
          restrictedAgent.validateToolAccess([authorizedToolCall]);
        }, returnsNormally);
      });

      test('validateToolAccess rejects unauthorized tools', () {
        final unauthorizedToolCall = ToolCall(
          id: 'call_1',
          type: 'function',
          function: ToolCallFunction(
            name: 'mock_tool',
            arguments: '{"param": "value"}',
          ),
        );

        expect(() {
          restrictedAgent.validateToolAccess([unauthorizedToolCall]);
        }, throwsA(isA<ArgumentError>()));
      });

      test('validateToolAccess handles mixed authorized/unauthorized tools',
          () {
        final authorizedToolCall = ToolCall(
          id: 'call_1',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "San Francisco"}',
          ),
        );

        final unauthorizedToolCall = ToolCall(
          id: 'call_2',
          type: 'function',
          function: ToolCallFunction(
            name: 'mock_tool',
            arguments: '{"param": "value"}',
          ),
        );

        expect(() {
          restrictedAgent
              .validateToolAccess([authorizedToolCall, unauthorizedToolCall]);
        }, throwsA(isA<ArgumentError>()));
      });

      test('validateToolAccess allows all tools when allowedToolNames is null',
          () {
        final unrestrictedAgent = Agent(
          apiClient: mockApiClient,
          toolRegistry: toolRegistry,
          systemPrompt: 'Test agent',
          allowedToolNames: null,
        );

        final anyToolCall = ToolCall(
          id: 'call_1',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "San Francisco"}',
          ),
        );

        expect(() {
          unrestrictedAgent.validateToolAccess([anyToolCall]);
        }, returnsNormally);
      });
    });

    group('🚀 INTEGRATION: Tool filtering integrates with sendMessage', () {
      test('sendMessage uses filtered tools when calling API', () async {
        // Create a mock API client that captures the tools passed to it
        List<Tool>? capturedTools;
        final capturingApiClient = CapturingApiClient(
          baseUrl: 'https://api.deepseek.com',
          apiKey: 'test-key',
          onSendMessage: (messages, tools, config) {
            capturedTools = tools;
            return Future.value(Message.assistant(content: 'Test response'));
          },
        );

        final agent = Agent(
          apiClient: capturingApiClient,
          toolRegistry: toolRegistry,
          systemPrompt: 'Test agent',
          allowedToolNames: {'get_weather'},
        );

        await agent.sendMessage('What is the weather?');

        expect(capturedTools, isNotNull);
        expect(capturedTools!.length, equals(1));
        expect(capturedTools!.first.function.name, equals('get_weather'));
      });
    });
  });
}

/// 🎭 MOCK API CLIENT: For testing Agent class without real API calls
class MockApiClient implements ApiClient {
  final List<Message> _mockResponses = [];
  ChatCompletionConfig? lastUsedConfig;

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
    lastUsedConfig = config ?? defaultConfig;

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

/// 🧪 MOCK TOOL EXECUTOR: Test implementation for tool filtering tests
class MockToolExecutor implements ToolExecutor {
  @override
  final String toolName;
  @override
  final String toolDescription;

  MockToolExecutor(this.toolName, this.toolDescription);

  @override
  bool canExecute(ToolCall toolCall) => toolCall.function.name == toolName;

  @override
  Future<String> executeTool(ToolCall toolCall, {Duration? timeout}) async => 'Mock result';

  @override
  Map<String, dynamic> get toolParameters => {
        'type': 'object',
        'properties': {
          'param': {
            'type': 'string',
            'description': 'Test parameter',
          }
        },
        'required': ['param']
      };

  @override
  Tool get asTool => Tool(
        function: FunctionObject(
          name: toolName,
          description: toolDescription,
          parameters: toolParameters,
        ),
      );
}

/// 🧪 CAPTURING API CLIENT: Mock API client that captures parameters for testing
class CapturingApiClient extends ApiClient {
  final Future<Message> Function(
      List<Message>, List<Tool>, ChatCompletionConfig?) onSendMessage;

  CapturingApiClient({
    required super.baseUrl,
    required super.apiKey,
    required this.onSendMessage,
  });

  @override
  Future<Message> sendMessage(
    List<Message> messages,
    List<Tool> tools, {
    ChatCompletionConfig? config,
  }) async {
    return await onSendMessage(messages, tools, config ?? defaultConfig);
  }
}
