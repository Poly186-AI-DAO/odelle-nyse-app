import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../config/digital_worker_config.dart';
import 'openai_webrtc_service.dart';
import 'models/openai_response_models.dart';
import 'handlers/message/audio_message_handler.dart';
import 'dart:developer' as developer;

/// A WebRTC service that handles all audio-related functionality.
///
/// This service extends OpenAIWebRTCService to provide comprehensive audio support:
///
/// Input Audio Management:
/// - Appending audio data to the input buffer
/// - Committing audio buffers to create messages
/// - Clearing audio buffers
/// - Voice Activity Detection (VAD) support
///
/// Input Audio Events:
/// - input_audio_buffer.committed: Buffer committed (manual/VAD)
/// - input_audio_buffer.cleared: Buffer cleared
/// - input_audio_buffer.speech_started: Speech detected (VAD)
/// - input_audio_buffer.speech_stopped: Speech ended (VAD)
/// - conversation.item.input_audio_transcription.completed: Transcription completed
/// - conversation.item.input_audio_transcription.failed: Transcription failed
///
/// Output Audio Events:
/// - response.audio_transcript.delta: Streaming transcript updates
/// - response.audio_transcript.done: Final transcripts
/// - response.audio.delta: Streaming audio data
/// - response.audio.done: Audio generation complete
class OpenAiAudioWebRTCService extends OpenAIWebRTCService {
  void Function(String itemId, String previousItemId)? onAudioBufferCommitted;
  void Function()? onAudioBufferCleared;
  void Function(int audioStartMs, String itemId)? onSpeechStarted;
  void Function(int audioEndMs, String itemId)? onSpeechStopped;
  void Function(
    String responseId,
    String itemId,
    int outputIndex,
    int contentIndex,
    String delta,
  )? onAudioTranscriptDelta;
  void Function(
    String responseId,
    String itemId,
    int outputIndex,
    int contentIndex,
    String transcript,
  )? onAudioTranscriptDone;
  void Function(
    String responseId,
    String itemId,
    int outputIndex,
    int contentIndex,
    String audioData,
  )? onAudioDelta;
  void Function(
    String responseId,
    String itemId,
    int outputIndex,
    int contentIndex,
  )? onAudioDone;
  void Function(AudioTranscriptionCompletedEvent)?
      onInputAudioTranscriptionCompleted;
  void Function(AudioTranscriptionFailedEvent)? onInputAudioTranscriptionFailed;

  late final AudioMessageHandler _audioMessageHandler;

  // Message handler function that will be passed to the base class
  void _handleAudioMessage(Map<String, dynamic> message) {
    developer.log('Received WebRTC message:', name: 'OpenAiAudioWebRTCService');
    developer.log('Message content: ${json.encode(message)}',
        name: 'OpenAiAudioWebRTCService');

    try {
      _audioMessageHandler.handleMessage(message);
      developer.log('Successfully handled message',
          name: 'OpenAiAudioWebRTCService');
    } catch (e, stackTrace) {
      developer.log('Error handling message',
          name: 'OpenAiAudioWebRTCService',
          error:
              'Error: $e\nStack trace: $stackTrace\nMessage: ${json.encode(message)}');
    }
  }

  /// Gets the web-specific renderer for audio playback
  @override
  RTCVideoRenderer? get webRenderer => super.webRenderer;

  @override
  Future<void> initialize({
    required DigitalWorkerConfig config,
  }) async {
    // Initialize the audio message handler first
    _audioMessageHandler = AudioMessageHandler(
      onAudioBufferCommitted: onAudioBufferCommitted,
      onAudioBufferCleared: onAudioBufferCleared,
      onSpeechStarted: onSpeechStarted,
      onSpeechStopped: onSpeechStopped,
      onAudioTranscriptDelta: onAudioTranscriptDelta,
      onAudioTranscriptDone: onAudioTranscriptDone,
      onAudioDelta: onAudioDelta,
      onAudioDone: onAudioDone,
      onInputAudioTranscriptionCompleted: (event) {
        final completedEvent = AudioTranscriptionCompletedEvent(
          eventId: event.eventId,
          itemId: event.itemId,
          transcript: event.transcript,
        );
        onInputAudioTranscriptionCompleted?.call(completedEvent);
      },
      onInputAudioTranscriptionFailed: (event) {
        final failedEvent = AudioTranscriptionFailedEvent(
          eventId: event.eventId,
          itemId: event.itemId,
          error: event.error,
        );
        onInputAudioTranscriptionFailed?.call(failedEvent);
      },
    );

    // Set child handler to our message handler function
    childHandler = _handleAudioMessage;

    // Initialize base class
    await super.initialize(
      config: config,
    );
  }

  /// Appends audio bytes to the input audio buffer.
  ///
  /// The audio buffer is temporary storage that can be written to and later committed.
  /// In Server VAD mode, the audio buffer is used to detect speech and the server
  /// will decide when to commit. When Server VAD is disabled, you must commit the
  /// audio buffer manually.
  ///
  /// [audioBytes] must be in the format specified by the input_audio_format field
  /// in the session configuration.
  ///
  /// [eventId] is an optional client-generated ID to identify this event.
  Future<void> appendAudioBuffer(List<int> audioBytes,
      {String? eventId}) async {
    if (!super.isReadyToSendEvents()) {
      throw Exception('WebRTC service is not ready to append audio buffer');
    }

    final event = {
      if (eventId != null) 'event_id': eventId,
      'type': 'input_audio_buffer.append',
      'audio': base64Encode(audioBytes),
    };

    await super.sendEvent(event);
  }

  /// Commits the user input audio buffer, which will create a new user message
  /// item in the conversation.
  ///
  /// This will produce an error if the input audio buffer is empty.
  /// When in Server VAD mode, the client does not need to call this method,
  /// as the server will commit the audio buffer automatically.
  ///
  /// [eventId] is an optional client-generated ID to identify this event.
  Future<void> commitAudioBuffer({String? eventId}) async {
    if (!super.isReadyToSendEvents()) {
      throw Exception('WebRTC service is not ready to commit audio buffer');
    }

    final event = {
      if (eventId != null) 'event_id': eventId,
      'type': 'input_audio_buffer.commit',
    };

    await super.sendEvent(event);
  }

  /// Clears the audio bytes in the buffer.
  ///
  /// [eventId] is an optional client-generated ID to identify this event.
  Future<void> clearAudioBuffer({String? eventId}) async {
    if (!super.isReadyToSendEvents()) {
      throw Exception('WebRTC service is not ready to clear audio buffer');
    }

    final event = {
      if (eventId != null) 'event_id': eventId,
      'type': 'input_audio_buffer.clear',
    };

    await super.sendEvent(event);
  }
}
