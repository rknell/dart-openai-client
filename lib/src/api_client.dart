import 'dart:convert';

import 'package:http/http.dart' as http;

import 'tool.dart';
import 'message.dart';

/// ⚙️ CHAT COMPLETION CONFIG: Configuration for chat completion requests
///
/// Contains all configurable parameters for the chat completion API.
/// Follows the DeepSeek API specification with sensible defaults.
class ChatCompletionConfig {
  /// 🎯 MODEL: ID of the model to use
  ///
  /// Default: "deepseek-chat"
  /// Possible values: ["deepseek-chat", "deepseek-reasoner"]
  final String model;

  /// 🌡️ TEMPERATURE: Sampling temperature for response randomness
  ///
  /// Range: 0 to 2, Default: 1
  /// Higher values (0.8) = more random, Lower values (0.2) = more focused
  final double temperature;

  /// 🔝 TOP_P: Nucleus sampling parameter
  ///
  /// Range: 0 to 1, Default: 1
  /// Alternative to temperature - consider tokens with top_p probability mass
  final double topP;

  /// 📏 MAX_TOKENS: Maximum tokens to generate
  ///
  /// Range: 1 to 8192, Default: 4096
  /// Total input + generated tokens limited by model context length
  final int maxTokens;

  /// 🔄 FREQUENCY_PENALTY: Penalize token frequency
  ///
  /// Range: -2 to 2, Default: 0
  /// Positive values penalize repeated tokens
  final double frequencyPenalty;

  /// 🆕 PRESENCE_PENALTY: Penalize token presence
  ///
  /// Range: -2 to 2, Default: 0
  /// Positive values encourage new topics
  final double presencePenalty;

  /// 🛑 STOP: Stop sequences for generation
  ///
  /// Optional stop sequences to halt generation
  final List<String>? stop;

  /// 📊 LOGPROBS: Return log probabilities
  ///
  /// Whether to return log probabilities of output tokens
  final bool logprobs;

  /// 🔝 TOP_LOGPROBS: Number of top log probabilities
  ///
  /// Range: 0 to 20, Default: null
  /// Number of most likely tokens to return with log probabilities
  final int? topLogprobs;

  /// 🏗️ CONSTRUCTOR: Create new configuration instance
  ///
  /// All parameters are optional with sensible defaults
  const ChatCompletionConfig({
    this.model = 'deepseek-chat',
    this.temperature = 1.0,
    this.topP = 1.0,
    this.maxTokens = 4096,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.stop,
    this.logprobs = false,
    this.topLogprobs,
  });

  /// 🔍 VALIDATE: Ensure all parameters are within valid ranges
  ///
  /// Throws ArgumentError if any parameter is invalid
  void validate() {
    if (temperature < 0 || temperature > 2) {
      throw ArgumentError('Temperature must be between 0 and 2, got: $temperature');
    }
    if (topP < 0 || topP > 1) {
      throw ArgumentError('top_p must be between 0 and 1, got: $topP');
    }
    if (maxTokens < 1 || maxTokens > 8192) {
      throw ArgumentError('max_tokens must be between 1 and 8192, got: $maxTokens');
    }
    if (frequencyPenalty < -2 || frequencyPenalty > 2) {
      throw ArgumentError('frequency_penalty must be between -2 and 2, got: $frequencyPenalty');
    }
    if (presencePenalty < -2 || presencePenalty > 2) {
      throw ArgumentError('presence_penalty must be between -2 and 2, got: $presencePenalty');
    }
    if (topLogprobs != null && (topLogprobs! < 0 || topLogprobs! > 20)) {
      throw ArgumentError('top_logprobs must be between 0 and 20, got: $topLogprobs');
    }
  }

  /// 📋 TO JSON: Convert configuration to API request format
  ///
  /// Returns a Map suitable for JSON encoding in API requests
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'model': model,
      'temperature': temperature,
      'top_p': topP,
      'max_tokens': maxTokens,
      'frequency_penalty': frequencyPenalty,
      'presence_penalty': presencePenalty,
      'logprobs': logprobs,
    };

    // Add optional parameters only if they have values
    if (stop != null && stop!.isNotEmpty) {
      json['stop'] = stop;
    }
    if (topLogprobs != null) {
      json['top_logprobs'] = topLogprobs;
    }

    return json;
  }

  /// 🔄 COPY WITH: Create a copy with modified parameters
  ///
  /// Returns a new instance with the specified parameters changed
  ChatCompletionConfig copyWith({
    String? model,
    double? temperature,
    double? topP,
    int? maxTokens,
    double? frequencyPenalty,
    double? presencePenalty,
    List<String>? stop,
    bool? logprobs,
    int? topLogprobs,
  }) {
    return ChatCompletionConfig(
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      stop: stop ?? this.stop,
      logprobs: logprobs ?? this.logprobs,
      topLogprobs: topLogprobs ?? this.topLogprobs,
    );
  }
}

/// 🌐 API CLIENT: OpenAI-compatible API client for chat completions
///
/// Handles HTTP communication with OpenAI-compatible API endpoints.
/// Supports both standard chat completions and function calling via tools.
class ApiClient {
  /// 🔗 BASE URL: API endpoint base URL
  ///
  /// Examples: "https://api.openai.com/v1", "https://api.deepseek.com/v1"
  final String baseUrl;

  /// 🔑 API KEY: Authentication token for API access
  ///
  /// Must be provided in the Authorization header as "Bearer {apiKey}"
  final String apiKey;

  /// ⚙️ DEFAULT CONFIG: Default configuration for chat completions
  ///
  /// Used when no specific configuration is provided
  final ChatCompletionConfig defaultConfig;

  /// 🏗️ CONSTRUCTOR: Create new API client instance
  ///
  /// [baseUrl] - Base URL for API endpoint
  /// [apiKey] - Authentication token
  /// [defaultConfig] - Default configuration for chat completions
  ApiClient({
    required this.baseUrl,
    required this.apiKey,
    this.defaultConfig = const ChatCompletionConfig(),
  });

  /// 📤 SEND MESSAGE: Send chat completion request with optional tools
  ///
  /// [messages] - List of conversation messages
  /// [tools] - List of available tools for function calling
  /// [config] - Optional configuration override (uses default if not provided)
  ///
  /// Returns the assistant's response message with tool calls if any.
  /// Throws exception on API errors or invalid responses.
  Future<Message> sendMessage(
    List<Message> messages,
    List<Tool> tools, {
    ChatCompletionConfig? config,
  }) async {
    // Use provided config or default
    final effectiveConfig = config ?? defaultConfig;
    
    // Validate configuration
    effectiveConfig.validate();

    // Prepare request body
    final requestBody = <String, dynamic>{
      ...effectiveConfig.toJson(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };

    // Include tools if provided (OpenAI API v1 specification)
    if (tools.isNotEmpty) {
      requestBody['tools'] = tools.map((tool) => tool.toJson()).toList();
    }

    // DeepSeek uses OpenAI-compatible chat/completions endpoint
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Handle OpenAI-compatible response format
      if (data['choices'] != null && data['choices'].isNotEmpty) {
        final choice = data['choices'][0];
        final messageData = choice['message'];

        // Parse tool calls if present
        List<ToolCall>? toolCalls;
        if (messageData['tool_calls'] != null) {
          toolCalls = (messageData['tool_calls'] as List<dynamic>)
              .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
              .toList();
        }

        return Message(
          role: messageData['role'] ?? 'assistant',
          content: messageData['content'],
          toolCalls: toolCalls,
        );
      } else {
        throw Exception('Invalid response format: ${response.body}');
      }
    } else {
      print('❌ API Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  /// 🧹 CLOSE: Clean up resources
  ///
  /// Performs any necessary cleanup when the API client is no longer needed.
  /// Currently a no-op but provides a consistent interface for cleanup operations.
  Future<void> close() async {
    // No specific cleanup needed for HTTP client, but provides consistent interface
    print('🧹 ApiClient closed');
  }
}
