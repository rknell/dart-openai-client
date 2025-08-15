#!/usr/bin/env dart

/// 🚀 DEEPSEEK FUNCTION CALLING DEMO WITH AGENT CLASS
///
/// ⚔️ ARCHITECTURAL BATTLE LOG:
/// - Decision: Use Agent class for conversation management and tool execution
/// - Challenge: Integrate weather agent with automatic tool calling
/// - Victory: Clean, maintainable code with full conversation tracking
/// - Usage: Demonstrates real-world agent-based function calling patterns
///
/// 🎯 MISSION: Full circle tool request and response using Agent class according to:
/// https://api-docs.deepseek.com/guides/function_calling

import 'dart:io';
import '../lib/dart_openai_client.dart';

/// 🔧 MAIN FUNCTION: Execute the full circle tool calling demo using Agent class
Future<void> main() async {
  print('🚀 DEEPSEEK FUNCTION CALLING DEMO WITH AGENT CLASS');
  print('=' * 60);

  // Check for API key
  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ ERROR: DEEPSEEK_API_KEY environment variable not set');
    print('Please set your DeepSeek API key:');
    print('export DEEPSEEK_API_KEY="your-api-key-here"');
    exit(1);
  }

  try {
    // 🏗️ SETUP: Initialize API client and tools
    final client = ApiClient(
      baseUrl: 'https://api.deepseek.com/v1',
      apiKey: apiKey,
    );

    print('🔧 Setting up modular tool system...');
    print('');

    // 🛠️ CREATE TOOL EXECUTOR: Initialize weather tool executor
    final weatherExecutor = WeatherToolExecutor();

    // 📝 CREATE TOOL REGISTRY: Register the weather tool executor
    final toolRegistry =
        McpToolExecutorRegistry(mcpConfig: File("config/mcp_servers.json"));
    await toolRegistry.initialize();
    toolRegistry.registerExecutor(weatherExecutor);

    print(
        '🔧 Tools configured: ${toolRegistry.executorCount} executor(s) available');
    print('📝 Weather tool: ${weatherExecutor.toolName}');
    print('📋 Tool description: ${weatherExecutor.toolDescription}');
    print('');

    // 🤖 CREATE AGENT: Initialize agent with API client and tool registry
    final agent = Agent(
      apiClient: client,
      toolRegistry: toolRegistry,
      messages: [],
      systemPrompt:
          'You are a helpful weather assistant. You can check the weather for any location using the get_weather tool. Always provide helpful and informative responses.',
    );

    print('🤖 Weather Agent initialized with conversation tracking');
    print('📚 System prompt: ${agent.systemPrompt}');
    print('');

    // 🎯 DEMO 1: Basic weather query
    print('🎯 DEMO 1: Basic Weather Query');
    print('-' * 40);

    final userQuestion1 = "How's the weather in Hangzhou?";
    print('👤 User: $userQuestion1');

    final response1 = await agent.sendMessage(userQuestion1);
    print('🤖 Assistant: ${response1.content ?? "No content"}');
    print('📊 Message count: ${agent.messageCount}');
    print('');

    // 🎯 DEMO 2: Multiple weather queries to show conversation tracking
    print('🎯 DEMO 2: Multiple Weather Queries (Conversation Tracking)');
    print('-' * 60);

    final userQuestion2 =
        "What about Tokyo? And can you compare it to Hangzhou?";
    print('👤 User: $userQuestion2');

    final response2 = await agent.sendMessage(userQuestion2);
    print('🤖 Assistant: ${response2.content ?? "No content"}');
    print('📊 Message count: ${agent.messageCount}');
    print('');

    // 🎯 DEMO 3: Show conversation history
    print('🎯 DEMO 3: Conversation History');
    print('-' * 30);

    print('📚 Full conversation history:');
    for (int i = 0; i < agent.conversationHistory.length; i++) {
      final message = agent.conversationHistory[i];
      final role = message.role.padRight(10);
      final content = message.content ?? 'No content';

      if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
        print('  $i. [$role] Tool calls: ${message.toolCalls!.length} tool(s)');
        for (final toolCall in message.toolCalls!) {
          print(
              '      🛠️ ${toolCall.function.name}(${toolCall.function.arguments})');
        }
      } else {
        print(
            '  $i. [$role] ${content.length > 80 ? "${content.substring(0, 80)}..." : content}');
      }
    }
    print('');

    // 🎯 DEMO 4: Add custom weather location
    print('🎯 DEMO 4: Custom Weather Location');
    print('-' * 35);

    weatherExecutor.addWeatherLocation('Vancouver', '18°C, Rainy');
    print('🌍 Added custom weather for Vancouver: 18°C, Rainy');

    final userQuestion3 = "What's the weather like in Vancouver?";
    print('👤 User: $userQuestion3');

    final response3 = await agent.sendMessage(userQuestion3);
    print('🤖 Assistant: ${response3.content ?? "No content"}');
    print('📊 Message count: ${agent.messageCount}');
    print('');

    // 🎯 DEMO 5: Show available locations
    print('🎯 DEMO 5: Available Weather Locations');
    print('-' * 40);

    final locations = weatherExecutor.getAvailableLocations();
    print('🌍 Available weather locations (${locations.length}):');
    for (final location in locations) {
      print('  • $location');
    }
    print('');

    // 🎯 DEMO 6: Search functionality
    print('🎯 DEMO 6: Weather Search');
    print('-' * 20);

    final searchResults = weatherExecutor.searchWeather('York');
    print('🔍 Search results for "York":');
    for (final entry in searchResults.entries) {
      print('  • ${entry.key}: ${entry.value}');
    }
    print('');

    print(
        '✅ Full circle tool calling demo with Agent class completed successfully!');
    print(
        '🎉 The agent automatically handled all tool calls and maintained conversation state!');
  } catch (e) {
    print('\n❌ ERROR: $e');
    if (e.toString().contains('401')) {
      print(
          '💡 This usually means an invalid API key. Please check your DEEPSEEK_API_KEY.');
    } else if (e.toString().contains('429')) {
      print('💡 Rate limit exceeded. Please wait before trying again.');
    }
    exit(1);
  }
}
