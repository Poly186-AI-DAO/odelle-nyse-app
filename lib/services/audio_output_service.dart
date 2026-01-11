import 'dart:typed_data';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import '../utils/logger.dart';

/// Singleton service for playing raw PCM audio from Azure responses
class AudioOutputService {
  static const String _tag = 'AudioOutputService';
  static AudioOutputService? _instance;
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  
  // Azure sends 24kHz PCM16 mono audio
  static const int sampleRate = 24000;
  static const int numChannels = 1;
  
  AudioOutputService._();
  
  static AudioOutputService get instance {
    _instance ??= AudioOutputService._();
    return _instance!;
  }
  
  /// Initialize the audio player
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
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
      Logger.info('Audio output initialized (${sampleRate}Hz, $numChannels ch)', tag: _tag);
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
  void _onFeedCallback(int remainingFrames) {
    // This is called when buffer is running low
    // We don't need to do anything here since we're feeding 
    // audio as it arrives from Azure
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
      
      Logger.info('Audio playback stopped (interruption)', tag: _tag);
    } catch (e) {
      Logger.error('Failed to stop audio: $e', tag: _tag);
    }
  }
  
  /// Stop and release the audio player
  Future<void> dispose() async {
    try {
      await FlutterPcmSound.release();
      _isInitialized = false;
      _isPlaying = false;
      Logger.info('Audio output disposed', tag: _tag);
    } catch (e) {
      Logger.error('Failed to dispose audio output: $e', tag: _tag);
    }
  }
}

