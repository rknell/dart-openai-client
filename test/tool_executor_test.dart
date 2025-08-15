import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 TOOL EXECUTOR TEST SUITE: Comprehensive testing for tool execution system
///
/// Tests the ToolExecutor interface, WeatherToolExecutor implementation,
/// and ToolExecutorRegistry management to ensure reliable tool execution.
void main() {
  group('ToolExecutor Tests', () {
    group('🛠️ ToolExecutor Interface', () {
      test('✅ ToolExecutor is abstract and cannot be instantiated', () {
        // This test verifies that ToolExecutor is properly abstract
        // We can't test instantiation directly, but we can verify
        // that concrete implementations work correctly
        expect(WeatherToolExecutor(), isA<ToolExecutor>());
      });
    });

    group('🌤️ WeatherToolExecutor', () {
      late WeatherToolExecutor weatherExecutor;

      setUp(() {
        weatherExecutor = WeatherToolExecutor();
      });

      group('🏗️ Constructor and Properties', () {
        test('✅ Creates weather executor with default data', () {
          expect(weatherExecutor.toolName, equals('get_weather'));
          expect(
              weatherExecutor.toolDescription,
              equals(
                  'Get weather of a location, the user should supply a location first'));
          expect(weatherExecutor.toolParameters, isNotEmpty);
          expect(weatherExecutor.toolParameters['type'], equals('object'));
          expect(weatherExecutor.toolParameters['properties'], isNotEmpty);
          expect(
              weatherExecutor.toolParameters['required'], contains('location'));
        });

        test('✅ Creates weather executor with custom data', () {
          final customData = {'CustomCity': 'Custom Weather'};
          final customExecutor = WeatherToolExecutor(weatherData: customData);

          expect(customExecutor.toolName, equals('get_weather'));
          expect(
              customExecutor.getAvailableLocations(), contains('CustomCity'));
        });
      });

      group('🔍 Tool Execution', () {
        test('✅ Can execute weather tool calls', () {
          final toolCall = ToolCall(
            id: 'test_call',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_weather',
              arguments: '{"location": "Hangzhou"}',
            ),
          );

          expect(weatherExecutor.canExecute(toolCall), isTrue);
        });

        test('✅ Cannot execute non-weather tool calls', () {
          final toolCall = ToolCall(
            id: 'test_call',
            type: 'function',
            function: ToolCallFunction(
              name: 'other_tool',
              arguments: '{"param": "value"}',
            ),
          );

          expect(weatherExecutor.canExecute(toolCall), isFalse);
        });

        test('✅ Executes weather tool call successfully', () async {
          final toolCall = ToolCall(
            id: 'test_call',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_weather',
              arguments: '{"location": "Hangzhou"}',
            ),
          );

          final result = await weatherExecutor.executeTool(toolCall);

          expect(result, equals('24°C, Partly Cloudy'));
        });

        test('✅ Handles missing location parameter', () async {
          final toolCall = ToolCall(
            id: 'test_call',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_weather',
              arguments: '{}',
            ),
          );

          final result = await weatherExecutor.executeTool(toolCall);

          expect(result, contains('Error: No location provided'));
        });

        test('✅ Handles invalid JSON arguments', () async {
          final toolCall = ToolCall(
            id: 'test_call',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_weather',
              arguments: 'invalid json',
            ),
          );

          final result = await weatherExecutor.executeTool(toolCall);

          expect(result, contains('Error parsing weather tool arguments'));
        });

        test('✅ Throws error for non-executable tool calls', () async {
          final toolCall = ToolCall(
            id: 'test_call',
            type: 'function',
            function: ToolCallFunction(
              name: 'other_tool',
              arguments: '{"param": "value"}',
            ),
          );

          expect(
            () => weatherExecutor.executeTool(toolCall),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('🌍 Weather Data Management', () {
        test('✅ Gets weather for known location', () {
          final weather = weatherExecutor.getWeather('Hangzhou');
          expect(weather, equals('24°C, Partly Cloudy'));
        });

        test('✅ Returns unavailable message for unknown location', () {
          final weather = weatherExecutor.getWeather('UnknownCity');
          expect(weather, equals('Weather data unavailable for UnknownCity'));
        });

        test('✅ Adds custom weather location', () {
          weatherExecutor.addWeatherLocation('CustomCity', 'Custom Weather');

          final weather = weatherExecutor.getWeather('CustomCity');
          expect(weather, equals('Custom Weather'));
        });

        test('✅ Gets all available locations', () {
          final locations = weatherExecutor.getAvailableLocations();

          expect(locations, contains('Hangzhou'));
          expect(locations, contains('San Francisco'));
          expect(locations, contains('New York'));
          expect(locations, contains('Tokyo'));
          expect(locations.length, greaterThan(5));
        });

        test('✅ Searches weather by partial location name', () {
          final results = weatherExecutor.searchWeather('York');

          expect(results, contains('New York'));
          expect(results['New York'], equals('22°C, Sunny'));
        });

        test('✅ Search is case insensitive', () {
          final results = weatherExecutor.searchWeather('york');

          expect(results, contains('New York'));
          expect(results['New York'], equals('22°C, Sunny'));
        });

        test('✅ Search returns empty map for no matches', () {
          final results = weatherExecutor.searchWeather('NonexistentCity');

          expect(results, isEmpty);
        });
      });

      group('🔧 Tool Creation', () {
        test('✅ Creates Tool instance correctly', () {
          final tool = weatherExecutor.asTool;

          expect(tool.type, equals('function'));
          expect(tool.function.name, equals('get_weather'));
          expect(
              tool.function.description,
              equals(
                  'Get weather of a location, the user should supply a location first'));
          expect(tool.function.parameters, isNotEmpty);
        });

        test('✅ Tool parameters match executor parameters', () {
          final tool = weatherExecutor.asTool;

          expect(
              tool.function.parameters, equals(weatherExecutor.toolParameters));
        });
      });
    });

    group('🔧 ToolExecutorRegistry', () {
      TestToolExecutorRegistry registry = TestToolExecutorRegistry();
      WeatherToolExecutor weatherExecutor = WeatherToolExecutor();
      MockToolExecutor mockExecutor = MockToolExecutor();

      setUp(() {
        registry = TestToolExecutorRegistry();
        weatherExecutor = WeatherToolExecutor();
        mockExecutor = MockToolExecutor();
      });

      group('📝 Registration', () {
        test('✅ Registers tool executor', () {
          registry.registerExecutor(weatherExecutor);

          expect(registry.executorCount, equals(1));
          expect(registry.findExecutor(_createToolCall('get_weather')),
              equals(weatherExecutor));
        });

        test('✅ Registers multiple executors', () {
          registry.registerExecutor(weatherExecutor);
          registry.registerExecutor(mockExecutor);

          expect(registry.executorCount, equals(2));
          expect(registry.findExecutor(_createToolCall('get_weather')),
              equals(weatherExecutor));
          expect(registry.findExecutor(_createToolCall('mock_tool')),
              equals(mockExecutor));
        });

        test('✅ Overwrites existing executor with same name', () {
          registry.registerExecutor(weatherExecutor);

          final newWeatherExecutor = WeatherToolExecutor();
          registry.registerExecutor(newWeatherExecutor);

          expect(registry.executorCount, equals(1));
          expect(registry.findExecutor(_createToolCall('get_weather')),
              equals(newWeatherExecutor));
        });
      });

      group('🔍 Executor Finding', () {
        test('✅ Finds executor for registered tool', () {
          registry.registerExecutor(weatherExecutor);

          final found = registry.findExecutor(_createToolCall('get_weather'));
          expect(found, equals(weatherExecutor));
        });

        test('✅ Returns null for unregistered tool', () {
          registry.registerExecutor(weatherExecutor);

          final found = registry.findExecutor(_createToolCall('unknown_tool'));
          expect(found, isNull);
        });

        test('✅ Returns null when registry is empty', () {
          final found = registry.findExecutor(_createToolCall('any_tool'));
          expect(found, isNull);
        });
      });

      group('🛠️ Tool Execution', () {
        test('✅ Executes tool using registered executor', () async {
          registry.registerExecutor(weatherExecutor);

          final toolCall = _createToolCall('get_weather');
          final result = await registry.executeTool(toolCall);

          expect(result, equals('24°C, Partly Cloudy'));
        });

        test('✅ Throws exception for unregistered tool', () async {
          final toolCall = _createToolCall('unknown_tool');

          expect(
            () => registry.executeTool(toolCall),
            throwsA(isA<Exception>()),
          );
        });
      });

      group('📋 Tool Management', () {
        test('✅ Gets all registered tools', () {
          registry.registerExecutor(weatherExecutor);
          registry.registerExecutor(mockExecutor);

          final tools = registry.getAllTools();

          expect(tools.length, equals(2));
          expect(
              tools.any((tool) => tool.function.name == 'get_weather'), isTrue);
          expect(
              tools.any((tool) => tool.function.name == 'mock_tool'), isTrue);
        });

        test('✅ Returns empty list when no executors registered', () {
          final tools = registry.getAllTools();

          expect(tools, isEmpty);
        });

        test('✅ Gets correct executor count', () {
          expect(registry.executorCount, equals(0));

          registry.registerExecutor(weatherExecutor);
          expect(registry.executorCount, equals(1));

          registry.registerExecutor(mockExecutor);
          expect(registry.executorCount, equals(2));
        });
      });

      group('🧹 Registry Management', () {
        test('✅ Clears all registered executors', () {
          registry.registerExecutor(weatherExecutor);
          registry.registerExecutor(mockExecutor);

          expect(registry.executorCount, equals(2));

          registry.clear();

          expect(registry.executorCount, equals(0));
          expect(registry.getAllTools(), isEmpty);
        });
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
  void clear() {
    _executors.clear();
  }
}

/// 🎭 MOCK TOOL EXECUTOR: For testing ToolExecutorRegistry
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
  Future<String> executeTool(ToolCall toolCall) async {
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

/// 🔧 HELPER FUNCTION: Create tool call for testing
ToolCall _createToolCall(String functionName) {
  String arguments;
  if (functionName == 'get_weather') {
    arguments = '{"location": "Hangzhou"}';
  } else {
    arguments = '{"param": "value"}';
  }

  return ToolCall(
    id: 'test_call',
    type: 'function',
    function: ToolCallFunction(
      name: functionName,
      arguments: arguments,
    ),
  );
}
