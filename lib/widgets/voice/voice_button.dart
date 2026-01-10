import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/design_constants.dart';

/// Primary voice interaction button
/// Supports Hold-to-Talk and Swipe-to-Lock gestures
class VoiceButton extends StatefulWidget {
  final VoidCallback? onTap; // Fallback or tap
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final VoidCallback? onLock; // Triggered when swiped up to lock
  final bool isActive; // Recording/listening state
  final bool isConnected; // Connected to voice service
  final bool isProcessing;
  final bool isLocked; // Visual state for locked mode
  final double size;

  const VoiceButton({
    super.key,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.onLock,
    this.isActive = false,
    this.isConnected = false,
    this.isProcessing = false,
    this.isLocked = false,
    this.size = 64,
  });

  bool get isListening => isActive;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Drag logic
  double _dragOffset = 0.0;
  static const double _lockThreshold = -60.0; // Distance to swipe up
  bool _isDragging = false;
  bool _hasLocked = false;

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
      // Reset drag state if stopped externally
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
        _hasLocked = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.isListening || widget.isLocked) return;

    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dy;
      // Clamp to only go up
      if (_dragOffset > 0) _dragOffset = 0;
    });

    // Check threshold
    if (_dragOffset <= _lockThreshold && !_hasLocked) {
      _hasLocked = true;
      HapticFeedback.heavyImpact();
      widget.onLock?.call();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isLocked || _hasLocked) {
      // Already locked, reset local drag
      setState(() {
        _isDragging = false;
        _dragOffset = 0;
      });
      return;
    }

    // Released without locking -> Stop
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
    widget.onLongPressEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lock Icon Indicator (slides up)
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isDragging || widget.isLocked ? 1.0 : 0.0,
          child: Transform.translate(
            offset: Offset(0, _isDragging ? _dragOffset * 0.5 + 20 : 0),
            child: Icon(
              widget.isLocked ? Icons.lock : Icons.lock_open,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ),
        
        const SizedBox(height: 8),

        // Main Button
        GestureDetector(
          onTap: widget.onTap,
          onLongPressStart: (_) {
            HapticFeedback.mediumImpact();
            setState(() {
              _hasLocked = false;
              _isDragging = false;
              _dragOffset = 0;
            });
            widget.onLongPressStart?.call();
          },
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          onLongPressEnd: (_) {
             if (!_hasLocked && !widget.isLocked) {
               widget.onLongPressEnd?.call();
             }
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = widget.isListening ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Transform.translate(
                  offset: Offset(0, _isDragging ? _dragOffset : 0),
                  child: child,
                ),
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
                            Icons.graphic_eq,
                            size: widget.size * 0.4,
                            color: const Color(0xFF1A1A1A),
                          ),
              ),
            ),
          ),
        ),
      ],
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
