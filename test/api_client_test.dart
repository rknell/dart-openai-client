import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 API CLIENT TEST SUITE: Testing for ApiClient class
///
/// Tests the ApiClient constructor and properties since HTTP mocking
/// requires more complex setup that's better suited for integration tests.
void main() {
  group('ApiClient Tests', () {
    group('🏗️ Constructor and Properties', () {
      test('✅ Creates API client with correct properties', () {
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.com',
          apiKey: 'test-api-key',
        );

        expect(apiClient.baseUrl, equals('https://api.test.com'));
        expect(apiClient.apiKey, equals('test-api-key'));
      });

      test('✅ Creates API client with different URLs', () {
        final openaiClient = ApiClient(
          baseUrl: 'https://api.openai.com/v1',
          apiKey: 'openai-key',
        );

        expect(openaiClient.baseUrl, equals('https://api.openai.com/v1'));
        expect(openaiClient.apiKey, equals('openai-key'));
      });

      test('✅ Creates API client with DeepSeek URL', () {
        final deepseekClient = ApiClient(
          baseUrl: 'https://api.deepseek.com/v1',
          apiKey: 'deepseek-key',
        );

        expect(deepseekClient.baseUrl, equals('https://api.deepseek.com/v1'));
        expect(deepseekClient.apiKey, equals('deepseek-key'));
      });
    });

    group('🔧 Configuration Validation', () {
      test('✅ Handles empty base URL', () {
        final apiClient = ApiClient(
          baseUrl: '',
          apiKey: 'test-key',
        );

        expect(apiClient.baseUrl, equals(''));
        expect(apiClient.apiKey, equals('test-key'));
      });

      test('✅ Handles empty API key', () {
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.com',
          apiKey: '',
        );

        expect(apiClient.baseUrl, equals('https://api.test.com'));
        expect(apiClient.apiKey, equals(''));
      });

      test('✅ Handles special characters in API key', () {
        final specialKey = 'sk-1234567890abcdef';
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.com',
          apiKey: specialKey,
        );

        expect(apiClient.apiKey, equals(specialKey));
      });
    });

    group('📋 API Endpoint Construction', () {
      test('✅ Base URL is properly formatted', () {
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.com',
          apiKey: 'test-key',
        );

        // Verify the base URL doesn't have trailing slashes
        expect(apiClient.baseUrl, equals('https://api.test.com'));
      });

      test('✅ Base URL with trailing slash is handled', () {
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.com/',
          apiKey: 'test-key',
        );

        expect(apiClient.baseUrl, equals('https://api.test.com/'));
      });

      test('✅ Base URL with path is preserved', () {
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.com/v1',
          apiKey: 'test-key',
        );

        expect(apiClient.baseUrl, equals('https://api.test.com/v1'));
      });
    });
  });
}
