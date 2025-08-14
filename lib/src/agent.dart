import 'api_client.dart';
import 'message.dart';
import 'tool_executor.dart';

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
  ToolExecutorRegistry toolRegistry;

  /// 🌐 API CLIENT: HTTP client for API communication
  ///
  /// Handles all HTTP requests to the AI service endpoint.
  ApiClient apiClient;

  /// 🎯 SYSTEM PROMPT: AI behavior instructions
  ///
  /// Defines the AI's role, personality, and behavior guidelines.
  /// Inserted as the first message in every conversation.
  String systemPrompt;

  /// 📝 LAST MESSAGE: Most recent message content
  ///
  /// Convenience getter for accessing the latest message.
  /// Returns empty string if no content or no messages.
  String get lastMessage => messages.isEmpty ? '' : (messages.last.content ?? '');

  /// 📚 CONVERSATION HISTORY: Get all messages in the conversation
  ///
  /// Returns a copy of the conversation history.
  List<Message> get conversationHistory => List.unmodifiable(messages);

  /// 🔢 MESSAGE COUNT: Get the total number of messages
  ///
  /// Returns the current message count.
  int get messageCount => messages.length;

  /// 🧹 CLEAR CONVERSATION: Reset conversation history
  ///
  /// Clears all messages except system prompt.
  void clearConversation() {
    messages.removeWhere((msg) => msg.role != 'system');
  }

  /// 🚀 SEND MESSAGE: Process user input and get AI response
  ///
  /// [message] - User's input message
  ///
  /// Returns the AI's response message.
  /// Automatically manages system prompts and conversation state.
  /// Handles tool calls automatically if the AI requests them.
  Future<Message> sendMessage(String message) async {
    // Remove any existing system messages to ensure only one system prompt
    messages.removeWhere((msg) => msg.role == 'system');

    // Prepend system prompt at the beginning
    messages.insert(0, Message.system(content: systemPrompt));

    // Add user message
    messages.add(Message.user(content: message));

    // Get AI response
    final response =
        await apiClient.sendMessage(messages, toolRegistry.getAllTools());
    messages.add(response);

    // Check if the AI wants to call tools
    if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
      // Execute all requested tools
      await _executeToolCalls(response.toolCalls!);

      // Get final response after tool execution
      final finalResponse =
          await apiClient.sendMessage(messages, toolRegistry.getAllTools());
      messages.add(finalResponse);
      return finalResponse;
    }

    return response;
  }

  /// 🛠️ EXECUTE TOOL CALLS: Execute requested tools and add results to conversation
  ///
  /// [toolCalls] - List of tool calls to execute
  ///
  /// Executes each tool call using the tool executor registry.
  Future<void> _executeToolCalls(List<ToolCall> toolCalls) async {
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

  /// 🏗️ CONSTRUCTOR: Create new agent instance
  ///
  /// [apiClient] - HTTP client for API communication
  /// [toolRegistry] - Registry of available tool executors
  /// [messages] - Initial conversation messages
  /// [systemPrompt] - AI behavior instructions
  Agent({
    required this.apiClient,
    required this.toolRegistry,
    required this.messages,
    required this.systemPrompt,
  });
}
