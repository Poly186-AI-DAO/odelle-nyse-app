import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/service_providers.dart';
import '../services/azure_speech_service.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/voice/voice_waveform_animated.dart';

/// Voice Screen - Display-only view
/// Implements the "Hero Card" two-tone design
/// Top 75% is a large gradient card containing the text
class VoiceScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const VoiceScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  late AzureSpeechService _service;
  StreamSubscription<VoiceLiveState>? _stateSubscription;
  StreamSubscription<String>? _partialSubscription;
  StreamSubscription<String>? _transcriptionSubscription;
  VoiceLiveState _voiceState = VoiceLiveState.disconnected;
  String _transcription = '';

  // Debug mode - set to false for production
  static const bool _showDebug = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = ref.read(voiceServiceProvider);

    _stateSubscription?.cancel();
    _stateSubscription = _service.stateStream.listen((state) {
      if (mounted) setState(() => _voiceState = state);
    });
    _voiceState = _service.state;

    // Use streams instead of callbacks to avoid clobbering HomeScreen's callbacks
    _partialSubscription?.cancel();
    _partialSubscription = _service.partialStream.listen((text) {
      if (mounted) setState(() => _transcription += text);
    });

    _transcriptionSubscription?.cancel();
    _transcriptionSubscription = _service.transcriptionStream.listen((text) {
      if (mounted) setState(() => _transcription = text);
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _partialSubscription?.cancel();
    _transcriptionSubscription?.cancel();
    super.dispose();
  }

  bool get _isDisconnected => _voiceState == VoiceLiveState.disconnected;
  bool get _isConnecting => _voiceState == VoiceLiveState.connecting;
  bool get _isConnected =>
      _voiceState == VoiceLiveState.connected ||
      _voiceState == VoiceLiveState.recording ||
      _voiceState == VoiceLiveState.processing;
  bool get _isRecording => _voiceState == VoiceLiveState.recording;

  @override
  Widget build(BuildContext context) {
    // Use FloatingHeroCard for the floating design
    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Space for nav bar overlay
                const SizedBox(height: 70),

                const Spacer(flex: 2),

                // The main content area - CENTERED
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _buildContent(),
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),

            // Debug overlay (top-right corner)
            if (_showDebug)
              Positioned(
                top: 80,
                right: 16,
                child: _buildDebugOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  /// Debug overlay showing current state
  Widget _buildDebugOverlay() {
    final stateColor = switch (_voiceState) {
      VoiceLiveState.disconnected => Colors.grey,
      VoiceLiveState.connecting => Colors.orange,
      VoiceLiveState.connected => Colors.green,
      VoiceLiveState.recording => Colors.red,
      VoiceLiveState.processing => Colors.blue,
    };

    final modeText = _service.mode == VoiceLiveMode.transcription
        ? 'Transcription'
        : 'Conversation';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stateColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _voiceState.name,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            modeText,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Unified content that changes based on state
  Widget _buildContent() {
    // Connecting
    if (_isConnecting) {
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
    if (_isRecording || _transcription.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording && _transcription.isEmpty)
            VoiceWaveformAnimated(
              barCount: 5,
              size: 48,
              color: Colors.white.withValues(alpha: 0.9),
              isActive: true,
            ),
          if (_transcription.isNotEmpty)
            Text(
              _transcription,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                height: 1.4,
                letterSpacing: -0.3,
              ),
            ),
          if (_isRecording && _transcription.isEmpty)
            const SizedBox(height: 24),
          if (_isRecording && _transcription.isEmpty)
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
        Text(
          _getGreeting(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _getSubtitle(),
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

  String _getSubtitle() {
    if (_isDisconnected) return 'Tap to connect';
    if (_isRecording) return 'Tap to stop';
    if (_isConnected) return 'Hold to talk • Tap to disconnect';
    return '';
  }
}
