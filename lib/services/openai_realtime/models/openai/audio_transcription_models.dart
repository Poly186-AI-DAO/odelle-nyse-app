/// Represents a completed audio transcription event
class AudioTranscriptionCompletedEvent {
  final String eventId;
  final String type;
  final String itemId;
  final int contentIndex;
  final String transcript;

  AudioTranscriptionCompletedEvent({
    required this.eventId,
    required this.type,
    required this.itemId,
    required this.contentIndex,
    required this.transcript,
  });

  factory AudioTranscriptionCompletedEvent.fromJson(Map<String, dynamic> json) {
    return AudioTranscriptionCompletedEvent(
      eventId: json['event_id'] as String,
      type: json['type'] as String,
      itemId: json['item_id'] as String,
      contentIndex: json['content_index'] as int,
      transcript: json['transcript'] as String,
    );
  }
}

/// Represents an error object in transcription failure
class TranscriptionError {
  final String type;
  final String code;
  final String message;
  final dynamic param;

  TranscriptionError({
    required this.type,
    required this.code,
    required this.message,
    this.param,
  });

  factory TranscriptionError.fromJson(Map<String, dynamic> json) {
    return TranscriptionError(
      type: json['type'] as String,
      code: json['code'] as String,
      message: json['message'] as String,
      param: json['param'],
    );
  }
}

/// Represents a failed audio transcription event
class AudioTranscriptionFailedEvent {
  final String eventId;
  final String type;
  final String itemId;
  final int contentIndex;
  final TranscriptionError error;

  AudioTranscriptionFailedEvent({
    required this.eventId,
    required this.type,
    required this.itemId,
    required this.contentIndex,
    required this.error,
  });

  factory AudioTranscriptionFailedEvent.fromJson(Map<String, dynamic> json) {
    return AudioTranscriptionFailedEvent(
      eventId: json['event_id'] as String,
      type: json['type'] as String,
      itemId: json['item_id'] as String,
      contentIndex: json['content_index'] as int,
      error: TranscriptionError.fromJson(json['error'] as Map<String, dynamic>),
    );
  }
}
