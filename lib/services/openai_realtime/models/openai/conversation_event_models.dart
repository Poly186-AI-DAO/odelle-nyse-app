/// Represents a truncated conversation item event
class ConversationItemTruncatedEvent {
  final String eventId;
  final String type;
  final String itemId;
  final int contentIndex;
  final int audioEndMs;

  ConversationItemTruncatedEvent({
    required this.eventId,
    required this.type,
    required this.itemId,
    required this.contentIndex,
    required this.audioEndMs,
  });

  factory ConversationItemTruncatedEvent.fromJson(Map<String, dynamic> json) {
    return ConversationItemTruncatedEvent(
      eventId: json['event_id'] as String,
      type: json['type'] as String,
      itemId: json['item_id'] as String,
      contentIndex: json['content_index'] as int,
      audioEndMs: json['audio_end_ms'] as int,
    );
  }
}

/// Represents a deleted conversation item event
class ConversationItemDeletedEvent {
  final String eventId;
  final String type;
  final String itemId;

  ConversationItemDeletedEvent({
    required this.eventId,
    required this.type,
    required this.itemId,
  });

  factory ConversationItemDeletedEvent.fromJson(Map<String, dynamic> json) {
    return ConversationItemDeletedEvent(
      eventId: json['event_id'] as String,
      type: json['type'] as String,
      itemId: json['item_id'] as String,
    );
  }
}
