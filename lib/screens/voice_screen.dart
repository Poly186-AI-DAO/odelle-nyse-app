import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../services/azure_speech_service.dart';
import '../widgets/voice/voice_waveform_animated.dart';

/// Voice Screen - Display-only view
/// Implements the "Hero Card" two-tone design
/// Top 75% is a large gradient card containing the text
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late AzureSpeechService _service;
  StreamSubscription<VoiceLiveState>? _stateSubscription;
  VoiceLiveState _voiceState = VoiceLiveState.disconnected;
  String _transcription = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = context.watch<AzureSpeechService>();
    
    _stateSubscription?.cancel();
    _stateSubscription = _service.stateStream.listen((state) {
      if (mounted) setState(() => _voiceState = state);
    });
    _voiceState = _service.state;

    _service.onPartialResult = (text) {
      if (mounted) setState(() => _transcription += text);
    };
    _service.onTranscription = (text) {
      if (mounted) setState(() => _transcription = text);
    };
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }

  bool get _isDisconnected => _voiceState == VoiceLiveState.disconnected;
  bool get _isConnecting => _voiceState == VoiceLiveState.connecting;
  bool get _isConnected =>
      _voiceState == VoiceLiveState.connected ||
      _voiceState == VoiceLiveState.recording ||
      _voiceState == VoiceLiveState.processing;
  bool get _isRecording => _voiceState == VoiceLiveState.recording;
  bool get _isProcessing => _voiceState == VoiceLiveState.processing;

  @override
  Widget build(BuildContext context) {
    // "Hero Card" extending from TOP of screen
    // Uses theme colors for consistency
    return Column(
      children: [
        // Top Section - The massive gradient card
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // Use theme gradient colors
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                   ThemeConstants.deepNavy,     // Dark at top
                   ThemeConstants.darkTeal,     // Mid teal
                   ThemeConstants.steelBlue,    // Steel blue
                   ThemeConstants.calmSilver,   // Silver at bottom edge
                ],
                stops: [0.0, 0.4, 0.7, 1.0],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Space for nav bar overlay
                  const SizedBox(height: 60),
                  
                  const Spacer(flex: 2),
                  
                  // The main content area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _buildContent(),
                  ),
                  
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),

        // Bottom Section - Light Silver bg (from parent gradient)
        const Expanded(
          flex: 1,
          child: SizedBox(), 
        ),
      ],
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
      children: [
        Text(
          _getGreeting(),
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
    if (_isConnected) return 'Hold to speak';
    return '';
  }
}
