import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import '../utils/logger.dart';

/// Singleton service for playing raw PCM audio from Azure responses
class AudioOutputService {
  static const String _tag = 'AudioOutputService';
  static AudioOutputService? _instance;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isAudioSessionConfigured = false;

  // iOS: Track if mic_stream may have reset the audio session
  // Set to true when mic stream starts, cleared after we re-configure
  bool _needsAudioSessionReconfig = false;

  // Azure sends 24kHz PCM16 mono audio
  static const int sampleRate = 24000;
  static const int numChannels = 1;

  AudioOutputService._();

  static AudioOutputService get instance {
    _instance ??= AudioOutputService._();
    return _instance!;
  }

  /// Call this when mic_stream starts on iOS to mark that audio session
  /// may have been reset and needs re-configuration before playback
  void markAudioSessionNeedsReconfig() {
    if (Platform.isIOS) {
      _needsAudioSessionReconfig = true;
      Logger.info('iOS: Marked audio session for re-configuration', tag: _tag);
    }
  }

  /// Configure the iOS audio session for voice chat with speaker output
  /// This MUST be called before microphone activation (and potentially after)
  /// to ensure audio routes to speaker instead of earpiece.
  /// Set [force] to true to re-apply even if already configured.
  Future<void> configureAudioSession({bool force = false}) async {
    if (_isAudioSessionConfigured && !force) return;

    try {
      final session = await AudioSession.instance;

      // Configure for voice chat: simultaneous record + playback
      // - defaultToSpeaker: Routes audio to speaker instead of earpiece
      // - allowBluetooth: Enables Bluetooth headphones/speakers
      // - allowBluetoothA2dp: High quality Bluetooth audio
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
                AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.allowBluetoothA2dp,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));

      // Activate the session
      await session.setActive(true);

      _isAudioSessionConfigured = true;
      Logger.info(
          'iOS audio session configured (playAndRecord, defaultToSpeaker, voiceChat)',
          tag: _tag);
    } catch (e) {
      Logger.error('Failed to configure audio session: $e', tag: _tag);
      // Continue anyway - audio might work with default settings
    }
  }

  /// Initialize the audio player
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio session FIRST (iOS requires this before mic activation)
      // This ensures audio routes to speaker instead of earpiece
      if (Platform.isIOS || Platform.isMacOS) {
        await configureAudioSession();
      }

      // Set log level (0 = none, 1 = error, 2 = standard, 3 = verbose)
      FlutterPcmSound.setLogLevel(LogLevel.standard);

      // Setup with sample rate and channel count
      await FlutterPcmSound.setup(
        sampleRate: sampleRate,
        channelCount: numChannels,
      );

      // Set callback for when more audio is needed (optional)
      FlutterPcmSound.setFeedCallback(_onFeedCallback);

      _isInitialized = true;
      Logger.info('Audio output initialized (${sampleRate}Hz, $numChannels ch)',
          tag: _tag);
    } catch (e) {
      Logger.error('Failed to initialize audio output: $e', tag: _tag);
    }
  }

  /// Feed audio data to the player
  void feedAudio(Uint8List pcmData) {
    if (!_isInitialized) {
      Logger.warning('Audio output not initialized', tag: _tag);
      return;
    }

    // iOS: Re-configure audio session if mic_stream may have reset it
    // This ensures speaker output even if AI responds very quickly
    if (Platform.isIOS && _needsAudioSessionReconfig) {
      _needsAudioSessionReconfig = false;
      Logger.info('iOS: Re-configuring audio session before playback',
          tag: _tag);
      configureAudioSession(force: true);
    }

    try {
      // Convert Uint8List (bytes) to Int16List (samples)
      // PCM16 = 2 bytes per sample, little-endian
      final samples = pcmData.buffer.asInt16List();

      // Feed the samples to the player using correct API
      FlutterPcmSound.feed(PcmArrayInt16.fromList(samples.toList()));

      if (!_isPlaying) {
        _isPlaying = true;
        FlutterPcmSound.start();
        Logger.debug('Audio playback started', tag: _tag);
      }
    } catch (e) {
      Logger.error('Failed to feed audio: $e', tag: _tag);
    }
  }

  /// Callback when player needs more audio (low buffer)
  /// Also detects when playback completes (remainingFrames == 0)
  void _onFeedCallback(int remainingFrames) {
    // When buffer is fully drained, playback has stopped
    // Reset _isPlaying so start() is called for the next response
    if (remainingFrames == 0 && _isPlaying) {
      _isPlaying = false;
      Logger.debug('Audio playback completed (buffer drained)', tag: _tag);
    }
  }

  /// Stop playback immediately (for interruption handling)
  /// Called when user starts speaking during AI audio playback
  /// flutter_pcm_sound v3+ has no clear() method - use release/setup pattern
  Future<void> stop() async {
    if (!_isInitialized || !_isPlaying) return;

    try {
      // Release and re-setup to immediately stop and clear buffer
      await FlutterPcmSound.release();
      _isPlaying = false;

      // Re-initialize for next audio
      await FlutterPcmSound.setup(
        sampleRate: sampleRate,
        channelCount: numChannels,
      );
      FlutterPcmSound.setFeedCallback(_onFeedCallback);

      // iOS: Re-configure audio session to ensure speaker output after stop
      // FlutterPcmSound.release() may affect audio routing
      if (Platform.isIOS) {
        await configureAudioSession(force: true);
      }

      Logger.info('Audio playback stopped (interruption)', tag: _tag);
    } catch (e) {
      Logger.error('Failed to stop audio: $e', tag: _tag);
    }
  }

  /// Stop and release the audio player
  Future<void> dispose() async {
    try {
      await FlutterPcmSound.release();

      // Deactivate audio session on iOS/macOS
      if (_isAudioSessionConfigured && (Platform.isIOS || Platform.isMacOS)) {
        try {
          final session = await AudioSession.instance;
          await session.setActive(false);
          _isAudioSessionConfigured = false;
          Logger.info('Audio session deactivated', tag: _tag);
        } catch (e) {
          Logger.warning('Failed to deactivate audio session: $e', tag: _tag);
        }
      }

      _isInitialized = false;
      _isPlaying = false;
      Logger.info('Audio output disposed', tag: _tag);
    } catch (e) {
      Logger.error('Failed to dispose audio output: $e', tag: _tag);
    }
  }
}
