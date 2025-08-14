import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 TOOL TEST SUITE: Comprehensive testing for Tool and FunctionObject classes
///
/// Tests serialization, deserialization, equality, and all functionality
/// to ensure the Tool system works correctly in all scenarios.
void main() {
  group('Tool Tests', () {
    group('🛠️ Tool Class', () {
      test('✅ Creates tool with required parameters', () {
        final function = FunctionObject(
          name: 'test_function',
          description: 'A test function',
          parameters: {'type': 'object'},
        );

        final tool = Tool(function: function);

        expect(tool.type, equals('function'));
        expect(tool.function, equals(function));
      });

      test('✅ Creates tool with custom type', () {
        final function = FunctionObject(name: 'test_function');
        final tool = Tool(function: function, type: 'custom_type');

        expect(tool.type, equals('custom_type'));
        expect(tool.function, equals(function));
      });

      test('✅ Serializes to JSON correctly', () {
        final function = FunctionObject(
          name: 'test_function',
          description: 'A test function',
          parameters: {
            'type': 'object',
            'properties': {
              'test_param': {'type': 'string'}
            },
            'required': ['test_param']
          },
        );

        final tool = Tool(function: function);
        final json = tool.toJson();

        expect(json['type'], equals('function'));
        expect(json['function'], isMap);
        expect(json['function']['name'], equals('test_function'));
        expect(json['function']['description'], equals('A test function'));
        expect(json['function']['parameters'], isMap);
      });

      test('✅ Deserializes from JSON correctly', () {
        final json = {
          'type': 'function',
          'function': {
            'name': 'test_function',
            'description': 'A test function',
            'parameters': {
              'type': 'object',
              'properties': {
                'test_param': {'type': 'string'}
              },
              'required': ['test_param']
            }
          }
        };

        final tool = Tool.fromJson(json);

        expect(tool.type, equals('function'));
        expect(tool.function.name, equals('test_function'));
        expect(tool.function.description, equals('A test function'));
        expect(tool.function.parameters, isMap);
      });

      test('✅ Handles legacy flat JSON format', () {
        final json = {
          'type': 'function',
          'name': 'test_function',
          'description': 'A test function',
          'parameters': {
            'type': 'object',
            'properties': {
              'test_param': {'type': 'string'}
            }
          }
        };

        final tool = Tool.fromJson(json);

        expect(tool.type, equals('function'));
        expect(tool.function.name, equals('test_function'));
        expect(tool.function.description, equals('A test function'));
        expect(tool.function.parameters, isMap);
      });

      test('✅ Provides meaningful string representation', () {
        final function = FunctionObject(name: 'test_function');
        final tool = Tool(function: function);

        final string = tool.toString();
        expect(string, contains('Tool'));
        expect(string, contains('test_function'));
      });

      test('✅ Equality comparison works correctly', () {
        final function1 = FunctionObject(name: 'test_function');
        final function2 = FunctionObject(name: 'test_function');
        final function3 = FunctionObject(name: 'different_function');

        final tool1 = Tool(function: function1);
        final tool2 = Tool(function: function2);
        final tool3 = Tool(function: function3);

        expect(tool1, equals(tool2));
        expect(tool1, isNot(equals(tool3)));
        expect(tool1.hashCode, equals(tool2.hashCode));
      });
    });

    group('🔧 FunctionObject Class', () {
      test('✅ Creates function with required parameters', () {
        final function = FunctionObject(name: 'test_function');

        expect(function.name, equals('test_function'));
        expect(function.description, equals(''));
        expect(function.parameters, isEmpty);
        expect(function.strict, isFalse);
      });

      test('✅ Creates function with all parameters', () {
        final function = FunctionObject(
          name: 'test_function',
          description: 'A test function',
          parameters: {'type': 'object'},
          strict: true,
        );

        expect(function.name, equals('test_function'));
        expect(function.description, equals('A test function'));
        expect(function.parameters, equals({'type': 'object'}));
        expect(function.strict, isTrue);
      });

      test('✅ Serializes to JSON correctly', () {
        final function = FunctionObject(
          name: 'test_function',
          description: 'A test function',
          parameters: {
            'type': 'object',
            'properties': {
              'test_param': {'type': 'string'}
            }
          },
          strict: true,
        );

        final json = function.toJson();

        expect(json['name'], equals('test_function'));
        expect(json['description'], equals('A test function'));
        expect(json['parameters'], isMap);
        expect(json['strict'], isTrue);
      });

      test('✅ Omits empty optional fields from JSON', () {
        final function = FunctionObject(name: 'test_function');
        final json = function.toJson();

        expect(json['name'], equals('test_function'));
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('parameters'), isFalse);
        expect(json.containsKey('strict'), isFalse);
      });

      test('✅ Deserializes from JSON correctly', () {
        final json = {
          'name': 'test_function',
          'description': 'A test function',
          'parameters': {
            'type': 'object',
            'properties': {
              'test_param': {'type': 'string'}
            }
          },
          'strict': true
        };

        final function = FunctionObject.fromJson(json);

        expect(function.name, equals('test_function'));
        expect(function.description, equals('A test function'));
        expect(function.parameters, isMap);
        expect(function.strict, isTrue);
      });

      test('✅ Handles missing optional fields in JSON', () {
        final json = {'name': 'test_function'};

        final function = FunctionObject.fromJson(json);

        expect(function.name, equals('test_function'));
        expect(function.description, equals(''));
        expect(function.parameters, isEmpty);
        expect(function.strict, isFalse);
      });

      test('✅ Provides meaningful string representation', () {
        final function = FunctionObject(
          name: 'test_function',
          description: 'A test function',
        );

        final string = function.toString();
        expect(string, contains('FunctionObject'));
        expect(string, contains('test_function'));
        expect(string, contains('A test function'));
      });

      test('✅ Equality comparison works correctly', () {
        final function1 = FunctionObject(
          name: 'test_function',
          description: 'A test function',
          parameters: {'type': 'object'},
          strict: false,
        );

        final function2 = FunctionObject(
          name: 'test_function',
          description: 'A test function',
          parameters: {'type': 'object'},
          strict: false,
        );

        final function3 = FunctionObject(
          name: 'different_function',
          description: 'A test function',
          parameters: {'type': 'object'},
          strict: false,
        );

        expect(function1, equals(function2));
        expect(function1, isNot(equals(function3)));
        expect(function1.hashCode, equals(function2.hashCode));
      });

      test('✅ Equality handles different parameter maps', () {
        final function1 = FunctionObject(
          name: 'test_function',
          parameters: {'type': 'object', 'param1': 'value1'},
        );

        final function2 = FunctionObject(
          name: 'test_function',
          parameters: {'type': 'object', 'param1': 'value1'},
        );

        final function3 = FunctionObject(
          name: 'test_function',
          parameters: {'type': 'object', 'param1': 'value2'},
        );

        expect(function1, equals(function2));
        expect(function1, isNot(equals(function3)));
      });
    });

    group('🔍 Edge Cases and Validation', () {
      test('✅ Handles empty parameters map', () {
        final function = FunctionObject(
          name: 'test_function',
          parameters: {},
        );

        final json = function.toJson();
        expect(json.containsKey('parameters'), isFalse);
      });

      test('✅ Handles null parameters gracefully', () {
        final json = {
          'name': 'test_function',
          'parameters': null,
        };

        final function = FunctionObject.fromJson(json);
        expect(function.parameters, isEmpty);
      });

      test('✅ Handles complex nested parameters', () {
        final complexParams = {
          'type': 'object',
          'properties': {
            'user': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'age': {'type': 'number'},
                'preferences': {
                  'type': 'array',
                  'items': {'type': 'string'}
                }
              },
              'required': ['name']
            }
          }
        };

        final function = FunctionObject(
          name: 'complex_function',
          parameters: complexParams,
        );

        final json = function.toJson();
        expect(json['parameters'], equals(complexParams));

        final parsed = FunctionObject.fromJson(json);
        expect(parsed.parameters, equals(complexParams));
      });
    });
  });
}
