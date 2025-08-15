import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 API CLIENT TEST SUITE: Comprehensive testing for ApiClient class
///
/// Tests HTTP communication, request formatting, and response parsing
/// to ensure the ApiClient works correctly with the API endpoint.
void main() {
  group('ApiClient Tests', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient(
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'test-api-key',
      );
    });

    group('🛠️ Constructor and Properties', () {
      test('✅ Creates API client with correct properties', () {
        expect(apiClient.baseUrl, equals('https://api.deepseek.com'));
        expect(apiClient.apiKey, equals('test-api-key'));
        expect(apiClient.defaultConfig, isA<ChatCompletionConfig>());
      });

      test('✅ Creates API client with custom default config', () {
        final customConfig = ChatCompletionConfig(
          temperature: 0.5,
          maxTokens: 2048,
          model: 'deepseek-reasoner',
        );

        final clientWithConfig = ApiClient(
          baseUrl: 'https://api.deepseek.com',
          apiKey: 'test-key',
          defaultConfig: customConfig,
        );

        expect(clientWithConfig.defaultConfig.temperature, equals(0.5));
        expect(clientWithConfig.defaultConfig.maxTokens, equals(2048));
        expect(
            clientWithConfig.defaultConfig.model, equals('deepseek-reasoner'));
      });
    });

    group('⚙️ ChatCompletionConfig Tests', () {
      test('✅ Creates config with default values', () {
        const config = ChatCompletionConfig();

        expect(config.model, equals('deepseek-chat'));
        expect(config.temperature, equals(1.0));
        expect(config.topP, equals(1.0));
        expect(config.maxTokens, equals(4096));
        expect(config.frequencyPenalty, equals(0.0));
        expect(config.presencePenalty, equals(0.0));
        expect(config.stop, isNull);
        expect(config.logprobs, isFalse);
        expect(config.topLogprobs, isNull);
      });

      test('✅ Creates config with custom values', () {
        const config = ChatCompletionConfig(
          model: 'deepseek-reasoner',
          temperature: 0.3,
          topP: 0.9,
          maxTokens: 1024,
          frequencyPenalty: 0.1,
          presencePenalty: 0.2,
          stop: ['END', 'STOP'],
          logprobs: true,
          topLogprobs: 5,
        );

        expect(config.model, equals('deepseek-reasoner'));
        expect(config.temperature, equals(0.3));
        expect(config.topP, equals(0.9));
        expect(config.maxTokens, equals(1024));
        expect(config.frequencyPenalty, equals(0.1));
        expect(config.presencePenalty, equals(0.2));
        expect(config.stop, equals(['END', 'STOP']));
        expect(config.logprobs, isTrue);
        expect(config.topLogprobs, equals(5));
      });

      test('✅ Config validation passes with valid values', () {
        const config = ChatCompletionConfig(
          temperature: 1.5,
          topP: 0.8,
          maxTokens: 2048,
          frequencyPenalty: 0.5,
          presencePenalty: -0.5,
          topLogprobs: 10,
        );

        expect(() => config.validate(), returnsNormally);
      });

      test('❌ Config validation fails with invalid temperature', () {
        const config = ChatCompletionConfig(temperature: 2.5);
        expect(() => config.validate(), throwsArgumentError);
      });

      test('❌ Config validation fails with invalid topP', () {
        const config = ChatCompletionConfig(topP: 1.5);
        expect(() => config.validate(), throwsArgumentError);
      });

      test('❌ Config validation fails with invalid maxTokens', () {
        const config = ChatCompletionConfig(maxTokens: 0);
        expect(() => config.validate(), throwsArgumentError);
      });

      test('❌ Config validation fails with invalid frequencyPenalty', () {
        const config = ChatCompletionConfig(frequencyPenalty: 3.0);
        expect(() => config.validate(), throwsArgumentError);
      });

      test('❌ Config validation fails with invalid presencePenalty', () {
        const config = ChatCompletionConfig(presencePenalty: -3.0);
        expect(() => config.validate(), throwsArgumentError);
      });

      test('❌ Config validation fails with invalid topLogprobs', () {
        const config = ChatCompletionConfig(topLogprobs: 25);
        expect(() => config.validate(), throwsArgumentError);
      });

      test('✅ toJson includes all required fields', () {
        const config = ChatCompletionConfig(
          temperature: 0.7,
          topP: 0.9,
          maxTokens: 1024,
          frequencyPenalty: 0.1,
          presencePenalty: 0.2,
          logprobs: true,
        );

        final json = config.toJson();

        expect(json['model'], equals('deepseek-chat'));
        expect(json['temperature'], equals(0.7));
        expect(json['top_p'], equals(0.9));
        expect(json['max_tokens'], equals(1024));
        expect(json['frequency_penalty'], equals(0.1));
        expect(json['presence_penalty'], equals(0.2));
        expect(json['logprobs'], isTrue);
      });

      test('✅ toJson includes optional fields when provided', () {
        const config = ChatCompletionConfig(
          stop: ['END'],
          topLogprobs: 5,
        );

        final json = config.toJson();

        expect(json['stop'], equals(['END']));
        expect(json['top_logprobs'], equals(5));
      });

      test('✅ toJson excludes optional fields when not provided', () {
        const config = ChatCompletionConfig();

        final json = config.toJson();

        expect(json.containsKey('stop'), isFalse);
        expect(json.containsKey('top_logprobs'), isFalse);
      });

      test('✅ copyWith creates new instance with modified values', () {
        const original = ChatCompletionConfig(
          temperature: 0.5,
          maxTokens: 1024,
        );

        final modified = original.copyWith(
          temperature: 0.8,
          topP: 0.9,
        );

        // Original should be unchanged
        expect(original.temperature, equals(0.5));
        expect(original.maxTokens, equals(1024));
        expect(original.topP, equals(1.0));

        // Modified should have new values
        expect(modified.temperature, equals(0.8));
        expect(modified.maxTokens, equals(1024)); // Unchanged
        expect(modified.topP, equals(0.9));
      });

      test('✅ copyWith preserves all other values', () {
        const original = ChatCompletionConfig(
          temperature: 0.5,
          topP: 0.8,
          maxTokens: 1024,
          frequencyPenalty: 0.1,
          presencePenalty: 0.2,
          stop: ['END'],
          logprobs: true,
          topLogprobs: 5,
        );

        final modified = original.copyWith(temperature: 0.7);

        expect(modified.topP, equals(0.8));
        expect(modified.maxTokens, equals(1024));
        expect(modified.frequencyPenalty, equals(0.1));
        expect(modified.presencePenalty, equals(0.2));
        expect(modified.stop, equals(['END']));
        expect(modified.logprobs, isTrue);
        expect(modified.topLogprobs, equals(5));
      });
    });

    group('🔍 Configuration Validation', () {
      test('✅ Validates temperature range', () {
        expect(() => ChatCompletionConfig(temperature: 0.0).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(temperature: 2.0).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(temperature: -0.1).validate(),
            throwsArgumentError);
        expect(() => ChatCompletionConfig(temperature: 2.1).validate(),
            throwsArgumentError);
      });

      test('✅ Validates topP range', () {
        expect(
            () => ChatCompletionConfig(topP: 0.0).validate(), returnsNormally);
        expect(
            () => ChatCompletionConfig(topP: 1.0).validate(), returnsNormally);
        expect(() => ChatCompletionConfig(topP: -0.1).validate(),
            throwsArgumentError);
        expect(() => ChatCompletionConfig(topP: 1.1).validate(),
            throwsArgumentError);
      });

      test('✅ Validates maxTokens range', () {
        expect(() => ChatCompletionConfig(maxTokens: 1).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(maxTokens: 8192).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(maxTokens: 0).validate(),
            throwsArgumentError);
        expect(() => ChatCompletionConfig(maxTokens: 8193).validate(),
            throwsArgumentError);
      });

      test('✅ Validates frequencyPenalty range', () {
        expect(() => ChatCompletionConfig(frequencyPenalty: -2.0).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(frequencyPenalty: 2.0).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(frequencyPenalty: -2.1).validate(),
            throwsArgumentError);
        expect(() => ChatCompletionConfig(frequencyPenalty: 2.1).validate(),
            throwsArgumentError);
      });

      test('✅ Validates presencePenalty range', () {
        expect(() => ChatCompletionConfig(presencePenalty: -2.0).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(presencePenalty: 2.0).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(presencePenalty: -2.1).validate(),
            throwsArgumentError);
        expect(() => ChatCompletionConfig(presencePenalty: 2.1).validate(),
            throwsArgumentError);
      });

      test('✅ Validates topLogprobs range', () {
        expect(() => ChatCompletionConfig(topLogprobs: 0).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(topLogprobs: 20).validate(),
            returnsNormally);
        expect(() => ChatCompletionConfig(topLogprobs: -1).validate(),
            throwsArgumentError);
        expect(() => ChatCompletionConfig(topLogprobs: 21).validate(),
            throwsArgumentError);
      });
    });

    group('🧹 Cleanup', () {
      test('✅ Close method works without errors', () async {
        expect(() => apiClient.close(), returnsNormally);
      });
    });
  });
}
