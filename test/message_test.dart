import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 MESSAGE TEST SUITE: Comprehensive testing for Message class
///
/// Tests message creation, serialization, deserialization, and tool call handling
/// to ensure the Message system works correctly in all scenarios.
void main() {
  group('Message Tests', () {
    group('🏗️ Message Creation', () {
      test('✅ Creates message with all parameters', () {
        final message = Message(
          role: 'user',
          content: 'Hello world',
          toolCalls: null,
          toolCallId: null,
        );

        expect(message.role, equals('user'));
        expect(message.content, equals('Hello world'));
        expect(message.toolCalls, isNull);
        expect(message.toolCallId, isNull);
      });

      test('✅ Creates message with minimal parameters', () {
        final message = Message(role: 'assistant');

        expect(message.role, equals('assistant'));
        expect(message.content, isNull);
        expect(message.toolCalls, isNull);
        expect(message.toolCallId, isNull);
      });
    });

    group('🔧 Factory Methods', () {
      test('✅ Message.user creates user message', () {
        final message = Message.user(content: 'Hello there');

        expect(message.role, equals('user'));
        expect(message.content, equals('Hello there'));
        expect(message.toolCalls, isNull);
        expect(message.toolCallId, isNull);
      });

      test('✅ Message.assistant creates assistant message', () {
        final message = Message.assistant(content: 'Hi there!');

        expect(message.role, equals('assistant'));
        expect(message.content, equals('Hi there!'));
        expect(message.toolCalls, isNull);
        expect(message.toolCallId, isNull);
      });

      test('✅ Message.assistant with tool calls', () {
        final toolCalls = [
          ToolCall(
            id: 'call_123',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_weather',
              arguments: '{"location": "Hangzhou"}',
            ),
          ),
        ];

        final message = Message.assistant(
          content: 'I will check the weather',
          toolCalls: toolCalls,
        );

        expect(message.role, equals('assistant'));
        expect(message.content, equals('I will check the weather'));
        expect(message.toolCalls, equals(toolCalls));
        expect(message.toolCallId, isNull);
      });

      test('✅ Message.system creates system message', () {
        final message = Message.system(content: 'You are a helpful assistant');

        expect(message.role, equals('system'));
        expect(message.content, equals('You are a helpful assistant'));
        expect(message.toolCalls, isNull);
        expect(message.toolCallId, isNull);
      });

      test('✅ Message.toolResult creates tool result message', () {
        final message = Message.toolResult(
          toolCallId: 'call_123',
          content: '24°C, Partly Cloudy',
        );

        expect(message.role, equals('tool'));
        expect(message.content, equals('24°C, Partly Cloudy'));
        expect(message.toolCalls, isNull);
        expect(message.toolCallId, equals('call_123'));
      });
    });

    group('📤 JSON Serialization', () {
      test('✅ Serializes basic message correctly', () {
        final message = Message.user(content: 'Hello world');
        final json = message.toJson();

        expect(json['role'], equals('user'));
        expect(json['content'], equals('Hello world'));
        expect(json.containsKey('tool_calls'), isFalse);
        expect(json.containsKey('tool_call_id'), isFalse);
      });

      test('✅ Serializes message with tool calls', () {
        final toolCalls = [
          ToolCall(
            id: 'call_123',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_weather',
              arguments: '{"location": "Hangzhou"}',
            ),
          ),
        ];

        final message = Message.assistant(
          content: 'I will check the weather',
          toolCalls: toolCalls,
        );

        final json = message.toJson();

        expect(json['role'], equals('assistant'));
        expect(json['content'], equals('I will check the weather'));
        expect(json['tool_calls'], isList);
        expect(json['tool_calls'].length, equals(1));
        expect(json['tool_calls'][0]['id'], equals('call_123'));
      });

      test('✅ Serializes message with tool call ID', () {
        final message = Message.toolResult(
          toolCallId: 'call_123',
          content: 'Weather result',
        );

        final json = message.toJson();

        expect(json['role'], equals('tool'));
        expect(json['content'], equals('Weather result'));
        expect(json['tool_call_id'], equals('call_123'));
      });

      test('✅ Omits null fields from JSON', () {
        final message = Message(role: 'user');
        final json = message.toJson();

        expect(json['role'], equals('user'));
        expect(json.containsKey('content'), isFalse);
        expect(json.containsKey('tool_calls'), isFalse);
        expect(json.containsKey('tool_call_id'), isFalse);
      });
    });

    group('📥 JSON Deserialization', () {
      test('✅ Deserializes basic message correctly', () {
        final json = {
          'role': 'user',
          'content': 'Hello world',
        };

        final message = Message.fromJson(json);

        expect(message.role, equals('user'));
        expect(message.content, equals('Hello world'));
        expect(message.toolCalls, isNull);
        expect(message.toolCallId, isNull);
      });

      test('✅ Deserializes message with tool calls', () {
        final json = {
          'role': 'assistant',
          'content': 'I will check the weather',
          'tool_calls': [
            {
              'id': 'call_123',
              'type': 'function',
              'function': {
                'name': 'get_weather',
                'arguments': '{"location": "Hangzhou"}',
              },
            },
          ],
        };

        final message = Message.fromJson(json);

        expect(message.role, equals('assistant'));
        expect(message.content, equals('I will check the weather'));
        expect(message.toolCalls, isNotNull);
        expect(message.toolCalls!.length, equals(1));
        expect(message.toolCalls!.first.id, equals('call_123'));
        expect(message.toolCalls!.first.function.name, equals('get_weather'));
      });

      test('✅ Deserializes message with tool call ID', () {
        final json = {
          'role': 'tool',
          'content': 'Weather result',
          'tool_call_id': 'call_123',
        };

        final message = Message.fromJson(json);

        expect(message.role, equals('tool'));
        expect(message.content, equals('Weather result'));
        expect(message.toolCallId, equals('call_123'));
      });

      test('✅ Handles missing optional fields gracefully', () {
        final json = {'role': 'user'};

        final message = Message.fromJson(json);

        expect(message.role, equals('user'));
        expect(message.content, isNull);
        expect(message.toolCalls, isNull);
        expect(message.toolCallId, isNull);
      });

      test('✅ Handles null tool calls gracefully', () {
        final json = {
          'role': 'assistant',
          'content': 'Hello',
          'tool_calls': null,
        };

        final message = Message.fromJson(json);

        expect(message.role, equals('assistant'));
        expect(message.content, equals('Hello'));
        expect(message.toolCalls, isNull);
      });
    });

    group('🔍 String Representation', () {
      test('✅ Provides meaningful string for basic message', () {
        final message = Message.user(content: 'Hello world');
        final string = message.toString();

        expect(string, contains('Message'));
        expect(string, contains('user'));
        expect(string, contains('Hello world'));
      });

      test('✅ Provides meaningful string for message with tool calls', () {
        final toolCalls = [
          ToolCall(
            id: 'call_123',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_weather',
              arguments: '{"location": "Hangzhou"}',
            ),
          ),
        ];

        final message = Message.assistant(
          content: 'I will check the weather',
          toolCalls: toolCalls,
        );

        final string = message.toString();

        expect(string, contains('Message'));
        expect(string, contains('assistant'));
        expect(string, contains('toolCalls: 1'));
      });

      test('✅ Truncates long content in string representation', () {
        final longContent = 'A' * 100; // 100 characters
        final message = Message.user(content: longContent);
        final string = message.toString();

        expect(string, contains('Message'));
        expect(string, contains('user'));
        expect(string, contains('...'));
        expect(string.length, lessThan(longContent.length));
      });
    });

    group('🛠️ Tool Call Integration', () {
      test('✅ ToolCall serialization works correctly', () {
        final toolCall = ToolCall(
          id: 'call_123',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "Hangzhou"}',
          ),
        );

        final json = toolCall.toJson();

        expect(json['id'], equals('call_123'));
        expect(json['type'], equals('function'));
        expect(json['function'], isMap);
        expect(json['function']['name'], equals('get_weather'));
      });

      test('✅ ToolCall deserialization works correctly', () {
        final json = {
          'id': 'call_123',
          'type': 'function',
          'function': {
            'name': 'get_weather',
            'arguments': '{"location": "Hangzhou"}',
          },
        };

        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.id, equals('call_123'));
        expect(toolCall.type, equals('function'));
        expect(toolCall.function.name, equals('get_weather'));
        expect(toolCall.function.arguments, equals('{"location": "Hangzhou"}'));
      });

      test('✅ ToolCallFunction serialization works correctly', () {
        final function = ToolCallFunction(
          name: 'get_weather',
          arguments: '{"location": "Hangzhou"}',
        );

        final json = function.toJson();

        expect(json['name'], equals('get_weather'));
        expect(json['arguments'], equals('{"location": "Hangzhou"}'));
      });

      test('✅ ToolCallFunction deserialization works correctly', () {
        final json = {
          'name': 'get_weather',
          'arguments': '{"location": "Hangzhou"}',
        };

        final function = ToolCallFunction.fromJson(json);

        expect(function.name, equals('get_weather'));
        expect(function.arguments, equals('{"location": "Hangzhou"}'));
      });

      test('✅ ToolCall string representation', () {
        final toolCall = ToolCall(
          id: 'call_123',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "Hangzhou"}',
          ),
        );

        final string = toolCall.toString();
        expect(string, contains('ToolCall'));
        expect(string, contains('call_123'));
        expect(string, contains('get_weather'));
      });

      test('✅ ToolCallFunction string representation', () {
        final function = ToolCallFunction(
          name: 'get_weather',
          arguments: '{"location": "Hangzhou"}',
        );

        final string = function.toString();
        expect(string, contains('ToolCallFunction'));
        expect(string, contains('get_weather'));
      });
    });

    group('🔍 Edge Cases and Validation', () {
      test('✅ Handles empty tool calls list', () {
        final message = Message.assistant(
          content: 'Hello',
          toolCalls: [],
        );

        final json = message.toJson();
        expect(json['tool_calls'], isEmpty);

        final parsed = Message.fromJson(json);
        expect(parsed.toolCalls, isEmpty);
      });

      test('✅ Handles complex nested tool calls', () {
        final toolCalls = [
          ToolCall(
            id: 'call_1',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_weather',
              arguments: '{"location": "Hangzhou"}',
            ),
          ),
          ToolCall(
            id: 'call_2',
            type: 'function',
            function: ToolCallFunction(
              name: 'get_time',
              arguments: '{"timezone": "Asia/Shanghai"}',
            ),
          ),
        ];

        final message = Message.assistant(
          content: 'I will get weather and time',
          toolCalls: toolCalls,
        );

        final json = message.toJson();
        final parsed = Message.fromJson(json);

        expect(parsed.toolCalls!.length, equals(2));
        expect(parsed.toolCalls!.any((tc) => tc.function.name == 'get_weather'),
            isTrue);
        expect(parsed.toolCalls!.any((tc) => tc.function.name == 'get_time'),
            isTrue);
      });
    });
  });
}
