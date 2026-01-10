import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import '../panels/bottom_panel.dart';

/// A floating hero card that covers most of the screen
/// Matching the fintech reference design with optional bottom panel
class FloatingHeroCard extends StatelessWidget {
  final Widget child;
  final Widget? bottomPanel;
  final double panelVisibility;
  final double horizontalMargin;
  final double topMarginExtra;
  final double bottomPercentage;
  final bool draggableBottomPanel;
  final double? bottomPanelMinHeight;
  final double? bottomPanelMaxHeight;
  final EdgeInsetsGeometry? bottomPanelPadding;
  final bool bottomPanelShowHandle;
  final bool bottomPanelPulseEnabled;
  final Duration bottomPanelPulseDuration;
  final double bottomPanelPulseAmplitude;

  const FloatingHeroCard({
    super.key,
    required this.child,
    this.bottomPanel,
    this.panelVisibility = 1.0,
    this.horizontalMargin = 12.0,
    this.topMarginExtra = 12.0,
    this.bottomPercentage = 0.18,
    this.draggableBottomPanel = false,
    this.bottomPanelMinHeight,
    this.bottomPanelMaxHeight,
    this.bottomPanelPadding,
    this.bottomPanelShowHandle = true,
    this.bottomPanelPulseEnabled = false,
    this.bottomPanelPulseDuration = const Duration(milliseconds: 2800),
    this.bottomPanelPulseAmplitude = 6,
  });

  @override
  Widget build(BuildContext context) {
    final cardOffset = (1 - panelVisibility) * 50;
    final cardOpacity = panelVisibility.clamp(0.0, 1.0);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPanelHeight = screenHeight * 0.38;
    final minPanelHeight = bottomPanelMinHeight ?? bottomPanelHeight;
    final maxPanelHeight = bottomPanelMaxHeight ?? screenHeight * 0.78;
    final resolvedMaxHeight =
        maxPanelHeight < minPanelHeight ? minPanelHeight : maxPanelHeight;

    return Stack(
      children: [
        // The floating dark hero card - extends BEHIND Dynamic Island
        Positioned(
          top: topMarginExtra, // No safe area offset - goes behind island
          left: horizontalMargin,
          right: horizontalMargin,
          bottom: MediaQuery.of(context).size.height * bottomPercentage,
          child: Transform.translate(
            offset: Offset(0, cardOffset),
            child: Opacity(
              opacity: cardOpacity,
              child: const BreathingCard(
                borderRadius: 52,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),

        // Content layer (on the dark card)
        Opacity(
          opacity: cardOpacity,
          child: child,
        ),

        // White bottom panel with rounded top corners (if provided)
        if (bottomPanel != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: draggableBottomPanel ? null : bottomPanelHeight,
            child: Opacity(
              opacity: cardOpacity,
              child: draggableBottomPanel
                  ? DraggableBottomPanel(
                      minHeight: minPanelHeight,
                      maxHeight: resolvedMaxHeight,
                      borderRadius: 32,
                      backgroundColor: Colors.white,
                      padding: bottomPanelPadding ??
                          const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      showHandle: bottomPanelShowHandle,
                      pulseEnabled: bottomPanelPulseEnabled,
                      pulseDuration: bottomPanelPulseDuration,
                      pulseAmplitude: bottomPanelPulseAmplitude,
                      child: bottomPanel!,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x15000000),
                            blurRadius: 20,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: bottomPanel,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

/// A card with a gentle breathing animation
/// Follows zen breathing rhythm: 4s inhale, 6s exhale (6 breaths/min)
class BreathingCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool animate;

  const BreathingCard({
    super.key,
    required this.child,
    this.borderRadius = 48,
    this.animate = true,
  });

  @override
  State<BreathingCard> createState() => _BreathingCardState();
}

class _BreathingCardState extends State<BreathingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _borderAnimation;

  // Zen breathing: 4s inhale + 6s exhale = 10s cycle
  static const Duration _breathCycle = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _breathCycle,
    );

    // Subtle scale: 1.0 -> 1.008 (barely perceptible, calming)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.008,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _BreathingCurve(),
    ));

    // Shadow intensity pulses with breath
    _shadowAnimation = Tween<double>(
      begin: 0.12,
      end: 0.22,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _BreathingCurve(),
    ));

    // Border opacity pulses subtly
    _borderAnimation = Tween<double>(
      begin: 0.05,
      end: 0.15,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _BreathingCurve(),
    ));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BreathingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
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
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              // Smooth gradient with more stops to prevent banding
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ThemeConstants.deepNavy, // 0% - Deep navy
                  Color(0xFF142740), // 15% - Navy blend
                  ThemeConstants.darkTeal, // 30% - Dark teal
                  Color(0xFF2D4A5F), // 42% - Teal blend
                  Color(0xFF3D5A6A), // 52% - Warm teal
                  ThemeConstants.steelBlue, // 62% - Steel blue
                  Color(0xFF5A7080), // 72% - Steel blend
                  Color(0xFF6A7D8A), // 82% - Warm steel
                  ThemeConstants.calmSilver, // 92% - Calm silver
                  Color(0xFF8A9AA8), // 100% - Silver edge
                ],
                stops: [
                  0.0,
                  0.15,
                  0.30,
                  0.42,
                  0.52,
                  0.62,
                  0.72,
                  0.82,
                  0.92,
                  1.0
                ],
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius),
              ),
              // Breathing border glow
              border: Border.all(
                color: Colors.white.withValues(alpha: _borderAnimation.value),
                width: 0.5,
              ),
              // Breathing shadow
              boxShadow: [
                // Main shadow - breathes
                BoxShadow(
                  color: Colors.black.withValues(alpha: _shadowAnimation.value),
                  blurRadius: 24 + (_shadowAnimation.value * 20),
                  spreadRadius: _shadowAnimation.value * 2,
                  offset: const Offset(0, 8),
                ),
                // Subtle inner glow
                BoxShadow(
                  color: ThemeConstants.calmSilver
                      .withValues(alpha: _borderAnimation.value * 0.3),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Custom curve that mimics natural breathing
/// Inhale is faster (40% of cycle), exhale is slower (60% of cycle)
class _BreathingCurve extends Curve {
  @override
  double transformInternal(double t) {
    // Use sine wave for smooth breathing feel
    // Shifted so inhale is slightly faster than exhale
    if (t < 0.4) {
      // Inhale phase (0 -> 0.4) maps to (0 -> 1)
      final inhaleT = t / 0.4;
      return Curves.easeInOutSine.transform(inhaleT);
    } else {
      // Exhale phase (0.4 -> 1.0) maps to (1 -> 0)
      // But since we use reverse: true, this becomes the "hold at peak" feel
      return 1.0;
    }
  }
}
