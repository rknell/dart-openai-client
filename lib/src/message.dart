/// 🎯 MESSAGE: OpenAI API Message with Tool Call Support
///
/// Represents a message in the conversation with support for:
/// - Standard text content
/// - Tool calls (function calls)
/// - Tool results
class Message {
  final String role;
  final String? content;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;

  const Message({
    required this.role,
    this.content,
    this.toolCalls,
    this.toolCallId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] as String,
      content: json['content'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List<dynamic>)
              .map((item) => ToolCall.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      toolCallId: json['tool_call_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      if (content != null) 'content': content,
      if (toolCalls != null) 'tool_calls': toolCalls!.map((tc) => tc.toJson()).toList(),
      if (toolCallId != null) 'tool_call_id': toolCallId,
    };
  }

  /// 🔧 CREATE TOOL RESULT: Create a tool result message
  ///
  /// Used when responding to a tool call with the result
  factory Message.toolResult({
    required String toolCallId,
    required String content,
  }) {
    return Message(
      role: 'tool',
      content: content,
      toolCallId: toolCallId,
    );
  }

  /// 🔧 CREATE USER MESSAGE: Create a user message
  factory Message.user({required String content}) {
    return Message(role: 'user', content: content);
  }

  /// 🔧 CREATE ASSISTANT MESSAGE: Create an assistant message
  factory Message.assistant({String? content, List<ToolCall>? toolCalls}) {
    return Message(role: 'assistant', content: content, toolCalls: toolCalls);
  }

  /// 🔧 CREATE SYSTEM MESSAGE: Create a system message
  factory Message.system({required String content}) {
    return Message(role: 'system', content: content);
  }

  @override
  String toString() {
    if (toolCalls != null && toolCalls!.isNotEmpty) {
      return 'Message(role: $role, toolCalls: ${toolCalls!.length})';
    }
    return 'Message(role: $role, content: ${content?.substring(0, content!.length > 50 ? 50 : content!.length)}...)';
  }
}

/// 🛠️ TOOL CALL: Function call from the model
///
/// Represents a tool call that the model wants to make
class ToolCall {
  final String id;
  final String type;
  final ToolCallFunction function;

  const ToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      type: json['type'] as String,
      function: ToolCallFunction.fromJson(json['function'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'function': function.toJson(),
    };
  }

  @override
  String toString() {
    return 'ToolCall(id: $id, function: ${function.name})';
  }
}

/// 🔧 TOOL CALL FUNCTION: The function to be called
///
/// Contains the function name and arguments
class ToolCallFunction {
  final String name;
  final String arguments;

  const ToolCallFunction({
    required this.name,
    required this.arguments,
  });

  factory ToolCallFunction.fromJson(Map<String, dynamic> json) {
    return ToolCallFunction(
      name: json['name'] as String,
      arguments: json['arguments'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'arguments': arguments,
    };
  }

  @override
  String toString() {
    return 'ToolCallFunction(name: $name, arguments: $arguments)';
  }
}
