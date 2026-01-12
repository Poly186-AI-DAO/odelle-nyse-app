import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mode for the circular timer
enum TimerMode {
  /// Counts down from the set duration to zero
  countdown,

  /// Counts up from zero (stopwatch mode)
  countUp,
}

/// A beautiful circular timer with animated progress ring.
/// Supports countdown, count-up, and can be used for meditation, pomodoro, etc.
class CircularTimer extends StatefulWidget {
  /// Total duration in seconds (for countdown mode)
  final int durationSeconds;

  /// Timer mode: countdown or countUp
  final TimerMode mode;

  /// Size of the timer circle
  final double size;

  /// Ring stroke width
  final double strokeWidth;

  /// Progress ring color
  final Color progressColor;

  /// Background ring color
  final Color backgroundColor;

  /// Whether to auto-start the timer
  final bool autoStart;

  /// Callback when timer completes (countdown mode)
  final VoidCallback? onComplete;

  /// Callback for each tick with remaining/elapsed seconds
  final ValueChanged<int>? onTick;

  /// Whether to show control buttons
  final bool showControls;

  /// Custom center widget (overrides default time display)
  final Widget? centerWidget;

  /// Label text below the timer
  final String? label;

  const CircularTimer({
    super.key,
    this.durationSeconds = 60,
    this.mode = TimerMode.countdown,
    this.size = 280,
    this.strokeWidth = 8,
    this.progressColor = const Color(0xFFFF6B35),
    this.backgroundColor = const Color(0xFF2D3E50),
    this.autoStart = false,
    this.onComplete,
    this.onTick,
    this.showControls = true,
    this.centerWidget,
    this.label,
  });

  @override
  State<CircularTimer> createState() => CircularTimerState();
}

class CircularTimerState extends State<CircularTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    if (widget.autoStart) {
      start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Start the timer
  void start() {
    if (_isRunning && !_isPaused) return;

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    if (widget.mode == TimerMode.countdown) {
      _animationController.forward(from: _animationController.value);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
      });

      widget.onTick?.call(_currentDisplaySeconds);

      if (widget.mode == TimerMode.countdown &&
          _elapsedSeconds >= widget.durationSeconds) {
        _complete();
      }
    });

    HapticFeedback.lightImpact();
  }

  /// Pause the timer
  void pause() {
    if (!_isRunning || _isPaused) return;

    _timer?.cancel();
    _animationController.stop();

    setState(() {
      _isPaused = true;
    });

    HapticFeedback.lightImpact();
  }

  /// Resume from pause
  void resume() {
    if (!_isPaused) return;
    start();
  }

  /// Reset the timer
  void reset() {
    _timer?.cancel();
    _animationController.reset();

    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _isPaused = false;
    });

    HapticFeedback.mediumImpact();
  }

  void _complete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    HapticFeedback.heavyImpact();
    widget.onComplete?.call();
  }

  int get _currentDisplaySeconds {
    if (widget.mode == TimerMode.countdown) {
      return (widget.durationSeconds - _elapsedSeconds).clamp(0, widget.durationSeconds);
    }
    return _elapsedSeconds;
  }

  double get _progress {
    if (widget.mode == TimerMode.countdown) {
      return _elapsedSeconds / widget.durationSeconds;
    }
    // For count-up, progress wraps every minute
    return (_elapsedSeconds % 60) / 60;
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer Circle
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress Ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularProgressPainter(
                  progress: _progress,
                  progressColor: widget.progressColor,
                  backgroundColor: widget.backgroundColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),

              // Center Content
              widget.centerWidget ??
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_currentDisplaySeconds),
                        style: GoogleFonts.inter(
                          fontSize: widget.size * 0.18,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      if (widget.label != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.label!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
            ],
          ),
        ),

        // Controls
        if (widget.showControls) ...[
          const SizedBox(height: 32),
          _buildControls(),
        ],
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button
        _buildControlButton(
          icon: Icons.refresh,
          onTap: reset,
          isSecondary: true,
        ),
        const SizedBox(width: 24),

        // Play/Pause Button
        _buildControlButton(
          icon: _isRunning && !_isPaused ? Icons.pause : Icons.play_arrow,
          onTap: () {
            if (_isRunning && !_isPaused) {
              pause();
            } else if (_isPaused) {
              resume();
            } else {
              start();
            }
          },
          isLarge: true,
        ),
        const SizedBox(width: 24),

        // Stop Button
        _buildControlButton(
          icon: Icons.stop,
          onTap: () {
            reset();
            widget.onComplete?.call();
          },
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isLarge = false,
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 72 : 48,
        height: isLarge ? 72 : 48,
        decoration: BoxDecoration(
          color: isLarge ? widget.progressColor : Colors.transparent,
          shape: BoxShape.circle,
          border: isSecondary
              ? Border.all(color: widget.progressColor.withValues(alpha: 0.5), width: 2)
              : null,
          boxShadow: isLarge
              ? [
                  BoxShadow(
                    color: widget.progressColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isLarge ? Colors.white : widget.progressColor,
          size: isLarge ? 36 : 24,
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect at the end of progress
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final endAngle = -math.pi / 2 + sweepAngle;
      final endPoint = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      canvas.drawCircle(endPoint, strokeWidth / 2 + 4, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
