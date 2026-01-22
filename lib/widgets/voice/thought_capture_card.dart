import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/viewmodels/voice_viewmodel.dart';
import '../../providers/voice_trigger_provider.dart';
import 'voice_waveform_animated.dart';

/// "Ready to capture your thoughts?" card widget
/// Shows on non-main screens to prompt voice transcription
class ThoughtCaptureCard extends ConsumerWidget {
  /// Optional callback when card is tapped (in addition to triggering recording)
  final VoidCallback? onTap;

  const ThoughtCaptureCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceViewModelProvider);
    final isRecording = voiceState.isRecording;
    final isConnecting = voiceState.isConnecting;
    final transcription = voiceState.partialTranscription.isNotEmpty
        ? voiceState.partialTranscription
        : voiceState.currentTranscription;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            isRecording
                ? 'Listening...'
                : 'Ready to capture your\nthoughts?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
              height: 1.3,
            ),
          ),

          const SizedBox(height: 24),

          // Transcription area (when recording)
          if (isRecording && transcription.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: SingleChildScrollView(
                child: Text(
                  transcription,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Mic button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              // Trigger recording via provider - HomeScreen will handle actual recording
              ref.read(voiceTriggerProvider.notifier).triggerRecording();
              onTap?.call();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: isRecording
                      ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0),
                  width: isRecording ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (isRecording)
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Center(
                child: isConnecting
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1A1A1A),
                          ),
                        ),
                      )
                    : isRecording
                        ? VoiceWaveformAnimated(
                            size: 32,
                            color: const Color(0xFF1A1A1A),
                            isActive: true,
                          )
                        : const Icon(
                            Icons.mic_none_rounded,
                            size: 32,
                            color: Color(0xFF1A1A1A),
                          ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            isRecording ? 'Tap to stop' : 'Tap to start recording',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
