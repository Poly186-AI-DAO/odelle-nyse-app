import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/viewmodels/voice_viewmodel.dart';
import 'voice_waveform_animated.dart';

/// Full-screen overlay for voice transcription
/// Shows blur background + centered card with live transcription
/// Dismisses when recording stops
class ThoughtCaptureOverlay extends ConsumerStatefulWidget {
  final VoidCallback? onDismiss;

  const ThoughtCaptureOverlay({
    super.key,
    this.onDismiss,
  });

  @override
  ConsumerState<ThoughtCaptureOverlay> createState() =>
      _ThoughtCaptureOverlayState();
}

class _ThoughtCaptureOverlayState extends ConsumerState<ThoughtCaptureOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceViewModelProvider);
    final isRecording = voiceState.isRecording;
    final isConnecting = voiceState.isConnecting;
    final transcription = voiceState.partialTranscription.isNotEmpty
        ? voiceState.partialTranscription
        : voiceState.currentTranscription;

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent dismiss when tapping card
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 40),
                    constraints: const BoxConstraints(maxWidth: 360),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 60,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: isRecording ? 0.15 : 0.0),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated waveform indicator with pulse glow
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final glowOpacity = isRecording
                                ? 0.15 + (_pulseAnimation.value * 0.15)
                                : 0.0;
                            final scale = isRecording
                                ? 1.0 + (_pulseAnimation.value * 0.05)
                                : 1.0;

                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFF0FDF4),
                                      Colors.white,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: isRecording
                                        ? const Color(0xFF22C55E)
                                            .withValues(alpha: 0.4)
                                        : const Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    if (isRecording)
                                      BoxShadow(
                                        color: const Color(0xFF22C55E)
                                            .withValues(alpha: glowOpacity),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: isConnecting
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Color(0xFF22C55E),
                                            ),
                                          ),
                                        )
                                      : VoiceWaveformAnimated(
                                          size: 32,
                                          color: const Color(0xFF1A1A1A),
                                          isActive: isRecording,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Title with subtle animation
                        Text(
                          isConnecting
                              ? 'Connecting...'
                              : isRecording
                                  ? 'Listening...'
                                  : 'Processing...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),

                        // Live transcription
                        if (transcription.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 160),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: SingleChildScrollView(
                              reverse: true,
                              child: Text(
                                transcription,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF4B5563),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Hint text with icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 16,
                              color: const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tap button below to stop',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
