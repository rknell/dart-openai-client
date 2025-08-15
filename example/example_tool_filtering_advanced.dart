import 'dart:io';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🎯 ADVANCED TOOL FILTERING EXAMPLE: Demonstrates MCP tool filtering capabilities
///
/// This example shows how to create agents with customized tool sets using the new
/// FilteredToolExecutorRegistry. Different agents can have access to different subsets
/// of tools while maintaining full access to all tools in the underlying registry.
void main() async {
  print('🔒 Advanced Tool Filtering Example\n');

  // Check for API key
  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ DEEPSEEK_API_KEY environment variable is not set');
    print('Please set it with: export DEEPSEEK_API_KEY="your-api-key-here"');
    exit(1);
  }

  try {
    // 🏗️ SETUP: Initialize API client and MCP tool registry
    print('🔧 Setting up MCP tool registry...');

    final client = ApiClient(
      baseUrl: 'https://api.deepseek.com/v1',
      apiKey: apiKey,
    );

    final mcpConfig = File('config/mcp_servers.json');
    if (!mcpConfig.existsSync()) {
      print('❌ MCP configuration file not found: config/mcp_servers.json');
      print('Please create this file with your MCP server configurations');
      exit(1);
    }

    final toolRegistry = McpToolExecutorRegistry(mcpConfig: mcpConfig);
    await toolRegistry.initialize();

    print(
        '✅ MCP Tool Registry initialized with ${toolRegistry.toolCount} tools');
    print('');

    // 📋 DISPLAY AVAILABLE TOOLS
    print('📋 Available tools in registry:');
    final allTools = toolRegistry.getAllTools();
    for (final tool in allTools) {
      print('  - ${tool.function.name}: ${tool.function.description}');
    }
    print('');

    // 🎯 EXAMPLE 1: NAVIGATION-ONLY AGENT
    print('🌐 Example 1: Navigation-Only Agent');
    print('-' * 40);

    final navigationAgent = Agent.withFilteredTools(
      apiClient: client,
      toolRegistry: toolRegistry,
      systemPrompt:
          'You are a web navigation specialist. You can only navigate to websites.',
      allowedToolNames: {'puppeteer_navigate'}, // Only navigation tool
    );

    print(
        '✅ Navigation agent created with access to: ${navigationAgent.getFilteredTools().map((t) => t.function.name).join(', ')}');
    print('🔒 Agent tool count: ${navigationAgent.toolRegistry.executorCount}');
    print('');

    // 🎯 EXAMPLE 2: MULTI-TOOL AGENT
    print('🛠️ Example 2: Multi-Tool Agent');
    print('-' * 40);

    final multiToolAgent = Agent.withFilteredTools(
      apiClient: client,
      toolRegistry: toolRegistry,
      systemPrompt:
          'You are a general assistant with access to multiple tools.',
      allowedToolNames: {
        'puppeteer_navigate',
        'puppeteer_screenshot'
      }, // Multiple tools
    );

    print(
        '✅ Multi-tool agent created with access to: ${multiToolAgent.getFilteredTools().map((t) => t.function.name).join(', ')}');
    print('🔒 Agent tool count: ${multiToolAgent.toolRegistry.executorCount}');
    print('');

    // 🎯 EXAMPLE 3: FULL-ACCESS AGENT
    print('🚀 Example 3: Full-Access Agent');
    print('-' * 40);

    final fullAccessAgent = Agent.withFilteredTools(
      apiClient: client,
      toolRegistry: toolRegistry,
      systemPrompt:
          'You are a powerful assistant with access to all available tools.',
      allowedToolNames: null, // All tools accessible
    );

    print(
        '✅ Full-access agent created with access to: ${fullAccessAgent.getFilteredTools().map((t) => t.function.name).join(', ')}');
    print('🔒 Agent tool count: ${fullAccessAgent.toolRegistry.executorCount}');
    print('');

    // 🎯 EXAMPLE 4: CUSTOM TOOL SET AGENT
    print('🎨 Example 4: Custom Tool Set Agent');
    print('-' * 40);

    // Create a custom set of tools for a specific workflow
    final customToolSet = {
      'puppeteer_navigate',
      'puppeteer_screenshot',
      'puppeteer_click',
    };

    final customAgent = Agent.withFilteredTools(
      apiClient: client,
      toolRegistry: toolRegistry,
      systemPrompt:
          'You are a web automation specialist with access to navigation, screenshot, and clicking tools.',
      allowedToolNames: customToolSet,
    );

    print(
        '✅ Custom agent created with access to: ${customAgent.getFilteredTools().map((t) => t.function.name).join(', ')}');
    print('🔒 Agent tool count: ${customAgent.toolRegistry.executorCount}');
    print('');

    // 📊 STATUS COMPARISON
    print('📊 Agent Tool Access Comparison');
    print('=' * 50);
    print('| Agent Type          | Tools Available | Count |');
    print('|---------------------|-----------------|-------|');
    print(
        '| Navigation-Only     | ${navigationAgent.getFilteredTools().map((t) => t.function.name).join(', ')} | ${navigationAgent.toolRegistry.executorCount} |');
    print(
        '| Multi-Tool          | ${multiToolAgent.getFilteredTools().map((t) => t.function.name).join(', ')} | ${multiToolAgent.toolRegistry.executorCount} |');
    print(
        '| Full-Access         | ${fullAccessAgent.getFilteredTools().map((t) => t.function.name).join(', ')} | ${fullAccessAgent.toolRegistry.executorCount} |');
    print(
        '| Custom Tool Set     | ${customAgent.getFilteredTools().map((t) => t.function.name).join(', ')} | ${customAgent.toolRegistry.executorCount} |');
    print('');

    // 🔍 ADVANCED FEATURES
    print('🔍 Advanced Features');
    print('-' * 30);

    // Check if agents can access filtered registries
    if (navigationAgent.toolRegistry is FilteredToolExecutorRegistry) {
      final filteredRegistry =
          navigationAgent.toolRegistry as FilteredToolExecutorRegistry;
      print('✅ Navigation agent uses filtered registry');
      print('   Source registry type: ${filteredRegistry.source.runtimeType}');
      print(
          '   Allowed tools: ${filteredRegistry.allowedTools?.join(', ') ?? 'ALL'}');
      print('   Filtering enabled: ${filteredRegistry.allowedTools != null}');
    }

    // 🧪 DEMO: Send a message to show tool filtering in action
    print('');
    print('🧪 Demo: Tool Filtering in Action');
    print('-' * 40);

    print('Sending message to navigation agent...');
    try {
      final response = await navigationAgent
          .sendMessage('What tools do you have access to? Please list them.');
      print('🤖 Navigation Agent Response:');
      print('   ${response.content ?? "No content"}');
    } catch (e) {
      print('❌ Error: $e');
    }

    print('');
    print('🎉 Tool filtering demonstration completed!');
    print('');
    print('💡 Key Benefits:');
    print('   • Different agents can have different tool access levels');
    print('   • Full registry maintains access to all tools');
    print('   • Filtered registries provide security and focus');
    print('   • Easy to create specialized agents for specific workflows');
    print('   • No performance impact - filtering is transparent');

    // 🧹 CLEANUP
    await toolRegistry.shutdown();
    await client.close();
  } catch (e) {
    print('❌ Error during execution: $e');
    exit(1);
  }
}
