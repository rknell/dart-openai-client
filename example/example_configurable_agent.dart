import 'dart:io';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🎯 CONFIGURABLE AGENT EXAMPLE: Demonstrates the new configurable API parameters
///
/// This example shows how to use the new ChatCompletionConfig class to control
/// various API parameters like temperature, max tokens, penalties, and more.
void main() async {
  print('🚀 Configurable Agent Example\n');

  // Create API client with custom default configuration
  final apiClient = ApiClient(
    baseUrl: 'https://api.deepseek.com',
    apiKey: 'your-api-key-here',
    defaultConfig: ChatCompletionConfig(
      temperature: 0.7,
      maxTokens: 2048,
      frequencyPenalty: 0.1,
      presencePenalty: 0.1,
    ),
  );

  // Create tool registry
  final toolRegistry =
      McpToolExecutorRegistry(mcpConfig: File("config/mcp_servers.json"));

  // Example 1: Creative Agent (High temperature for more random responses)
  print('🎨 Example 1: Creative Agent (High Temperature)');
  // final creativeAgent = Agent(
  //   apiClient: apiClient,
  //   toolRegistry: toolRegistry,
  //   systemPrompt:
  //       'You are a creative writer who loves to tell imaginative stories.',
  //   apiConfig: ChatCompletionConfig(
  //     temperature: 1.8, // High temperature for creativity
  //     maxTokens: 1024,
  //     frequencyPenalty: 0.3, // Encourage diverse vocabulary
  //     presencePenalty: 0.2, // Encourage new topics
  //   ),
  // );

  // Example 2: Precise Agent (Low temperature for focused responses)
  print('🎯 Example 2: Precise Agent (Low Temperature)');
  // final preciseAgent = Agent(
  //   apiClient: apiClient,
  //   toolRegistry: toolRegistry,
  //   systemPrompt:
  //       'You are a technical expert who provides precise, factual answers.',
  //   apiConfig: ChatCompletionConfig(
  //     temperature: 0.2, // Low temperature for consistency
  //     maxTokens: 512,
  //     frequencyPenalty: 0.0, // No penalty for repetition
  //     presencePenalty: 0.0, // No penalty for staying on topic
  //   ),
  // );

  // Example 3: Balanced Agent (Medium temperature with custom penalties)
  print('⚖️ Example 3: Balanced Agent (Medium Temperature)');
  // final balancedAgent = Agent(
  //   apiClient: apiClient,
  //   toolRegistry: toolRegistry,
  //   systemPrompt:
  //       'You are a helpful assistant who balances creativity with accuracy.',
  //   apiConfig: ChatCompletionConfig(
  //     temperature: 0.8,
  //     maxTokens: 1536,
  //     frequencyPenalty: 0.1,
  //     presencePenalty: 0.1,
  //     topP: 0.9, // Use nucleus sampling
  //   ),
  // );

  // Example 4: Direct Property Access
  print('🔄 Example 4: Direct Property Access');
  final dynamicAgent = Agent(
    apiClient: apiClient,
    toolRegistry: toolRegistry,
    systemPrompt: 'You are a versatile assistant.',
  );

  // Set temperature directly on the agent
  print('\n🌡️ Setting temperature directly on agent...');
  dynamicAgent.temperature = 0.3; // Low temperature for precise responses
  print('✅ Agent temperature set to: ${dynamicAgent.temperature}');

  // Set other properties directly
  dynamicAgent.maxTokens = 1024;
  dynamicAgent.frequencyPenalty = 0.1;
  dynamicAgent.presencePenalty = 0.1;
  dynamicAgent.topP = 0.9;

  print('✅ Agent configuration:');
  print('  - Temperature: ${dynamicAgent.temperature}');
  print('  - Max Tokens: ${dynamicAgent.maxTokens}');
  print('  - Frequency Penalty: ${dynamicAgent.frequencyPenalty}');
  print('  - Presence Penalty: ${dynamicAgent.presencePenalty}');
  print('  - Top P: ${dynamicAgent.topP}');

  // Example 5: Dynamic Configuration Override
  print('\n🔄 Example 5: Dynamic Configuration Override');

  // Override configuration for a specific message
  // final customConfig = ChatCompletionConfig(
  //   temperature: 0.1, // Very low temperature for this specific response
  //   maxTokens: 256, // Short response
  //   stop: ['END', 'STOP'], // Stop sequences
  // );

  try {
    // This would send a message with the custom configuration
    // final response = await dynamicAgent.sendMessage(
    //   'Explain quantum computing in simple terms.',
    //   config: customConfig,
    // );
    // print('Response: ${response.content}');
    print('✅ Message would be sent with custom configuration');
  } catch (e) {
    print('❌ Error: $e');
  }

  // Example 6: Configuration Validation
  print('\n🔍 Example 6: Configuration Validation');

  try {
    // This would throw an error due to invalid temperature
    final invalidConfig = ChatCompletionConfig(temperature: 2.5);
    invalidConfig.validate();
    print('❌ Should have thrown an error for invalid temperature');
  } catch (e) {
    print('✅ Correctly caught validation error: $e');
  }

  try {
    // This would throw an error due to invalid max tokens
    final invalidConfig = ChatCompletionConfig(maxTokens: 0);
    invalidConfig.validate();
    print('❌ Should have thrown an error for invalid max tokens');
  } catch (e) {
    print('✅ Correctly caught validation error: $e');
  }

  // Example 7: Configuration Copying
  print('\n📋 Example 7: Configuration Copying');

  final baseConfig = ChatCompletionConfig(
    temperature: 0.7,
    maxTokens: 1024,
    frequencyPenalty: 0.1,
  );

  // Create a copy with modifications
  final modifiedConfig = baseConfig.copyWith(
    temperature: 0.9,
    maxTokens: 2048,
  );

  print(
      'Base config - Temperature: ${baseConfig.temperature}, Max Tokens: ${baseConfig.maxTokens}');
  print(
      'Modified config - Temperature: ${modifiedConfig.temperature}, Max Tokens: ${modifiedConfig.maxTokens}');
  print('✅ Original config unchanged, new config has modifications');

  // Example 8: Advanced Configuration Features
  print('\n🚀 Example 8: Advanced Configuration Features');

  final advancedConfig = ChatCompletionConfig(
    model: 'deepseek-reasoner', // Use the reasoner model
    temperature: 0.5,
    topP: 0.8, // Nucleus sampling
    maxTokens: 4096,
    frequencyPenalty: 0.2,
    presencePenalty: 0.1,
    stop: ['###', 'END'], // Custom stop sequences
    logprobs: true, // Return log probabilities
    topLogprobs: 5, // Top 5 log probabilities
  );

  print('Advanced config created with:');
  print('- Model: ${advancedConfig.model}');
  print('- Temperature: ${advancedConfig.temperature}');
  print('- Top P: ${advancedConfig.topP}');
  print('- Max Tokens: ${advancedConfig.maxTokens}');
  print('- Stop Sequences: ${advancedConfig.stop}');
  print('- Log Probabilities: ${advancedConfig.logprobs}');
  print('- Top Log Probabilities: ${advancedConfig.topLogprobs}');

  // Validate the advanced configuration
  try {
    advancedConfig.validate();
    print('✅ Advanced configuration is valid');
  } catch (e) {
    print('❌ Advanced configuration validation failed: $e');
  }

  print('\n🎉 Configurable Agent Example Complete!');
  print('\n📚 Key Features Demonstrated:');
  print('• Temperature control for response randomness');
  print('• Max tokens for response length control');
  print('• Frequency and presence penalties for diversity');
  print('• Top-p nucleus sampling');
  print('• Stop sequences for controlled generation');
  print('• Log probabilities for advanced analysis');
  print('• Per-message configuration overrides');
  print('• Configuration validation and error handling');
  print('• Configuration copying and modification');
}
