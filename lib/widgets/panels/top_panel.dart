import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';

/// Animated top panel that slides down from the top of the screen
/// Used for transcription display, notifications, or contextual content
/// Inspired by the "Autonomous Index" card design - deep blue to warm gradient
class TopPanel extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool isVisible;
  final Duration animationDuration;
  final Curve animationCurve;
  final double topOffset;
  final List<Color>? gradientColors;

  const TopPanel({
    super.key,
    required this.child,
    this.title,
    this.isVisible = false,
    this.animationDuration = const Duration(milliseconds: 400),
    this.animationCurve = Curves.easeOutCubic,
    this.topOffset = 60,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? _defaultGradient;

    return AnimatedPositioned(
      duration: animationDuration,
      curve: animationCurve,
      top: isVisible ? topOffset : -300,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }

  /// Default gradient: deep blue → warm sunset (like Autonomous Index)
  static const List<Color> _defaultGradient = [
    Color(0xFF0A1628), // Deep navy
    Color(0xFF1E3A5F), // Dark teal
    Color(0xFF4A6B7C), // Steel blue
    Color(0xFF7A6B5C), // Warm taupe
    Color(0xFFA08060), // Sunset amber
  ];

  /// Cool blue gradient
  static const List<Color> coolBlueGradient = [
    Color(0xFF0A1628),
    Color(0xFF1E3A5F),
    Color(0xFF3A5A7C),
    Color(0xFF4A6B8C),
  ];

  /// Warm sunset gradient
  static const List<Color> warmSunsetGradient = [
    Color(0xFF2C1810),
    Color(0xFF4A3020),
    Color(0xFF7A5540),
    Color(0xFFA08060),
    Color(0xFFC4A574),
  ];
}

/// Stateful wrapper for TopPanel with built-in visibility control
class AnimatedTopPanel extends StatefulWidget {
  final Widget child;
  final String? title;
  final bool isVisible;
  final Duration animationDuration;
  final Curve animationCurve;
  final double topOffset;
  final List<Color>? gradientColors;
  final VoidCallback? onDismiss;

  const AnimatedTopPanel({
    super.key,
    required this.child,
    this.title,
    this.isVisible = false,
    this.animationDuration = const Duration(milliseconds: 400),
    this.animationCurve = Curves.easeOutCubic,
    this.topOffset = 60,
    this.gradientColors,
    this.onDismiss,
  });

  @override
  State<AnimatedTopPanel> createState() => _AnimatedTopPanelState();
}

class _AnimatedTopPanelState extends State<AnimatedTopPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedTopPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ?? TopPanel._defaultGradient;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -200) {
              widget.onDismiss?.call();
            }
          },
          child: Container(
            margin: EdgeInsets.fromLTRB(16, widget.topOffset, 16, 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null) ...[
                  Text(
                    widget.title!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Transcription-specific panel with waveform support
class TranscriptionPanel extends StatelessWidget {
  final String? partialText;
  final String? finalText;
  final bool isListening;
  final bool isVisible;
  final Widget? waveformWidget;

  const TranscriptionPanel({
    super.key,
    this.partialText,
    this.finalText,
    this.isListening = false,
    this.isVisible = false,
    this.waveformWidget,
  });

  @override
  Widget build(BuildContext context) {
    return TopPanel(
      isVisible: isVisible,
      title: isListening ? 'Listening...' : 'Transcription',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Show waveform while listening with no text
    if (isListening &&
        (partialText?.isEmpty ?? true) &&
        waveformWidget != null) {
      return Center(child: waveformWidget!);
    }

    // Show text
    final displayText = partialText?.isNotEmpty == true
        ? partialText!
        : finalText?.isNotEmpty == true
            ? finalText!
            : 'Start speaking...';

    return Text(
      displayText,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w300,
        color: Colors.white,
        height: 1.6,
      ),
    );
  }
}
