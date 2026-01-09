import 'package:equatable/equatable.dart';

abstract class DigitalWorkerChatEvent extends Equatable {
  const DigitalWorkerChatEvent();

  @override
  List<Object?> get props => [];
}

class StartRecording extends DigitalWorkerChatEvent {}

class StopRecording extends DigitalWorkerChatEvent {}

class TranscriptDeltaReceived extends DigitalWorkerChatEvent {
  final String responseId;
  final String itemId;
  final int outputIndex;
  final int contentIndex;
  final String delta;

  const TranscriptDeltaReceived(
    this.responseId,
    this.itemId,
    this.outputIndex,
    this.contentIndex,
    this.delta,
  );

  @override
  List<Object?> get props => [
        responseId,
        itemId,
        outputIndex,
        contentIndex,
        delta,
      ];
}

class TranscriptCompleted extends DigitalWorkerChatEvent {
  final String responseId;
  final String itemId;
  final int outputIndex;
  final int contentIndex;
  final String transcript;

  const TranscriptCompleted(
    this.responseId,
    this.itemId,
    this.outputIndex,
    this.contentIndex,
    this.transcript,
  );

  @override
  List<Object?> get props => [
        responseId,
        itemId,
        outputIndex,
        contentIndex,
        transcript,
      ];
}

class ConversationItemReceived extends DigitalWorkerChatEvent {
  final dynamic item;

  const ConversationItemReceived(this.item);

  @override
  List<Object?> get props => [item];
}

class ConversationItemTruncated extends DigitalWorkerChatEvent {
  final String eventId;
  final String type;
  final String itemId;
  final int contentIndex;
  final int audioEndMs;

  const ConversationItemTruncated(
    this.eventId,
    this.type,
    this.itemId,
    this.contentIndex,
    this.audioEndMs,
  );

  @override
  List<Object?> get props => [
        eventId,
        type,
        itemId,
        contentIndex,
        audioEndMs,
      ];
}

class ConversationItemDeleted extends DigitalWorkerChatEvent {
  final String eventId;
  final String type;
  final String itemId;

  const ConversationItemDeleted(
    this.eventId,
    this.type,
    this.itemId,
  );

  @override
  List<Object?> get props => [eventId, type, itemId];
}

class AudioTranscriptionCompleted extends DigitalWorkerChatEvent {
  final String eventId;
  final String type;
  final String itemId;
  final int contentIndex;
  final String transcript;

  const AudioTranscriptionCompleted(
    this.eventId,
    this.type,
    this.itemId,
    this.contentIndex,
    this.transcript,
  );

  @override
  List<Object?> get props => [
        eventId,
        type,
        itemId,
        contentIndex,
        transcript,
      ];
}

class AudioTranscriptionFailed extends DigitalWorkerChatEvent {
  final String eventId;
  final String type;
  final String itemId;
  final int contentIndex;
  final dynamic error;

  const AudioTranscriptionFailed(
    this.eventId,
    this.type,
    this.itemId,
    this.contentIndex,
    this.error,
  );

  @override
  List<Object?> get props => [
        eventId,
        type,
        itemId,
        contentIndex,
        error,
      ];
}

class ErrorOccurred extends DigitalWorkerChatEvent {
  final String message;

  const ErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}
