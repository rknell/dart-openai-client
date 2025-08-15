/// 🧪 PUPPETEER MCP SERVER TEST: Permanent test for Dart-based puppeteer MCP functionality
///
/// ⚔️ ARCHITECTURAL BATTLE LOG:
/// - Decision: Create permanent unit test for Dart-based puppeteer MCP server
/// - Challenge: Ensure puppeteer tools work with proper browser connectivity and content extraction
/// - Victory: Validate both innerText and innerHTML extraction capabilities
/// - Usage: Permanent regression test for puppeteer MCP tool behavior
///
/// 🏰 PERMANENT TEST FORTRESS PROTOCOL:
/// - This test prevents regression of puppeteer MCP tool functionality
/// - Ensures browser connectivity is properly established
/// - Validates content extraction returns actual results, not undefined
/// - Documents the expected behavior for future developers

import 'package:test/test.dart';
import 'dart:convert';
import '../example/mcp_server_puppeteer.dart';
import '../lib/src/base_mcp_server.dart';

/// 🧪 PUPPETEER MCP SERVER TEST SUITE
///
/// Tests the complete puppeteer MCP server functionality:
/// 1. Server initialization and tool discovery
/// 2. Browser navigation and page loading
/// 3. Content extraction (innerText and innerHTML)
/// 4. JavaScript execution
/// 5. Error handling and resource cleanup
void main() {
  group('🧪 Puppeteer MCP Server Tests', () {
    late PuppeteerMCPServerSimple server;

    setUpAll(() async {
      // 🏗️ SETUP: Initialize Puppeteer MCP server
      server = PuppeteerMCPServerSimple(
        headless: true,
        navigationTimeout: Duration(seconds: 30),
        evaluationTimeout: Duration(seconds: 10),
        logger: (level, message, [data]) {
          print('[$level] $message${data != null ? ': $data' : ''}');
        },
      );

      // Initialize the server to register tools, resources, and prompts
      await server.initializeServer();
    });

    tearDownAll(() async {
      // 🧹 CLEANUP: Shutdown server
      await server.shutdown();
    });

    test('🛡️ REGRESSION: Server initializes with expected tools', () async {
      // Test that server has the expected tools
      final tools = await server.getAvailableTools();
      expect(tools.length, greaterThan(0));

      final toolNames = tools.map((t) => t.name).toSet();

      // Verify essential puppeteer tools are available
      expect(toolNames, contains('puppeteer_navigate'));
      expect(toolNames, contains('puppeteer_get_inner_text'));
      expect(toolNames, contains('puppeteer_navigate_html'));
      expect(toolNames, contains('puppeteer_get_inner_html'));
      expect(toolNames, contains('puppeteer_close_browser'));

      print('✅ Puppeteer server initialized with ${tools.length} tools');
    });

    test('🛡️ REGRESSION: Server capabilities are properly configured', () {
      final capabilities = server.getCapabilities();

      expect(capabilities['tools']['listChanged'], isTrue);
      expect(capabilities['tools']['call'], isTrue);
      expect(capabilities['puppeteer']['version'], equals('3.19.0'));
      expect(capabilities['puppeteer']['features'], contains('navigation'));
      expect(capabilities['puppeteer']['features'],
          contains('content_extraction'));

      print('✅ Server capabilities properly configured');
    });

    test('🛡️ REGRESSION: Navigation to target URL succeeds', () async {
      // Test navigation to a simple test page
      final result = await server.callTool('puppeteer_navigate', {
        'url': 'https://httpbin.org/html',
        'waitUntil': 'networkidle2',
        'timeout': 30000,
      });

      expect(result.isError, isFalse);
      expect(result.content.length, greaterThan(0));
      expect(result.content.first.text, contains('Herman Melville'));
      expect(result.content.first.text, contains('Moby-Dick'));

      print('✅ Navigation successful: ${result.content.first.text}');
    });

    test('🛡️ REGRESSION: InnerText extraction returns actual content',
        () async {
      // First navigate to a page
      await server.callTool('puppeteer_navigate', {
        'url': 'https://httpbin.org/html',
        'waitUntil': 'networkidle2',
      });

      // Wait a moment for page to load
      await Future.delayed(Duration(seconds: 2));

      // Test innerText extraction
      final result = await server.callTool('puppeteer_get_inner_text', {
        'selector': 'body',
        'timeout': 10000,
      });

      expect(result.isError, isFalse);
      expect(result.content.length, greaterThan(0));

      final text = result.content.first.text;
      expect(text, isNotNull);
      expect(text, isNotEmpty);
      expect(text!.length, greaterThan(100)); // Should have substantial content
      expect(text, contains('Herman')); // httpbin.org/html contains this text

      print('✅ InnerText extraction successful: ${text.length} characters');
    });

    test('🛡️ REGRESSION: InnerHTML extraction returns actual HTML content',
        () async {
      // First navigate to a page
      await server.callTool('puppeteer_navigate', {
        'url': 'https://httpbin.org/html',
        'waitUntil': 'networkidle2',
      });

      // Wait a moment for page to load
      await Future.delayed(Duration(seconds: 2));

      // Test innerHTML extraction
      final result = await server.callTool('puppeteer_get_inner_html', {
        'selector': 'body',
        'timeout': 10000,
      });

      expect(result.isError, isFalse);
      expect(result.content.length, greaterThan(0));

      final html = result.content.first.text;
      expect(html, isNotNull);
      expect(html, isNotEmpty);
      expect(html!.length, greaterThan(500)); // HTML should be longer than text
      expect(html, contains('<h1>')); // Should contain h1 tag
      expect(html, contains('<div>')); // Should contain div tag

      print('✅ InnerHTML extraction successful: ${html.length} characters');
    });

    test('🛡️ REGRESSION: HTML navigation and extraction works correctly',
        () async {
      // First navigate to a page
      await server.callTool('puppeteer_navigate_html', {
        'url': 'https://httpbin.org/html',
        'waitUntil': 'networkidle2',
      });

      // Wait a moment for page to load
      await Future.delayed(Duration(seconds: 2));

      // Test HTML extraction
      final result = await server.callTool('puppeteer_get_inner_html', {
        'selector': 'body',
        'timeout': 10000,
      });

      expect(result.isError, isFalse);
      expect(result.content.length, greaterThan(0));

      final html = result.content.first.text;
      expect(html, isNotNull);
      expect(html, isNotEmpty);
      expect(html!.length, greaterThan(500)); // HTML should be substantial
      expect(html, contains('<h1>')); // Should contain h1 tag
      expect(html, contains('<div>')); // Should contain div tag

      print(
          '✅ HTML navigation and extraction successful: ${html.length} characters');
    });

    test('🛡️ REGRESSION: Resource reading works correctly', () async {
      // Test reading the browser status resource
      final result = await server.readResource('puppeteer://status');

      expect(result, isNotNull);
      expect(result.mimeType, equals('application/json'));

      final statusData = jsonDecode(result.data!);
      expect(statusData['browserActive'], isA<bool>());
      expect(statusData['hasPage'], isA<bool>());
      expect(statusData['headless'], isA<bool>());
      expect(statusData['version'], equals('3.19.0'));

      print(
          '✅ Resource reading successful: ${result.data?.length ?? 0} characters');
    });

    test('🛡️ REGRESSION: Error handling for invalid URLs', () async {
      // Test navigation to an invalid URL
      expect(
        () async => await server.callTool('puppeteer_navigate', {
          'url': 'https://invalid-domain-that-does-not-exist-12345.com',
          'timeout': 10000, // Shorter timeout for faster failure
        }),
        throwsA(isA<MCPServerException>()),
      );

      print('✅ Error handling for invalid URL: Exception thrown as expected');
    });

    test('🛡️ REGRESSION: Error handling for invalid selectors', () async {
      // First navigate to a page
      await server.callTool('puppeteer_navigate', {
        'url': 'https://httpbin.org/html',
        'waitUntil': 'networkidle2',
      });

      // Wait a moment for page to load
      await Future.delayed(Duration(seconds: 2));

      // Test innerText extraction with invalid selector
      final result = await server.callTool('puppeteer_get_inner_text', {
        'selector': '#non-existent-element',
        'timeout': 10000,
      });

      // This should still work because we fall back to document.body.innerText
      expect(result.isError, isFalse);
      expect(result.content.length, greaterThan(0));

      final text = result.content.first.text;
      expect(text, isNotEmpty);

      print(
          '✅ Fallback handling for invalid selector: ${text?.length ?? 0} characters');
    });

    test('🛡️ REGRESSION: Browser cleanup works correctly', () async {
      // Test browser cleanup
      final result = await server.callTool('puppeteer_close_browser', {});

      expect(result.isError, isFalse);
      expect(result.content.length, greaterThan(0));
      expect(result.content.first.text,
          contains('Browser closed and resources cleaned up'));

      print(
          '✅ Browser cleanup successful: ${result.content.first.text ?? "No text"}');
    });

    test('🛡️ REGRESSION: Resources are properly exposed', () async {
      final resources = await server.getAvailableResources();
      expect(resources.length, greaterThan(0));

      final statusResource =
          resources.firstWhere((r) => r.uri == 'puppeteer://status');
      expect(statusResource.name, equals('Browser Status'));
      expect(statusResource.mimeType, equals('application/json'));

      // Test reading the status resource
      final content = await server.readResource('puppeteer://status');
      expect(content.type, equals('resource'));
      expect(content.mimeType, equals('application/json'));

      final statusData = jsonDecode(content.data!);
      expect(statusData['version'], equals('3.19.0'));
      expect(statusData['headless'], isA<bool>());

      print('✅ Resources properly exposed: ${statusData['version']}');
    });

    test('🛡️ REGRESSION: Prompts are properly exposed', () async {
      final prompts = await server.getAvailablePrompts();
      expect(prompts.length, greaterThan(0));

      final webScrapingPrompt =
          prompts.firstWhere((p) => p.name == 'web_scraping_workflow');
      expect(webScrapingPrompt.description, contains('web scraping'));
      expect(webScrapingPrompt.arguments?.length, equals(2));

      // Test getting the prompt
      final messages = await server.getPrompt('web_scraping_workflow', {
        'url': 'https://example.com',
        'content_type': 'text',
      });

      expect(messages.length, equals(2));
      expect(messages[0].method, equals('tools/call'));
      expect(messages[1].method, equals('tools/call'));

      print('✅ Prompts properly exposed: ${prompts.length} prompts available');
    });

    test(
        '🛡️ REGRESSION: Complete workflow from navigation to content extraction',
        () async {
      // Test the complete workflow: navigate -> extract text -> extract HTML -> cleanup

      // Step 1: Navigate to the page
      final navigateResult = await server.callTool('puppeteer_navigate', {
        'url': 'https://httpbin.org/html',
        'waitUntil': 'networkidle2',
      });

      expect(navigateResult.isError, isFalse);
      expect(navigateResult.content.first.text, contains('Herman Melville'));

      // Step 2: Wait for page to load
      await Future.delayed(Duration(seconds: 2));

      // Step 3: Extract text content
      final textResult = await server.callTool('puppeteer_get_inner_text', {
        'selector': 'body',
      });

      expect(textResult.isError, isFalse);
      expect(textResult.content.first.text?.length ?? 0, greaterThan(100));

      // Step 4: Extract HTML content
      final htmlResult = await server.callTool('puppeteer_get_inner_html', {
        'selector': 'body',
      });

      expect(htmlResult.isError, isFalse);
      expect(htmlResult.content.first.text?.length ?? 0, greaterThan(500));
      expect(htmlResult.content.first.text, contains('<h1>'));

      // Step 5: Clean up
      final cleanupResult =
          await server.callTool('puppeteer_close_browser', {});
      expect(cleanupResult.isError, isFalse);

      print('✅ Complete workflow successful');
      print('📄 Navigation: ${navigateResult.content.first.text}');
      print(
          '📄 Text length: ${textResult.content.first.text?.length ?? 0} characters');
      print(
          '📄 HTML length: ${htmlResult.content.first.text?.length ?? 0} characters');
    });

    test('🛡️ REGRESSION: Server remains responsive after multiple operations',
        () async {
      // Test that the server remains responsive after multiple operations
      for (int i = 0; i < 3; i++) {
        // Navigate
        final navigateResult = await server.callTool('puppeteer_navigate', {
          'url': 'https://httpbin.org/html',
          'waitUntil': 'networkidle2',
        });
        expect(navigateResult.isError, isFalse);

        // Extract content
        final textResult = await server.callTool('puppeteer_get_inner_text', {
          'selector': 'body',
        });
        expect(textResult.isError, isFalse);

        // Clean up
        await server.callTool('puppeteer_close_browser', {});

        print('✅ Operation $i completed successfully');
      }

      print('✅ Server remained responsive through multiple operations');
    });
  });
}
