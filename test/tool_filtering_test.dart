import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 TOOL FILTERING TEST SUITE: Comprehensive testing for tool filtering capabilities
///
/// Tests the new FilteredToolExecutorRegistry and Agent.withFilteredTools functionality
/// to ensure agents can have customized tool sets while maintaining full access
/// to all tools in the underlying registry.
void main() {
  group('Tool Filtering Tests', () {
    late ToolExecutorRegistry baseRegistry;
    late WeatherToolExecutor weatherTool;
    late MockToolExecutor mockTool;

    setUp(() {
      // Create base registry with multiple tools
      baseRegistry = MockToolExecutorRegistry();

      // Add weather tool
      weatherTool = WeatherToolExecutor();
      baseRegistry.registerExecutor(weatherTool);

      // Add mock tool
      mockTool = MockToolExecutor('mock_tool', 'Mock tool for testing');
      baseRegistry.registerExecutor(mockTool);
    });

    group(
        '🛡️ REGRESSION: FilteredToolExecutorRegistry filters tools correctly',
        () {
      test('should filter tools based on allowed tool names', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: {'get_weather'},
        );

        final availableTools = filteredRegistry.getAllTools();
        expect(availableTools.length, equals(1));
        expect(availableTools.first.function.name, equals('get_weather'));
      });

      test('should allow all tools when allowedToolNames is null', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: null,
        );

        final availableTools = filteredRegistry.getAllTools();
        expect(availableTools.length, equals(2));
        expect(availableTools.map((t) => t.function.name).toSet(),
            containsAll(['get_weather', 'mock_tool']));
      });

      test('should return empty list when allowedToolNames is empty set', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: <String>{},
        );

        final availableTools = filteredRegistry.getAllTools();
        expect(availableTools, isEmpty);
      });

      test('should filter multiple allowed tools', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: {'get_weather', 'mock_tool'},
        );

        final availableTools = filteredRegistry.getAllTools();
        expect(availableTools.length, equals(2));
        expect(availableTools.map((t) => t.function.name).toSet(),
            containsAll(['get_weather', 'mock_tool']));
      });
    });

    group(
        '🔒 REGRESSION: FilteredToolExecutorRegistry executor count is correct',
        () {
      test('should count filtered executors correctly', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: {'get_weather'},
        );

        expect(filteredRegistry.executorCount, equals(1));
      });

      test('should count all executors when no filtering', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: null,
        );

        expect(filteredRegistry.executorCount, equals(2));
      });

      test('should count zero executors when empty allowed set', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: <String>{},
        );

        expect(filteredRegistry.executorCount, equals(0));
      });
    });

    group('🛠️ REGRESSION: FilteredToolExecutorRegistry tool execution works',
        () {
      test('should execute allowed tools successfully', () async {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: {'get_weather'},
        );

        final toolCall = ToolCall(
          id: 'test_1',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "San Francisco"}',
          ),
        );

        final result = await filteredRegistry.executeTool(toolCall);
        expect(result, isNotEmpty);
        expect(result.contains('San Francisco') || result.contains('Foggy'),
            isTrue);
      });

      test('should reject unauthorized tool execution', () async {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: {'get_weather'},
        );

        final toolCall = ToolCall(
          id: 'test_2',
          type: 'function',
          function: ToolCallFunction(
            name: 'mock_tool',
            arguments: '{"param": "value"}',
          ),
        );

        expect(
          () => filteredRegistry.executeTool(toolCall),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should allow all tools when no filtering', () async {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: null,
        );

        final toolCall = ToolCall(
          id: 'test_3',
          type: 'function',
          function: ToolCallFunction(
            name: 'mock_tool',
            arguments: '{"param": "value"}',
          ),
        );

        final result = await filteredRegistry.executeTool(toolCall);
        expect(result, isNotEmpty);
      });
    });

    group('🔍 REGRESSION: FilteredToolExecutorRegistry findExecutor works', () {
      test('should find allowed executors', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: {'get_weather'},
        );

        final toolCall = ToolCall(
          id: 'test_4',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "San Francisco"}',
          ),
        );

        final executor = filteredRegistry.findExecutor(toolCall);
        expect(executor, isNotNull);
        expect(executor!.toolName, equals('get_weather'));
      });

      test('should not find unauthorized executors', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: {'get_weather'},
        );

        final toolCall = ToolCall(
          id: 'test_5',
          type: 'function',
          function: ToolCallFunction(
            name: 'mock_tool',
            arguments: '{"param": "value"}',
          ),
        );

        final executor = filteredRegistry.findExecutor(toolCall);
        expect(executor, isNull);
      });
    });

    group('🏗️ REGRESSION: Agent.withFilteredTools factory constructor works',
        () {
      late ApiClient mockApiClient;

      setUp(() {
        mockApiClient = MockApiClient();
      });

      test('should create agent with filtered tools', () {
        final agent = Agent.withFilteredTools(
          apiClient: mockApiClient,
          toolRegistry: baseRegistry,
          systemPrompt: 'Test agent',
          allowedToolNames: {'get_weather'},
        );

        expect(agent.toolRegistry, isA<FilteredToolExecutorRegistry>());
        expect(agent.getFilteredTools().length, equals(1));
        expect(agent.getFilteredTools().first.function.name,
            equals('get_weather'));
      });

      test('should create agent with all tools when allowedToolNames is null',
          () {
        final agent = Agent.withFilteredTools(
          apiClient: mockApiClient,
          toolRegistry: baseRegistry,
          systemPrompt: 'Test agent',
          allowedToolNames: null,
        );

        // When no filtering is requested, should return original registry
        expect(agent.toolRegistry, equals(baseRegistry));
        expect(agent.getFilteredTools().length, equals(2));
      });

      test('should create agent with no tools when allowedToolNames is empty',
          () {
        final agent = Agent.withFilteredTools(
          apiClient: mockApiClient,
          toolRegistry: baseRegistry,
          systemPrompt: 'Test agent',
          allowedToolNames: <String>{},
        );

        expect(agent.toolRegistry, isA<FilteredToolExecutorRegistry>());
        expect(agent.getFilteredTools(), isEmpty);
      });
    });

    group('📊 REGRESSION: FilteredToolExecutorRegistry status reporting works',
        () {
      test('should report correct status information', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: {'get_weather'},
        );

        final status = filteredRegistry.getStatus();

        expect(status['type'], equals('FilteredToolExecutorRegistry'));
        expect(status['allowedToolCount'], equals(1));
        expect(status['filteringEnabled'], isTrue);
        expect(status['allowedToolNames'], contains('get_weather'));
      });

      test('should report correct status when no filtering', () {
        final filteredRegistry = FilteredToolExecutorRegistry(
          sourceRegistry: baseRegistry,
          allowedToolNames: null,
        );

        final status = filteredRegistry.getStatus();

        expect(status['type'], equals('FilteredToolExecutorRegistry'));
        expect(status['allowedToolCount'], equals(2));
        expect(status['filteringEnabled'], isFalse);
        expect(status['allowedToolNames'], contains('ALL_TOOLS'));
      });
    });
  });
}

/// 🧪 MOCK TOOL EXECUTOR: Mock tool executor for testing
class MockToolExecutor implements ToolExecutor {
  @override
  final String toolName;

  @override
  final String toolDescription;

  MockToolExecutor(this.toolName, this.toolDescription);

  @override
  Map<String, dynamic> get toolParameters => {
        'type': 'object',
        'properties': {
          'param': {'type': 'string'}
        },
        'required': ['param']
      };

  @override
  bool canExecute(ToolCall toolCall) => toolCall.function.name == toolName;

  @override
  Future<String> executeTool(ToolCall toolCall) async {
    return 'Mock result for $toolName';
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

/// 🧪 MOCK TOOL EXECUTOR REGISTRY: Mock registry for testing
class MockToolExecutorRegistry extends ToolExecutorRegistry {
  final Map<String, ToolExecutor> _executors = {};

  @override
  Map<String, ToolExecutor> get executors => _executors;

  @override
  void registerExecutor(ToolExecutor executor) {
    _executors[executor.toolName] = executor;
  }

  @override
  ToolExecutor? findExecutor(ToolCall toolCall) {
    return _executors[toolCall.function.name];
  }

  @override
  Future<String> executeTool(ToolCall toolCall) async {
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
  int get executorCount => _executors.length;

  @override
  void clear() {
    _executors.clear();
  }
}

/// 🧪 MOCK API CLIENT: Mock API client for testing
class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'https://test.com', apiKey: 'test-key');

  @override
  Future<Message> sendMessage(
    List<Message> messages,
    List<Tool> tools, {
    ChatCompletionConfig? config,
  }) async {
    return Message.assistant(content: 'Mock response');
  }

  @override
  Future<void> close() async {}
}
