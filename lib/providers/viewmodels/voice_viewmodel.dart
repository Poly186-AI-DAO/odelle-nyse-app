import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/azure_speech_service.dart';
import '../../utils/logger.dart';
import '../service_providers.dart';

/// Voice state for the entire app
/// Centralized state management for voice features
class VoiceState {
  final VoiceLiveState connectionState;
  final VoiceLiveMode activeMode;
  final bool isModeLocked;
  final String currentTranscription;
  final String partialTranscription;
  final String aiResponseText;
  final bool isAISpeaking;
  final String? error;

  const VoiceState({
    this.connectionState = VoiceLiveState.disconnected,
    this.activeMode = VoiceLiveMode.transcription,
    this.isModeLocked = false,
    this.currentTranscription = '',
    this.partialTranscription = '',
    this.aiResponseText = '',
    this.isAISpeaking = false,
    this.error,
  });

  bool get isDisconnected => connectionState == VoiceLiveState.disconnected;
  bool get isConnecting => connectionState == VoiceLiveState.connecting;
  bool get isConnected =>
      connectionState == VoiceLiveState.connected ||
      connectionState == VoiceLiveState.recording ||
      connectionState == VoiceLiveState.processing;
  bool get isRecording => connectionState == VoiceLiveState.recording;
  bool get isProcessing => connectionState == VoiceLiveState.processing;

  VoiceState copyWith({
    VoiceLiveState? connectionState,
    VoiceLiveMode? activeMode,
    bool? isModeLocked,
    String? currentTranscription,
    String? partialTranscription,
    String? aiResponseText,
    bool? isAISpeaking,
    String? error,
  }) {
    return VoiceState(
      connectionState: connectionState ?? this.connectionState,
      activeMode: activeMode ?? this.activeMode,
      isModeLocked: isModeLocked ?? this.isModeLocked,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      partialTranscription: partialTranscription ?? this.partialTranscription,
      aiResponseText: aiResponseText ?? this.aiResponseText,
      isAISpeaking: isAISpeaking ?? this.isAISpeaking,
      error: error,
    );
  }
}

/// VoiceViewModel - Centralized voice state management
/// All screens read from this, HomeScreen controls it
class VoiceViewModel extends Notifier<VoiceState> {
  static const String _tag = 'VoiceViewModel';

  StreamSubscription<VoiceLiveState>? _stateSubscription;
  StreamSubscription<String>? _transcriptionSubscription;
  StreamSubscription<String>? _partialSubscription;
  StreamSubscription<String>? _aiResponseSubscription;

  AzureSpeechService get _service => ref.read(voiceServiceProvider);

  @override
  VoiceState build() {
    // Subscribe to service streams
    _subscribeToStreams();

    // Cleanup on dispose
    ref.onDispose(() {
      _stateSubscription?.cancel();
      _transcriptionSubscription?.cancel();
      _partialSubscription?.cancel();
      _aiResponseSubscription?.cancel();
    });

    return const VoiceState();
  }

  void _subscribeToStreams() {
    _stateSubscription?.cancel();
    _stateSubscription = _service.stateStream.listen((newState) {
      state = state.copyWith(connectionState: newState);
    });

    _transcriptionSubscription?.cancel();
    _transcriptionSubscription = _service.transcriptionStream.listen((text) {
      // Clear AI response when user's turn finishes (new AI response incoming)
      state = state.copyWith(
        currentTranscription: text,
        partialTranscription: '',
        aiResponseText: '', // Clear for new AI response
        isAISpeaking: false,
      );
    });

    _partialSubscription?.cancel();
    _partialSubscription = _service.partialStream.listen((text) {
      state = state.copyWith(
        partialTranscription: state.partialTranscription + text,
      );
    });

    // Subscribe to AI response text stream (for real-time subtitles)
    _aiResponseSubscription?.cancel();
    _aiResponseSubscription = _service.aiResponseStream.listen((textDelta) {
      state = state.copyWith(
        aiResponseText: state.aiResponseText + textDelta,
        isAISpeaking: true,
      );
    });
  }

  /// Connect to voice service
  Future<bool> connect({VoiceLiveMode? mode}) async {
    final targetMode = mode ?? state.activeMode;
    Logger.info('Connecting with mode: ${targetMode.name}', tag: _tag);

    state = state.copyWith(
      activeMode: targetMode,
      error: null,
      currentTranscription: '',
      partialTranscription: '',
      aiResponseText: '',
      isAISpeaking: false,
    );

    final connected = await _service.connect(mode: targetMode);
    if (!connected) {
      state = state.copyWith(error: 'Failed to connect');
    }
    return connected;
  }

  /// Disconnect from voice service
  Future<void> disconnect() async {
    Logger.info('Disconnecting', tag: _tag);
    await _service.disconnect();
    state = state.copyWith(
      isModeLocked: false,
      currentTranscription: '',
      partialTranscription: '',
      aiResponseText: '',
      isAISpeaking: false,
    );
  }

  /// Start recording
  void startRecording() {
    Logger.info('Starting recording', tag: _tag);
    state = state.copyWith(
      currentTranscription: '',
      partialTranscription: '',
    );
    _service.startRecording();
  }

  /// Send audio chunk
  void sendAudioChunk(Uint8List audioBytes) {
    _service.sendAudioChunk(audioBytes);
  }

  /// Stop recording
  Future<void> stopRecording() async {
    Logger.info('Stopping recording', tag: _tag);
    await _service.stopRecording();
  }

  /// Cancel recording without transcribing
  void cancelRecording() {
    Logger.info('Cancelling recording', tag: _tag);
    _service.cancelRecording();
    state = state.copyWith(
      partialTranscription: '',
    );
  }

  /// Switch voice mode (transcription <-> conversation)
  void switchMode(VoiceLiveMode newMode) {
    if (state.activeMode == newMode) return;

    Logger.info('Switching mode: ${state.activeMode.name} → ${newMode.name}',
        tag: _tag);

    state = state.copyWith(activeMode: newMode);
    _service.switchMode(newMode);
  }

  /// Lock mode (for live conversation)
  void lockMode() {
    Logger.info('Locking to conversation mode', tag: _tag);
    state = state.copyWith(
      isModeLocked: true,
      activeMode: VoiceLiveMode.conversation,
    );
    _service.switchMode(VoiceLiveMode.conversation);
  }

  /// Unlock mode
  void unlockMode() {
    Logger.info('Unlocking mode', tag: _tag);
    state = state.copyWith(isModeLocked: false);
  }

  /// Clear transcription
  void clearTranscription() {
    state = state.copyWith(
      currentTranscription: '',
      partialTranscription: '',
    );
  }

  /// Clear AI response (for interruption handling)
  void clearAiResponse() {
    state = state.copyWith(
      aiResponseText: '',
      isAISpeaking: false,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for VoiceViewModel
final voiceViewModelProvider =
    NotifierProvider<VoiceViewModel, VoiceState>(VoiceViewModel.new);
