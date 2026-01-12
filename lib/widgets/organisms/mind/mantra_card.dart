import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/theme_constants.dart';
import '../../../models/mantra.dart';

/// A beautiful glassmorphic card for displaying mantras/affirmations
/// Features:
/// - 3D perspective transform on swipe
/// - Breathing glow animation
/// - Parallax text effect
/// - Category badge with gradient
/// - Subtle shimmer overlay
class MantraCard extends StatefulWidget {
  final Mantra mantra;
  final double scrollOffset; // -1 to 1, 0 = centered
  final int index;
  final int totalCount;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool isActive;

  const MantraCard({
    super.key,
    required this.mantra,
    this.scrollOffset = 0,
    this.index = 0,
    this.totalCount = 1,
    this.onTap,
    this.onDoubleTap,
    this.isActive = true,
  });

  @override
  State<MantraCard> createState() => _MantraCardState();
}

class _MantraCardState extends State<MantraCard> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _shimmerController;
  late Animation<double> _breathAnimation;
  late Animation<double> _shimmerAnimation;

  static const Duration _shimmerCycle = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    // Breathing animation - uses zen rhythm from ThemeConstants
    _breathController = AnimationController(
      vsync: this,
      duration: ThemeConstants.zenBreathCycle,
    );

    // Zen breathing: 4s inhale, 6s exhale (coherent breathing for HRV)
    _breathAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: ThemeConstants.zenInhaleWeight,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: ThemeConstants.zenExhaleWeight,
      ),
    ]).animate(_breathController);

    // Shimmer animation for highlight sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: _shimmerCycle,
    );

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _breathController.repeat();
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(MantraCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_breathController.isAnimating) {
      _breathController.repeat();
      _shimmerController.repeat();
    } else if (!widget.isActive && _breathController.isAnimating) {
      _breathController.stop();
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // Get category color based on mantra category
  Color _getCategoryColor() {
    switch (widget.mantra.category?.toLowerCase()) {
      case 'morning':
        return const Color(0xFFFFB347); // Warm sunrise orange
      case 'focus':
        return ThemeConstants.accentBlue;
      case 'motivation':
        return const Color(0xFFFF6B6B); // Energetic coral
      case 'meditation':
        return const Color(0xFF9B59B6); // Deep purple
      case 'stress':
        return const Color(0xFF26C6DA); // Calm cyan
      case 'evening':
        return const Color(0xFF5C6BC0); // Twilight indigo
      default:
        return ThemeConstants.polyMint400;
    }
  }

  // Get gradient for category badge
  LinearGradient _getCategoryGradient() {
    final baseColor = _getCategoryColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withValues(alpha: 0.7),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathController, _shimmerController]),
      builder: (context, child) {
        final breath = _breathAnimation.value;
        final shimmer = _shimmerAnimation.value;

        // 3D perspective based on scroll offset
        final rotateY = widget.scrollOffset * 0.15; // Subtle rotation
        final scale = 1.0 - (widget.scrollOffset.abs() * 0.08);
        final translateX = widget.scrollOffset * 20;

        // Breathing effects
        final glowIntensity = lerpDouble(0.3, 0.6, breath) ?? 0.3;
        final borderGlow = lerpDouble(0.1, 0.25, breath) ?? 0.1;

        return Transform.translate(
          offset: Offset(translateX, 0),
          child: Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateY(rotateY),
              child: GestureDetector(
                onTap: widget.onTap,
                onDoubleTap: widget.onDoubleTap,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      // Main breathing shadow
                      BoxShadow(
                        color: _getCategoryColor()
                            .withValues(alpha: glowIntensity * 0.4),
                        blurRadius: 30 + (breath * 15),
                        spreadRadius: breath * 8,
                        offset: const Offset(0, 12),
                      ),
                      // Soft ambient shadow
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: -5,
                        offset: const Offset(0, 8),
                      ),
                      // Inner glow
                      BoxShadow(
                        color: Colors.white.withValues(alpha: borderGlow * 0.2),
                        blurRadius: 40,
                        spreadRadius: -20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          // Glass gradient with breathing
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ThemeConstants.deepNavy.withValues(alpha: 0.95),
                              ThemeConstants.darkTeal.withValues(alpha: 0.85),
                              ThemeConstants.steelBlue.withValues(alpha: 0.75),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          // Breathing border
                          border: Border.all(
                            color: Colors.white.withValues(alpha: borderGlow),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Shimmer overlay
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment(shimmer - 1, 0),
                                      end: Alignment(shimmer, 0),
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.srcATop,
                                  child: Container(color: Colors.white),
                                ),
                              ),
                            ),

                            // Main content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header: Category + Index
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Category badge
                                    _buildCategoryBadge(),
                                    // Card number indicator
                                    _buildIndexIndicator(),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // Mantra text with parallax
                                Transform.translate(
                                  offset: Offset(
                                      widget.scrollOffset * -10, 0), // Parallax
                                  child: Text(
                                    '"${widget.mantra.text}"',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      height: 1.5,
                                      letterSpacing: 0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Bottom row: Swipe hint + breathing indicator
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Swipe hint
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.swipe_rounded,
                                          size: 16,
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Swipe to explore',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.4),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Breathing dot indicator
                                    _buildBreathingIndicator(breath),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBadge() {
    final category = widget.mantra.category ?? 'mantra';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: _getCategoryGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            category.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.mantra.category?.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'focus':
        return Icons.center_focus_strong_outlined;
      case 'motivation':
        return Icons.flash_on_outlined;
      case 'meditation':
        return Icons.self_improvement_outlined;
      case 'stress':
        return Icons.spa_outlined;
      case 'evening':
        return Icons.nightlight_round_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  Widget _buildIndexIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        '${widget.index + 1} / ${widget.totalCount}',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBreathingIndicator(double breath) {
    return Row(
      children: List.generate(3, (i) {
        // Staggered breathing animation
        final stagger = (breath + (i * 0.33)) % 1.0;
        final size = 6.0 + (stagger * 4);
        final opacity = 0.3 + (stagger * 0.5);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getCategoryColor().withValues(alpha: opacity),
              boxShadow: [
                BoxShadow(
                  color: _getCategoryColor().withValues(alpha: opacity * 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// A simplified mantra card for list views (non-carousel usage)
class MantraCardCompact extends StatelessWidget {
  final Mantra mantra;
  final VoidCallback? onTap;
  final bool showCategory;

  const MantraCardCompact({
    super.key,
    required this.mantra,
    this.onTap,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeConstants.deepNavy.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCategory && mantra.category != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  mantra.category!.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ThemeConstants.polyMint400,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            Text(
              mantra.text,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
