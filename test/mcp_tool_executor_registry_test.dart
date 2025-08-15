import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 MCP TOOL EXECUTOR REGISTRY TESTS: Verify the new API works correctly
///
/// Tests the McpToolExecutorRegistry class that provides the API needed by
/// the accounting workflow. This ensures the registry can load MCP servers
/// from configuration files and manage their lifecycle properly.
void main() {
  group('🧪 MCP Tool Executor Registry Tests', () {
    late File tempConfigFile;
    late McpToolExecutorRegistry registry;

    setUp(() {
      // Create a temporary config file for testing
      tempConfigFile = File('test_temp_mcp_config.json');
      tempConfigFile.writeAsStringSync('''
{
  "mcpServers": {
    "test_server": {
      "command": "echo",
      "args": ["test"],
      "env": {},
      "description": "Test MCP server for unit testing"
    }
  }
}
''');
    });

    tearDown(() async {
      // Clean up temporary file
      if (await tempConfigFile.exists()) {
        await tempConfigFile.delete();
      }
    });

    test(
        '🛡️ REGRESSION: McpToolExecutorRegistry can be created with config file',
        () {
      registry = McpToolExecutorRegistry(mcpConfig: tempConfigFile);
      expect(registry, isNotNull);
      expect(registry.mcpConfig, equals(tempConfigFile));
    });

    test('🛡️ REGRESSION: Registry provides allTools getter for compatibility',
        () {
      registry = McpToolExecutorRegistry(mcpConfig: tempConfigFile);
      expect(registry.allTools, isA<List<Tool>>());
      expect(registry.allTools, isEmpty); // No tools until initialized
    });

    test('🛡️ REGRESSION: Registry provides toolCount getter', () {
      registry = McpToolExecutorRegistry(mcpConfig: tempConfigFile);
      expect(registry.toolCount, equals(0)); // No tools until initialized
    });

    test('🛡️ REGRESSION: Registry provides status information', () {
      registry = McpToolExecutorRegistry(mcpConfig: tempConfigFile);
      final status = registry.getStatus();

      expect(status, isA<Map<String, dynamic>>());
      expect(status['isInitialized'], isFalse);
      expect(status['executorCount'], equals(0));
      expect(status['toolCount'], equals(0));
      expect(status['mcpClientCount'], equals(0));
      expect(status['mcpServerStatus'], isA<Map<String, dynamic>>());
    });

    test(
        '🛡️ REGRESSION: Registry can be shut down safely when not initialized',
        () async {
      registry = McpToolExecutorRegistry(mcpConfig: tempConfigFile);

      // Should not throw when shutting down uninitialized registry
      await expectLater(registry.shutdown(), completes);
    });

    test('🛡️ REGRESSION: Registry provides correct API interface', () {
      registry = McpToolExecutorRegistry(mcpConfig: tempConfigFile);

      // Test that the registry provides the expected API
      expect(registry.allTools, isA<List<Tool>>());
      expect(registry.toolCount, equals(0));
      expect(registry.executorCount, equals(0));

      final status = registry.getStatus();
      expect(status['isInitialized'], isFalse);
      expect(status['executorCount'], equals(0));
      expect(status['toolCount'], equals(0));
      expect(status['mcpClientCount'], equals(0));
    });
  });
}
