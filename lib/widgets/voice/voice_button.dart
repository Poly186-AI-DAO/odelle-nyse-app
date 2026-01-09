import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/design_constants.dart';

/// Primary voice interaction button
/// Circular white button with sound wave icon
/// Matches fintech design reference
class VoiceButton extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final bool isListening;
  final bool isProcessing;
  final double size;

  const VoiceButton({
    super.key,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.isListening = false,
    this.isProcessing = false,
    this.size = 64,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

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
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPressStart: (_) {
        HapticFeedback.mediumImpact();
        widget.onLongPressStart?.call();
      },
      onLongPressEnd: (_) {
        widget.onLongPressEnd?.call();
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = widget.isListening ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: _isPressed ? 0.95 : scale,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              if (widget.isListening)
                BoxShadow(
                  color: DesignConstants.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
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
                        Icons.graphic_eq,
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
    // Smooth wave function
    return (1 + (t * 3.14159 * 2).sin()) / 2;
  }
}

extension on double {
  double sin() => 0.5 + 0.5 * (this - 1.5708).abs() < 1.5708
      ? (this).abs() < 0.01
          ? this
          : (1 - ((this.abs() - 1.5708).abs() / 1.5708))
      : 0;
}
