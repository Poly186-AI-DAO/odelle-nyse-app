import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' show VoidCallback;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/logger.dart';

/// Connection timeout duration
const Duration _connectionTimeout = Duration(seconds: 10);

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

  // Callbacks
  Function(String transcription)? onTranscription;
  Function(String partialResult)? onPartialResult;
  Function(String error)? onError;
  Function(Uint8List audioData)? onAudioResponse;
  Function(String text)? onTextResponse;
  VoidCallback? onSpeechStarted;
  VoidCallback? onSpeechStopped;
  VoidCallback? onConnected;

  // State
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isRecording = false;
  String _sessionId = '';

  AzureSpeechService() {
    _initialize();
  }

  void _initialize() {
    // Get Azure OpenAI Realtime API configuration from .env
    // Using the new poly-ai-foundry endpoint
    _apiKey = dotenv.env['AZURE_GPT_REALTIME_KEY'] ?? '';

    // Parse the target URL to get the base endpoint
    final targetUrl = dotenv.env['AZURE_GPT_REALTIME_DEPLOYMENT_URL'] ?? '';

    if (_apiKey.isEmpty || targetUrl.isEmpty) {
      Logger.error(
          'Azure Realtime API key or endpoint not found in environment',
          tag: _tag);
      Logger.error(
          'Expected env vars: AZURE_GPT_REALTIME_KEY, AZURE_GPT_REALTIME_DEPLOYMENT_URL',
          tag: _tag);
      return;
    }

    // Convert https:// to wss:// for WebSocket connection
    _endpointUrl = targetUrl.replaceFirst('https://', 'wss://');

    Logger.info(
        'Azure Realtime Service initialized with endpoint: ${_endpointUrl.split('?').first}',
        tag: _tag);
    _isInitialized = true;
  }

  /// Connect to Azure OpenAI Realtime API
  Future<bool> connect() async {
    if (!_isInitialized) {
      onError?.call('Service not initialized');
      return false;
    }

    if (_isConnected) {
      Logger.info('Already connected', tag: _tag);
      return true;
    }

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
          _isConnected = false;
          _connectionCompleter?.complete(false);
        },
        onDone: () {
          Logger.info('WebSocket closed', tag: _tag);
          _isConnected = false;
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
          return false;
        },
      );

      return connected;
    } catch (e, stackTrace) {
      Logger.error('Failed to connect: $e', tag: _tag, data: {
        'stackTrace': stackTrace.toString(),
      });
      onError?.call('Failed to connect: $e');
      return false;
    }
  }

  /// Configure the session for transcription
  void _configureSession() {
    if (_channel == null) return;

    // Azure OpenAI Realtime API session configuration
    // Docs: https://github.com/azure-samples/aoai-realtime-audio-sdk
    final sessionConfig = {
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'voice': 'alloy',
        'instructions':
            'You are a helpful voice journal assistant. Listen to the user and acknowledge what they say.',
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 600,
        },
        'temperature': 0.8,
      },
    };

    _sendJson(sessionConfig);
    Logger.info('Session configured for transcription', tag: _tag);
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
          }
          break;

        case 'conversation.item.input_audio_transcription.completed':
          final transcript = data['transcript'] as String?;
          if (transcript != null && transcript.isNotEmpty) {
            Logger.info('Transcription complete: $transcript', tag: _tag);
            onTranscription?.call(transcript);
          }
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
    _isConnected = true;

    Logger.info('Session created: $_sessionId', tag: _tag);

    // Complete the connection completer
    _connectionCompleter?.complete(true);

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
    _isRecording = true;

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

    _isRecording = false;
    Logger.info('Recording stopped, total bytes: $_totalAudioBytes', tag: _tag);

    // Commit the audio buffer to trigger transcription
    _sendJson({
      'type': 'input_audio_buffer.commit',
    });

    // Clear local buffer
    _audioBuffer.clear();
    _totalAudioBytes = 0;
  }

  /// Cancel recording without transcribing
  void cancelRecording() {
    if (!_isRecording) return;

    _isRecording = false;
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

    _isConnected = false;
    _isRecording = false;
    _audioBuffer.clear();

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
    disconnect();
    _isInitialized = false;
  }
}
