import 'dart:convert';
import 'dart:io';
import 'message.dart';
import 'tool.dart';
import 'mcp_client.dart';
import 'mcp_server_manager.dart';

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
      : _weatherData = weatherData ??
            {
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
      throw ArgumentError(
          'This executor cannot handle tool: ${toolCall.function.name}');
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
abstract class ToolExecutorRegistry {
  /// 🔒 EXECUTORS: Map of tool names to their executors
  ///
  /// This field is public to allow subclasses to access it.
  /// Use the public methods instead of accessing this directly.
  Map<String, ToolExecutor> get executors;

  /// 📝 REGISTER EXECUTOR: Add a tool executor to the registry
  ///
  /// [executor] - The tool executor to register
  ///
  /// Registers the executor so it can be found by tool name.
  void registerExecutor(ToolExecutor executor) {
    executors[executor.toolName] = executor;
  }

  /// 🔍 FIND EXECUTOR: Find an executor for a specific tool call
  ///
  /// [toolCall] - The tool call to find an executor for
  ///
  /// Returns the appropriate executor or null if none found.
  ToolExecutor? findExecutor(ToolCall toolCall) {
    return executors[toolCall.function.name];
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
    return executors.values.map((executor) => executor.asTool).toList();
  }

  /// 🔢 EXECUTOR COUNT: Get the number of registered executors
  ///
  /// Returns the total number of registered tool executors.
  int get executorCount => executors.length;

  /// 🧹 CLEAR REGISTRY: Remove all registered executors
  ///
  /// Clears the registry of all tool executors.
  void clear() {
    executors.clear();
  }
}

/// 🚀 MCP TOOL EXECUTOR REGISTRY: Registry with MCP server management
///
/// Extends ToolExecutorRegistry to automatically load and manage MCP servers
/// from a configuration file. Provides the API needed by the accounting workflow.
class McpToolExecutorRegistry extends ToolExecutorRegistry {
  /// 📁 MCP CONFIG FILE: Configuration file for MCP servers
  final File mcpConfig;

  /// 🔒 EXECUTORS: Map of tool names to their executors
  ///
  /// This field stores all registered tool executors.
  final Map<String, ToolExecutor> _executors = {};

  @override
  Map<String, ToolExecutor> get executors => _executors;

  /// 🌐 MCP CLIENTS: Active MCP client instances
  final List<McpClient> _mcpClients = [];

  /// 🔒 INITIALIZATION FLAG: Track if registry has been initialized
  bool _isInitialized = false;

  /// 🏗️ CONSTRUCTOR: Create new MCP tool executor registry
  ///
  /// [mcpConfig] - Configuration file containing MCP server definitions
  McpToolExecutorRegistry({required this.mcpConfig});

  /// 🚀 INITIALIZE: Load and start MCP servers from configuration
  ///
  /// Reads the MCP configuration file, starts all configured servers,
  /// and registers their tools as executors.
  Future<void> initialize() async {
    if (_isInitialized) {
      throw Exception('MCP ToolExecutorRegistry already initialized');
    }

    try {
      print('🔧 Initializing MCP ToolExecutorRegistry...');

      // Read and parse MCP configuration
      final configContent = await mcpConfig.readAsString();
      final config = jsonDecode(configContent) as Map<String, dynamic>;
      final mcpServers = config['mcpServers'] as Map<String, dynamic>?;

      if (mcpServers == null || mcpServers.isEmpty) {
        print('⚠️  No MCP servers found in configuration');
        _isInitialized = true;
        return;
      }

      print('🔍 Found ${mcpServers.length} MCP servers in configuration');

      // Initialize each MCP server
      for (final entry in mcpServers.entries) {
        final serverName = entry.key;
        final serverConfig = entry.value as Map<String, dynamic>;

        try {
          print('🚀 Initializing MCP server: $serverName');

          // Create MCP server configuration
          final mcpServerConfig = McpServerConfig.fromJson(serverConfig);

          // Get or create MCP client
          final mcpClient =
              await mcpServerManager.getOrCreateServer(mcpServerConfig);
          _mcpClients.add(mcpClient);

          // Register tools from this MCP server
          for (final tool in mcpClient.tools) {
            final executor = McpToolExecutor(mcpClient, tool);
            registerExecutor(executor);
            print('   ✅ Registered tool: ${tool.function.name}');
          }

          print(
              '✅ MCP server $serverName initialized with ${mcpClient.toolCount} tools');
        } catch (e) {
          print('❌ Failed to initialize MCP server $serverName: $e');
        }
      }

      _isInitialized = true;
      print(
          '🎉 MCP ToolExecutorRegistry initialized with ${getAllTools().length} total tools');
    } catch (e) {
      // Mark as initialized even if initialization fails to prevent double initialization
      _isInitialized = true;
      throw Exception('Failed to initialize MCP ToolExecutorRegistry: $e');
    }
  }

  /// 🧹 SHUTDOWN: Clean up all MCP servers and resources
  ///
  /// Releases all MCP server instances and cleans up resources.
  Future<void> shutdown() async {
    if (!_isInitialized) {
      return;
    }

    print('🧹 Shutting down MCP ToolExecutorRegistry...');

    // Clear all executors
    clear();

    // Release all MCP clients
    for (final client in _mcpClients) {
      try {
        // Find the config for this client and release it
        // Note: This is a simplified approach - in a real implementation,
        // we'd need to track which config each client was created from
        await mcpServerManager.releaseServer(
            McpServerConfig(command: '', args: []), // Placeholder
            client);
      } catch (e) {
        print('⚠️  Error releasing MCP client: $e');
      }
    }

    _mcpClients.clear();
    _isInitialized = false;

    print('✅ MCP ToolExecutorRegistry shut down');
  }

  /// 📋 GET ALL TOOLS: Get all registered tools (alias for compatibility)
  ///
  /// Returns a list of all registered tools that can be used with the API client.
  List<Tool> get allTools => getAllTools();

  /// 🔢 TOOL COUNT: Get the number of available tools
  ///
  /// Returns the total number of tools available from all MCP servers.
  int get toolCount => getAllTools().length;

  /// 📊 STATUS: Get current registry status
  ///
  /// Returns status information about the registry and MCP servers.
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'executorCount': executorCount,
      'toolCount': toolCount,
      'mcpClientCount': _mcpClients.length,
      'mcpServerStatus': mcpServerManager.getStatus(),
    };
  }

  /// 🔒 CREATE FILTERED REGISTRY: Create a filtered view of this registry
  ///
  /// [allowedToolNames] - Set of tool names to allow (null = all tools)
  ///
  /// Returns a FilteredToolExecutorRegistry that only exposes the specified tools.
  /// This allows agents to have customized tool sets while maintaining full access
  /// to all tools in the underlying registry.
  FilteredToolExecutorRegistry createFilteredRegistry(
      Set<String>? allowedToolNames) {
    return FilteredToolExecutorRegistry(
      sourceRegistry: this,
      allowedToolNames: allowedToolNames,
    );
  }
}

/// 🔒 FILTERED TOOL EXECUTOR REGISTRY: Registry that filters tools from another registry
///
/// Wraps another ToolExecutorRegistry and only exposes tools with names in the
/// allowedToolNames set. This allows agents to have customized tool sets while
/// maintaining full access to all tools in the source registry.
///
/// 🎯 ARCHITECTURAL DECISIONS:
/// - Use composition over inheritance for flexible tool filtering
/// - Maintain full access to source registry for tool execution
/// - Support null allowedToolNames for "all tools" access
/// - Preserve all registry functionality while filtering tool discovery
class FilteredToolExecutorRegistry extends ToolExecutorRegistry {
  /// 🗄️ SOURCE REGISTRY: The underlying registry containing all tools
  final ToolExecutorRegistry sourceRegistry;

  /// 🔒 EXECUTORS: Map of tool names to their executors
  ///
  /// This field is not used directly but is required by the abstract class.
  /// All operations delegate to the source registry.
  @override
  Map<String, ToolExecutor> get executors => sourceRegistry.executors;

  /// 🔒 ALLOWED TOOL NAMES: Tools this filtered registry can access
  ///
  /// If null, all tools are accessible (no filtering).
  /// If provided, only tools with names in this set are accessible.
  final Set<String>? allowedToolNames;

  /// 🏗️ CONSTRUCTOR: Create new filtered tool executor registry
  ///
  /// [sourceRegistry] - The underlying registry to filter
  /// [allowedToolNames] - Optional set of allowed tool names (null = all tools)
  FilteredToolExecutorRegistry({
    required this.sourceRegistry,
    this.allowedToolNames,
  });

  /// 🛠️ EXECUTE TOOL: Execute a tool call using the appropriate executor
  ///
  /// [toolCall] - The tool call to execute
  ///
  /// Returns the result of the tool execution.
  /// Throws an exception if no executor is found or tool is not accessible.
  Future<String> executeTool(ToolCall toolCall) async {
    // Validate tool access before execution
    if (allowedToolNames != null &&
        !allowedToolNames!.contains(toolCall.function.name)) {
      throw ArgumentError(
          'Tool ${toolCall.function.name} is not accessible in this filtered registry. '
          'Allowed tools: ${allowedToolNames!.join(', ')}');
    }

    // Execute using source registry (which has full access to all tools)
    return await sourceRegistry.executeTool(toolCall);
  }

  /// 📝 REGISTER EXECUTOR: Add a tool executor to the source registry
  ///
  /// [executor] - The tool executor to register
  ///
  /// Delegates to the source registry for registration.
  void registerExecutor(ToolExecutor executor) {
    // Delegate to source registry for registration
    sourceRegistry.registerExecutor(executor);
  }

  /// 🔍 FIND EXECUTOR: Find an executor for a specific tool call
  ///
  /// [toolCall] - The tool call to find an executor for
  ///
  /// Returns the appropriate executor or null if none found or tool not accessible.
  ToolExecutor? findExecutor(ToolCall toolCall) {
    if (allowedToolNames != null &&
        !allowedToolNames!.contains(toolCall.function.name)) {
      return null; // Tool not accessible in this filtered view
    }
    return sourceRegistry.findExecutor(toolCall);
  }

  /// 📋 GET ALL TOOLS: Get all accessible tools
  ///
  /// Returns a filtered list of tools based on allowedToolNames.
  /// If allowedToolNames is null, returns all tools.
  List<Tool> getAllTools() {
    final allTools = sourceRegistry.getAllTools();

    if (allowedToolNames == null) {
      return allTools; // No filtering
    }

    // Filter tools based on allowed names
    return allTools
        .where((tool) => allowedToolNames!.contains(tool.function.name))
        .toList();
  }

  /// 🔢 EXECUTOR COUNT: Get the number of accessible executors
  ///
  /// Returns the total number of executors this filtered registry can access.
  int get executorCount {
    if (allowedToolNames == null) {
      return sourceRegistry.executorCount;
    }

    // Count only allowed executors by filtering the tools
    return getAllTools().length;
  }

  /// 🧹 CLEAR REGISTRY: Clear all executors from source registry
  ///
  /// Delegates to the source registry.
  void clear() {
    // Delegate to source registry
    sourceRegistry.clear();
  }

  /// 🔍 GET SOURCE REGISTRY: Access the underlying source registry
  ///
  /// Returns the source registry that contains all tools.
  /// This allows advanced users to bypass filtering when needed.
  ToolExecutorRegistry get source => sourceRegistry;

  /// 🔒 GET ALLOWED TOOL NAMES: Get the set of allowed tool names
  ///
  /// Returns the set of tool names this filtered registry allows.
  /// Returns null if no filtering is applied.
  Set<String>? get allowedTools => allowedToolNames;

  /// 📊 STATUS: Get current filtered registry status
  ///
  /// Returns status information about the filtered registry.
  Map<String, dynamic> getStatus() {
    return {
      'type': 'FilteredToolExecutorRegistry',
      'allowedToolCount':
          allowedToolNames?.length ?? sourceRegistry.executorCount,
      'sourceRegistryType': sourceRegistry.runtimeType.toString(),
      'sourceRegistryStatus': sourceRegistry is McpToolExecutorRegistry
          ? (sourceRegistry as McpToolExecutorRegistry).getStatus()
          : {'executorCount': sourceRegistry.executorCount},
      'filteringEnabled': allowedToolNames != null,
      'allowedToolNames': allowedToolNames?.toList() ?? ['ALL_TOOLS'],
    };
  }
}
