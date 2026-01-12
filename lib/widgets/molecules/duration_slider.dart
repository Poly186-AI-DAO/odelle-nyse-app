import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A sleek duration slider with tick marks and an orange duration pill.
/// Matches the iOS-style time range picker design.
class DurationSlider extends StatefulWidget {
  /// Initial duration in minutes
  final int initialMinutes;

  /// Minimum duration in minutes
  final int minMinutes;

  /// Maximum duration in minutes
  final int maxMinutes;

  /// Step size in minutes (e.g., 5 for 5-minute increments)
  final int stepMinutes;

  /// Callback when duration changes
  final ValueChanged<int>? onChanged;

  /// Optional start time label (e.g., "4:31 PM")
  final String? startTimeLabel;

  /// Optional end time label (e.g., "3:00 PM")
  final String? endTimeLabel;

  /// Whether to show time labels on the sides
  final bool showTimeLabels;

  const DurationSlider({
    super.key,
    this.initialMinutes = 10,
    this.minMinutes = 1,
    this.maxMinutes = 120,
    this.stepMinutes = 1,
    this.onChanged,
    this.startTimeLabel,
    this.endTimeLabel,
    this.showTimeLabels = false,
  });

  @override
  State<DurationSlider> createState() => _DurationSliderState();
}

class _DurationSliderState extends State<DurationSlider> {
  late double _currentValue;
  final int _tickCount = 41; // More ticks for denser metallic look

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialMinutes.toDouble();
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}m';
    }
    return '${totalMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slider Area
        SizedBox(
          height: 120, // Height to accommodate floating pill and ticks
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sliderWidth = constraints.maxWidth;
              // Calculate normalized value
              final normalizedValue = (_currentValue - widget.minMinutes) /
                  (widget.maxMinutes - widget.minMinutes);
              
              // Calculate thumb position
              final thumbX = normalizedValue * sliderWidth;

              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  _handleDrag(details.localPosition.dx, sliderWidth);
                },
                onTapDown: (details) {
                  _handleDrag(details.localPosition.dx, sliderWidth);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Metallic Container Track
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 64,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E), // Deep metallic dark
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Start Label
                            if (widget.showTimeLabels) ...[
                              _buildTimeLabel(widget.startTimeLabel ?? ''),
                              const SizedBox(width: 12),
                            ],
                            
                            // Ticks
                            Expanded(
                              child: CustomPaint(
                                painter: _MetallicTickPainter(
                                  tickCount: _tickCount,
                                  normalizedValue: normalizedValue,
                                  activeColor: const Color(0xFFFF6B35),
                                  inactiveColor: const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                            
                             // End Label
                            if (widget.showTimeLabels) ...[
                              const SizedBox(width: 12),
                              _buildTimeLabel(widget.endTimeLabel ?? ''),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Thumb Indicator Line (The red/orange line)
                    Positioned(
                      left: widget.showTimeLabels ? thumbX + 60 : thumbX, // Approximate offset adjustment if labels exist, but for accurate logic we should separate labels. 
                      // actually, putting labels inside changes the width. Let's simplfy: remove labels from inside calculation or render them outside.
                      // For this design, let's keep labels inside but assume they consume fixed width? 
                      // Better approach: Floating pill is absolute, ticks are relative.
                      // Let's reimplement _buildTickSlider structure simplified.
                      bottom: 12,
                      child: IgnorePointer(
                        child: Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Floating Pill attached to thumb
                    Positioned(
                      left: (widget.showTimeLabels ? thumbX + 60 : thumbX) - 36, // Center pill (width 72)
                      bottom: 70, // Float above track
                      child: _buildFloatingPill(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingPill() {
    return Container(
      width: 80, // Fixed width
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _formatDuration(_currentValue.round()),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF8E8E93),
      ),
    );
  }

  void _handleDrag(double localX, double sliderWidth) {
    // Adjust for padding or labels if necessary.
    // For simplicity in this 'swag' version, let's assume dragging across full width maps to range.
    
    final normalizedPosition = (localX / sliderWidth).clamp(0.0, 1.0);
    final rawValue = widget.minMinutes +
        (normalizedPosition * (widget.maxMinutes - widget.minMinutes));
    
    // Snap to step
    final steppedValue =
        (rawValue / widget.stepMinutes).round() * widget.stepMinutes;
    final clampedValue =
        steppedValue.clamp(widget.minMinutes, widget.maxMinutes);

    if (clampedValue != _currentValue.round()) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _currentValue = clampedValue.toDouble();
    });

    widget.onChanged?.call(clampedValue);
  }
}

class _MetallicTickPainter extends CustomPainter {
  final int tickCount;
  final double normalizedValue;
  final Color activeColor;
  final Color inactiveColor;

  _MetallicTickPainter({
    required this.tickCount,
    required this.normalizedValue,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tickSpacing = size.width / (tickCount - 1);
    
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    for (int i = 0; i < tickCount; i++) {
      final x = i * tickSpacing;
      final isHighlighted = (i / (tickCount - 1)) <= normalizedValue;
      
      // Determine height: taller every 5th tick
      final isMajor = i % 5 == 0;
      final height = isMajor ? 24.0 : 12.0;
      
      // Metallic gradient effect simulates by opacity
      final color = isHighlighted ? activeColor : inactiveColor.withValues(alpha: 0.5);

      paint.color = color;
      
      // Draw tick centered vertically
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MetallicTickPainter oldDelegate) {
    return oldDelegate.normalizedValue != normalizedValue;
  }
}
