import 'package:test/test.dart';
import 'package:dart_openai_client/dart_openai_client.dart';

/// 🧪 AGENT TEST SUITE: Comprehensive testing for Agent class
///
/// Tests conversation management, tool execution, and message handling
/// to ensure the Agent class works correctly in all scenarios.
void main() {
  group('Agent Tests', () {
    late MockApiClient mockApiClient;
    late ToolExecutorRegistry toolRegistry;
    late WeatherToolExecutor weatherExecutor;
    late Agent agent;

    setUp(() {
      mockApiClient = MockApiClient();
      toolRegistry = ToolExecutorRegistry();
      weatherExecutor = WeatherToolExecutor();
      toolRegistry.registerExecutor(weatherExecutor);

      agent = Agent(
        apiClient: mockApiClient,
        toolRegistry: toolRegistry,
        messages: [],
        systemPrompt: 'You are a helpful weather assistant.',
      );
    });

    group('🛠️ Constructor and Properties', () {
      test('✅ Creates agent with correct initial state', () {
        expect(agent.apiClient, equals(mockApiClient));
        expect(agent.toolRegistry, equals(toolRegistry));
        expect(
            agent.systemPrompt, equals('You are a helpful weather assistant.'));
        expect(agent.messages, isEmpty);
        expect(agent.messageCount, equals(0));
        expect(agent.conversationHistory, isEmpty);
      });

      test('✅ Creates agent with existing messages', () {
        final existingMessages = [
          Message.user(content: 'Hello'),
          Message.assistant(content: 'Hi there!'),
        ];

        final agentWithMessages = Agent(
          apiClient: mockApiClient,
          toolRegistry: toolRegistry,
          messages: existingMessages,
          systemPrompt: 'Test prompt',
        );

        expect(agentWithMessages.messages, equals(existingMessages));
        expect(agentWithMessages.messageCount, equals(2));
      });
    });

    group('📚 Conversation Management', () {
      test('✅ System prompt is automatically managed', () async {
        // Mock API response
        mockApiClient.setMockResponse(Message.assistant(
            content: 'Hello! How can I help you with weather?'));

        await agent.sendMessage('What\'s the weather like?');

        // Check that system message is first
        expect(agent.messages.first.role, equals('system'));
        expect(agent.messages.first.content,
            equals('You are a helpful weather assistant.'));

        // Check that user message was added
        expect(agent.messages[1].role, equals('user'));
        expect(agent.messages[1].content, equals('What\'s the weather like?'));

        // Check that assistant response was added
        expect(agent.messages[2].role, equals('assistant'));
        expect(agent.messages[2].content,
            equals('Hello! How can I help you with weather?'));
      });

      test('✅ Only one system message is maintained', () async {
        mockApiClient
            .setMockResponse(Message.assistant(content: 'First response'));

        await agent.sendMessage('First message');

        // Send second message
        mockApiClient
            .setMockResponse(Message.assistant(content: 'Second response'));
        await agent.sendMessage('Second message');

        // Should only have one system message
        final systemMessages =
            agent.messages.where((msg) => msg.role == 'system').toList();
        expect(systemMessages.length, equals(1));
        expect(systemMessages.first.content,
            equals('You are a helpful weather assistant.'));
      });

      test('✅ Message count increases correctly', () async {
        expect(agent.messageCount, equals(0));

        mockApiClient.setMockResponse(Message.assistant(content: 'Response'));
        await agent.sendMessage('Test message');

        // System + User + Assistant = 3 messages
        expect(agent.messageCount, equals(3));
      });

      test('✅ Conversation history is accessible', () async {
        mockApiClient.setMockResponse(Message.assistant(content: 'Response'));
        await agent.sendMessage('Test message');

        final history = agent.conversationHistory;
        expect(history.length, equals(3));
        expect(history.first.role, equals('system'));
        expect(history[1].role, equals('user'));
        expect(history[2].role, equals('assistant'));
      });

      test('✅ Last message getter works correctly', () async {
        expect(agent.lastMessage, equals(''));

        mockApiClient.setMockResponse(
            Message.assistant(content: 'Last message content'));
        await agent.sendMessage('Test message');

        expect(agent.lastMessage, equals('Last message content'));
      });
    });

    group('🧹 Conversation Clearing', () {
      test('✅ Clear conversation removes non-system messages', () async {
        mockApiClient.setMockResponse(Message.assistant(content: 'Response'));
        await agent.sendMessage('Test message');

        expect(agent.messageCount, equals(3)); // System + User + Assistant

        agent.clearConversation();

        expect(agent.messageCount, equals(1)); // Only system message remains
        expect(agent.messages.first.role, equals('system'));
        expect(agent.messages.first.content,
            equals('You are a helpful weather assistant.'));
      });
    });

    group('🛠️ Tool Execution', () {
      test('✅ Tool calls are executed automatically', () async {
        // Mock API response with tool call
        final toolCall = ToolCall(
          id: 'call_123',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "Hangzhou"}',
          ),
        );

        mockApiClient.setMockResponse(Message.assistant(
          content: 'I will check the weather',
          toolCalls: [toolCall],
        ));

        // Mock final response after tool execution
        mockApiClient.setMockResponse(Message.assistant(
          content: 'The weather in Hangzhou is 24°C, Partly Cloudy',
        ));

        final response =
            await agent.sendMessage('What\'s the weather in Hangzhou?');

        expect(response.content,
            equals('The weather in Hangzhou is 24°C, Partly Cloudy'));

        // Check that tool result was added to conversation
        final toolResult =
            agent.messages.where((msg) => msg.role == 'tool').toList();
        expect(toolResult.length, equals(1));
        expect(toolResult.first.toolCallId, equals('call_123'));
        expect(toolResult.first.content, equals('24°C, Partly Cloudy'));
      });

      test('✅ Multiple tool calls are executed', () async {
        final toolCall1 = ToolCall(
          id: 'call_1',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "Tokyo"}',
          ),
        );

        final toolCall2 = ToolCall(
          id: 'call_2',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "Paris"}',
          ),
        );

        mockApiClient.setMockResponse(Message.assistant(
          content: 'I will check weather for both cities',
          toolCalls: [toolCall1, toolCall2],
        ));

        mockApiClient.setMockResponse(Message.assistant(
          content: 'Weather checked for both cities',
        ));

        await agent.sendMessage('Check weather for Tokyo and Paris');

        // Check that both tool results were added
        final toolResults =
            agent.messages.where((msg) => msg.role == 'tool').toList();
        expect(toolResults.length, equals(2));
        expect(toolResults.any((msg) => msg.toolCallId == 'call_1'), isTrue);
        expect(toolResults.any((msg) => msg.toolCallId == 'call_2'), isTrue);
      });

      test('✅ Tool execution errors are handled gracefully', () async {
        // Mock API response with tool call
        final toolCall = ToolCall(
          id: 'call_error',
          type: 'function',
          function: ToolCallFunction(
            name: 'get_weather',
            arguments: '{"location": "InvalidLocation"}',
          ),
        );

        mockApiClient.setMockResponse(Message.assistant(
          content: 'I will check the weather',
          toolCalls: [toolCall],
        ));

        // Mock final response after tool execution
        mockApiClient.setMockResponse(Message.assistant(
          content: 'I encountered an error checking the weather',
        ));

        await agent.sendMessage('Check weather for InvalidLocation');

        // Check that tool result was added to conversation
        final toolResults =
            agent.messages.where((msg) => msg.role == 'tool').toList();
        expect(toolResults.length, equals(1));
        expect(toolResults.first.toolCallId, equals('call_error'));
        expect(toolResults.first.content, contains('Weather data unavailable'));
      });
    });

    group('🚀 Message Sending', () {
      test('✅ Send message returns correct response', () async {
        final expectedResponse =
            Message.assistant(content: 'Hello! How can I help you?');
        mockApiClient.setMockResponse(expectedResponse);

        final response = await agent.sendMessage('Hello');

        expect(response, equals(expectedResponse));
      });

      test('✅ Send message adds user message to conversation', () async {
        mockApiClient.setMockResponse(Message.assistant(content: 'Response'));

        await agent.sendMessage('Test user message');

        final userMessages =
            agent.messages.where((msg) => msg.role == 'user').toList();
        expect(userMessages.length, equals(1));
        expect(userMessages.first.content, equals('Test user message'));
      });

      test('✅ Send message adds assistant response to conversation', () async {
        final assistantResponse =
            Message.assistant(content: 'Assistant response');
        mockApiClient.setMockResponse(assistantResponse);

        await agent.sendMessage('Test message');

        final assistantMessages =
            agent.messages.where((msg) => msg.role == 'assistant').toList();
        expect(assistantMessages.length, equals(1));
        expect(assistantMessages.first.content, equals('Assistant response'));
      });
    });
  });
}

/// 🎭 MOCK API CLIENT: For testing Agent class without real API calls
class MockApiClient implements ApiClient {
  final List<Message> _mockResponses = [];

  void setMockResponse(Message response) {
    _mockResponses.add(response);
  }

  @override
  String get baseUrl => 'https://test.api.com';

  @override
  String get apiKey => 'test-key';

  @override
  Future<Message> sendMessage(List<Message> messages, List<Tool> tools) async {
    if (_mockResponses.isEmpty) {
      throw Exception('Mock response not set');
    }
    return _mockResponses.removeAt(0);
  }
}
