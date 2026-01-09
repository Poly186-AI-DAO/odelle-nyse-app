import 'dart:convert';
import '../../models/openai_response_models.dart';

/// Helper class to handle audio-related WebRTC messages
class AudioMessageHandler {
  final void Function(String itemId, String previousItemId)?
      onAudioBufferCommitted;
  final void Function()? onAudioBufferCleared;
  final void Function(int audioStartMs, String itemId)? onSpeechStarted;
  final void Function(int audioEndMs, String itemId)? onSpeechStopped;
  final void Function(
    String responseId,
    String itemId,
    int outputIndex,
    int contentIndex,
    String delta,
  )? onAudioTranscriptDelta;
  final void Function(
    String responseId,
    String itemId,
    int outputIndex,
    int contentIndex,
    String transcript,
  )? onAudioTranscriptDone;
  final void Function(
    String responseId,
    String itemId,
    int outputIndex,
    int contentIndex,
    String audioData,
  )? onAudioDelta;
  final void Function(
    String responseId,
    String itemId,
    int outputIndex,
    int contentIndex,
  )? onAudioDone;
  final void Function(AudioTranscriptionCompletedEvent)?
      onInputAudioTranscriptionCompleted;
  final void Function(AudioTranscriptionFailedEvent)?
      onInputAudioTranscriptionFailed;

  AudioMessageHandler({
    this.onAudioBufferCommitted,
    this.onAudioBufferCleared,
    this.onSpeechStarted,
    this.onSpeechStopped,
    this.onAudioTranscriptDelta,
    this.onAudioTranscriptDone,
    this.onAudioDelta,
    this.onAudioDone,
    this.onInputAudioTranscriptionCompleted,
    this.onInputAudioTranscriptionFailed,
  });

  /// Handles audio-specific WebRTC messages
  void handleMessage(Map<String, dynamic> message) {
    print('🎤 AudioMessageHandler received message:');
    print(json.encode(message));
    final type = message['type'] as String?;
    print('🎤 Message type: $type');

    try {
      switch (type) {
        case 'input_audio_buffer.committed':
          _handleAudioBufferCommitted(message);
          break;

        case 'input_audio_buffer.cleared':
          _handleAudioBufferCleared();
          break;

        case 'input_audio_buffer.speech_started':
          _handleSpeechStarted(message);
          break;

        case 'input_audio_buffer.speech_stopped':
          _handleSpeechStopped(message);
          break;

        case 'conversation.item.input_audio_transcription.completed':
          _handleInputAudioTranscriptionCompleted(message);
          break;

        case 'conversation.item.input_audio_transcription.failed':
          _handleInputAudioTranscriptionFailed(message);
          break;

        case 'response.audio_transcript.delta':
          _handleAudioTranscriptDelta(message);
          break;

        case 'response.audio_transcript.done':
          _handleAudioTranscriptDone(message);
          break;

        case 'response.audio.delta':
          _handleAudioDelta(message);
          break;

        case 'response.audio.done':
          _handleAudioDone(message);
          break;
      }
    } catch (e, stackTrace) {
      print('🎤 Error handling message:');
      print('  Error: $e');
      print('  Stack trace: $stackTrace');
      print('  Message: ${json.encode(message)}');
    }
  }

  void _handleAudioBufferCommitted(Map<String, dynamic> message) {
    onAudioBufferCommitted?.call(
      message['item_id'] as String,
      message['previous_item_id'] as String,
    );
  }

  void _handleAudioBufferCleared() {
    onAudioBufferCleared?.call();
  }

  void _handleSpeechStarted(Map<String, dynamic> message) {
    onSpeechStarted?.call(
      message['audio_start_ms'] as int,
      message['item_id'] as String,
    );
  }

  void _handleSpeechStopped(Map<String, dynamic> message) {
    onSpeechStopped?.call(
      message['audio_end_ms'] as int,
      message['item_id'] as String,
    );
  }

  void _handleInputAudioTranscriptionCompleted(Map<String, dynamic> message) {
    print('🎤 Handling input audio transcription completed:');
    print('  Event ID: ${message['event_id']}');
    print('  Item ID: ${message['item_id']}');
    print('  Transcript: "${message['transcript']}"');

    onInputAudioTranscriptionCompleted?.call(
      AudioTranscriptionCompletedEvent.fromJson(message),
    );
    print('  Completed handler called successfully');
  }

  void _handleInputAudioTranscriptionFailed(Map<String, dynamic> message) {
    print('🎤 Handling input audio transcription failed:');
    print('  Event ID: ${message['event_id']}');
    print('  Item ID: ${message['item_id']}');
    print('  Error: ${message['error']}');

    onInputAudioTranscriptionFailed?.call(
      AudioTranscriptionFailedEvent.fromJson(message),
    );
    print('  Failed handler called successfully');
  }

  void _handleAudioTranscriptDelta(Map<String, dynamic> message) {
    print('🎤 Handling transcript delta:');
    print('  Response ID: ${message['response_id']}');
    print('  Item ID: ${message['item_id']}');
    print('  Delta: "${message['delta']}"');

    onAudioTranscriptDelta?.call(
      message['response_id'] as String,
      message['item_id'] as String,
      message['output_index'] as int,
      message['content_index'] as int,
      message['delta'] as String,
    );
    print('  Delta handler called successfully');
  }

  void _handleAudioTranscriptDone(Map<String, dynamic> message) {
    print('🎤 Handling transcript done:');
    print('  Response ID: ${message['response_id']}');
    print('  Item ID: ${message['item_id']}');
    print('  Transcript: "${message['transcript']}"');

    onAudioTranscriptDone?.call(
      message['response_id'] as String,
      message['item_id'] as String,
      message['output_index'] as int,
      message['content_index'] as int,
      message['transcript'] as String,
    );
    print('  Done handler called successfully');
  }

  void _handleAudioDelta(Map<String, dynamic> message) {
    onAudioDelta?.call(
      message['response_id'] as String,
      message['item_id'] as String,
      message['output_index'] as int,
      message['content_index'] as int,
      message['delta'] as String,
    );
  }

  void _handleAudioDone(Map<String, dynamic> message) {
    onAudioDone?.call(
      message['response_id'] as String,
      message['item_id'] as String,
      message['output_index'] as int,
      message['content_index'] as int,
    );
  }
}
