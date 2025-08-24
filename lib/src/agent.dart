import 'api_client.dart';
import 'message.dart';
import 'tool_executor.dart';
import 'tool.dart';

/// 🤖 AGENT: AI conversation agent with tool calling capabilities
///
/// Manages conversation state and coordinates between user input,
/// system prompts, and API responses. Supports function calling
/// via tools for enhanced AI capabilities.
class Agent {
  /// 💬 MESSAGES: Conversation history
  ///
  /// Maintains the complete conversation thread including
  /// system prompts, user messages, and assistant responses.
  List<Message> messages;

  /// 🛠️ TOOL EXECUTOR REGISTRY: Registry of available tool executors
  ///
  /// Contains all the tool executors that the AI can use during conversations.
  /// Each executor handles a specific type of tool call.
  /// Can be a full registry or a filtered registry for customized tool access.
  final ToolExecutorRegistry toolRegistry;

  /// 🌐 API CLIENT: HTTP client for API communication
  ///
  /// Handles all HTTP requests to the AI service endpoint.
  ApiClient apiClient;

  /// 🎯 SYSTEM PROMPT: AI behavior instructions
  ///
  /// Defines the AI's role, personality, and behavior guidelines.
  /// Inserted as the first message in every conversation.
  String systemPrompt;

  /// ⚙️ API CONFIG: Configuration for chat completion requests
  ///
  /// Controls temperature, max tokens, penalties, and other API parameters.
  /// Can be overridden per message for dynamic behavior control.
  ChatCompletionConfig apiConfig;

  /// 🔒 ALLOWED TOOL NAMES: Tools this agent can access
  ///
  /// If null, agent can access all tools in the registry.
  /// If provided, agent can only access tools with names in this list.
  final Set<String>? allowedToolNames;

  /// 📝 LAST MESSAGE: Most recent message content
  ///
  /// Convenience getter for accessing the latest message.
  /// Returns empty string if no content or no messages.
  String get lastMessage =>
      messages.isEmpty ? '' : (messages.last.content ?? '');

  /// 📚 CONVERSATION HISTORY: Get all messages in the conversation
  ///
  /// Returns a copy of the conversation history.
  List<Message> get conversationHistory => List.unmodifiable(messages);

  /// 🔢 MESSAGE COUNT: Get the total number of messages
  ///
  /// Returns the current message count.
  int get messageCount => messages.length;

  /// 🌡️ TEMPERATURE: Get or set the temperature for response randomness
  ///
  /// Range: 0.0 to 2.0
  /// Higher values (0.8+) = more random/creative responses
  /// Lower values (0.2-) = more focused/deterministic responses
  double get temperature => apiConfig.temperature;
  set temperature(double value) {
    apiConfig = apiConfig.copyWith(temperature: value);
  }

  /// 📏 MAX TOKENS: Get or set the maximum tokens for responses
  ///
  /// Range: 1 to 8192
  /// Controls the maximum length of generated responses
  int get maxTokens => apiConfig.maxTokens;
  set maxTokens(int value) {
    apiConfig = apiConfig.copyWith(maxTokens: value);
  }

  /// 🔄 FREQUENCY PENALTY: Get or set the frequency penalty
  ///
  /// Range: -2.0 to 2.0
  /// Positive values penalize repeated tokens
  double get frequencyPenalty => apiConfig.frequencyPenalty;
  set frequencyPenalty(double value) {
    apiConfig = apiConfig.copyWith(frequencyPenalty: value);
  }

  /// 🆕 PRESENCE PENALTY: Get or set the presence penalty
  ///
  /// Range: -2.0 to 2.0
  /// Positive values encourage new topics
  double get presencePenalty => apiConfig.presencePenalty;
  set presencePenalty(double value) {
    apiConfig = apiConfig.copyWith(presencePenalty: value);
  }

  /// 🔝 TOP P: Get or set the top-p nucleus sampling parameter
  ///
  /// Range: 0.0 to 1.0
  /// Alternative to temperature for controlling randomness
  double get topP => apiConfig.topP;
  set topP(double value) {
    apiConfig = apiConfig.copyWith(topP: value);
  }

  /// 🧹 CLEAR CONVERSATION: Reset conversation history
  ///
  /// Clears all messages except system prompt.
  void clearConversation() {
    messages.removeWhere((msg) => msg.role != 'system');
  }

  /// 🔍 GET FILTERED TOOLS: Get tools this agent can access
  ///
  /// Returns a filtered list of tools based on allowedToolNames.
  /// If allowedToolNames is null, returns all tools.
  List<Tool> getFilteredTools() {
    final allTools = toolRegistry.getAllTools();

    if (allowedToolNames == null) {
      return allTools;
    }

    return allTools
        .where((tool) => allowedToolNames!.contains(tool.function.name))
        .toList();
  }

  /// 🛠️ VALIDATE TOOL ACCESS: Validate that agent can access requested tools
  ///
  /// [toolCalls] - List of tool calls to validate
  ///
  /// Throws ArgumentError if agent tries to access unauthorized tools.
  void validateToolAccess(List<ToolCall> toolCalls) {
    if (allowedToolNames == null) {
      return; // Agent can access all tools
    }

    final unauthorizedTools = <String>[];

    for (final toolCall in toolCalls) {
      if (!allowedToolNames!.contains(toolCall.function.name)) {
        unauthorizedTools.add(toolCall.function.name);
      }
    }

    if (unauthorizedTools.isNotEmpty) {
      throw ArgumentError(
          'Agent is not authorized to use tools: ${unauthorizedTools.join(', ')}. '
          'Allowed tools: ${allowedToolNames!.join(', ')}');
    }
  }

  /// 🚀 SEND MESSAGE: Process user input and get AI response
  ///
  /// [message] - User's input message
  /// [config] - Optional configuration override for this specific message
  ///
  /// Returns the AI's response message.
  /// Automatically manages system prompts and conversation state.
  /// Handles tool calls automatically if the AI requests them.
  Future<Message> sendMessage(
    String message, {
    ChatCompletionConfig? config,
  }) async {
    // Remove any existing system messages to ensure only one system prompt
    messages.removeWhere((msg) => msg.role == 'system');

    // Prepend system prompt at the beginning
    messages.insert(0, Message.system(content: systemPrompt));

    // Add user message
    messages.add(Message.user(content: message));

    // Continue processing tool calls until the AI provides a final response
    Message currentResponse;
    int toolCallRounds = 0;
    const maxToolCallRounds = 40; // Increased for multi-supplier research

    do {
      // Get AI response with optional config override
      // Use filtered tools based on agent's permissions
      currentResponse = await apiClient.sendMessage(
        messages,
        getFilteredTools(),
        config: config ?? apiConfig,
      );
      messages.add(currentResponse);

      // Check if the AI wants to call tools
      if (currentResponse.toolCalls != null &&
          currentResponse.toolCalls!.isNotEmpty) {
        toolCallRounds++;
        if (toolCallRounds > maxToolCallRounds) {
          // Clean up incomplete tool call state before throwing
          _cleanupIncompleteToolCalls(currentResponse.toolCalls!);
          throw Exception(
              'Maximum tool call rounds exceeded. The AI seems to be stuck in a tool calling loop.');
        }

        // Validate tool access before execution
        validateToolAccess(currentResponse.toolCalls!);

        // Execute all requested tools
        await executeToolCalls(currentResponse.toolCalls!);
      }
    } while (currentResponse.toolCalls != null &&
        currentResponse.toolCalls!.isNotEmpty);

    return currentResponse;
  }

  /// 🛠️ EXECUTE TOOL CALLS: Execute requested tools and add results to conversation
  ///
  /// [toolCalls] - List of tool calls to execute
  ///
  /// Executes each tool call using the tool executor registry.
  Future<void> executeToolCalls(List<ToolCall> toolCalls) async {
    for (final toolCall in toolCalls) {
      try {
        // Execute the tool using the registry
        final result = await toolRegistry.executeTool(toolCall);

        // Add tool result to conversation
        messages.add(Message.toolResult(
          toolCallId: toolCall.id,
          content: result,
        ));
      } catch (e) {
        // Handle tool execution errors gracefully
        final errorMessage = 'Tool execution failed: $e';
        messages.add(Message.toolResult(
          toolCallId: toolCall.id,
          content: errorMessage,
        ));
      }
    }
  }

  /// 🧹 CLEANUP INCOMPLETE TOOL CALLS: Clean up tool call state when max rounds exceeded
  ///
  /// [toolCalls] - List of tool calls that couldn't be completed
  ///
  /// Adds error responses for incomplete tool calls to prevent context pollution
  /// and ensure the AI understands why tool execution was terminated.
  void _cleanupIncompleteToolCalls(List<ToolCall> toolCalls) {
    for (final toolCall in toolCalls) {
      // Add error response for each incomplete tool call
      messages.add(Message.toolResult(
        toolCallId: toolCall.id,
        content: 'ERROR: Tool execution terminated - maximum tool call rounds exceeded. '
                'The AI was stuck in a tool calling loop and execution was stopped to prevent '
                'context window overflow and infinite loops.',
      ));
    }
    
    // Add a final assistant message explaining the situation
    messages.add(Message.assistant(
      content: '⚠️  SYSTEM INTERVENTION: Maximum tool call rounds (40) exceeded. '
              'Tool execution has been terminated to prevent infinite loops and context overflow. '
              'Please simplify your request or break it into smaller steps.',
    ));
  }

  /// ⚙️ UPDATE API CONFIG: Update the agent's API configuration
  ///
  /// [config] - New configuration to apply
  ///
  /// Updates the agent's default API configuration for future messages.
  void updateApiConfig(ChatCompletionConfig config) {
    apiConfig = config;
  }

  /// 🔄 COPY API CONFIG: Create a copy of current config with modifications
  ///
  /// [temperature] - Optional temperature override
  /// [maxTokens] - Optional max tokens override
  /// [frequencyPenalty] - Optional frequency penalty override
  /// [presencePenalty] - Optional presence penalty override
  /// [topP] - Optional top_p override
  /// [stop] - Optional stop sequences override
  /// [logprobs] - Optional logprobs override
  /// [topLogprobs] - Optional top_logprobs override
  ///
  /// Returns a new configuration with the specified parameters changed.
  ChatCompletionConfig copyApiConfig({
    double? temperature,
    int? maxTokens,
    double? frequencyPenalty,
    double? presencePenalty,
    double? topP,
    List<String>? stop,
    bool? logprobs,
    int? topLogprobs,
  }) {
    return apiConfig.copyWith(
      temperature: temperature,
      maxTokens: maxTokens,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      topP: topP,
      stop: stop,
      logprobs: logprobs,
      topLogprobs: topLogprobs,
    );
  }

  /// 🏗️ CONSTRUCTOR: Create new agent instance
  ///
  /// [apiClient] - HTTP client for API communication
  /// [toolRegistry] - Registry of available tool executors
  /// [messages] - Initial conversation messages (defaults to empty list)
  /// [systemPrompt] - AI behavior instructions
  /// [apiConfig] - Configuration for API parameters (uses sensible defaults if not provided)
  /// [allowedToolNames] - Optional list of tool names this agent can access (null = all tools)
  Agent({
    required this.apiClient,
    required this.toolRegistry,
    List<Message>? messages,
    required this.systemPrompt,
    ChatCompletionConfig? apiConfig,
    Set<String>? allowedToolNames,
  })  : messages = messages ?? [],
        apiConfig = apiConfig ?? const ChatCompletionConfig(),
        allowedToolNames = allowedToolNames {
    // Validate that all allowed tool names exist in the registry
    if (allowedToolNames != null) {
      final availableTools =
          toolRegistry.getAllTools().map((tool) => tool.function.name).toSet();

      final invalidTools = allowedToolNames.difference(availableTools);
      if (invalidTools.isNotEmpty) {
        throw ArgumentError(
            'Agent cannot access tools that do not exist in registry: '
            '${invalidTools.join(', ')}. '
            'Available tools: ${availableTools.join(', ')}');
      }
    }
  }

  /// 🏗️ FACTORY CONSTRUCTOR: Create agent with filtered tool access
  ///
  /// [apiClient] - HTTP client for API communication
  /// [toolRegistry] - Full registry containing all available tools
  /// [messages] - Initial conversation messages (defaults to empty list)
  /// [systemPrompt] - AI behavior instructions
  /// [apiConfig] - Configuration for API parameters (uses sensible defaults if not provided)
  /// [allowedToolNames] - Set of tool names this agent can access (null = all tools)
  ///
  /// Creates a filtered view of the tool registry and creates an agent with access
  /// only to the specified tools. This is the recommended approach for creating
  /// agents with customized tool sets.
  factory Agent.withFilteredTools({
    required ApiClient apiClient,
    required ToolExecutorRegistry toolRegistry,
    List<Message>? messages,
    required String systemPrompt,
    ChatCompletionConfig? apiConfig,
    Set<String>? allowedToolNames,
  }) {
    // Create filtered registry if tool filtering is requested
    final effectiveRegistry = allowedToolNames != null
        ? _createFilteredRegistry(toolRegistry, allowedToolNames)
        : toolRegistry;

    return Agent(
      apiClient: apiClient,
      toolRegistry: effectiveRegistry,
      messages: messages,
      systemPrompt: systemPrompt,
      apiConfig: apiConfig,
      allowedToolNames: null, // No additional filtering needed
    );
  }

  /// 🔒 CREATE FILTERED REGISTRY: Create a filtered registry for tool access control
  ///
  /// [toolRegistry] - The source registry to filter
  /// [allowedToolNames] - Set of tool names to allow
  ///
  /// Returns a filtered registry that only exposes the specified tools.
  /// This is a private helper method for the factory constructor.
  static ToolExecutorRegistry _createFilteredRegistry(
    ToolExecutorRegistry toolRegistry,
    Set<String> allowedToolNames,
  ) {
    // Check if the registry already supports filtering
    if (toolRegistry is McpToolExecutorRegistry) {
      return toolRegistry.createFilteredRegistry(allowedToolNames);
    }

    // For other registry types, create a generic filtered wrapper
    return FilteredToolExecutorRegistry(
      sourceRegistry: toolRegistry,
      allowedToolNames: allowedToolNames,
    );
  }
}
