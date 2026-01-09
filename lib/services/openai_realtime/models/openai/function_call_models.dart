import 'dart:convert';

/// Model for function call arguments event
class FunctionCallArgumentsEvent {
  final String eventId;
  final String name;
  final Map<String, dynamic> arguments;

  FunctionCallArgumentsEvent({
    required this.eventId,
    required this.name,
    required this.arguments,
  });

  factory FunctionCallArgumentsEvent.fromJson(Map<String, dynamic> json) {
    return FunctionCallArgumentsEvent(
      eventId: json['event_id'] as String,
      name: json['name'] as String,
      arguments: json['arguments'] is String
          ? jsonDecode(json['arguments'] as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(json['arguments'] as Map),
    );
  }
}

/// Model for function call response event
class FunctionCallResponseEvent {
  final String eventId;
  final String name;
  final Map<String, dynamic> response;

  FunctionCallResponseEvent({
    required this.eventId,
    required this.name,
    required this.response,
  });

  Map<String, dynamic> toJson() => {
        'type': 'function.response',
        'event_id': eventId,
        'name': name,
        'response': response,
      };
}
