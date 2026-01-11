import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' show VoidCallback;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/azure_ai_config.dart';
import '../config/odelle_system_prompt.dart';
import '../utils/logger.dart';

/// Connection timeout duration
const Duration _connectionTimeout = Duration(seconds: 10);

/// Voice Live connection states
enum VoiceLiveState {
  disconnected, // Not connected to Azure
  connecting, // WebSocket connecting, waiting for session.created
  connected, // Ready to record (session active)
  recording, // Streaming audio to Azure
  processing, // Audio committed, waiting for transcription
}

/// Voice Live mode - determines session configuration
enum VoiceLiveMode {
  transcription, // Speech-to-text only (for journaling)
  conversation, // Full voice in/out with AI responses
}

/// Azure Voice Live API Service for real-time transcription
/// Uses WebSocket connection to Azure OpenAI Realtime API
/// Docs: https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/realtime-audio
class AzureSpeechService {
  static const String _tag = 'AzureSpeechService';

  // Azure configuration - loaded from .env
  late final String _apiKey;
  late final String _endpointUrl; // Full WebSocket URL from .env

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;

  // Audio buffer for collecting chunks before commit
  final List<Uint8List> _audioBuffer = [];
  int _totalAudioBytes = 0;

  // Connection completer for waiting on session.created
  Completer<bool>? _connectionCompleter;

  // State management
  VoiceLiveState _state = VoiceLiveState.disconnected;
  VoiceLiveMode _mode = VoiceLiveMode.transcription;
  final _stateController = StreamController<VoiceLiveState>.broadcast();

  // Transcription stream for multi-listener support (fixes callback clobbering)
  final _transcriptionController = StreamController<String>.broadcast();
  final _partialController = StreamController<String>.broadcast();
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<String> get partialStream => _partialController.stream;

  // AI response text stream (for subtitles/display)
  final _aiResponseController = StreamController<String>.broadcast();
  Stream<String> get aiResponseStream => _aiResponseController.stream;

  // Callbacks (legacy - prefer streams for multi-listener)
  Function(String transcription)? onTranscription;
  Function(String partialResult)? onPartialResult;
  Function(String error)? onError;
  Function(Uint8List audioData)? onAudioResponse;
  Function(String text)? onTextResponse;
  VoidCallback? onSpeechStarted;
  VoidCallback? onSpeechStopped;
  VoidCallback? onConnected;

  // Legacy state booleans (kept for compatibility, derived from _state)
  bool get _isConnected =>
      _state == VoiceLiveState.connected ||
      _state == VoiceLiveState.recording ||
      _state == VoiceLiveState.processing;
  bool get _isRecording => _state == VoiceLiveState.recording;
  bool _isInitialized = false;
  String _sessionId = '';

  // Public state access
  VoiceLiveState get state => _state;
  VoiceLiveMode get mode => _mode;
  Stream<VoiceLiveState> get stateStream => _stateController.stream;

  AzureSpeechService() {
    _initialize();
  }

  void _setState(VoiceLiveState newState) {
    if (_state != newState) {
      Logger.info('State: $_state → $newState', tag: _tag);
      _state = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  void _initialize() {
    // Get Azure AI Foundry configuration from .env
    _apiKey = dotenv.env['AZURE_AI_FOUNDRY_KEY'] ?? '';
    final endpoint = dotenv.env['AZURE_AI_FOUNDRY_ENDPOINT'] ?? '';

    if (_apiKey.isEmpty || endpoint.isEmpty) {
      Logger.error('Azure AI Foundry key or endpoint not found in environment',
          tag: _tag);
      Logger.error(
          'Expected env vars: AZURE_AI_FOUNDRY_KEY, AZURE_AI_FOUNDRY_ENDPOINT',
          tag: _tag);
      return;
    }

    // Build the Realtime API URL using AzureAIConfig
    final realtimeUri = AzureAIConfig.buildRealtimeUri(
      endpoint: endpoint,
      deployment: AzureAIConfig.defaultRealtimeDeployment,
    );

    // Convert https:// to wss:// for WebSocket connection
    _endpointUrl = realtimeUri.toString().replaceFirst('https://', 'wss://');

    Logger.info(
        'Azure Realtime Service initialized with endpoint: ${_endpointUrl.split('?').first}',
        tag: _tag);
    _isInitialized = true;
  }

  /// Connect to Azure OpenAI Realtime API
  Future<bool> connect(
      {VoiceLiveMode mode = VoiceLiveMode.transcription}) async {
    if (!_isInitialized) {
      onError?.call('Service not initialized');
      return false;
    }

    if (_isConnected) {
      Logger.info('Already connected', tag: _tag);
      return true;
    }

    _mode = mode;
    _setState(VoiceLiveState.connecting);

    try {
      // Use the pre-configured WebSocket URL from .env and add api-key
      // Format: wss://<resource>.openai.azure.com/openai/realtime?api-version=X&deployment=Y&api-key=Z
      final baseUrl = Uri.parse(_endpointUrl);
      final wsUrl = baseUrl.replace(
        queryParameters: {
          ...baseUrl.queryParameters,
          'api-key': _apiKey,
        },
      );

      Logger.info('Connecting to Azure Realtime API: ${wsUrl.host}...',
          tag: _tag);

      _channel = WebSocketChannel.connect(wsUrl);

      // Create completer to wait for session.created
      _connectionCompleter = Completer<bool>();

      // Listen for messages
      _wsSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          Logger.error('WebSocket error: $error', tag: _tag);
          onError?.call('Connection error: $error');
          _setState(VoiceLiveState.disconnected);
          _connectionCompleter?.complete(false);
        },
        onDone: () {
          Logger.info('WebSocket closed', tag: _tag);
          _setState(VoiceLiveState.disconnected);
          if (!(_connectionCompleter?.isCompleted ?? true)) {
            _connectionCompleter?.complete(false);
          }
        },
      );

      // Wait for session.created with timeout
      final connected = await _connectionCompleter!.future.timeout(
        _connectionTimeout,
        onTimeout: () {
          Logger.error('Connection timeout', tag: _tag);
          onError?.call('Connection timeout');
          _setState(VoiceLiveState.disconnected);
          return false;
        },
      );

      return connected;
    } catch (e, stackTrace) {
      Logger.error('Failed to connect: $e', tag: _tag, data: {
        'stackTrace': stackTrace.toString(),
      });
      onError?.call('Failed to connect: $e');
      _setState(VoiceLiveState.disconnected);
      return false;
    }
  }

  /// Switch mode (Transcription <-> Conversation)
  void switchMode(VoiceLiveMode newMode) {
    if (_mode == newMode) return;

    _mode = newMode;
    Logger.info('Switching to $_mode mode', tag: _tag);

    // Reconfigure session if connected
    if (_isConnected) {
      _configureSession();
    }
  }

  /// Configure the session for transcription or conversation
  void _configureSession() {
    if (_channel == null) return;

    // Azure OpenAI Realtime API session configuration
    // Docs: https://github.com/azure-samples/aoai-realtime-audio-sdk
    // Configure based on mode
    final modalities = _mode == VoiceLiveMode.conversation
        ? ['text', 'audio']
        : ['text']; // Transcription-only mode

    final turnDetection = _mode == VoiceLiveMode.conversation
        ? {
            'type': 'server_vad',
            'threshold': 0.5,
            'prefix_padding_ms': 300,
            'silence_duration_ms': 600,
          }
        : null; // transcription mode: client controls commit

    final sessionConfig = {
      'type': 'session.update',
      'session': {
        'modalities': modalities,
        'voice': 'alloy',
        'instructions': OdelleSystemPrompt.getPrompt(
            _mode == VoiceLiveMode.conversation),
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        'turn_detection': turnDetection,
        'temperature': 0.8,
      },
    };

    _sendJson(sessionConfig);
    Logger.info('Session configured for ${_mode.name} mode', tag: _tag);
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      Logger.debug('Received: $type', tag: _tag);

      switch (type) {
        case 'session.created':
          _handleSessionCreated(data);
          break;

        case 'session.updated':
          Logger.info('Session updated successfully', tag: _tag);
          break;

        case 'input_audio_buffer.speech_started':
          Logger.info('Speech started', tag: _tag);
          onSpeechStarted?.call();
          break;

        case 'input_audio_buffer.speech_stopped':
          Logger.info('Speech stopped', tag: _tag);
          onSpeechStopped?.call();
          break;

        case 'conversation.item.input_audio_transcription.delta':
          final delta = data['delta'] as String?;
          if (delta != null && delta.isNotEmpty) {
            onPartialResult?.call(delta);
            if (!_partialController.isClosed) {
              _partialController.add(delta);
            }
          }
          break;

        case 'conversation.item.input_audio_transcription.completed':
          final transcript = data['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            Logger.info('Transcription complete: $transcript', tag: _tag);
            onTranscription?.call(transcript);
            if (!_transcriptionController.isClosed) {
              _transcriptionController.add(transcript);
            }
          }
          // Return to connected state after transcription
          _setState(VoiceLiveState.connected);
          break;

        case 'response.audio.delta':
          final audioBase64 = data['delta'] as String?;
          if (audioBase64 != null) {
            final audioBytes = base64Decode(audioBase64);
            onAudioResponse?.call(audioBytes);
          }
          break;

        case 'response.audio_transcript.delta':
          final textDelta = data['delta'] as String?;
          if (textDelta != null) {
            onTextResponse?.call(textDelta);
            if (!_aiResponseController.isClosed) {
              _aiResponseController.add(textDelta);
            }
          }
          break;

        case 'response.done':
          Logger.info('Response complete', tag: _tag);
          break;

        case 'error':
          final errorData = data['error'] as Map<String, dynamic>?;
          final errorMsg = errorData?['message'] ?? 'Unknown error';
          Logger.error('API Error: $errorMsg', tag: _tag);
          onError?.call(errorMsg);
          break;

        default:
          Logger.debug('Unhandled event: $type', tag: _tag);
      }
    } catch (e) {
      Logger.error('Error handling message: $e', tag: _tag);
    }
  }

  /// Handle session created event
  void _handleSessionCreated(Map<String, dynamic> data) {
    final session = data['session'] as Map<String, dynamic>?;
    _sessionId = session?['id'] ?? '';

    Logger.info('Session created: $_sessionId', tag: _tag);

    // Complete the connection completer
    _connectionCompleter?.complete(true);

    // Set state to connected
    _setState(VoiceLiveState.connected);

    onConnected?.call();

    // Configure the session
    _configureSession();
  }

  /// Start recording - call this when user taps record
  void startRecording() {
    if (!_isConnected) {
      Logger.warning('Not connected, cannot start recording', tag: _tag);
      return;
    }

    _audioBuffer.clear();
    _totalAudioBytes = 0;
    _setState(VoiceLiveState.recording);

    Logger.info('Recording started', tag: _tag);
  }

  /// Send audio chunk - call this with mic data
  /// [audioBytes] - PCM16 audio data at 24kHz mono
  void sendAudioChunk(Uint8List audioBytes) {
    if (!_isConnected || !_isRecording) return;

    // Buffer the audio
    _audioBuffer.add(audioBytes);
    _totalAudioBytes += audioBytes.length;

    // Send to Azure
    final base64Audio = base64Encode(audioBytes);
    _sendJson({
      'type': 'input_audio_buffer.append',
      'audio': base64Audio,
    });
  }

  /// Stop recording and commit audio for transcription
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _setState(VoiceLiveState.processing);
    Logger.info('Recording stopped, total bytes: $_totalAudioBytes', tag: _tag);

    // Only commit in transcription mode - server_vad auto-commits in conversation mode
    if (_mode == VoiceLiveMode.transcription) {
      _sendJson({
        'type': 'input_audio_buffer.commit',
      });
    } else {
      // In conversation mode, just go back to connected state
      // Server VAD handles the commit
      _setState(VoiceLiveState.connected);
    }

    // Clear local buffer
    _audioBuffer.clear();
    _totalAudioBytes = 0;
  }

  /// Cancel recording without transcribing
  void cancelRecording() {
    if (!_isRecording) return;

    _setState(VoiceLiveState.connected);
    _audioBuffer.clear();
    _totalAudioBytes = 0;

    // Clear the server-side buffer
    _sendJson({
      'type': 'input_audio_buffer.clear',
    });

    Logger.info('Recording cancelled', tag: _tag);
  }

  /// Request AI response (for voice assistant mode)
  void requestResponse() {
    if (!_isConnected) return;

    _sendJson({
      'type': 'response.create',
    });
  }

  /// Send JSON message over WebSocket
  void _sendJson(Map<String, dynamic> data) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  /// Disconnect from the service
  Future<void> disconnect() async {
    await _wsSubscription?.cancel();
    _wsSubscription = null;

    await _channel?.sink.close();
    _channel = null;

    _audioBuffer.clear();
    _setState(VoiceLiveState.disconnected);

    Logger.info('Disconnected', tag: _tag);
  }

  /// Check if service is ready
  bool get isReady => _isInitialized;

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Check if recording
  bool get isRecording => _isRecording;

  /// Dispose resources
  void dispose() {
    // Disconnect first (while streams are still open)
    disconnect();
    // Then close streams
    _stateController.close();
    _transcriptionController.close();
    _partialController.close();
    _aiResponseController.close();
    _isInitialized = false;
  }
}
