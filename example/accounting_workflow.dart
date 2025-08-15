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

  final supplierList = File("config/supplier_list.json").readAsStringSync();
  final chartOfAccounts =
      File("config/chart_of_accounts.json").readAsStringSync();

  final systemPrompt = """
  Your job is to take lines on a bank statement and correctly categorise them to an account. 
  Use the chart of accounts and the supplier list to categorise the lines. 
   
  If a supplier is not in the known supplier list, follow this workflow:
  1. Use puppeteer_navigate to go to "https://duckduckgo.com/?q=[supplier name]"
  2. The puppeteer_navigate tool will automatically return the page's innerText content
  3. Analyze the search results to understand what the supplier does
  
  If after researching you are still unsure which account it should go in, leave it as "Unknown".
  
  MANDATORY: You must categorise all provided line items before completing the task.

  Use the company profile to help you understand the company and its operations.
  Company Profile:
  ${File('config/company_profile.txt').readAsStringSync().trim()}

  If the line item can reasonably be matched to a supplier, just match it.
  Known Suppliers:
  ${supplierList}

  Chart of accounts:
  ${chartOfAccounts}

  Assume all transactions are business expenses and try to find a likely justification for each one.

  MANDATORY: Response must be in JSON format and only include the JSON object. Do not include any other text. Response format:
  [
    {
      "account": "501",
      "supplierName": "7-Eleven",
      "lineItem": "20/12/2024	Visa Purchase                 17Dec 7-Eleven 4210 Ormeau Ormeau	130.48		232939.4",
      "justification": "The purchase of fuel"
    }
  ]
  """;

  // Create agent with access only to the navigate function
  final agent = Agent.withFilteredTools(
    apiClient: client,
    toolRegistry: toolRegistry,
    systemPrompt: systemPrompt,
    allowedToolNames: {'puppeteer_navigate'}, // Only allow navigation tool
  )..temperature = 0.3;

  final result = await agent.sendMessage("""
10/10/2024	Osko Withdrawal               10Oct13:12 Occulus Occulus Adrian Smith	220		135100.25
09/10/2024	Visa Purchase                 05Oct Ampol Hamilton 11781 Hamilton	108.54		135320.25
09/10/2024	Visa Purchase                 07Oct Coles Express 1837   Cleveland	46.07		135428.79
09/10/2024	Osko Withdrawal               09Oct12:44 Ryan    Dinner Ryan   Dinner Rotary Orme	15		135474.86
08/10/2024	Visa Purchase                 05Oct Sq *Portside Social  Hamilton	32.44		135489.86
07/10/2024	Zeller Rebelli05102413:00		3166.03	135522.3
05/10/2024	Visa Purchase                 02Oct Amazon Web Services  Sydney	180.56		132356.27
05/10/2024	Foreign Currency Conversn Fee	0.43		132536.83
05/10/2024	Visa Purchase O/Seas          04Oct Usd10.00 Ngrok 71P4Qik9Tho-00	14.65		132537.26
04/10/2024	Visa Purchase                 02Oct Caltex Pimpama       Pimpama	56.56		132551.91
04/10/2024	Visa Purchase                 01Oct Google*Gsuite Snappy Cc Google	9.24		132608.47
04/10/2024	Visa Purchase                 01Oct Google*Cloud Bzvzgv  Cc Google	0.95		132617.71
""");

  print(result.content);

  final result2 = await agent.sendMessage("""
Please update ./config/supplier_list.json with any new suppliers you have found.
""");

  print(result2.content);

  await toolRegistry.shutdown();
  await client.close();
  exit(0);
}
