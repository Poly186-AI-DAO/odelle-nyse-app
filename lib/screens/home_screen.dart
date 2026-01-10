import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../database/app_database.dart';
import '../models/journal_entry.dart';
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
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      assetIcon: 'assets/icons/body_gym_icon.png',
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
    _speechService = context.read<AzureSpeechService>();
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
    final db = context.read<AppDatabase>();
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
    final int currentRawPage = _pageController.page?.round() ?? _initialPageOffset + 1;
    final int targetRawPage = currentRawPage + (index - (currentRawPage % 3));
    
    _pageController.animateToPage(
      targetRawPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// FAB tap - toggle connection
  Future<void> _onVoiceButtonTap() async {
    // Navigate to voice page if not there
    if (_currentPage != 1) {
      _onPillarTapped(1);
    }

    // Toggle connection
    if (_isConnected) {
      await _disconnect();
    } else if (!_isConnecting) {
      await _connect();
    }
  }

  /// FAB long press start - begin recording
  Future<void> _onVoiceButtonLongPressStart() async {
    HapticFeedback.mediumImpact();
    
    if (!_isConnected) {
      await _connect();
      // Wait for connection
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if (_isConnected && !_isRecording) {
      await _startRecording();
    }
  }

  /// FAB long press end - stop recording
  Future<void> _onVoiceButtonLongPressEnd() async {
    if (_isRecording) {
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

  Future<void> _disconnect() async {
    await _stopMicStream();
    await _speechService.disconnect();
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
  Color _getInterpolatedBackground() {
    final double progress = _scrollProgress % 3;
    
    // Key colors
    const Color darkColor = ThemeConstants.deepNavy;
    const Color voiceColor = Color(0xFFE2E8F0); // Light silver from voice background

    if (progress <= 1.0) {
      // Body (0.0) -> Voice (1.0)
      return Color.lerp(darkColor, voiceColor, progress)!;
    } else if (progress <= 2.0) {
      // Voice (1.0) -> Mind (2.0)
      return Color.lerp(voiceColor, darkColor, progress - 1.0)!;
    } else {
      // Mind (2.0) -> Body (3.0/0.0)
      return Color.lerp(darkColor, darkColor, progress - 2.0)!;
    }
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
            
            // Nav bar - positioned at TOP of screen
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: PillarNavBarThin(
                  pillars: _pillars,
                  currentIndex: _currentPage,
                  onPillarTapped: _onPillarTapped,
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
          onTap: _onVoiceButtonTap,
          onLongPressStart: _onVoiceButtonLongPressStart,
          onLongPressEnd: _onVoiceButtonLongPressEnd,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
