#!/usr/bin/env dart

/// 🚀 MCP FUNCTION CALLING DEMO WITH AGENT CLASS
///
/// ⚔️ ARCHITECTURAL BATTLE LOG:
/// - Decision: Use MCP client for server communication and tool discovery
/// - Challenge: Integrate multiple MCP servers with automatic tool loading
/// - Victory: Clean, maintainable code with full MCP server support
/// - Usage: Demonstrates real-world MCP-based function calling patterns
///
/// 🎯 MISSION: Full circle MCP tool request and response using Agent class
/// Loads MCP servers from JSON configuration and makes their tools available

import 'dart:convert';
import 'dart:io';
import '../lib/dart_openai_client.dart';

/// 🔧 MAIN FUNCTION: Execute the full circle MCP tool calling demo
Future<void> main() async {
  print('🚀 MCP FUNCTION CALLING DEMO WITH AGENT CLASS');
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
    // 🏗️ SETUP: Initialize API client
    final client = ApiClient(
      baseUrl: 'https://api.deepseek.com/v1',
      apiKey: apiKey,
    );

    print('🔧 Setting up MCP tool system...');
    print('');

    // 📁 LOAD MCP CONFIG: Load server configurations from JSON file
    final configFile = File('config/mcp_servers.json');
    if (!await configFile.exists()) {
      print(
          '❌ ERROR: MCP configuration file not found at config/mcp_servers.json');
      print('Please create the configuration file first.');
      exit(1);
    }

    final configData = jsonDecode(await configFile.readAsString());
    final mcpServers = configData['mcpServers'] as Map<String, dynamic>;

    print('📋 Loaded ${mcpServers.length} MCP server(s) from configuration');
    print('');

    // 🛠️ CREATE TOOL REGISTRY: Initialize tool registry for MCP tools
    final toolRegistry =
        McpToolExecutorRegistry(mcpConfig: File("config/mcp_servers.json"));
    await toolRegistry.initialize();
    final mcpClients = <String, McpClient>{};
    final manager = mcpServerManager;

    // 🚀 INITIALIZE MCP SERVERS: Start each configured MCP server
    for (final entry in mcpServers.entries) {
      final serverName = entry.key;
      final serverConfig = entry.value as Map<String, dynamic>;

      print('🚀 Initializing MCP server: $serverName');
      print(
          '   Command: ${serverConfig['command']} ${serverConfig['args'].join(' ')}');

      try {
        // Create MCP server configuration
        final config = McpServerConfig.fromJson(serverConfig);

        // Get or create persistent MCP client
        final mcpClient = await manager.getOrCreateServer(config);

        // Store client for cleanup
        mcpClients[serverName] = mcpClient;

        // Register each tool from the MCP server
        for (final tool in mcpClient.tools) {
          final executor = McpToolExecutor(mcpClient, tool);
          toolRegistry.registerExecutor(executor);

          print(
              '   ✅ Tool: ${tool.function.name} - ${tool.function.description}');
        }

        print('   🎯 Total tools from $serverName: ${mcpClient.toolCount}');
        print('');
      } catch (e) {
        print('   ❌ Failed to initialize $serverName: $e');
        print('   ⚠️  Skipping this server...');
        print('');
      }
    }

    print(
        '🔧 MCP tools configured: ${toolRegistry.executorCount} executor(s) available');
    print('');

    // 🤖 CREATE AGENT: Initialize agent with API client and MCP tool registry
    final agent = Agent(
      apiClient: client,
      toolRegistry: toolRegistry,
      messages: [],
      systemPrompt:
          'You are a helpful assistant with access to MCP tools. You can use these tools to perform various tasks like web scraping, file operations, and more. Always provide helpful and informative responses.',
    );

    print('🤖 MCP Agent initialized with conversation tracking');
    print('📚 System prompt: ${agent.systemPrompt}');
    print('');

    // 🎯 DEMO 1: List available MCP tools
    print('🎯 DEMO 1: Available MCP Tools');
    print('-' * 30);

    final allTools = toolRegistry.getAllTools();
    print('🛠️  Available tools (${allTools.length}):');
    for (final tool in allTools) {
      print('  • ${tool.function.name}: ${tool.function.description}');
    }
    print('');

    // 🎯 DEMO 2: Test MCP tool execution (if puppeteer is available)
    if (mcpClients.containsKey('puppeteer')) {
      print('🎯 DEMO 2: Testing Puppeteer MCP Tool');
      print('-' * 35);

      final userQuestion =
          "Can you scrape the todos from https://jsonplaceholder.typicode.com/todos and tell me how many are completed vs incomplete?";
      print('👤 User: $userQuestion');

      final response = await agent.sendMessage(userQuestion);
      print('🤖 Assistant: ${response.content ?? "No content"}');
      print('📊 Message count: ${agent.messageCount}');
      print('');
    }

    // 🎯 DEMO 3: Test filesystem tool (if available)
    if (mcpClients.containsKey('filesystem')) {
      print('🎯 DEMO 3: Testing Filesystem MCP Tool');
      print('-' * 35);

      final userQuestion = "Can you list the files in the current directory?";
      print('👤 User: $userQuestion');

      final response = await agent.sendMessage(userQuestion);
      print('🤖 Assistant: ${response.content ?? "No content"}');
      print('📊 Message count: ${agent.messageCount}');
      print('');
    }

    // 🎯 DEMO 4: Show conversation history
    print('🎯 DEMO 4: Conversation History');
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

    // 🎯 DEMO 5: Test custom query with MCP tools
    print('🎯 DEMO 5: Custom Query with MCP Tools');
    print('-' * 40);

    final userQuestion =
        "What can you do with the available MCP tools? Please demonstrate their capabilities.";
    print('👤 User: $userQuestion');

    final response = await agent.sendMessage(userQuestion);
    print('🤖 Assistant: ${response.content ?? "No content"}');
    print('📊 Message count: ${agent.messageCount}');
    print('');

    print('✅ Full circle MCP tool calling demo completed successfully!');
    print(
        '🎉 The agent automatically handled all MCP tool calls and maintained conversation state!');
    print('');
    print(
        '💡 You can modify config/mcp_servers.json to add more MCP servers or change configurations.');

    // 🧹 CLEANUP: Release MCP clients (servers stay persistent)
    print('');
    print('🧹 Releasing MCP clients (servers remain persistent)...');
    for (final entry in mcpClients.entries) {
      final serverName = entry.key;
      final client = entry.value;

      // Get the config for this server to release it properly
      final serverConfig = mcpServers[serverName] as Map<String, dynamic>;
      final config = McpServerConfig.fromJson(serverConfig);

      await manager.releaseServer(config, client);
      print('   📉 Released $serverName server');
    }
    print('✅ Cleanup completed (servers remain persistent for future use)');

    // Show final server status
    print('');
    print('📊 Final MCP Server Status:');
    final status = manager.getStatus();
    if (status.isEmpty) {
      print('   🚫 No active servers');
    } else {
      for (final entry in status.entries) {
        print(
            '   🔄 ${entry.key}: ${entry.value['referenceCount']} refs, ${entry.value['toolCount']} tools');
      }
    }
  } catch (e) {
    print('\n❌ ERROR: $e');
    if (e.toString().contains('401')) {
      print(
          '💡 This usually means an invalid API key. Please check your DEEPSEEK_API_KEY.');
    } else if (e.toString().contains('429')) {
      print('💡 Rate limit exceeded. Please wait before trying again.');
    } else if (e.toString().contains('ENOENT')) {
      print(
          '💡 MCP server command not found. Make sure the required tools are installed.');
    }
    exit(1);
  }
}
