import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';

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
  final int _tickCount = 30; // Number of tick marks

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: ThemeConstants.deepNavy,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ThemeConstants.glassBorderWeak,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Duration Pill
          _buildDurationPill(),
          const SizedBox(height: 12),
          
          // Slider Row
          Row(
            children: [
              // Start Time Label
              if (widget.showTimeLabels) ...[
                _buildTimeLabel(widget.startTimeLabel ?? ''),
                const SizedBox(width: 12),
              ],

              // Tick Marks Slider
              Expanded(
                child: _buildTickSlider(),
              ),

              // End Time Label
              if (widget.showTimeLabels) ...[
                const SizedBox(width: 12),
                _buildTimeLabel(widget.endTimeLabel ?? ''),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35), // Orange accent
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatDuration(_currentValue.round()),
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTimeLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeConstants.glassBorderWeak,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTickSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        final normalizedValue = (_currentValue - widget.minMinutes) /
            (widget.maxMinutes - widget.minMinutes);
        final thumbPosition = normalizedValue * sliderWidth;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            _handleDrag(details.localPosition.dx, sliderWidth);
          },
          onTapDown: (details) {
            _handleDrag(details.localPosition.dx, sliderWidth);
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: ThemeConstants.glassBackgroundWeak,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Tick Marks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_tickCount, (index) {
                    final isHighlighted = (index / (_tickCount - 1)) <= normalizedValue;
                    return Container(
                      width: 2,
                      height: index % 5 == 0 ? 24 : 16,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? const Color(0xFFFF6B35).withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),

                // Thumb Line
                Positioned(
                  left: thumbPosition.clamp(0, sliderWidth - 2),
                  child: Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDrag(double localX, double sliderWidth) {
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
