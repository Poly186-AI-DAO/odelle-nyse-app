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

  // Recent entries for display
  List<JournalEntry> _recentEntries = [];

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
    _loadRecentEntries();
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

  Future<void> _loadRecentEntries() async {
    final entries = await _database.getJournalEntries(limit: 3);
    setState(() {
      _recentEntries = entries;
    });
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
      await _loadRecentEntries();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),

        // Main conversation area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _buildConversationArea(),
        ),

        const Spacer(flex: 3),

        // Bottom spacing for voice button
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildConversationArea() {
    // Show transcription if available
    if (_finalTranscription.isNotEmpty) {
      return ConversationText(
        text: _finalTranscription,
        isTyping: false,
        fontSize: 22,
        textColor: ThemeConstants.textOnDark,
      );
    }

    // Show partial transcription while recording
    if (_partialTranscription.isNotEmpty) {
      return ConversationText(
        text: _partialTranscription,
        isTyping: true,
        fontSize: 22,
        textColor: ThemeConstants.textOnDark,
      );
    }

    // Show waveform while recording
    if (_isRecording) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceWaveformAnimated(
            barCount: 5,
            size: 48,
            color: ThemeConstants.textOnDark,
            isActive: true,
          ),
          const SizedBox(height: 24),
          Text(
            'Listening...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ThemeConstants.textOnDark.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
        ],
      );
    }

    // Show connecting state
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

    // Default idle state - greeting
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
