import 'dart:convert';
import 'message.dart';
import 'tool.dart';

/// 🛠️ TOOL EXECUTOR: Interface for executing tool calls
///
/// Provides a clean abstraction for tool execution that can be implemented
/// by different tool types (weather, MCP, custom, etc.).
/// This allows tools to be completely independent of agents.
abstract class ToolExecutor {
  /// 🔧 EXECUTE TOOL: Execute a tool call and return the result
  ///
  /// [toolCall] - The tool call to execute
  ///
  /// Returns the result of the tool execution as a string.
  /// This method should be implemented by concrete tool executors.
  Future<String> executeTool(ToolCall toolCall);

  /// 🔍 CAN EXECUTE: Check if this executor can handle the given tool call
  ///
  /// [toolCall] - The tool call to check
  ///
  /// Returns true if this executor can handle the tool call.
  /// This allows multiple executors to coexist and handle different tools.
  bool canExecute(ToolCall toolCall);

  /// 📛 TOOL NAME: Get the name of the tool this executor handles
  ///
  /// Returns the tool name that this executor is responsible for.
  String get toolName;

  /// 📝 TOOL DESCRIPTION: Get the description of the tool
  ///
  /// Returns a human-readable description of what the tool does.
  String get toolDescription;

  /// 🎯 TOOL PARAMETERS: Get the JSON Schema parameters for the tool
  ///
  /// Returns the parameter schema that defines what arguments the tool accepts.
  Map<String, dynamic> get toolParameters;

  /// 🛠️ CREATE TOOL: Create a Tool instance from this executor
  ///
  /// Returns a Tool instance that can be used with the API client.
  Tool get asTool;
}

/// 🌤️ WEATHER TOOL EXECUTOR: Executes weather-related tool calls
///
/// Implements the ToolExecutor interface to provide weather functionality.
/// This is completely independent of any agent and can be used by any agent.
class WeatherToolExecutor implements ToolExecutor {
  /// 🌍 WEATHER DATA: Simulated weather information
  ///
  /// In a real application, this would be replaced with actual weather API calls.
  final Map<String, String> _weatherData;

  /// 🏗️ CONSTRUCTOR: Create new weather tool executor
  ///
  /// [weatherData] - Optional custom weather data to use
  WeatherToolExecutor({Map<String, String>? weatherData})
      : _weatherData = weatherData ?? {
            'Hangzhou': '24°C, Partly Cloudy',
            'San Francisco': '18°C, Foggy',
            'New York': '22°C, Sunny',
            'London': '15°C, Rainy',
            'Tokyo': '28°C, Clear',
            'Paris': '20°C, Cloudy',
            'Sydney': '25°C, Sunny',
            'Berlin': '16°C, Rainy',
            'Mumbai': '32°C, Hot and Humid',
            'Cairo': '30°C, Clear',
          };

  @override
  String get toolName => 'get_weather';

  @override
  String get toolDescription =>
      'Get weather of a location, the user should supply a location first';

  @override
  Map<String, dynamic> get toolParameters => {
        'type': 'object',
        'properties': {
          'location': {
            'type': 'string',
            'description': 'The city and state, e.g. San Francisco, CA',
          }
        },
        'required': ['location']
      };

  @override
  bool canExecute(ToolCall toolCall) {
    return toolCall.function.name == toolName;
  }

  @override
  Future<String> executeTool(ToolCall toolCall) async {
    if (!canExecute(toolCall)) {
      throw ArgumentError('This executor cannot handle tool: ${toolCall.function.name}');
    }

    try {
      // Parse the tool arguments
      final arguments = jsonDecode(toolCall.function.arguments);
      final location = arguments['location'] as String?;

      if (location == null) {
        return 'Error: No location provided for weather query';
      }

      // Get weather for the specified location
      return getWeather(location);
    } catch (e) {
      return 'Error parsing weather tool arguments: $e';
    }
  }

  /// 🌤️ GET WEATHER: Simulate weather API call
  ///
  /// [location] - The location to get weather for
  ///
  /// Returns simulated weather data for the specified location.
  /// In production, this would call an actual weather API.
  String getWeather(String location) {
    // Simulate API call delay
    Future.delayed(Duration(milliseconds: 100));
    
    return _weatherData[location] ?? 'Weather data unavailable for $location';
  }

  /// 🌍 ADD WEATHER LOCATION: Add custom weather data
  ///
  /// [location] - The location name
  /// [weather] - The weather description
  ///
  /// Allows adding custom weather data for testing or demonstration.
  void addWeatherLocation(String location, String weather) {
    _weatherData[location] = weather;
  }

  /// 📊 GET AVAILABLE LOCATIONS: List all available weather locations
  ///
  /// Returns a list of all locations with available weather data.
  List<String> getAvailableLocations() {
    return _weatherData.keys.toList();
  }

  /// 🔍 SEARCH WEATHER: Search for weather by partial location name
  ///
  /// [query] - Partial location name to search for
  ///
  /// Returns matching locations and their weather data.
  Map<String, String> searchWeather(String query) {
    final results = <String, String>{};
    final lowerQuery = query.toLowerCase();

    for (final entry in _weatherData.entries) {
      if (entry.key.toLowerCase().contains(lowerQuery)) {
        results[entry.key] = entry.value;
      }
    }

    return results;
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

/// 🔧 TOOL EXECUTOR REGISTRY: Manages multiple tool executors
///
/// Provides a centralized way to register and find tool executors.
/// This allows agents to use multiple tools without knowing their implementation details.
class ToolExecutorRegistry {
  final Map<String, ToolExecutor> _executors = {};

  /// 📝 REGISTER EXECUTOR: Add a tool executor to the registry
  ///
  /// [executor] - The tool executor to register
  ///
  /// Registers the executor so it can be found by tool name.
  void registerExecutor(ToolExecutor executor) {
    _executors[executor.toolName] = executor;
  }

  /// 🔍 FIND EXECUTOR: Find an executor for a specific tool call
  ///
  /// [toolCall] - The tool call to find an executor for
  ///
  /// Returns the appropriate executor or null if none found.
  ToolExecutor? findExecutor(ToolCall toolCall) {
    return _executors[toolCall.function.name];
  }

  /// 🛠️ EXECUTE TOOL: Execute a tool call using the appropriate executor
  ///
  /// [toolCall] - The tool call to execute
  ///
  /// Returns the result of the tool execution.
  /// Throws an exception if no executor is found.
  Future<String> executeTool(ToolCall toolCall) async {
    final executor = findExecutor(toolCall);
    if (executor == null) {
      throw Exception('No executor found for tool: ${toolCall.function.name}');
    }
    return await executor.executeTool(toolCall);
  }

  /// 📋 GET ALL TOOLS: Get all registered tools
  ///
  /// Returns a list of all registered tools that can be used with the API client.
  List<Tool> getAllTools() {
    return _executors.values.map((executor) => executor.asTool).toList();
  }

  /// 🔢 EXECUTOR COUNT: Get the number of registered executors
  ///
  /// Returns the total number of registered tool executors.
  int get executorCount => _executors.length;

  /// 🧹 CLEAR REGISTRY: Remove all registered executors
  ///
  /// Clears the registry of all tool executors.
  void clear() {
    _executors.clear();
  }
}
