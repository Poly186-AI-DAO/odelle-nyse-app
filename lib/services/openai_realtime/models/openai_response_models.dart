/// Base class for OpenAI WebRTC events
abstract class OpenAIEvent {
  final String eventId;
  final String itemId;

  OpenAIEvent({
    required this.eventId,
    required this.itemId,
  });
}

/// Event emitted when audio transcription is completed successfully
class AudioTranscriptionCompletedEvent extends OpenAIEvent {
  final String transcript;

  AudioTranscriptionCompletedEvent({
    required super.eventId,
    required super.itemId,
    required this.transcript,
  });

  factory AudioTranscriptionCompletedEvent.fromJson(Map<String, dynamic> json) {
    return AudioTranscriptionCompletedEvent(
      eventId: json['event_id'] as String,
      itemId: json['item_id'] as String,
      transcript: json['transcript'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'item_id': itemId,
        'transcript': transcript,
      };
}

/// Event emitted when audio transcription fails
class AudioTranscriptionFailedEvent extends OpenAIEvent {
  final String error;

  AudioTranscriptionFailedEvent({
    required super.eventId,
    required super.itemId,
    required this.error,
  });

  factory AudioTranscriptionFailedEvent.fromJson(Map<String, dynamic> json) {
    return AudioTranscriptionFailedEvent(
      eventId: json['event_id'] as String,
      itemId: json['item_id'] as String,
      error: json['error'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'item_id': itemId,
        'error': error,
      };
}
