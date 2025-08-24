import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'tool.dart';
import 'message.dart';
import 'tool_executor.dart';

/// 🌐 MCP CLIENT: Model Context Protocol Client Implementation
///
/// Provides communication with MCP servers to discover and execute tools.
/// Follows the MCP specification for tool discovery and execution.
///
/// 🎯 ARCHITECTURAL DECISIONS:
/// - Use Process communication for MCP server interaction
/// - JSON-RPC 2.0 protocol for message exchange
/// - Async/await for non-blocking operations
/// - Tool discovery on initialization for performance
class McpClient {
  /// 🔧 MCP SERVER PROCESS: The running MCP server instance
  Process? _process;

  /// 📝 SERVER CONFIG: Configuration for the MCP server
  final McpServerConfig _config;

  /// 🛠️ AVAILABLE TOOLS: Tools discovered from the MCP server
  final List<Tool> _tools = [];

  /// 🔢 REQUEST ID COUNTER: For JSON-RPC message identification
  int _requestId = 0;

  /// 📡 RESPONSE STREAM: Stream controller for MCP responses
  StreamController<String>? _responseController;

  /// 📋 RESPONSE QUEUE: Queue of responses waiting to be processed
  final List<String> _responseQueue = [];

  /// 🔄 RESPONSE TRACKER: Track responses for each request ID
  final Map<int, Completer<String>> _pendingRequests = {};

  /// 🔒 INITIALIZATION LOCK: Prevent multiple initializations
  bool _isInitialized = false;

  /// 🏗️ CONSTRUCTOR: Create new MCP client
  ///
  /// [config] - Configuration for the MCP server to connect to
  McpClient(this._config);

  /// 🚀 INITIALIZE: Start MCP server and discover tools
  ///
  /// Starts the MCP server process and discovers available tools.
  /// Must be called before using any tools.
  Future<void> initialize() async {
    if (_isInitialized) {
      throw Exception('MCP client already initialized');
    }

    try {
      // Start the MCP server process
      _process = await Process.start(
        _config.command,
        _config.args,
        environment: _config.env,
        workingDirectory: _config.workingDirectory,
      );

      // Set up logging from MCP server stderr
      _process!.stderr.transform(utf8.decoder).listen((data) {
        // Parse log level from MCP server output format: [timestamp] [level] message
        final lines = data.trim().split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          // Try to extract log level from format: [timestamp] [level] message
          final logLevelMatch = RegExp(r'\[.*?\]\s*\[(\w+)\]').firstMatch(line);
          if (logLevelMatch != null) {
            final level = logLevelMatch.group(1)?.toLowerCase() ?? 'info';
            final message = line.substring(logLevelMatch.end).trim();
            print('MCP Server ${level.toUpperCase()}: $message');
          } else {
            // Fallback for unformatted messages
            print('MCP Server LOG: $line');
          }
        }
      });

      // Set up response stream handling
      _responseController = StreamController<String>();

      // Listen to stdout and forward to response controller
      _process!.stdout.transform(utf8.decoder).transform(LineSplitter()).listen(
        (line) {
          if (line.trim().isNotEmpty) {
            _responseQueue.add(line);

            // Try to match response to pending request
            try {
              final responseData = jsonDecode(line) as Map<String, dynamic>;
              final responseId = responseData['id'];
              if (responseId != null) {
                final responseIdInt = int.tryParse(responseId.toString());
                if (responseIdInt != null &&
                    _pendingRequests.containsKey(responseIdInt)) {
                  final completer = _pendingRequests.remove(responseIdInt)!;
                  completer.complete(line);
                }
              }
            } catch (e) {
              // Ignore parsing errors for non-JSON lines
            }
          }
        },
        onError: (error) {
          print('MCP stdout error: $error');
        },
        onDone: () {
          // Don't auto-close the controller here
          // Let dispose() handle it explicitly
        },
      );

      // Wait for server to be ready
      await Future.delayed(Duration(milliseconds: 500));

      // Discover available tools
      await _discoverTools();

      _isInitialized = true;
      print('✅ MCP Client initialized with ${_tools.length} tools');
    } catch (e) {
      throw Exception('Failed to initialize MCP client: $e');
    }
  }

  /// 🔍 DISCOVER TOOLS: Get available tools from MCP server
  ///
  /// Discovers all available tools by calling the MCP server's
  /// tools/list method and converts them to Tool instances.
  /// Falls back to alternative discovery methods if needed.
  Future<void> _discoverTools() async {
    try {
      // Try standard MCP protocol first
      // Use 3-second timeout for tools list (should be VERY fast)
      final response =
          await _sendRequest('tools/list', {}, timeout: Duration(seconds: 3));

      if (response['result'] != null) {
        final toolsData = response['result']['tools'] as List?;
        if (toolsData != null) {
          print('🔍 Discovered ${toolsData.length} tools from MCP server');
          for (final toolData in toolsData) {
            try {
              final tool = _convertMcpToolToTool(toolData);
              _tools.add(tool);
              print('   ✅ Tool: ${tool.function.name}');
            } catch (e) {
              print('   ⚠️  Failed to convert tool: $e');
            }
          }
          return; // Success, exit early
        }
      }

      // Try alternative method names
      await _tryAlternativeDiscoveryMethods();
    } catch (e) {
      print('Warning: Standard MCP tool discovery failed: $e');
      print('Trying alternative discovery methods...');
      try {
        await _tryAlternativeDiscoveryMethods();
      } catch (e2) {
        // If alternative methods also fail, throw the original error
        throw Exception('MCP tool discovery failed: $e');
      }
    }
  }

  /// 🔍 TRY ALTERNATIVE DISCOVERY: Attempt alternative tool discovery methods
  ///
  /// Some MCP servers may use different method names or protocols.
  Future<void> _tryAlternativeDiscoveryMethods() async {
    final alternativeMethods = [
      'list_tools',
      'tools.list',
      'get_tools',
      'tools/get',
    ];

    for (final method in alternativeMethods) {
      try {
        print('🔍 Trying alternative method: $method');
        // Use 3-second timeout for alternative tool discovery methods
        final response =
            await _sendRequest(method, {}, timeout: Duration(seconds: 3));

        if (response['result'] != null) {
          final toolsData = response['result']['tools'] as List?;
          if (toolsData != null && toolsData.isNotEmpty) {
            print('🔍 Discovered ${toolsData.length} tools using $method');
            for (final toolData in toolsData) {
              try {
                final tool = _convertMcpToolToTool(toolData);
                _tools.add(tool);
                print('   ✅ Tool: ${tool.function.name}');
              } catch (e) {
                print('   ⚠️  Failed to convert tool: $e');
              }
            }
            return; // Success, exit early
          }
        }
      } catch (e) {
        print('   ⚠️  Method $method failed: $e');
        continue;
      }
    }

    print('⚠️  No tools discovered using any method');
    print(
        'This MCP server may not support tool discovery or uses a different protocol');

    // Instead of adding mock tools, throw an exception so the AI agent knows
    // that no tools are available and can handle this appropriately
    throw Exception(
        'No tools discovered from MCP server. Server may not support tool discovery or uses a different protocol.');
  }

  /// 🔄 CONVERT MCP TOOL: Convert MCP tool format to Tool instance
  ///
  /// [mcpTool] - Tool data from MCP server
  ///
  /// Converts MCP tool format to our internal Tool class format.
  Tool _convertMcpToolToTool(Map<String, dynamic> mcpTool) {
    final name = mcpTool['name'] as String;
    final description = mcpTool['description'] as String? ?? '';

    // Convert MCP input schema to OpenAI function parameters
    final inputSchema = mcpTool['inputSchema'] as Map<String, dynamic>? ?? {};
    final parameters = _convertMcpSchemaToOpenAiSchema(inputSchema);

    return Tool(
      function: FunctionObject(
        name: name,
        description: description,
        parameters: parameters,
      ),
    );
  }

  /// 🔄 CONVERT MCP SCHEMA: Convert MCP JSON Schema to OpenAI format
  ///
  /// [mcpSchema] - MCP input schema
  ///
  /// Converts MCP JSON Schema format to OpenAI function parameters format.
  Map<String, dynamic> _convertMcpSchemaToOpenAiSchema(
      Map<String, dynamic> mcpSchema) {
    // MCP uses standard JSON Schema, so conversion is mostly direct
    // We just ensure the format matches OpenAI's expectations
    return Map<String, dynamic>.from(mcpSchema);
  }

  /// 📤 SEND REQUEST: Send JSON-RPC request to MCP server
  ///
  /// [method] - RPC method name
  /// [params] - Method parameters
  ///
  /// Sends a JSON-RPC 2.0 request to the MCP server and waits for response.
  Future<Map<String, dynamic>> _sendRequest(
      String method, Map<String, dynamic> params,
      {Duration? timeout}) async {
    if (_process == null) {
      throw Exception('MCP client not initialized');
    }

    final request = {
      'jsonrpc': '2.0',
      'id': ++_requestId,
      'method': method,
      'params': params,
    };

    final requestJson = jsonEncode(request);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    print('🕐 [${timestamp}] 📤 MCP Request #${_requestId}: $method');
    print('   📋 Params: ${jsonEncode(params)}');
    _process!.stdin.writeln(requestJson);

    // Create a completer for this request
    final responseCompleter = Completer<String>();
    _pendingRequests[_requestId] = responseCompleter;

    try {
      // Wait for response with timeout (configurable for web research)
      // Use longer default timeout for tools that might involve web research
      final effectiveTimeout = timeout ?? Duration(seconds: 30);
      final response = await responseCompleter.future.timeout(effectiveTimeout);

      final responseTimestamp = DateTime.now().millisecondsSinceEpoch;
      final duration = responseTimestamp - timestamp;
      print(
          '🕐 [${responseTimestamp}] 📥 MCP Response #${_requestId}: ${duration}ms');
      print(
          '   📄 Result: ${response.length > 200 ? response.substring(0, 200) + '...' : response}');

      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      // Clean up the pending request
      _pendingRequests.remove(_requestId);

      if (e is TimeoutException) {
        throw Exception('MCP server response timeout for method: $method');
      }
      rethrow;
    }
  }

  /// 🛠️ EXECUTE TOOL: Execute a tool call via MCP server
  ///
  /// [toolName] - Name of the tool to execute
  /// [arguments] - Tool arguments as JSON string
  ///
  /// Executes a tool call by sending it to the MCP server and returning the result.
  /// Falls back to mock tool execution if MCP server fails.
  Future<String> executeTool(String toolName, String arguments,
      {Duration? timeout}) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    print('🔧 [${startTime}] EXECUTING TOOL: $toolName');
    print('   📝 Arguments: $arguments');

    try {
      // MCP protocol uses 'tools/call' method
      final params = {
        'name': toolName,
        'arguments': jsonDecode(arguments),
      };

      final response =
          await _sendRequest('tools/call', params, timeout: timeout);

      if (response['error'] != null) {
        throw Exception('MCP tool execution failed: ${response['error']}');
      }

      final responseResult = response['result'];
      if (responseResult != null && responseResult['content'] != null) {
        final content = responseResult['content'];
        if (content is List) {
          // MCP content is typically an array of content objects
          final textParts = <String>[];
          for (final item in content) {
            if (item is Map<String, dynamic>) {
              if (item['type'] == 'text' && item['text'] != null) {
                textParts.add(item['text'] as String);
              }
            }
          }
          if (textParts.isNotEmpty) {
            final toolResult = textParts.join('\n');
            final endTime = DateTime.now().millisecondsSinceEpoch;
            final duration = endTime - startTime;
            print('✅ [${endTime}] TOOL COMPLETED: $toolName (${duration}ms)');
            print('   📊 Result length: ${toolResult.length} characters');
            return toolResult;
          }
        }
        // Fallback to string representation
        final toolResult = content.toString();
        final endTime = DateTime.now().millisecondsSinceEpoch;
        final duration = endTime - startTime;
        print('✅ [${endTime}] TOOL COMPLETED: $toolName (${duration}ms)');
        return toolResult;
      } else if (responseResult != null && responseResult['isError'] == true) {
        return 'Tool execution error: ${responseResult['error'] ?? 'Unknown error'}';
      }

      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      print('✅ [${endTime}] TOOL COMPLETED: $toolName (${duration}ms)');
      return 'Tool executed successfully';
    } catch (e) {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final duration = endTime - startTime;
      print('❌ [${endTime}] TOOL FAILED: $toolName (${duration}ms)');
      print('⚠️  MCP tool execution failed: $e');
      // Re-throw the error instead of falling back to mock execution
      // This allows the AI agent to receive the actual error and correct itself
      rethrow;
    }
  }

  /// 📋 GET TOOLS: Get all available tools
  ///
  /// Returns a list of all tools discovered from the MCP server.
  List<Tool> get tools => List.unmodifiable(_tools);

  /// 🔢 TOOL COUNT: Get the number of available tools
  ///
  /// Returns the total number of tools available from the MCP server.
  int get toolCount => _tools.length;

  /// 🧹 CLEANUP: Stop MCP server process
  ///
  /// Stops the MCP server process and cleans up resources.
  Future<void> dispose() async {
    print('🧹 Disposing MCP client...');

    // Complete any pending requests with timeout errors
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('MCP client disposed');
      }
    }
    _pendingRequests.clear();

    if (_process != null) {
      print('   🚫 Killing MCP server process...');
      _process!.kill();
      _process = null;
      print('   ✅ Process killed');
    }

    if (_responseController != null) {
      print('   🔒 Closing response controller...');
      try {
        // Close with timeout to prevent hanging
        await _responseController!.close().timeout(Duration(seconds: 2));
        print('   ✅ Response controller closed');
      } catch (e) {
        print('   ⚠️  Response controller close timeout, forcing close');
        try {
          _responseController!.addError('Forced close');
        } catch (e) {
          // Ignore errors when forcing close
        }
      }
      _responseController = null;
    }

    _isInitialized = false;
    print('✅ MCP client disposed successfully');
  }
}

/// ⚙️ MCP SERVER CONFIG: Configuration for MCP server connection
///
/// Contains all necessary information to start and connect to an MCP server.
class McpServerConfig {
  /// 🎯 COMMAND: The command to execute (e.g., "npx", "node", "python")
  final String command;

  /// 📝 ARGUMENTS: Command line arguments
  final List<String> args;

  /// 🌍 ENVIRONMENT: Environment variables for the process
  final Map<String, String> env;

  /// 📁 WORKING DIRECTORY: Working directory for the process
  final String? workingDirectory;

  /// 🏗️ CONSTRUCTOR: Create new MCP server configuration
  ///
  /// [command] - Command to execute
  /// [args] - Command arguments
  /// [env] - Environment variables
  /// [workingDirectory] - Working directory (optional)
  const McpServerConfig({
    required this.command,
    required this.args,
    this.env = const {},
    this.workingDirectory,
  });

  /// 📥 FROM JSON: Create config from JSON data
  ///
  /// [json] - JSON data containing server configuration
  ///
  /// Creates an McpServerConfig instance from JSON configuration.
  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    return McpServerConfig(
      command: json['command'] as String,
      args: List<String>.from(json['args'] ?? []),
      env: Map<String, String>.from(json['env'] ?? {}),
      workingDirectory: json['workingDirectory'] as String?,
    );
  }

  /// 📤 TO JSON: Convert config to JSON format
  ///
  /// Returns the configuration as a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'args': args,
      'env': env,
      if (workingDirectory != null) 'workingDirectory': workingDirectory,
    };
  }
}

/// 🔧 MCP TOOL EXECUTOR: Executes MCP tool calls
///
/// Implements the ToolExecutor interface to provide MCP tool functionality.
/// This allows MCP tools to be used by any agent through the standard interface.
class McpToolExecutor implements ToolExecutor {
  /// 🌐 MCP CLIENT: The MCP client for server communication
  final McpClient _mcpClient;

  /// 📝 TOOL NAME: The name of the tool this executor handles
  final String _toolName;

  /// 📋 TOOL DESCRIPTION: Description of what the tool does
  final String _toolDescription;

  /// 🎯 TOOL PARAMETERS: JSON Schema for tool parameters
  final Map<String, dynamic> _toolParameters;

  /// 🏗️ CONSTRUCTOR: Create new MCP tool executor
  ///
  /// [mcpClient] - MCP client for server communication
  /// [tool] - Tool definition from MCP server
  McpToolExecutor(this._mcpClient, Tool tool)
      : _toolName = tool.function.name,
        _toolDescription = tool.function.description,
        _toolParameters = tool.function.parameters;

  @override
  String get toolName => _toolName;

  @override
  String get toolDescription => _toolDescription;

  @override
  Map<String, dynamic> get toolParameters => _toolParameters;

  @override
  bool canExecute(ToolCall toolCall) {
    return toolCall.function.name == _toolName;
  }

  @override
  Future<String> executeTool(ToolCall toolCall, {Duration? timeout}) async {
    if (!canExecute(toolCall)) {
      return 'Error: This executor cannot handle tool: ${toolCall.function.name}';
    }

    try {
      final result = await _mcpClient.executeTool(
          _toolName, toolCall.function.arguments,
          timeout: timeout);
      return result;
    } catch (e) {
      // Re-throw the error instead of returning a string
      // This allows the AI agent to receive the actual error and correct itself
      rethrow;
    }
  }

  @override
  Tool get asTool => Tool(
        function: FunctionObject(
          name: _toolName,
          description: _toolDescription,
          parameters: _toolParameters,
        ),
      );
}
