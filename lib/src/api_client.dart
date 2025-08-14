import 'dart:convert';

import 'package:http/http.dart' as http;

import 'tool.dart';
import 'message.dart';

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

  /// 🏗️ CONSTRUCTOR: Create new API client instance
  ///
  /// [baseUrl] - Base URL for API endpoint
  /// [apiKey] - Authentication token
  ApiClient({required this.baseUrl, required this.apiKey});

  /// 📤 SEND MESSAGE: Send chat completion request with optional tools
  ///
  /// [messages] - List of conversation messages
  /// [tools] - List of available tools for function calling
  ///
  /// Returns the assistant's response message with tool calls if any.
  /// Throws exception on API errors or invalid responses.
  Future<Message> sendMessage(List<Message> messages, List<Tool> tools) async {
    // DeepSeek uses OpenAI-compatible chat/completions endpoint
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'max_tokens': 1000,
        'temperature': 0.7,
        // Include tools if provided (OpenAI API v1 specification)
        if (tools.isNotEmpty)
          'tools': tools.map((tool) => tool.toJson()).toList(),
      }),
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
}
