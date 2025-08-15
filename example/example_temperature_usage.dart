import 'dart:io';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🌡️ TEMPERATURE USAGE EXAMPLE: Simple demonstration of the temperature property
///
/// This example shows how easy it is to set and use the temperature property
/// directly on the Agent object.
void main() async {
  print('🌡️ Temperature Usage Example\n');

  // Create API client
  final apiClient = ApiClient(
    baseUrl: 'https://api.deepseek.com',
    apiKey: 'your-api-key-here',
  );

  // Create tool registry
  final toolRegistry =
      McpToolExecutorRegistry(mcpConfig: File("config/mcp_servers.json"));
  await toolRegistry.initialize();

  // Create agent
  final agent = Agent(
    apiClient: apiClient,
    toolRegistry: toolRegistry,
    systemPrompt: 'You are a helpful assistant.',
  );

  // Show default temperature
  print('📊 Default temperature: ${agent.temperature}');

  // Set temperature for creative responses
  print('\n🎨 Setting temperature for creative responses...');
  agent.temperature = 1.5; // High temperature for creativity
  print('✅ Temperature set to: ${agent.temperature}');

  // Set other properties easily
  agent.maxTokens = 1024;
  agent.frequencyPenalty = 0.2;
  agent.presencePenalty = 0.1;
  agent.topP = 0.9;

  print('\n📋 Current agent configuration:');
  print('  🌡️ Temperature: ${agent.temperature}');
  print('  📏 Max Tokens: ${agent.maxTokens}');
  print('  🔄 Frequency Penalty: ${agent.frequencyPenalty}');
  print('  🆕 Presence Penalty: ${agent.presencePenalty}');
  print('  🔝 Top P: ${agent.topP}');

  // Change temperature for precise responses
  print('\n🎯 Changing temperature for precise responses...');
  agent.temperature = 0.2; // Low temperature for precision
  print('✅ Temperature changed to: ${agent.temperature}');

  // Show how temperature affects the configuration
  print('\n🔍 Temperature is now part of the API configuration:');
  print('  API Config Temperature: ${agent.apiConfig.temperature}');
  print('  Direct Temperature Property: ${agent.temperature}');
  print('  ✅ Both values are synchronized!');

  print('\n🎉 Temperature Usage Example Complete!');
  print('\n💡 Key Benefits:');
  print('• Set temperature directly: agent.temperature = 0.5');
  print('• Get current temperature: print(agent.temperature)');
  print('• Temperature is automatically included in API requests');
  print('• All other configuration values are preserved');
  print('• Simple and intuitive API');
}
