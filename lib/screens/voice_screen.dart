import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/viewmodels/voice_viewmodel.dart';
import '../widgets/debug/debug_log_dialog.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/voice/voice_waveform_animated.dart';

/// Voice Screen - Display-only view
/// Implements the "Hero Card" two-tone design
/// Top 75% is a large gradient card containing the text
/// Now uses VoiceViewModel for centralized state management
class VoiceScreen extends ConsumerWidget {
  final double panelVisibility;

  const VoiceScreen({super.key, this.panelVisibility = 1.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceViewModelProvider);

    return FloatingHeroCard(
      panelVisibility: panelVisibility,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Space for nav bar overlay
            const SizedBox(height: 70),

            const Spacer(flex: 2),

            // The main content area - CENTERED
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildContent(context, voiceState),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  /// Unified content that changes based on state
  Widget _buildContent(BuildContext context, VoiceState voiceState) {
    final isConnecting = voiceState.isConnecting;
    final isRecording = voiceState.isRecording;
    final isConnected = voiceState.isConnected;
    final isDisconnected = voiceState.isDisconnected;

    // Combine partial and final transcription for display
    final displayText = voiceState.partialTranscription.isNotEmpty
        ? voiceState.partialTranscription
        : voiceState.currentTranscription;

    // Connecting
    if (isConnecting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
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

    // Recording / Transcription
    if (isRecording || displayText.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecording && displayText.isEmpty)
            VoiceWaveformAnimated(
              barCount: 5,
              size: 48,
              color: Colors.white.withValues(alpha: 0.9),
              isActive: true,
            ),
          if (displayText.isNotEmpty)
            Text(
              displayText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                height: 1.4,
                letterSpacing: -0.3,
              ),
            ),
          if (isRecording && displayText.isEmpty) const SizedBox(height: 24),
          if (isRecording && displayText.isEmpty)
            Text(
              'Listening...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
        ],
      );
    }

    // Default: Greeting
    return Column(
      mainAxisSize: MainAxisSize.min,
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
}
