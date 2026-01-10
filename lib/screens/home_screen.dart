import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/journal_entry.dart';
import '../providers/service_providers.dart';
import '../services/azure_speech_service.dart';
import '../utils/logger.dart';
import '../widgets/navigation/pillar_nav_bar.dart';
import '../widgets/voice/voice_button.dart';
import 'body_screen.dart';
import 'voice_screen.dart';
import 'mind_screen.dart';

/// Main home screen with horizontal pager navigation
/// 3 Pillars: Body (left) | Voice (center/default) | Mind (right)
/// Voice button persists and controls mic stream
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const String _tag = 'HomeScreen';

  late PageController _pageController;
  int _currentPage = 1; // Current pillar index (0, 1, 2)
  static const int _initialPageOffset = 3000; // Large multiple of 3

  // Voice control
  late AzureSpeechService _speechService;
  StreamSubscription<VoiceLiveState>? _stateSubscription;
  StreamSubscription<Uint8List>? _micSubscription;
  Stream<Uint8List>? _micStream;
  VoiceLiveState _voiceState = VoiceLiveState.disconnected;
  bool _hasPermission = false;

  // Pillar definitions
  static const List<PillarItem> _pillars = [
    PillarItem(
      assetIcon: 'assets/icons/body_powerlifting_icon.png',
      iconScale: 1.5,
      label: 'Body',
    ),
    PillarItem(
      icon: Icons.graphic_eq_outlined,
      activeIcon: Icons.graphic_eq,
      label: 'Voice',
    ),
    PillarItem(
      assetIcon: 'assets/icons/mind_meditate_icon.png',
      label: 'Mind',
    ),
  ];

  bool get _isConnecting => _voiceState == VoiceLiveState.connecting;
  bool get _isConnected =>
      _voiceState == VoiceLiveState.connected ||
      _voiceState == VoiceLiveState.recording ||
      _voiceState == VoiceLiveState.processing;
  bool get _isRecording => _voiceState == VoiceLiveState.recording;

  // Scroll progress for animations
  double _scrollProgress = 1.0;

  @override
  void initState() {
    super.initState();
    // Start at a large page index that is "Voice" (index 1 % 3)
    final initialPage = _initialPageOffset + 1;
    _pageController = PageController(initialPage: initialPage);
    _scrollProgress = initialPage.toDouble();
    _pageController.addListener(_onScroll);
    _checkPermissionStatus();
  }

  void _onScroll() {
    if (_pageController.hasClients && _pageController.page != null) {
      setState(() {
        _scrollProgress = _pageController.page!;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _speechService = ref.read(voiceServiceProvider);
    _subscribeToState();
    _setupSaveCallback();
  }

  void _subscribeToState() {
    _stateSubscription?.cancel();
    _stateSubscription = _speechService.stateStream.listen((state) {
      setState(() => _voiceState = state);
    });
    _voiceState = _speechService.state;
  }

  void _setupSaveCallback() {
    final db = ref.read(databaseProvider);
    _speechService.onTranscription = (text) async {
      if (text.isEmpty) return;
      try {
        await db.insertJournalEntry(JournalEntry(
          timestamp: DateTime.now(),
          transcription: text,
        ));
        Logger.info('Journal entry saved', tag: _tag);
      } catch (e) {
        Logger.error('Failed to save entry: $e', tag: _tag);
      }
    };

    // Handle connection errors
    _speechService.onError = (error) {
      Logger.error('Voice service error: $error', tag: _tag);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice error: $error'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };

    // Log when connected
    _speechService.onConnected = () {
      Logger.info('Voice service connected', tag: _tag);
    };
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.microphone.status;
    setState(() => _hasPermission = status.isGranted);
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
    setState(() => _hasPermission = result.isGranted);
    return result.isGranted;
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _stateSubscription?.cancel();
    _stopMicStream();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page % 3);
    HapticFeedback.selectionClick();
  }

  void _onPillarTapped(int index) {
    if (!_pageController.hasClients) return;

    // Find nearest page to animate to
    final int currentRawPage =
        _pageController.page?.round() ?? _initialPageOffset + 1;
    final int targetRawPage = currentRawPage + (index - (currentRawPage % 3));

    _pageController.animateToPage(
      targetRawPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // Lock logic
  bool _isLocked = false;

  /// FAB tap - toggle connection
  Future<void> _onVoiceButtonTap() async {
    // Navigate to voice page if not there
    if (_currentPage != 1) {
      _onPillarTapped(1);
    }

    // Toggle connection/recording
    if (_isLocked) {
      // If locked, tap stops
      await _stopRecording();
      setState(() => _isLocked = false);
    } else if (_isRecording) {
      // Tapped while recording (not locked) -> Stop
      await _stopRecording();
    } else if (_isConnected) {
      // Connected but not recording -> Disconnect? Or Start?
      // Standard behavior: tap to start recording if connected
      await _startRecording();
    } else {
      // Disconnected -> Connect
      await _connect();
    }
  }

  /// FAB long press start - begin recording (Transcription Mode)
  Future<void> _onVoiceButtonLongPressStart() async {
    HapticFeedback.mediumImpact();

    // Ensure on Voice Screen
    if (_currentPage != 1) {
      _onPillarTapped(1);
    }

    if (!_isConnected) {
      await _connect();
      // Wait for connection
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (_isConnected && !_isRecording) {
      // Default to transcription mode for hold-to-talk
      if (_speechService.mode != VoiceLiveMode.transcription) {
        _speechService.switchMode(VoiceLiveMode.transcription);
      }
      await _startRecording();
    }
  }

  /// FAB locked - switch to Live Mode
  void _onVoiceButtonLock() {
    setState(() => _isLocked = true);
    // Switch to conversation mode
    _speechService.switchMode(VoiceLiveMode.conversation);
  }

  /// FAB long press end - stop recording (if not locked)
  Future<void> _onVoiceButtonLongPressEnd() async {
    if (!_isLocked && _isRecording) {
      await _stopRecording();
    }
  }

  Future<void> _connect() async {
    if (_isConnecting || _isConnected) return;

    if (!_hasPermission) {
      final granted = await _requestMicrophonePermission();
      if (!granted) return;
    }

    await _speechService.connect();
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

      Logger.info('Recording started', tag: _tag);
    } catch (e) {
      Logger.error('Failed to start recording: $e', tag: _tag);
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _stopMicStream();
      await _speechService.stopRecording();
      Logger.info('Recording stopped', tag: _tag);
      setState(() => _isLocked = false);
    } catch (e) {
      Logger.error('Failed to stop recording: $e', tag: _tag);
    }
  }

  Future<void> _stopMicStream() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
    _micStream = null;
  }

  // Get interpolated background color based on scroll progress
  // All screens now use Hero Card design, so background is consistent light silver
  Color _getInterpolatedBackground() {
    // Light silver background for all screens (visible in bottom 18%)
    return const Color(0xFFE2E8F0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getInterpolatedBackground(),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        color: _getInterpolatedBackground(),
        // Use Stack so VoiceScreen can extend behind nav bar
        child: Stack(
          children: [
            // Page content - infinite looping carousel
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemCount: null, // Infinite
              itemBuilder: (context, index) {
                // Modulo to cycle through 3 screens
                final pageIndex = index % 3;

                // Calculate visibility based on distance from current scroll position
                final distance = (index - _scrollProgress).abs();
                final visibility = (1.0 - distance).clamp(0.0, 1.0);

                switch (pageIndex) {
                  case 0:
                    return BodyScreen(panelVisibility: visibility);
                  case 1:
                    return VoiceScreen(panelVisibility: visibility);
                  case 2:
                    return MindScreen(panelVisibility: visibility);
                  default:
                    return const SizedBox();
                }
              },
            ),

            // Nav bar - positioned INSIDE the floating card area
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16), // Inside card margin
                  child: PillarNavBarThin(
                    pillars: _pillars,
                    currentIndex: _currentPage,
                    onPillarTapped: _onPillarTapped,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Persistent voice button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: VoiceButton(
          size: 64,
          isActive: _isRecording,
          isConnected: _isConnected,
          isLocked: _isLocked,
          onTap: _onVoiceButtonTap,
          onLongPressStart: _onVoiceButtonLongPressStart,
          onLongPressEnd: _onVoiceButtonLongPressEnd,
          onLock: _onVoiceButtonLock,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
