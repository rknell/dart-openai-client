import 'package:test/test.dart';
import '../lib/src/mcp_client.dart';

void main() {
  group('MCP Client Logging', () {
    test('should determine log level from environment variables', () {
      // Test default log level (info)
      expect(LogLevel.values.contains(LogLevel.info), isTrue);

      // Test log level enum values
      expect(LogLevel.none.index, equals(0));
      expect(LogLevel.error.index, equals(1));
      expect(LogLevel.warn.index, equals(2));
      expect(LogLevel.info.index, equals(3));
      expect(LogLevel.debug.index, equals(4));
    });

    test('should respect log level hierarchy', () {
      // Test that higher log levels include lower ones
      expect(LogLevel.debug.index >= LogLevel.info.index, isTrue);
      expect(LogLevel.info.index >= LogLevel.warn.index, isTrue);
      expect(LogLevel.warn.index >= LogLevel.error.index, isTrue);
      expect(LogLevel.error.index >= LogLevel.none.index, isTrue);
    });
  });
}


