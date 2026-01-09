import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/digital_worker_config.dart';
import '../../bloc/settings/settings_bloc.dart';
import '../../bloc/settings/settings_state.dart';
import '../../services/openai_realtime/openai_webrtc_service.dart';
import '../../services/openai_realtime/openai_session_service.dart';
import '../../services/openai_realtime/models/openai/conversation_event_models.dart';
import 'digital_worker_chat_event.dart';
import 'digital_worker_chat_state.dart';

class DigitalWorkerChatBloc
    extends Bloc<DigitalWorkerChatEvent, DigitalWorkerChatState> {
  final OpenAIWebRTCService _webrtcService;
  final OpenAISessionService _sessionService;
  final List<dynamic> _messages = [];
  String _currentTranscript = '';

  final _transcriptController = StreamController<String>.broadcast();
  final _messageController = StreamController<dynamic>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<dynamic> get conversationStream => _messageController.stream;

  DigitalWorkerConfig _config;
  StreamSubscription<SettingsState>? _settingsSubscription;

  DigitalWorkerChatBloc({
    required OpenAIWebRTCService webrtcService,
    required OpenAISessionService sessionService,
    required DigitalWorkerConfig config,
    required SettingsBloc settingsBloc,
  })  : _webrtcService = webrtcService,
        _sessionService = sessionService,
        _config = config,
        super(DigitalWorkerChatInitial()) {
    _setupWebRTCHandlers();
    _settingsSubscription = settingsBloc.stream.listen((settings) {
      _config = DigitalWorkerConfig(
        voice: settings.voice,
        enableNoiseSuppression: settings.enableNoiseSuppression,
        enableEchoCancellation: settings.enableEchoCancellation,
        enableAutoGainControl: settings.enableAutoGainControl,
        vadThreshold: settings.vadThreshold,
        prefixPaddingMs: settings.prefixPaddingMs,
        silenceDurationMs: settings.silenceDurationMs,
        maxRecordingDuration: settings.maxRecordingDuration,
        connectionTimeout: settings.connectionTimeout,
      );
    });
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<TranscriptDeltaReceived>(_onTranscriptDelta);
    on<TranscriptCompleted>(_onTranscriptCompleted);
    on<ConversationItemReceived>(_onConversationItemReceived);
    on<ConversationItemTruncated>(_onConversationItemTruncated);
    on<ConversationItemDeleted>(_onConversationItemDeleted);
    on<AudioTranscriptionCompleted>(_onAudioTranscriptionCompleted);
    on<AudioTranscriptionFailed>(_onAudioTranscriptionFailed);
    on<ErrorOccurred>(_onError);
  }

  void _setupWebRTCHandlers() {
    _log('Setting up WebRTC handlers');
    _webrtcService
      ..onResponseCreated = (response) {
        _log('Response created: ${response.toString()}');
      }
      ..onResponseDone = (response) {
        _log('Response completed: ${response.toString()}');
      }
      ..onConversationItemCreated = (item) {
        _messageController.add(item);
        add(ConversationItemReceived(item));
      }
      ..onConversationItemTruncated = (ConversationItemTruncatedEvent event) {
        add(ConversationItemTruncated(
          event.eventId,
          event.type,
          event.itemId,
          event.contentIndex,
          event.audioEndMs,
        ));
      }
      ..onConversationItemDeleted = (ConversationItemDeletedEvent event) {
        add(ConversationItemDeleted(
          event.eventId,
          event.type,
          event.itemId,
        ));
      }
      ..onError = (error) {
        add(ErrorOccurred(error));
      };
  }

  Future<void> _onStartRecording(
    StartRecording event,
    Emitter<DigitalWorkerChatState> emit,
  ) async {
    try {
      _log('Starting recording session...');
      emit(const DigitalWorkerChatConnecting(
        message: 'Establishing secure connection...',
      ));

      _log('Initializing WebRTC service...');
      await _webrtcService.initialize(
        config: _config,
      );
      _log('WebRTC service initialized successfully');

      final renderer = _webrtcService.webRenderer;
      emit(DigitalWorkerChatReady(
        currentTranscript: _currentTranscript,
        messages: _messages,
        isRecording: true,
        isProcessing: false,
        webrtcRenderer: renderer,
      ));
    } catch (e, stackTrace) {
      _logError('Error during recording start: ${e.toString()}', e, stackTrace);
      await _webrtcService.dispose();
      emit(DigitalWorkerChatError(e.toString()));
    }
  }

  Future<void> _onStopRecording(
    StopRecording event,
    Emitter<DigitalWorkerChatState> emit,
  ) async {
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      if (!currentState.isRecording) return;

      try {
        _log('Stopping recording session...');

        emit(currentState.copyWith(
          isRecording: false,
          isProcessing: true,
        ));

        // End the WebRTC session
        await _webrtcService.endSession();
        _log('WebRTC session ended');

        // Clean up resources
        await _webrtcService.dispose();
        _log('WebRTC service disposed');

        // Clear state
        _messages.clear();
        _currentTranscript = '';

        // Reset to initial state
        emit(DigitalWorkerChatInitial());
      } catch (e, stackTrace) {
        _logError(
            'Error during recording stop: ${e.toString()}', e, stackTrace);
        emit(DigitalWorkerChatError(e.toString()));
      }
    }
  }

  void _onTranscriptDelta(
    TranscriptDeltaReceived event,
    Emitter<DigitalWorkerChatState> emit,
  ) {
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      _currentTranscript += event.delta;
      emit(currentState.copyWith(
        currentTranscript: _currentTranscript,
      ));
    }
  }

  void _onTranscriptCompleted(
    TranscriptCompleted event,
    Emitter<DigitalWorkerChatState> emit,
  ) {
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      _currentTranscript = event.transcript;
      emit(currentState.copyWith(
        currentTranscript: _currentTranscript,
      ));
    }
  }

  void _onConversationItemReceived(
    ConversationItemReceived event,
    Emitter<DigitalWorkerChatState> emit,
  ) {
    _log('Conversation item received: ${event.item}');
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      _messages.add(event.item);
      emit(currentState.copyWith(
        messages: List.from(_messages),
      ));
    }
  }

  void _onConversationItemTruncated(
    ConversationItemTruncated event,
    Emitter<DigitalWorkerChatState> emit,
  ) {
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      final index = _messages.indexWhere((m) => m.id == event.itemId);
      if (index != -1) {
        // Update the truncated message
        final item = _messages[index];
        _messages[index] = item.copyWith(
          status: 'truncated',
          content: item.content?.substring(0, event.contentIndex),
        );
        emit(currentState.copyWith(
          messages: List.from(_messages),
        ));
      }
    }
  }

  void _onConversationItemDeleted(
    ConversationItemDeleted event,
    Emitter<DigitalWorkerChatState> emit,
  ) {
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      _messages.removeWhere((m) => m.id == event.itemId);
      emit(currentState.copyWith(
        messages: List.from(_messages),
      ));
    }
  }

  void _onAudioTranscriptionCompleted(
    AudioTranscriptionCompleted event,
    Emitter<DigitalWorkerChatState> emit,
  ) {
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      final message = {
        'id': event.itemId,
        'type': event.type,
        'role': 'user',
        'content': event.transcript,
        'status': 'completed',
      };
      _messages.add(message);
      emit(currentState.copyWith(
        messages: List.from(_messages),
      ));
    }
  }

  void _onAudioTranscriptionFailed(
    AudioTranscriptionFailed event,
    Emitter<DigitalWorkerChatState> emit,
  ) {
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      emit(currentState.copyWith(isRecording: false, isProcessing: false));
      emit(
          DigitalWorkerChatError('Audio transcription failed: ${event.error}'));
    }
  }

  void _onError(
    ErrorOccurred event,
    Emitter<DigitalWorkerChatState> emit,
  ) {
    _log('Error occurred: ${event.message}');
    if (state is DigitalWorkerChatReady) {
      final currentState = state as DigitalWorkerChatReady;
      emit(currentState.copyWith(isRecording: false, isProcessing: false));
      emit(DigitalWorkerChatError(event.message));
    }
  }

  /// Helper method for logging that respects the config's enableDebugLogs setting
  void _log(String message) {
    if (_config.enableDebugLogs) {
      developer.log(message, name: 'DigitalWorkerChatBloc');
    }
  }

  /// Helper method for logging errors that respects the config's enableDebugLogs setting
  void _logError(String message, Object error, StackTrace stackTrace) {
    if (_config.enableDebugLogs) {
      developer.log(
        message,
        error: error,
        stackTrace: stackTrace,
        name: 'DigitalWorkerChatBloc',
      );
    }
  }

  @override
  Future<void> close() async {
    await _webrtcService.dispose();
    await _transcriptController.close();
    await _messageController.close();
    await _settingsSubscription?.cancel();
    return super.close();
  }
}
