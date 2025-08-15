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
  Your job is to analyze a company for the purposes of categorizing accounting transactions.

  You will scrape 5-10 pages of their website to analyze the goods and services they provide and would need to purchase in order to run the business

  This profile will be used by future sessions to determine the correct accounts to place transactions into.

  create a comapny profile in ./config/company_profile.txt
  """;

  final agent = Agent(
    apiClient: client,
    toolRegistry: toolRegistry,
    systemPrompt: systemPrompt,
  )..temperature = 1.2;

  final result = await agent.sendMessage("""
Build a company profile for https://www.rebelrum.com.au
""");

  print(result.content);

  final result2 = await agent.sendMessage("""
Please update ./config/company_profile.txt with the company profile.
""");

  print(result2.content);

  await toolRegistry.shutdown();
  await client.close();
  exit(0);
}
