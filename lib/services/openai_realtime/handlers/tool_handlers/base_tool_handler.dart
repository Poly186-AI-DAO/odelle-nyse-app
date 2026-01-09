import 'dart:convert';

/// Base interface for tool handlers
abstract class BaseToolHandler {
  /// Handle the function call and return a response
  Future<Map<String, dynamic>> handle({
    required Map<String, dynamic> arguments,
    required String callId,
  });

  /// Get the name of the tool this handler manages
  String get toolName;

  /// Create a function call output event
  Map<String, dynamic> createOutputEvent({
    required String callId,
    required Map<String, dynamic> output,
  }) {
    return {
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': jsonEncode(output),
      }
    };
  }
}
