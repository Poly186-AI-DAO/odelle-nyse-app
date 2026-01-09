import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Slide-to-action button for confirmations
/// "Slide to invest" / "Slide to confirm" style interaction
class SlideToAction extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onSlideComplete;
  final Color backgroundColor;
  final Color sliderColor;
  final Color textColor;
  final double height;
  final BorderRadius borderRadius;
  final bool enabled;

  const SlideToAction({
    super.key,
    required this.text,
    required this.onSlideComplete,
    this.icon = Icons.arrow_forward_rounded,
    this.backgroundColor = const Color(0xFF0A1628),
    this.sliderColor = Colors.white,
    this.textColor = Colors.white,
    this.height = 56,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.enabled = true,
  });

  @override
  State<SlideToAction> createState() => _SlideToActionState();
}

class _SlideToActionState extends State<SlideToAction>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isDragging = false;
  bool _isCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  // Slider button size
  static const double _sliderSize = 48;
  static const double _sliderPadding = 4;
  static const double _completionThreshold = 0.85;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.enabled || _isCompleted) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (!widget.enabled || _isCompleted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0, maxDrag);
    });
  }

  void _handleDragEnd(DragEndDetails details, double maxDrag) {
    if (!widget.enabled || _isCompleted) return;

    final progress = _dragPosition / maxDrag;

    if (progress >= _completionThreshold) {
      // Complete the action
      HapticFeedback.heavyImpact();
      setState(() {
        _isCompleted = true;
        _dragPosition = maxDrag;
      });
      _animationController.forward().then((_) {
        widget.onSlideComplete();
      });
    } else {
      // Snap back to start
      HapticFeedback.lightImpact();
      _animateToPosition(0);
    }

    setState(() {
      _isDragging = false;
    });
  }

  void _animateToPosition(double position) {
    final currentPosition = _dragPosition;
    final tween = Tween<double>(begin: currentPosition, end: position);
    final animation = tween.animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    void listener() {
      setState(() {
        _dragPosition = animation.value;
      });
    }

    animation.addListener(listener);
    _animationController.forward(from: 0).then((_) {
      animation.removeListener(listener);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag =
            constraints.maxWidth - _sliderSize - (_sliderPadding * 2);
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag) : 0.0;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: _dragPosition + _sliderSize + _sliderPadding,
                height: widget.height,
                decoration: BoxDecoration(
                  color: _isCompleted
                      ? const Color(0xFF22C55E)
                      : widget.sliderColor.withValues(alpha: 0.1),
                  borderRadius: widget.borderRadius,
                ),
              ),

              // Centered text
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: 1 - progress,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.text,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.textColor.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: widget.textColor.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: widget.textColor.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Completed checkmark
              if (_isCompleted)
                Center(
                  child: ScaleTransition(
                    scale: _bounceAnimation,
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

              // Slider button
              Positioned(
                left: _sliderPadding + _dragPosition,
                top: _sliderPadding,
                child: GestureDetector(
                  onHorizontalDragStart: _handleDragStart,
                  onHorizontalDragUpdate: (d) => _handleDragUpdate(d, maxDrag),
                  onHorizontalDragEnd: (d) => _handleDragEnd(d, maxDrag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: _sliderSize,
                    height: _sliderSize,
                    decoration: BoxDecoration(
                      color: _isCompleted ? Colors.white : widget.sliderColor,
                      borderRadius: BorderRadius.circular(_sliderSize / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: _isDragging ? 0.2 : 0.1),
                          blurRadius: _isDragging ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleted ? Icons.check_rounded : widget.icon,
                      color: _isCompleted
                          ? const Color(0xFF22C55E)
                          : widget.backgroundColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Reset the slider to initial state
  void reset() {
    setState(() {
      _isCompleted = false;
      _dragPosition = 0;
    });
    _animationController.reset();
  }
}

/// Confirmation button with loading state
class ConfirmButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const ConfirmButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = const Color(0xFF0A1628),
    this.textColor = Colors.white,
    this.icon,
  });

  @override
  State<ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<ConfirmButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) {
          HapticFeedback.mediumImpact();
          widget.onPressed();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 56,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: widget.backgroundColor
                  .withValues(alpha: _isPressed ? 0.2 : 0.3),
              blurRadius: _isPressed ? 4 : 8,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(widget.textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.textColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
