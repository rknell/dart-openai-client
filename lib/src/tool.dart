/// 🛠️ TOOL CLASS: OpenAI API Tool Definition
///
/// Represents a tool that can be called by the model according to the OpenAI API specification.
/// Currently only supports function tools with JSON Schema parameters.
///
/// 📚 SPECIFICATION COMPLIANCE:
/// - Follows OpenAI API v1 specification exactly
/// - Supports up to 128 functions per request
/// - JSON Schema parameter validation
/// - Strict mode for exact schema adherence
class Tool {
  /// 🎯 TOOL TYPE: Always "function" for current API version
  ///
  /// Currently only "function" is supported by OpenAI API.
  /// Future versions may support additional tool types.
  final String type;

  /// 🔧 FUNCTION DEFINITION: The actual function to be called
  ///
  /// Contains the function name, description, parameters schema,
  /// and strict mode configuration.
  final FunctionObject function;

  /// 🏗️ CONSTRUCTOR: Create a new tool definition
  ///
  /// [function] - The function object containing callable details
  /// [type] - Tool type (defaults to "function" as per spec)
  const Tool({
    required this.function,
    this.type = 'function',
  });

  /// 📤 JSON SERIALIZATION: Convert to OpenAI API format
  ///
  /// Returns the tool in the exact format expected by the OpenAI API:
  /// ```json
  /// {
  ///   "type": "function",
  ///   "function": {
  ///     "name": "function_name",
  ///     "description": "What it does",
  ///     "parameters": {...}
  ///   }
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'function': function.toJson(),
    };
  }

  /// 📥 JSON DESERIALIZATION: Parse from OpenAI API format
  ///
  /// Creates a Tool instance from the JSON response format.
  /// Handles both the new nested structure and legacy flat structure.
  factory Tool.fromJson(Map<String, dynamic> json) {
    // 🆕 NEW FORMAT: Nested function structure (OpenAI API v1)
    if (json.containsKey('function')) {
      return Tool(
        type: json['type'] as String? ?? 'function',
        function:
            FunctionObject.fromJson(json['function'] as Map<String, dynamic>),
      );
    }

    // 🔄 LEGACY FORMAT: Flat structure (backward compatibility)
    // This handles the old format where fields were directly on the tool
    return Tool(
      type: json['type'] as String? ?? 'function',
      function: FunctionObject(
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        parameters: json['parameters'] as Map<String, dynamic>? ?? {},
        strict: json['strict'] as bool? ?? false,
      ),
    );
  }

  /// 🔍 STRING REPRESENTATION: Human-readable tool description
  @override
  String toString() {
    return 'Tool(type: $type, function: ${function.name})';
  }

  /// ⚖️ EQUALITY COMPARISON: Deep equality for tool instances
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tool && other.type == type && other.function == function;
  }

  /// 🔢 HASH CODE: Consistent hashing for collections
  @override
  int get hashCode {
    return Object.hash(type, function);
  }
}

/// 🔧 FUNCTION OBJECT: OpenAI API Function Definition
///
/// Represents a callable function with its metadata and parameter schema.
/// This is the actual function that gets called when the tool is invoked.
class FunctionObject {
  /// 📛 FUNCTION NAME: Unique identifier for the function
  ///
  /// Must be a-z, A-Z, 0-9, or contain underscores and dashes.
  /// Maximum length: 64 characters.
  ///
  /// Examples: "get_weather", "calculate_total", "send_email"
  final String name;

  /// 📝 FUNCTION DESCRIPTION: What the function does
  ///
  /// Used by the model to choose when and how to call the function.
  /// Should be clear and descriptive to help the model make good decisions.
  final String description;

  /// 🎯 PARAMETER SCHEMA: JSON Schema for function parameters
  ///
  /// Defines the structure and validation rules for function arguments.
  /// Follows JSON Schema specification for type safety and validation.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "type": "object",
  ///   "properties": {
  ///     "location": {"type": "string"},
  ///     "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
  ///   },
  ///   "required": ["location"]
  /// }
  /// ```
  final Map<String, dynamic> parameters;

  /// 🔒 STRICT MODE: Exact schema adherence enforcement
  ///
  /// When true, the model must follow the exact parameter schema.
  /// Only a subset of JSON Schema is supported in strict mode.
  ///
  /// Default: false (allows more flexible parameter generation)
  final bool strict;

  /// 🏗️ CONSTRUCTOR: Create a new function definition
  ///
  /// [name] - Function name (required, max 64 chars)
  /// [description] - What the function does
  /// [parameters] - JSON Schema for parameters
  /// [strict] - Whether to enforce exact schema adherence
  const FunctionObject({
    required this.name,
    this.description = '',
    this.parameters = const {},
    this.strict = false,
  });

  /// 📤 JSON SERIALIZATION: Convert to OpenAI API format
  ///
  /// Returns the function in the exact format expected by the OpenAI API.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };

    // Only include optional fields if they have meaningful values
    if (description.isNotEmpty) {
      json['description'] = description;
    }

    if (parameters.isNotEmpty) {
      json['parameters'] = parameters;
    }

    if (strict) {
      json['strict'] = strict;
    }

    return json;
  }

  /// 📥 JSON DESERIALIZATION: Parse from OpenAI API format
  ///
  /// Creates a FunctionObject instance from the JSON response format.
  factory FunctionObject.fromJson(Map<String, dynamic> json) {
    return FunctionObject(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      strict: json['strict'] as bool? ?? false,
    );
  }

  /// 🔍 STRING REPRESENTATION: Human-readable function description
  @override
  String toString() {
    return 'FunctionObject(name: $name, description: $description)';
  }

  /// ⚖️ EQUALITY COMPARISON: Deep equality for function instances
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FunctionObject &&
        other.name == name &&
        other.description == description &&
        other.parameters.toString() == parameters.toString() &&
        other.strict == strict;
  }

  /// 🔢 HASH CODE: Consistent hashing for collections
  @override
  int get hashCode {
    return Object.hash(name, description, parameters.toString(), strict);
  }
}
