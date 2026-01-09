/// Represents the content of a message item
class MessageContent {
  final String type;
  final String? text;
  final String? transcript;
  final String? audio;

  MessageContent({
    required this.type,
    this.text,
    this.transcript,
    this.audio,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      type: json['type'] as String,
      text: json['text'] as String?,
      transcript: json['transcript'] as String?,
      audio: json['audio'] as String?,
    );
  }
}

/// Represents a message item in the response
class MessageItem {
  final String id;
  final String object;
  final String type;
  final String status;
  final String? role;
  final List<MessageContent>? content;
  final String? name;
  final String? callId;
  final String? arguments;

  MessageItem({
    required this.id,
    required this.object,
    required this.type,
    required this.status,
    this.role,
    this.content,
    this.name,
    this.callId,
    this.arguments,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id'] as String,
      object: json['object'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      role: json['role'] as String?,
      content: json['content'] != null
          ? (json['content'] as List<dynamic>)
              .map((e) => MessageContent.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      name: json['name'] as String?,
      callId: json['call_id'] as String?,
      arguments: json['arguments'] as String?,
    );
  }
}

/// Represents a conversation resource
class ConversationResource {
  final String id;
  final String object;

  ConversationResource({
    required this.id,
    required this.object,
  });

  factory ConversationResource.fromJson(Map<String, dynamic> json) {
    return ConversationResource(
      id: json['id'] as String,
      object: json['object'] as String,
    );
  }
}

/// Represents a conversation created event
class ConversationCreatedEvent {
  final String eventId;
  final String type;
  final ConversationResource conversation;

  ConversationCreatedEvent({
    required this.eventId,
    required this.type,
    required this.conversation,
  });

  factory ConversationCreatedEvent.fromJson(Map<String, dynamic> json) {
    return ConversationCreatedEvent(
      eventId: json['event_id'] as String,
      type: json['type'] as String,
      conversation: ConversationResource.fromJson(
          json['conversation'] as Map<String, dynamic>),
    );
  }
}

/// Represents a conversation item created event
class ConversationItemCreatedEvent {
  final String eventId;
  final String type;
  final String? previousItemId;
  final MessageItem item;

  ConversationItemCreatedEvent({
    required this.eventId,
    required this.type,
    this.previousItemId,
    required this.item,
  });

  factory ConversationItemCreatedEvent.fromJson(Map<String, dynamic> json) {
    return ConversationItemCreatedEvent(
      eventId: json['event_id'] as String,
      type: json['type'] as String,
      previousItemId: json['previous_item_id'] as String?,
      item: MessageItem.fromJson(json['item'] as Map<String, dynamic>),
    );
  }
}
