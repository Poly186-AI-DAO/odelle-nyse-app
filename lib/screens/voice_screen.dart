import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/theme_constants.dart';
import '../services/azure_speech_service.dart';
import '../database/app_database.dart';
import '../models/journal_entry.dart';
import '../utils/logger.dart';
import '../widgets/voice/conversation_text.dart';
import '../widgets/voice/voice_waveform_animated.dart';

/// Voice Screen - Primary interaction point
/// Clean minimal design with transcription display
/// This is the "home" screen users see first
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  static const String _tag = 'VoiceScreen';

  // Services
  final AzureSpeechService _speechService = AzureSpeechService();
  final AppDatabase _database = AppDatabase.instance;

  // Mic stream
  StreamSubscription<Uint8List>? _micSubscription;
  Stream<Uint8List>? _micStream;

  // State
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isRecording = false;
  bool _hasPermission = false;
  String _partialTranscription = '';
  String _finalTranscription = '';

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _speechService.onConnected = () {
      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });
      Logger.info('Connected to Voice Live', tag: _tag);
    };

    _speechService.onTranscription = (text) async {
      Logger.info('Transcription received: $text', tag: _tag);
      setState(() {
        _finalTranscription = text;
        _partialTranscription = '';
      });
      await _saveJournalEntry(text);
    };

    _speechService.onPartialResult = (text) {
      setState(() {
        _partialTranscription += text;
      });
    };

    _speechService.onError = (error) {
      Logger.error('Speech error: $error', tag: _tag);
      setState(() {
        _isRecording = false;
      });
      _stopMicStream();
    };

    _speechService.onSpeechStarted = () {
      Logger.info('Speech detected', tag: _tag);
    };

    _speechService.onSpeechStopped = () {
      Logger.info('Speech ended', tag: _tag);
    };
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.microphone.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final result = await Permission.microphone.request();
    setState(() {
      _hasPermission = result.isGranted;
    });
    return result.isGranted;
  }

  Future<void> _connect() async {
    if (_isConnecting || _isConnected) return;

    if (!_hasPermission) {
      final granted = await _requestMicrophonePermission();
      if (!granted) return;
    }

    setState(() {
      _isConnecting = true;
    });

    final success = await _speechService.connect();
    if (!success) {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_isConnected || _isRecording) return;

    try {
      _micStream = MicStream.microphone(
        sampleRate: 24000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );

      _speechService.startRecording();

      _micSubscription = _micStream!.listen((audioBytes) {
        _speechService.sendAudioChunk(audioBytes);
      });

      setState(() {
        _isRecording = true;
        _partialTranscription = '';
        _finalTranscription = '';
      });

      Logger.info('Recording started', tag: _tag);
    } catch (e) {
      Logger.error('Failed to start recording: $e', tag: _tag);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await _stopMicStream();
      await _speechService.stopRecording();

      setState(() {
        _isRecording = false;
      });

      Logger.info('Recording stopped', tag: _tag);
    } catch (e) {
      Logger.error('Failed to stop recording: $e', tag: _tag);
    }
  }

  Future<void> _stopMicStream() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
    _micStream = null;
  }

  Future<void> _saveJournalEntry(String transcription) async {
    if (transcription.isEmpty) return;

    try {
      final entry = JournalEntry(
        timestamp: DateTime.now(),
        transcription: transcription,
      );

      await _database.insertJournalEntry(entry);
      Logger.info('Journal entry saved', tag: _tag);
    } catch (e) {
      Logger.error('Failed to save entry: $e', tag: _tag);
    }
  }

  @override
  void dispose() {
    _stopMicStream();
    _speechService.dispose();
    super.dispose();
  }

  // Check if we have transcription content to show
  bool get _hasTranscription =>
      _finalTranscription.isNotEmpty ||
      _partialTranscription.isNotEmpty ||
      _isRecording;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isConnected ? null : _connect,
      onLongPressStart: _isConnected ? (_) => _startRecording() : null,
      onLongPressEnd: _isConnected ? (_) => _stopRecording() : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Main content - greeting centered
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildIdleContent(),
              ),
            ),
          ),

          // Animated top transcription panel - slides down when active
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            top: _hasTranscription ? 0 : -300,
            left: 0,
            right: 0,
            child: _buildTranscriptionPanel(),
          ),
        ],
      ),
    );
  }

  /// Top panel that slides down with transcription
  Widget _buildTranscriptionPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ThemeConstants.deepNavy.withValues(alpha: 0.95),
            ThemeConstants.darkTeal.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status label
          Text(
            _isRecording ? 'LISTENING' : 'TRANSCRIPTION',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textOnDark.withValues(alpha: 0.5),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Transcription content
          if (_isRecording && _partialTranscription.isEmpty)
            VoiceWaveformAnimated(
              barCount: 5,
              size: 32,
              color: ThemeConstants.textOnDark,
              isActive: true,
            )
          else
            Text(
              _partialTranscription.isNotEmpty
                  ? _partialTranscription
                  : _finalTranscription,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: ThemeConstants.textOnDark,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  /// Idle/greeting content when not transcribing
  Widget _buildIdleContent() {
    if (_isConnecting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ThemeConstants.textOnDark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ThemeConstants.textOnDark.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }

    // Show greeting when idle or has transcription (greeting shows behind panel)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getGreeting(),
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: ThemeConstants.textOnDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isConnected ? 'Hold to speak' : 'Tap to connect',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: ThemeConstants.textOnDark.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
