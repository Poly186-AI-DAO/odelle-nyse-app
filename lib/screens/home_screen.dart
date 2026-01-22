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
import '../providers/voice_trigger_provider.dart';
import '../services/azure_speech_service.dart';
import '../services/audio_output_service.dart';
import '../utils/audio_resampler.dart';
import '../utils/logger.dart';
import '../widgets/debug/debug_log_dialog.dart';
import '../widgets/navigation/pillar_nav_bar.dart';
import '../widgets/voice/voice_button.dart';
import '../widgets/voice/thought_capture_overlay.dart';
import '../widgets/molecules/sync_indicator.dart';
import '../widgets/feedback/app_toast.dart';
import 'soul_screen.dart';
import 'bonds_screen.dart';
import 'now_screen.dart';
import 'health_screen.dart';
import 'wealth_screen.dart';

/// Main home screen with horizontal pager navigation
/// 5 Pillars: Soul | Bonds | Now (center) | Health | Wealth
/// "Your Soul Bonds Now with Health and Wealth"
/// Voice button persists and controls mic stream
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const String _tag = 'HomeScreen';

  late PageController _pageController;
  int _currentPage = 2; // Current pillar index - Now is center (index 2)
  static const int _initialPageOffset = 5000; // Large multiple of 5

  // Voice control - mic stream managed locally, state via VoiceViewModel
  late AzureSpeechService _speechService;
  StreamSubscription<Uint8List>? _micSubscription;
  Stream<Uint8List>? _micStream;
  bool _hasPermission = false;

  // 5 Pillar definitions: Soul | Bonds | Now | Health | Wealth
  // "Your Soul Bonds Now with Health and Wealth"
  static const List<PillarItem> _pillars = [
    PillarItem(
      assetIcon: 'assets/icons/mind_meditate_icon.png',
      label: 'Soul',
    ),
    PillarItem(
      assetIcon: 'assets/icons/bonds_icon.png',
      label: 'Bonds',
    ),
    PillarItem(
      icon: Icons.graphic_eq_outlined,
      activeIcon: Icons.graphic_eq,
      label: 'Now',
    ),
    PillarItem(
      assetIcon: 'assets/icons/body_powerlifting_icon.png',
      iconScale: 1.5,
      label: 'Health',
    ),
    PillarItem(
      assetIcon: 'assets/icons/wealth_icon.png',
      label: 'Wealth',
    ),
  ];

  // Voice state from VoiceViewModel
  VoiceState get _voiceState => ref.read(voiceViewModelProvider);
  bool get _isConnecting => _voiceState.isConnecting;
  bool get _isConnected => _voiceState.isConnected;
  bool get _isRecording => _voiceState.isRecording;

  // Scroll progress for animations
  double _scrollProgress = 1.0;

  // Bootstrap status
  bool _bootstrapStarted = false;

  @override
  void initState() {
    super.initState();
    // Start at a large page index that is "Now" (index 2 % 5)
    final initialPage = _initialPageOffset + 2;
    _pageController = PageController(initialPage: initialPage);
    _scrollProgress = initialPage.toDouble();
    _pageController.addListener(_onScroll);

    // Initialize audio output for playing Azure responses
    AudioOutputService.instance.initialize();

    // Run bootstrap after first frame (deferred to avoid Riverpod issues)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runBootstrap();
    });
  }

  /// Run bootstrap check to ensure all data is ready
  Future<void> _runBootstrap() async {
    if (_bootstrapStarted) return;
    _bootstrapStarted = true;

    Logger.info('Starting bootstrap...', tag: _tag);

    // Trigger the bootstrap by reading the FutureProvider
    // The result will be available via ref.watch(bootstrapResultProvider)
    final result = await ref.read(bootstrapResultProvider.future);

    Logger.info('Bootstrap complete: ${result.success}', tag: _tag, data: {
      'summary': result.agentSummary,
    });

    if (result.agentSummary != null && mounted) {
      // Show a brief toast with the bootstrap summary
      AppToast.info(
          context,
          result.agentSummary!.length > 100
              ? '${result.agentSummary!.substring(0, 100)}...'
              : result.agentSummary!);
    }

    // Trigger initial sync
    if (mounted) {
      ref.read(syncServiceProvider).syncPendingChanges();
    }
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
        AppToast.error(context, 'Voice error: $error');
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

    // Handle voice interruptions: when user starts speaking during AI response
    // Per Azure Realtime API docs: use speech_started to interrupt playback
    // ECHO GATING: Filter false triggers from AI audio being picked up by mic
    _speechService.onSpeechStarted = () {
      // Check if AI is currently speaking (potential echo situation)
      if (!_speechService.isAiSpeaking) {
        // AI is not speaking - this is definitely real user speech
        Logger.debug('Speech started (AI not speaking)', tag: _tag);
        return;
      }

      // AI IS speaking - this could be echo or real interruption
      // For now, treat all speech during AI playback as real interruption
      // The tuned VAD parameters (threshold: 0.7, prefix_padding: 500ms)
      // should filter most echo. If this still triggers on echo,
      // we can add a debounce or energy threshold check here.
      Logger.info('User interrupted during AI speech', tag: _tag, data: {
        'audioPlayedMs': _speechService.audioPlayedMs,
        'responseItemId': _speechService.currentResponseItemId,
      });

      // 1. Stop local audio playback immediately
      AudioOutputService.instance.stop();

      // 2. Cancel server response generation
      _speechService.cancelResponse();

      // 3. Truncate conversation to what user actually heard
      _speechService.truncateResponse();

      // 4. Clear AI response text in the ViewModel
      ref.read(voiceViewModelProvider.notifier).clearAiResponse();
    };
  }

  /// Check current microphone permission status (without prompting)

  Future<bool> _requestMicrophonePermission() async {
    // permission_handler is now available on all platforms
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
    setState(() => _currentPage = page % 5);
    HapticFeedback.selectionClick();
  }

  void _onPillarTapped(int index) {
    if (!_pageController.hasClients) return;

    // Find nearest page to animate to
    final int currentRawPage =
        _pageController.page?.round() ?? _initialPageOffset + 2;
    final int targetRawPage = currentRawPage + (index - (currentRawPage % 5));

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
  VoiceLiveMode get _targetMode => _currentPage == 2 // Now screen
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
    if (_currentPage == 2) {
      // Now Screen: Toggle connection (conversation mode, always listening)
      await _toggleVoiceConnection();
    } else {
      // Other pillars: Toggle recording (transcription mode)
      await _toggleTranscriptionRecording();
    }
  }

  /// Check if there's an active voice session (connected or recording)
  bool get _hasActiveSession => _isConnected || _isRecording;

  /// Navigate to a specific screen by index
  void _navigateToScreen(int targetIndex) {
    if (!_pageController.hasClients) return;

    final int currentRawPage =
        _pageController.page?.round() ?? _initialPageOffset + 2;
    final int targetRawPage =
        currentRawPage + (targetIndex - (currentRawPage % 5));

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
      Logger.info('Transcription: Already connected, starting recording',
          tag: _tag);
      await _startRecording();
    } else {
      // Not connected, connect and start recording
      Logger.info('Transcription: Connecting and starting recording',
          tag: _tag);

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

    // For Now screen, start recording immediately after connecting
    if (_currentPage == 2) {
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

      // Platform-specific mic configuration:
      // iOS: Supports 24kHz mono natively - send directly to Azure
      // macOS: Only supports 48kHz stereo - must convert to 24kHz mono
      final bool isMacOS = Platform.isMacOS;
      final int targetSampleRate = isMacOS ? 48000 : 24000;

      Logger.info(
        'Initializing microphone stream (${targetSampleRate}Hz, ${isMacOS ? "macOS stereo→mono" : "iOS native mono"})',
        tag: _tag,
      );

      _micStream = MicStream.microphone(
        sampleRate: targetSampleRate,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT,
      );

      final voiceVM = ref.read(voiceViewModelProvider.notifier);
      voiceVM.startRecording();

      // iOS: Mark that audio session needs re-configuration before playback
      // mic_stream resets AVAudioSession when subscription begins
      if (Platform.isIOS) {
        AudioOutputService.instance.markAudioSessionNeedsReconfig();
      }

      // Track if we've configured the audio session after mic starts
      bool hasConfiguredAudioSession = false;

      _micSubscription = _micStream!.listen(
        (audioBytes) {
          chunkCount++;
          totalBytes += audioBytes.length;

          // iOS FIX: Configure audio session AFTER mic stream starts.
          // mic_stream resets AVAudioSession when subscription begins,
          // so we must re-configure on first audio chunk to route to speaker.
          if (!hasConfiguredAudioSession && Platform.isIOS) {
            hasConfiguredAudioSession = true;
            Logger.info(
                'iOS: Configuring audio session after mic stream started',
                tag: _tag);
            // Use Future to not block the audio callback
            AudioOutputService.instance
                .configureAudioSession(force: true)
                .then((_) {
              Logger.info('iOS: Audio session configured for speaker output',
                  tag: _tag);
            });
          }

          // Log every 10 chunks to verify mic is working
          if (chunkCount % 10 == 0) {
            Logger.debug('Mic: $chunkCount chunks, $totalBytes bytes total',
                tag: _tag);
          }

          // Platform-specific audio conversion
          Uint8List audioToSend;
          if (isMacOS) {
            // macOS: Convert 48kHz stereo to 24kHz mono
            audioToSend = AudioResampler.convertMacOSToAzure(audioBytes);
          } else {
            // iOS: Already 24kHz mono, send directly
            audioToSend = audioBytes;
          }

          // Debug: Log audio level every 50 chunks to verify signal is present
          if (chunkCount % 50 == 0 && audioToSend.length >= 4) {
            int maxLevel = 0;
            for (var i = 0; i < audioToSend.length - 1; i += 2) {
              final sample = (audioToSend[i + 1] << 8) | audioToSend[i];
              final level = sample < 32768 ? sample : sample - 65536;
              if (level.abs() > maxLevel) maxLevel = level.abs();
            }
            Logger.debug(
                'Audio level: $maxLevel / 32768 (${(maxLevel / 32768 * 100).toStringAsFixed(1)}%)',
                tag: _tag);
          }

          // Check if muted - skip sending audio but keep stream alive
          final voiceState = ref.read(voiceViewModelProvider);
          if (voiceState.isMuted) {
            // When muted, don't send audio but keep listening to AI
            return;
          }

          voiceVM.sendAudioChunk(audioToSend);
        },
        onError: (error) {
          Logger.error('Mic stream error: $error', tag: _tag);
        },
        onDone: () {
          Logger.info(
              'Mic stream completed: $chunkCount chunks, $totalBytes bytes',
              tag: _tag);
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

    // Listen for voice trigger from child screens (e.g., ThoughtCaptureCard)
    final voiceTrigger = ref.watch(voiceTriggerProvider);
    if (voiceTrigger) {
      // Clear the trigger and handle recording
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(voiceTriggerProvider.notifier).clearTrigger();
        _onVoiceButtonTap();
      });
    }

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
                // Modulo to cycle through 5 pillars
                final pageIndex = index % 5;

                // Calculate visibility based on distance from current scroll position
                final distance = (index - _scrollProgress).abs();
                final visibility = (1.0 - distance).clamp(0.0, 1.0);

                switch (pageIndex) {
                  case 0:
                    return SoulScreen(panelVisibility: visibility);
                  case 1:
                    return BondsScreen(panelVisibility: visibility);
                  case 2:
                    return NowScreen(panelVisibility: visibility);
                  case 3:
                    return HealthScreen(panelVisibility: visibility);
                  case 4:
                    return WealthScreen(panelVisibility: visibility);
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

            // Sync Indicator (Top Right)
            const Positioned(
              top: 0,
              right: 0,
              child: SyncIndicator(),
            ),

            // Thought Capture Overlay - shown when recording on non-Now screens
            if ((voiceState.isRecording ||
                    voiceState.isConnecting ||
                    voiceState.showCaptureOverlay) &&
                _currentPage != 2)
              Positioned.fill(
                child: ThoughtCaptureOverlay(
                  onRequestStopRecording: _onVoiceButtonTap, // Tap to stop
                  onRequestDismiss: () => ref
                      .read(voiceViewModelProvider.notifier)
                      .dismissCaptureOverlay(),
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
          // Inverted colors on non-main screens: black bg, white icon
          inverted: _currentPage != 2,
          // Icon logic:
          // - If locked (session on different screen): lock icon
          // - Otherwise: soundwave for all states (waveform animates when active)
          icon: _hasActiveSession && _activeSessionScreen != _currentPage
              ? Icons.lock_outline // Locked - tap to go back
              : Icons
                  .graphic_eq, // Same icon for all screens, waveform animates
          // isActive: show waveform animation when:
          // - Now screen: when connected (always listening mode)
          // - Other pillars: when recording
          isActive: _currentPage == 2
              ? voiceState.isConnected // Now: animate when connected
              : voiceState.isRecording, // Other pillars: animate when recording
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
