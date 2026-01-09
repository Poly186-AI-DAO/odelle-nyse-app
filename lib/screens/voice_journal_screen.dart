import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart';
import '../services/azure_speech_service.dart';
import '../database/app_database.dart';
import '../models/journal_entry.dart';
import '../utils/logger.dart';
import '../widgets/widgets.dart';

/// Voice Journal Screen - "Kitchen Confessional"
/// Tap to record → Azure Voice Live transcription → Save to local DB
class VoiceJournalScreen extends StatefulWidget {
  const VoiceJournalScreen({super.key});

  @override
  State<VoiceJournalScreen> createState() => _VoiceJournalScreenState();
}

class _VoiceJournalScreenState extends State<VoiceJournalScreen>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'VoiceJournalScreen';

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
  String _statusText = 'Tap to connect';
  String _partialTranscription = '';
  String _finalTranscription = '';

  // Recent entries
  List<JournalEntry> _recentEntries = [];

  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _checkPermissionStatus(); // Only check status, don't request
    _loadRecentEntries();
    _setupCallbacks();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController.repeat(reverse: true);
  }

  void _setupCallbacks() {
    _speechService.onConnected = () {
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _statusText = 'Connected - Hold to record';
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
        _statusText = 'Error: $error';
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

  /// Only check current permission status without requesting
  Future<void> _checkPermissionStatus() async {
    final status = await Permission.microphone.status;
    setState(() {
      _hasPermission = status.isGranted;
      if (!_hasPermission) {
        _statusText = 'Microphone permission required';
      }
    });
  }

  /// Request microphone permission when user taps connect
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      return true;
    }

    if (status.isPermanentlyDenied) {
      // User denied permanently, open app settings
      setState(() {
        _statusText = 'Permission denied - tap to open settings';
      });
      await openAppSettings();
      return false;
    }

    // Request permission
    final result = await Permission.microphone.request();
    setState(() {
      _hasPermission = result.isGranted;
      if (!_hasPermission) {
        _statusText = 'Microphone permission required';
      }
    });
    return result.isGranted;
  }

  Future<void> _loadRecentEntries() async {
    final entries = await _database.getJournalEntries(limit: 5);
    setState(() {
      _recentEntries = entries;
    });
  }

  Future<void> _connect() async {
    if (_isConnecting || _isConnected) return;

    // Request permission on user action
    if (!_hasPermission) {
      final granted = await _requestMicrophonePermission();
      if (!granted) return;
    }

    setState(() {
      _isConnecting = true;
      _statusText = 'Connecting...';
    });

    final success = await _speechService.connect();
    if (!success) {
      setState(() {
        _isConnecting = false;
        _statusText = 'Connection failed - Tap to retry';
      });
    }
  }

  Future<void> _startRecording() async {
    if (!_isConnected || _isRecording) return;

    try {
      // Start mic stream at 24kHz for Voice Live API
      _micStream = MicStream.microphone(
        sampleRate: 24000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );

      _speechService.startRecording();

      _micSubscription = _micStream!.listen((audioBytes) {
        // Send audio chunks to Azure
        _speechService.sendAudioChunk(audioBytes);
      });

      setState(() {
        _isRecording = true;
        _statusText = 'Recording...';
        _partialTranscription = '';
        _finalTranscription = '';
      });

      Logger.info('Recording started', tag: _tag);
    } catch (e) {
      Logger.error('Failed to start recording: $e', tag: _tag);
      setState(() {
        _statusText = 'Failed to start mic';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      // Stop mic stream
      await _stopMicStream();

      // Tell Azure to process the audio
      await _speechService.stopRecording();

      setState(() {
        _isRecording = false;
        _statusText = 'Processing...';
      });

      Logger.info('Recording stopped, waiting for transcription', tag: _tag);
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
    if (transcription.isEmpty) {
      setState(() {
        _statusText = 'No speech detected';
      });
      return;
    }

    try {
      final entry = JournalEntry(
        timestamp: DateTime.now(),
        transcription: transcription,
      );

      await _database.insertJournalEntry(entry);
      Logger.info('Journal entry saved', tag: _tag);

      setState(() {
        _statusText = 'Saved! Hold to record again';
      });

      // Reload recent entries
      await _loadRecentEntries();
    } catch (e) {
      Logger.error('Failed to save entry: $e', tag: _tag);
      setState(() {
        _statusText = 'Failed to save';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopMicStream();
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      extendBody: true,
      body: Stack(
        children: [
          // Rive background
          Positioned.fill(
            child: RiveAnimation.asset(
              'assets/riv/isometric_marketing_agency_animation.riv',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient overlay
          const Positioned.fill(
            child: GradientOverlay(),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),

                const Spacer(flex: 2),

                // Conversation area
                _buildConversationArea(),

                const Spacer(flex: 3),

                // Record button
                _buildVoiceButton(),

                const SizedBox(height: 24),

                // Recent entries in bottom panel
                _buildRecentEntriesPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'Kitchen Confessional',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildConversationArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status indicator
          VoiceStatusText(
            status: _isRecording
                ? VoiceStatus.listening
                : _isConnecting
                    ? VoiceStatus.processing
                    : VoiceStatus.idle,
            customText: _statusText,
          ),
          const SizedBox(height: 24),

          // Transcription display
          if (_finalTranscription.isNotEmpty)
            ConversationText(
              text: _finalTranscription,
              isTyping: false,
            )
          else if (_partialTranscription.isNotEmpty)
            ConversationText(
              text: _partialTranscription,
              isTyping: true,
            )
          else if (_isRecording)
            const VoiceWaveformAnimated(
              barCount: 5,
              size: 48,
              color: Colors.white,
              isActive: true,
            )
          else if (!_isConnected)
            GreetingText(
              greeting: 'Tap to',
              name: 'connect',
              subtitle: 'Then hold to record your thoughts',
            )
          else
            GreetingText(
              greeting: 'Ready to',
              name: 'listen',
              subtitle: 'Hold the mic button to record',
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    // Use VoiceButton's built-in gesture handling - no outer wrapper
    return VoiceButton(
      size: 80,
      isListening: _isRecording,
      onTap: !_isConnected ? _connect : null,
      onLongPressStart: _isConnected && !_isRecording ? _startRecording : null,
      onLongPressEnd: _isRecording ? _stopRecording : null,
    );
  }

  Widget _buildRecentEntriesPanel() {
    if (_recentEntries.isEmpty) {
      return const SizedBox(height: 100);
    }

    return Container(
      height: 160,
      margin: const EdgeInsets.only(top: 16),
      child: BottomPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'RECENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _recentEntries.length,
                itemBuilder: (context, index) {
                  final entry = _recentEntries[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(entry.timestamp),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            entry.transcription,
                            style: const TextStyle(
                              color: Color(0xFF0A1628),
                              fontSize: 13,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
