import "dart:io";

import "package:dart_openai_client/dart_openai_client.dart";

main() async {
  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception("DEEPSEEK_API_KEY is not set");
  }
  final client =
      ApiClient(baseUrl: "https://api.deepseek.com/v1", apiKey: apiKey);

  final mcpConfig = File("config/mcp_servers.json");

  final toolRegistry = McpToolExecutorRegistry(mcpConfig: mcpConfig);
  await toolRegistry.initialize(); //Load and start the MCP servers

  final systemPrompt = """
  you write funny jokes to local file ./config/jokes.txt
  """;

  final agent = Agent(
      apiClient: client,
      toolRegistry: toolRegistry,
      systemPrompt: systemPrompt);

  final result = await agent.sendMessage("""
please add a funny joke to the file ./config/jokes.txt
""");

  print(result.content);

  await toolRegistry.shutdown();
  await client.close();
  exit(0);
}
