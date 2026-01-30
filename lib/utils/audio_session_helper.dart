import 'dart:io' show Platform;
import 'package:audio_session/audio_session.dart';
import 'logger.dart';

/// Centralized audio session configuration for consistent audio routing.
/// Ensures audio plays through speaker (not earpiece) and supports
/// Bluetooth headphones/speakers across the app.
class AudioSessionHelper {
  static const String _tag = 'AudioSessionHelper';
  static bool _isConfigured = false;

  AudioSessionHelper._();

  /// Configure audio session for media playback (meditations, audio content).
  /// Routes audio to speaker by default, supports Bluetooth.
  /// Safe to call multiple times - will skip if already configured.
  static Future<void> configureForPlayback({bool force = false}) async {
    if (_isConfigured && !force) return;
    if (!Platform.isIOS && !Platform.isMacOS && !Platform.isAndroid) return;

    try {
      final session = await AudioSession.instance;

      await session.configure(AudioSessionConfiguration(
        // iOS: Playback category with speaker default
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
                AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.allowBluetoothA2dp |
                AVAudioSessionCategoryOptions.allowAirPlay,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        // Android: Media playback with speaker
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      await session.setActive(true);
      _isConfigured = true;

      Logger.info('Audio session configured for playback (speaker + bluetooth)',
          tag: _tag);
    } catch (e) {
      Logger.error('Failed to configure audio session for playback: $e',
          tag: _tag);
    }
  }

  /// Configure audio session for voice chat (realtime conversation).
  /// Routes audio to speaker, supports mic + playback simultaneously.
  static Future<void> configureForVoiceChat({bool force = false}) async {
    if (_isConfigured && !force) return;
    if (!Platform.isIOS && !Platform.isMacOS && !Platform.isAndroid) return;

    try {
      final session = await AudioSession.instance;

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

      await session.setActive(true);
      _isConfigured = true;

      Logger.info(
          'Audio session configured for voice chat (speaker + bluetooth)',
          tag: _tag);
    } catch (e) {
      Logger.error('Failed to configure audio session for voice chat: $e',
          tag: _tag);
    }
  }

  /// Reset configuration flag (call when audio session may have been
  /// disrupted by another component like mic_stream)
  static void markNeedsReconfiguration() {
    _isConfigured = false;
    Logger.debug('Audio session marked for reconfiguration', tag: _tag);
  }

  /// Deactivate audio session (call when done with audio)
  static Future<void> deactivate() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
      _isConfigured = false;
      Logger.debug('Audio session deactivated', tag: _tag);
    } catch (e) {
      Logger.warning('Failed to deactivate audio session: $e', tag: _tag);
    }
  }
}
