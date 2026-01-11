import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/viewmodels/voice_viewmodel.dart';
import '../widgets/debug/debug_log_dialog.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/voice/voice_waveform_animated.dart';

/// Voice Screen - Display-only view
/// Implements the "Hero Card" two-tone design
/// Shows AI responses prominently, user transcription fades after 3s
class VoiceScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const VoiceScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with SingleTickerProviderStateMixin {
  // User transcription fade timer
  Timer? _fadeTimer;
  double _userTextOpacity = 1.0;
  String _lastUserTranscription = '';

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  void _startFadeTimer() {
    _fadeTimer?.cancel();
    setState(() => _userTextOpacity = 1.0);
    _fadeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _userTextOpacity = 0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceViewModelProvider);

    // Track user transcription changes to trigger fade
    final currentUserText = voiceState.currentTranscription;
    if (currentUserText.isNotEmpty &&
        currentUserText != _lastUserTranscription) {
      _lastUserTranscription = currentUserText;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startFadeTimer());
    }

    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Space for nav bar overlay
            const SizedBox(height: 70),

            const Spacer(flex: 2),

            // The main content area - CENTERED
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildContent(context, voiceState),
                ),
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VoiceState voiceState) {
    final isConnecting = voiceState.isConnecting;
    final isRecording = voiceState.isRecording;
    final isConnected = voiceState.isConnected;
    final isDisconnected = voiceState.isDisconnected;

    // AI response text (real-time subtitles)
    final aiText = voiceState.aiResponseText;

    // User's last transcription (shown subtle at bottom)
    final userText = voiceState.currentTranscription;

    // Connecting
    if (isConnecting) {
      return _buildConnectingState();
    }

    // Show AI response or recording state
    if (aiText.isNotEmpty || isRecording || isConnected) {
      return _buildActiveState(
        aiText: aiText,
        userText: userText,
        isRecording: isRecording,
        isConnected: isConnected,
        isMuted: voiceState.isMuted,
      );
    }

    // Default: Greeting
    return _buildGreetingState(isDisconnected, isRecording, isConnected);
  }

  Widget _buildConnectingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Connecting...',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveState({
    required String aiText,
    required String userText,
    required bool isRecording,
    required bool isConnected,
    required bool isMuted,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // AI Response Text (prominent, real-time subtitles)
        if (aiText.isNotEmpty)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  aiText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    height: 1.4,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ),

        // Waveform when recording (no AI text yet)
        if (aiText.isEmpty && isRecording)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceWaveformAnimated(
                barCount: 5,
                size: 48,
                color: Colors.white.withValues(alpha: 0.9),
                isActive: true,
              ),
              const SizedBox(height: 24),
              Text(
                'Listening...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),

        // Connected but idle (show ready state)
        if (aiText.isEmpty && !isRecording && isConnected)
          Text(
            'Ready',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),

        // Mute button (shown when connected)
        if (isConnected || isRecording) ...[
          const SizedBox(height: 24),
          _buildMuteButton(isMuted),
        ],

        // User's last transcription (subtle, fades after 3s)
        if (userText.isNotEmpty) ...[
          const SizedBox(height: 32),
          AnimatedOpacity(
            opacity: _userTextOpacity,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You: "$userText"',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGreetingState(
      bool isDisconnected, bool isRecording, bool isConnected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Double-tap greeting to open debug logs
        GestureDetector(
          onDoubleTap: () => DebugLogDialog.show(context),
          child: Text(
            _getGreeting(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _getSubtitle(isDisconnected, isRecording, isConnected),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.6),
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

  String _getSubtitle(bool isDisconnected, bool isRecording, bool isConnected) {
    if (isDisconnected) return 'Tap to connect';
    if (isRecording) return 'Listening...';
    if (isConnected) return 'Tap to disconnect';
    return '';
  }

  Widget _buildMuteButton(bool isMuted) {
    return GestureDetector(
      onTap: () {
        ref.read(voiceViewModelProvider.notifier).toggleMute();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMuted
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isMuted
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMuted ? Icons.mic_off : Icons.mic,
              color: isMuted
                  ? Colors.red.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isMuted ? 'Muted' : 'Tap to mute',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isMuted
                    ? Colors.red.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
