import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/theme_constants.dart';
import '../../../models/mantra.dart';

/// Clean mantra card following design system
/// - Single card (no double nesting)
/// - Subtle category badge
/// - No redundant indicators (pagination is in bottom panel)
/// - Minimal, elegant design
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

class _MantraCardState extends State<MantraCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(MantraCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.isActive && _shimmerController.isAnimating) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Color _getCategoryColor() {
    switch (widget.mantra.category?.toLowerCase()) {
      case 'morning':
        return const Color(0xFFFFB347);
      case 'focus':
        return ThemeConstants.accentBlue;
      case 'motivation':
        return const Color(0xFFFF6B6B);
      case 'meditation':
        return const Color(0xFF9B59B6);
      case 'stress':
        return const Color(0xFF26C6DA);
      case 'evening':
        return const Color(0xFF5C6BC0);
      default:
        return ThemeConstants.polyMint400;
    }
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmer = _shimmerAnimation.value;

        // 3D perspective based on scroll offset
        final rotateY = widget.scrollOffset * 0.12;
        final scale = 1.0 - (widget.scrollOffset.abs() * 0.06);
        final translateX = widget.scrollOffset * 15;
        final categoryColor = _getCategoryColor();

        return Transform.translate(
          offset: Offset(translateX, 0),
          child: Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotateY),
              child: GestureDetector(
                onTap: widget.onTap,
                onDoubleTap: widget.onDoubleTap,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.08),
                        blurRadius: 40,
                        spreadRadius: -10,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // Subtle shimmer overlay
                        Positioned.fill(
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment(shimmer - 1, 0),
                                end: Alignment(shimmer, 0),
                                colors: [
                                  Colors.transparent,
                                  categoryColor.withValues(alpha: 0.03),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcATop,
                            child: Container(color: Colors.white),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Category badge (clean, minimal)
                              _buildCategoryBadge(categoryColor),

                              const SizedBox(height: 24),

                              // Mantra text with parallax
                              Transform.translate(
                                offset: Offset(widget.scrollOffset * -8, 0),
                                child: Text(
                                  '"${widget.mantra.text}"',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeConstants.textOnLight,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),

                              const Spacer(),

                              // Subtle tap hint
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.touch_app_outlined,
                                    size: 14,
                                    color: ThemeConstants.textMuted
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap to copy',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: ThemeConstants.textMuted
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildCategoryBadge(Color categoryColor) {
    final category = widget.mantra.category ?? 'mantra';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 14,
            color: categoryColor,
          ),
          const SizedBox(width: 6),
          Text(
            category.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: categoryColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
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

  Color _getCategoryColor() {
    switch (mantra.category?.toLowerCase()) {
      case 'morning':
        return const Color(0xFFFFB347);
      case 'focus':
        return ThemeConstants.accentBlue;
      case 'motivation':
        return const Color(0xFFFF6B6B);
      case 'meditation':
        return const Color(0xFF9B59B6);
      case 'stress':
        return const Color(0xFF26C6DA);
      case 'evening':
        return const Color(0xFF5C6BC0);
      default:
        return ThemeConstants.polyMint400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                    color: categoryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            Text(
              mantra.text,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: ThemeConstants.textOnLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
