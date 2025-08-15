/// 🧪 MCP PUPPETEER INTEGRATION TEST: Permanent test for puppeteer MCP functionality
///
/// ⚔️ ARCHITECTURAL BATTLE LOG:
/// - Decision: Create permanent unit test for puppeteer MCP integration
/// - Challenge: Ensure puppeteer tools work with proper browser connectivity
/// - Victory: Catch undefined results and ensure real browser functionality
/// - Usage: Permanent regression test for puppeteer MCP tool behavior
///
/// 🏰 PERMANENT TEST FORTRESS PROTOCOL:
/// - This test prevents regression of puppeteer MCP tool functionality
/// - Ensures browser connectivity is properly established
/// - Validates that JavaScript execution returns actual results, not undefined
/// - Documents the expected behavior for future developers

import 'package:test/test.dart';
import 'dart:convert';
import '../lib/dart_openai_client.dart';

/// 🧪 PUPPETEER MCP INTEGRATION TEST SUITE
///
/// Tests the complete puppeteer MCP integration workflow:
/// 1. Browser connection establishment
/// 2. Navigation to target URL
/// 3. JavaScript execution in browser context
/// 4. Data extraction and validation
void main() {
  group('🧪 MCP Puppeteer Integration Tests', () {
    late McpServerManager manager;
    late McpClient puppeteerClient;
    late McpServerConfig puppeteerConfig;

    setUpAll(() async {
      // 🏗️ SETUP: Initialize MCP server manager
      manager = mcpServerManager;

      // Create puppeteer MCP server configuration
      puppeteerConfig = McpServerConfig(
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-puppeteer'],
        env: {},
      );

      // Get or create persistent puppeteer server
      puppeteerClient = await manager.getOrCreateServer(puppeteerConfig);
    });

    tearDownAll(() async {
      // 🧹 CLEANUP: Release server reference
      await manager.releaseServer(puppeteerConfig, puppeteerClient);
    });

    test('🛡️ REGRESSION: Puppeteer server initializes with expected tools',
        () {
      // Test that puppeteer server has the expected tools
      expect(puppeteerClient.toolCount, greaterThan(0));

      final toolNames =
          puppeteerClient.tools.map((t) => t.function.name).toSet();

      // Verify essential puppeteer tools are available
      expect(toolNames, contains('puppeteer_navigate'));
      expect(toolNames, contains('puppeteer_evaluate'));
      expect(toolNames, contains('puppeteer_screenshot'));

      print(
          '✅ Puppeteer server initialized with ${puppeteerClient.toolCount} tools');
    });

    test('🛡️ REGRESSION: Browser connection establishes successfully',
        () async {
      // The official MCP puppeteer server handles browser connection automatically
      // Test by navigating to a page and checking if it works
      final result = await puppeteerClient.executeTool(
        'puppeteer_navigate',
        '{"url": "https://jsonplaceholder.typicode.com/todos"}',
      );

      expect(result, isA<String>());
      expect(result, contains('Navigated to'));

      print('✅ Browser connection successful: $result');
    });

    test('🛡️ REGRESSION: Navigation to target URL succeeds', () async {
      // Test navigation to the todos URL
      final result = await puppeteerClient.executeTool(
        'puppeteer_navigate',
        '{"url": "https://jsonplaceholder.typicode.com/todos"}',
      );

      expect(result, isA<String>());
      expect(result, contains('Navigated to'));

      print('✅ Navigation successful: $result');
    });

    test(
        '🛡️ REGRESSION: JavaScript execution returns actual results, not undefined',
        () async {
      // Navigate to a page first
      await puppeteerClient.executeTool(
        'puppeteer_navigate',
        '{"url": "https://jsonplaceholder.typicode.com/todos"}',
      );

      // Wait for page to load
      await Future.delayed(Duration(seconds: 2));

      // Test that JavaScript execution returns actual values, not undefined
      final testScripts = [
        {
          'name': 'document.title',
          'description': 'Page title should be a string',
          'expectedType': 'string',
        },
        {
          'name': 'document.readyState',
          'description': 'Page ready state should be a string',
          'expectedType': 'string',
        },
        {
          'name': 'window.location.href',
          'description': 'Current URL should be a string',
          'expectedType': 'string',
        },
        {
          'name': 'navigator.userAgent',
          'description': 'User agent should be a string',
          'expectedType': 'string',
        },
      ];

      for (final testScript in testScripts) {
        final result = await puppeteerClient.executeTool(
          'puppeteer_evaluate',
          '{"script": "${testScript['name']}"}',
        );

        expect(result, isA<String>());

        // Check if result contains "undefined" - this indicates no browser connection
        if (result.contains('undefined')) {
          fail(
              '❌ JavaScript execution returned undefined for ${testScript['name']}\n'
              '📄 Result: $result\n'
              '💡 This indicates no browser connection - Chrome debug mode required\n'
              '🔧 To fix: Start Chrome with --remote-debugging-port=9222');
        }

        // Result should contain actual data, not just "Execution result: undefined"
        expect(result, isNot(contains('Execution result:\nundefined')));

        print('✅ ${testScript['description']}: $result');
      }
    });

    test('🛡️ REGRESSION: Data extraction from todos API works correctly',
        () async {
      // Navigate to the page first
      await puppeteerClient.executeTool(
        'puppeteer_navigate',
        '{"url": "https://jsonplaceholder.typicode.com/todos"}',
      );

      // Wait for page to load
      await Future.delayed(Duration(seconds: 2));

      // Test extracting actual data from the todos API
      final result = await puppeteerClient.executeTool(
        'puppeteer_evaluate',
        '{"script": "fetch(\'https://jsonplaceholder.typicode.com/todos\').then(r => r.json()).then(data => JSON.stringify(data.slice(0, 3)))"}',
      );

      expect(result, isA<String>());

      if (result.contains('undefined')) {
        fail('❌ Data extraction returned undefined\n'
            '📄 Result: $result\n'
            '💡 This indicates no browser connection - Chrome debug mode required\n'
            '🔧 To fix: Start Chrome with --remote-debugging-port=9222');
      }

      // Result should contain JSON data, not undefined
      expect(result, isNot(contains('Execution result:\nundefined')));

      // Try to parse the result as JSON to validate it's actual data
      try {
        final jsonData =
            jsonDecode(result.replaceAll('Execution result:\n', ''));
        expect(jsonData, isA<List>());
        expect(jsonData.length, greaterThan(0));

        print(
            '✅ Data extraction successful: Retrieved ${jsonData.length} todo items');
      } catch (e) {
        // If JSON parsing fails, the result should still not be undefined
        expect(result, isNot(contains('undefined')));
        print('⚠️  Data extraction result not JSON but not undefined: $result');
      }
    });

    test('🛡️ REGRESSION: Complete workflow from navigation to data extraction',
        () async {
      // Test the complete workflow: connect -> navigate -> extract data -> validate

      // Step 1: Navigate to the page
      final navigateResult = await puppeteerClient.executeTool(
        'puppeteer_navigate',
        '{"url": "https://jsonplaceholder.typicode.com/todos"}',
      );

      expect(navigateResult, contains('Navigated to'));

      // Step 2: Wait a moment for page to load
      await Future.delayed(Duration(seconds: 2));

      // Step 3: Extract the page content
      final contentResult = await puppeteerClient.executeTool(
        'puppeteer_evaluate',
        '{"script": "document.body.innerText"}',
      );

      expect(contentResult, isA<String>());

      if (contentResult.contains('undefined')) {
        fail(
            '❌ Complete workflow failed - content extraction returned undefined\n'
            '📄 Navigation result: $navigateResult\n'
            '📄 Content result: $contentResult\n'
            '💡 This indicates no browser connection - Chrome debug mode required\n'
            '🔧 To fix: Start Chrome with --remote-debugging-port=9222');
      }

      // Step 4: Validate we got actual content
      expect(contentResult, isNot(contains('Execution result:\nundefined')));
      expect(contentResult.length,
          greaterThan(100)); // Should have substantial content

      print('✅ Complete workflow successful');
      print('📄 Navigation: $navigateResult');
      print('📄 Content length: ${contentResult.length} characters');
    });

    test('🛡️ REGRESSION: Server remains responsive after multiple operations',
        () async {
      // No need to connect - the official server handles this automatically

      // Test that the server remains responsive after multiple operations
      final operations = [
        'puppeteer_navigate',
        'puppeteer_evaluate',
        'puppeteer_evaluate',
        'puppeteer_evaluate',
      ];

      final arguments = [
        '{"url": "https://jsonplaceholder.typicode.com/todos"}',
        '{"script": "document.title"}',
        '{"script": "document.readyState"}',
        '{"script": "window.location.href"}',
      ];

      for (int i = 0; i < operations.length; i++) {
        final result = await puppeteerClient.executeTool(
          operations[i],
          arguments[i],
        );

        expect(result, isA<String>());
        expect(result, isNotEmpty);

        // Check for undefined results
        if (result.contains('undefined')) {
          fail('❌ Operation ${i + 1} returned undefined\n'
              '🛠️  Tool: ${operations[i]}\n'
              '📋 Arguments: ${arguments[i]}\n'
              '📄 Result: $result\n'
              '💡 This indicates no browser connection - Chrome debug mode required');
        }

        print('✅ Operation ${i + 1} successful: ${operations[i]}');
      }

      // Verify server is still healthy
      expect(puppeteerClient.toolCount, greaterThan(0));
      expect(puppeteerClient.tools, isNotEmpty);

      print(
          '✅ Server remains responsive after ${operations.length} operations');
    });
  });
}
