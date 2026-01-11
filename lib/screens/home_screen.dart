import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/journal_entry.dart';
import '../providers/service_providers.dart';
import '../providers/viewmodels/voice_viewmodel.dart';
import '../services/azure_speech_service.dart';
import '../services/audio_output_service.dart';
import '../utils/logger.dart';
import '../widgets/debug/debug_log_dialog.dart';
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

  // Voice control - mic stream managed locally, state via VoiceViewModel
  late AzureSpeechService _speechService;
  StreamSubscription<Uint8List>? _micSubscription;
  Stream<Uint8List>? _micStream;
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

  // Voice state from VoiceViewModel
  VoiceState get _voiceState => ref.read(voiceViewModelProvider);
  bool get _isConnecting => _voiceState.isConnecting;
  bool get _isConnected => _voiceState.isConnected;
  bool get _isRecording => _voiceState.isRecording;

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
    
    // Initialize audio output for playing Azure responses
    AudioOutputService.instance.initialize();
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
    _setupSaveCallback();
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

    // Handle connection errors - clean up state to prevent getting stuck
    _speechService.onError = (error) {
      Logger.error('Voice service error: $error', tag: _tag);
      
      // Clean up state on error to prevent stuck state
      _stopMicStream();
      _activeSessionScreen = null;
      _recordingStartTime = null;
      
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

    // Log when connected and start recording automatically
    _speechService.onConnected = () {
      Logger.info('Voice service connected', tag: _tag);
      // Start recording now that we're actually connected
      // Use forceStart to bypass _isConnected check since state hasn't propagated yet
      _startRecording(forceStart: true);
    };
    
    // Play Azure's audio responses through the speaker
    _speechService.onAudioResponse = (audioBytes) {
      AudioOutputService.instance.feedAudio(audioBytes);
    };
  }

  Future<void> _checkPermissionStatus() async {
    // permission_handler not available on desktop - assume granted
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      setState(() => _hasPermission = true);
      return;
    }
    final status = await Permission.microphone.status;
    setState(() => _hasPermission = status.isGranted);
  }

  Future<bool> _requestMicrophonePermission() async {
    // permission_handler not available on desktop - assume granted
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      setState(() => _hasPermission = true);
      return true;
    }
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
    _stopMicStream();
    AudioOutputService.instance.dispose();
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

  // Track recording start time to avoid buffer-too-small errors
  DateTime? _recordingStartTime;
  
  // Track which screen started the active session (for screen-lock behavior)
  // 0 = Body, 1 = Voice, 2 = Mind, null = no active session
  int? _activeSessionScreen;

  /// Get the appropriate mode for the current screen
  VoiceLiveMode get _targetMode => _currentPage == 1
      ? VoiceLiveMode.conversation
      : VoiceLiveMode.transcription;

  /// FAB tap - screen-aware toggle with screen-lock behavior
  /// If user is connected/recording and on a DIFFERENT screen, navigate back
  /// Otherwise, toggle the appropriate action for the current screen
  Future<void> _onVoiceButtonTap() async {
    // Screen-lock: If there's an active session on a different screen, navigate back
    if (_hasActiveSession && _activeSessionScreen != _currentPage) {
      Logger.info(
        'Screen-lock: Navigating back to screen $_activeSessionScreen (currently on $_currentPage)',
        tag: _tag,
      );
      _navigateToScreen(_activeSessionScreen!);
      return;
    }

    // Normal behavior: toggle based on current screen
    if (_currentPage == 1) {
      // Voice Screen: Toggle connection (conversation mode, always listening)
      await _toggleVoiceConnection();
    } else {
      // Body/Mind: Toggle recording (transcription mode)
      await _toggleTranscriptionRecording();
    }
  }
  
  /// Check if there's an active voice session (connected or recording)
  bool get _hasActiveSession => _isConnected || _isRecording;
  
  /// Navigate to a specific screen by index
  void _navigateToScreen(int targetIndex) {
    if (!_pageController.hasClients) return;
    
    final int currentRawPage =
        _pageController.page?.round() ?? _initialPageOffset + 1;
    final int targetRawPage = currentRawPage + (targetIndex - (currentRawPage % 3));
    
    HapticFeedback.mediumImpact();
    _pageController.animateToPage(
      targetRawPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// Toggle voice connection for Voice screen (conversation mode)
  Future<void> _toggleVoiceConnection() async {
    if (_isConnected) {
      Logger.info('Voice: Disconnecting', tag: _tag);
      await _disconnect();
    } else {
      Logger.info('Voice: Connecting in conversation mode', tag: _tag);
      _activeSessionScreen = 1; // Voice screen
      await _connect();
    }
  }

  /// Toggle transcription recording for Body/Mind screens
  /// Transcription is "tap to record, tap to stop and send" - not always-on
  Future<void> _toggleTranscriptionRecording() async {
    if (_isRecording) {
      // Stop recording AND disconnect (transcription is one-shot, not persistent)
      Logger.info('Transcription: Stopping and disconnecting', tag: _tag);
      await _stopRecording();
      await _disconnect(); // Full stop for transcription mode
    } else if (_isConnected) {
      // Shouldn't happen in transcription mode, but handle it
      Logger.info('Transcription: Already connected, starting recording', tag: _tag);
      await _startRecording();
    } else {
      // Not connected, connect and start recording
      Logger.info('Transcription: Connecting and starting recording', tag: _tag);
      
      if (!_hasPermission) {
        Logger.info('Requesting microphone permission', tag: _tag);
        final granted = await _requestMicrophonePermission();
        if (!granted) {
          Logger.warning('Microphone permission denied', tag: _tag);
          return;
        }
        Logger.info('Microphone permission granted', tag: _tag);
      }
      
      _activeSessionScreen = _currentPage; // Body or Mind

      final connected = await ref
          .read(voiceViewModelProvider.notifier)
          .connect(mode: VoiceLiveMode.transcription);
      
      if (connected) {
        await _startRecording();
      } else {
        Logger.error('Failed to connect for transcription', tag: _tag);
        _activeSessionScreen = null; // Clear on failure
      }
    }
  }

  /// FAB long press - open debug dialog
  void _onVoiceButtonLongPress() {
    HapticFeedback.mediumImpact();
    DebugLogDialog.show(context);
  }

  Future<void> _connect() async {
    if (_isConnecting || _isConnected) return;

    if (!_hasPermission) {
      final granted = await _requestMicrophonePermission();
      if (!granted) return;
    }

    await ref.read(voiceViewModelProvider.notifier).connect(mode: _targetMode);
    
    // For Voice screen, start recording immediately after connecting
    if (_currentPage == 1) {
      await _startRecording();
    }
  }

  Future<void> _disconnect() async {
    if (!_isConnected) return;

    try {
      await _stopMicStream();
      await ref.read(voiceViewModelProvider.notifier).disconnect();
      _activeSessionScreen = null; // Clear screen lock
      Logger.info('Disconnected', tag: _tag);
    } catch (e) {
      Logger.error('Failed to disconnect: $e', tag: _tag);
    }
  }

  Future<void> _startRecording({bool forceStart = false}) async {
    // forceStart bypasses _isConnected check when called from onConnected callback
    if (!forceStart && (!_isConnected || _isRecording)) return;
    if (_isRecording) return; // Always prevent double-recording

    try {
      _recordingStartTime = DateTime.now();
      int chunkCount = 0;
      int totalBytes = 0;

      Logger.info('Initializing microphone stream (24kHz, mono, PCM16)', tag: _tag);
      
      _micStream = await MicStream.microphone(
        sampleRate: 24000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );

      final voiceVM = ref.read(voiceViewModelProvider.notifier);
      voiceVM.startRecording();

      _micSubscription = _micStream!.listen(
        (audioBytes) {
          chunkCount++;
          totalBytes += audioBytes.length;
          
          // Log every 10 chunks to verify mic is working
          if (chunkCount % 10 == 0) {
            Logger.debug('Mic: $chunkCount chunks, $totalBytes bytes total', tag: _tag);
          }
          
          voiceVM.sendAudioChunk(audioBytes);
        },
        onError: (error) {
          Logger.error('Mic stream error: $error', tag: _tag);
        },
        onDone: () {
          Logger.info('Mic stream completed: $chunkCount chunks, $totalBytes bytes', tag: _tag);
        },
      );

      Logger.info('Recording started, listening for mic input...', tag: _tag);
    } catch (e) {
      Logger.error('Failed to start recording: $e', tag: _tag);
      _recordingStartTime = null;
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _stopMicStream();

      // Check if we recorded enough audio (at least 150ms to avoid buffer errors)
      final recordedDuration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!)
          : Duration.zero;
      _recordingStartTime = null;

      final voiceVM = ref.read(voiceViewModelProvider.notifier);
      if (recordedDuration.inMilliseconds < 150) {
        // Too short - cancel instead of committing
        Logger.info(
            'Recording too short (${recordedDuration.inMilliseconds}ms), cancelling',
            tag: _tag);
        voiceVM.cancelRecording();
      } else {
        await voiceVM.stopRecording();
        Logger.info(
            'Recording stopped after ${recordedDuration.inMilliseconds}ms',
            tag: _tag);
      }
    } catch (e) {
      Logger.error('Failed to stop recording: $e', tag: _tag);
      _recordingStartTime = null;
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
    // Watch voice state for reactive UI updates
    final voiceState = ref.watch(voiceViewModelProvider);

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
            // Long-press any icon to open debug logs
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
                    onLongPress: () => DebugLogDialog.show(context),
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
          // Icon logic:
          // - If locked (session on different screen): lock icon
          // - Otherwise: soundwave for all states (waveform animates when active)
          icon: _hasActiveSession && _activeSessionScreen != _currentPage
              ? Icons.lock_outline // Locked - tap to go back
              : Icons.graphic_eq,  // Same icon for all screens, waveform animates
          // isActive: show waveform animation when:
          // - Voice screen: when connected (always listening mode)
          // - Body/Mind: when recording
          isActive: _currentPage == 1 
              ? voiceState.isConnected  // Voice: animate when connected
              : voiceState.isRecording, // Body/Mind: animate when recording
          isConnected: voiceState.isConnected,
          isProcessing: voiceState.isConnecting,
          onTap: _onVoiceButtonTap,
          onLongPress: _onVoiceButtonLongPress,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
