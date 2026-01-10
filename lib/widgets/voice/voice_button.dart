import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/design_constants.dart';

/// Primary voice interaction button
/// Simple tap to toggle, long-press for debug dialog
class VoiceButton extends StatefulWidget {
  final IconData icon; // Dynamic icon based on context
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isActive; // Recording/listening state
  final bool isConnected; // Connected to voice service
  final bool isProcessing;
  final double size;

  const VoiceButton({
    super.key,
    this.icon = Icons.graphic_eq,
    this.onTap,
    this.onLongPress,
    this.isActive = false,
    this.isConnected = false,
    this.isProcessing = false,
    this.size = 64,
  });

  bool get isListening => isActive;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = widget.isListening ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            // Show border when connected
            border: widget.isConnected
                ? Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              // Blue glow when recording
              if (widget.isListening)
                BoxShadow(
                  color: DesignConstants.accentBlue.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              // Green glow when connected (not recording)
              if (widget.isConnected && !widget.isListening)
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: widget.isProcessing
                ? SizedBox(
                    width: widget.size * 0.4,
                    height: widget.size * 0.4,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1A1A1A),
                      ),
                    ),
                  )
                : widget.isListening
                    ? _VoiceWaveform(size: widget.size * 0.5)
                    : Icon(
                        widget.icon,
                        size: widget.size * 0.4,
                        color: const Color(0xFF1A1A1A),
                      ),
          ),
        ),
      ),
    );
  }
}

/// Animated waveform for active listening state
class _VoiceWaveform extends StatefulWidget {
  final double size;

  const _VoiceWaveform({required this.size});

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final phase = (index - 2).abs() * 0.2;
            final value = ((_controller.value + phase) % 1.0);
            final height = 0.3 + (0.7 * _wave(value));
            return Container(
              width: 3,
              height: widget.size * height,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }

  double _wave(double t) {
    // Smooth wave function using sine approximation
    return (1 + _sin(t * 3.14159 * 2)) / 2;
  }

  double _sin(double x) {
    // Simple sine approximation
    x = x % (3.14159 * 2);
    if (x > 3.14159) x -= 3.14159 * 2;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}
