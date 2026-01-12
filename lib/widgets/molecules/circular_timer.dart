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

/// A photorealistic, rotatable metallic timer knob.
/// Matches the physical "kitchen timer" aesthetic with knurled edges and glass face.
class CircularTimer extends StatefulWidget {
  /// Total duration in seconds
  final int durationSeconds;

  /// Timer mode
  final TimerMode mode;

  /// Size of the timer knob
  final double size;

  /// Whether to auto-start
  final bool autoStart;

  /// Callback when timer completes
  final VoidCallback? onComplete;

  /// Callback for each tick
  final ValueChanged<int>? onTick;

  /// Callback when user rotates the knob to change duration
  final ValueChanged<int>? onDurationChanged;

  const CircularTimer({
    super.key,
    this.durationSeconds = 60,
    this.mode = TimerMode.countdown,
    this.size = 280,
    this.autoStart = false,
    this.onComplete,
    this.onTick,
    this.onDurationChanged,
    // Ignoring unused params from previous version for API compatibility
    double strokeWidth = 0,
    Color? progressColor,
    Color? backgroundColor,
    bool showControls = true,
    Widget? centerWidget,
    String? label,
  });

  @override
  State<CircularTimer> createState() => CircularTimerState();
}

class CircularTimerState extends State<CircularTimer> with SingleTickerProviderStateMixin {
  late int _currentSeconds;
  Timer? _timer;
  bool _isRunning = false;
  double _rotationAngle = 0.0;
  
  // For interaction
  Offset? _dragStart;
  double _startRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.durationSeconds;
    if (widget.autoStart) {
      start();
    }
  }

  @override
  void didUpdateWidget(CircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.durationSeconds != oldWidget.durationSeconds && !_isRunning) {
      setState(() {
        _currentSeconds = widget.durationSeconds;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void start() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.mode == TimerMode.countdown) {
        if (_currentSeconds > 0) {
          setState(() => _currentSeconds--);
          widget.onTick?.call(_currentSeconds);
          // Auto-rotate knob slightly as it ticks? Optional.
        } else {
          _complete();
        }
      } else {
        setState(() => _currentSeconds++);
        widget.onTick?.call(_currentSeconds);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void reset() {
    pause();
    setState(() {
      _currentSeconds = widget.durationSeconds;
    });
  }

  void _complete() {
    pause();
    HapticFeedback.heavyImpact();
    widget.onComplete?.call();
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isRunning) return; // Lock rotation while running
    _dragStart = details.localPosition;
    _startRotation = _rotationAngle;
    HapticFeedback.selectionClick();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isRunning) return;

    final center = Offset(widget.size / 2, widget.size / 2);
    final currentPos = details.localPosition;
    
    // Calculate angle change
    final angle1 = (math.atan2(_dragStart!.dy - center.dy, _dragStart!.dx - center.dx));
    final angle2 = (math.atan2(currentPos.dy - center.dy, currentPos.dx - center.dx));
    final delta = angle2 - angle1;

    setState(() {
      _rotationAngle = _startRotation + delta;
      
      // Map rotation to time change (1 full rotation = 60 minutes?)
      // Sensitivity: 1 degree ~ 10 seconds
      final secondsChange = (delta * (60 * 5) / (2 * math.pi)).round(); 
      if (secondsChange.abs() > 0) {
        _currentSeconds = (_currentSeconds + secondsChange).clamp(0, 3600); // Max 60m
        widget.onDurationChanged?.call(_currentSeconds);
        // Reset start for incremental updates
        _dragStart = currentPos;
        _startRotation = _rotationAngle;
        
        if (secondsChange.abs() > 10) HapticFeedback.lightImpact(); // Feedback on change
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. The Metallic Knurled Ring (Base)
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _KnurledRingPainter(),
            ),

            // 2. The Inner Black Body
            Container(
              width: widget.size * 0.88,
              height: widget.size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C1C1E),
                // Outer shadow for depth effect (since inset isn't supported)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(-1, -1),
                  ),
                ],
              ),
            ),
            
            // 3. Digital Display
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'M',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(_currentSeconds ~/ 60).toString().padLeft(2, '0')}:${(_currentSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.shareTechMono( // Digital clock font look
                    fontSize: widget.size * 0.25,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10), // Glow
                    ],
                  ),
                ),
              ],
            ),

            // 4. Glass Reflection Overlay (Glossy Dome)
            IgnorePointer(
              child: Container(
                width: widget.size * 0.88,
                height: widget.size * 0.88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            
            // 5. Shine/Glare spot
            IgnorePointer(
              child: Positioned(
                top: widget.size * 0.2,
                right: widget.size * 0.25,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.all(Radius.elliptical(widget.size*0.3, widget.size*0.15)),
                  ),
                  transform: Matrix4.rotationZ(-0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnurledRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Main metallic body gradient
    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFE0E0E0), // Light Silver
          Color(0xFF9E9E9E), // Darker Grey
          Color(0xFFF5F5F5), // Highlight
          Color(0xFF9E9E9E),
          Color(0xFFE0E0E0),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);

    // Draw Knurled Texture (Tick marks on the edge)
    final tickPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    // Draw 120 knurled ridges
    const count = 120;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi) / count;
      
      // Outer and inner points for the ridge
      final outerX = center.dx + radius * math.cos(angle);
      final outerY = center.dy + radius * math.sin(angle);
      
      final innerX = center.dx + (radius - 12) * math.cos(angle); // 12px deep
      final innerY = center.dy + (radius - 12) * math.sin(angle);

      // Draw shadow side
      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
      
      // Draw highlight side slightly offset for 3D effect
      final offsetAngle = angle + 0.01;
      final hOuterX = center.dx + radius * math.cos(offsetAngle);
      final hOuterY = center.dy + radius * math.sin(offsetAngle);
      final hInnerX = center.dx + (radius - 12) * math.cos(offsetAngle);
      final hInnerY = center.dy + (radius - 12) * math.sin(offsetAngle);
      
      canvas.drawLine(Offset(hInnerX, hInnerY), Offset(hOuterX, hOuterY), highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

