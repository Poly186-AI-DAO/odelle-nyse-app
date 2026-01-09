import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';

class CyberTitle extends StatefulWidget {
  final List<String> lines;
  final double fontSize;
  final bool showBorder;

  const CyberTitle({
    super.key,
    required this.lines,
    this.fontSize = 32,
    this.showBorder = true,
  });

  @override
  State<CyberTitle> createState() => _CyberTitleState();
}

class _CyberTitleState extends State<CyberTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _lineAnimations;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create staggered animations for each line
    _lineAnimations = List.generate(
      widget.lines.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2, // Stagger start times
            index * 0.2 + 0.5, // Overlap animations
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    // Border animation
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
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
        return Container(
          padding: ThemeConstants.paddingLarge,
          decoration: widget.showBorder
              ? BoxDecoration(
                  border: Border.all(
                    color: ThemeConstants.borderColor
                        .withOpacity(_borderAnimation.value),
                    width: ThemeConstants.borderWidth,
                  ),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.lines.length; i++)
                FadeTransition(
                  opacity: _lineAnimations[i],
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-0.2, 0.0),
                      end: Offset.zero,
                    ).animate(_lineAnimations[i]),
                    child: Text(
                      widget.lines[i],
                      style: GoogleFonts.pressStart2p(
                        color: i == widget.lines.length - 1
                            ? ThemeConstants.primaryColor
                            : ThemeConstants.textColor,
                        fontSize: widget.fontSize,
                        height: 1.5,
                        shadows: ThemeConstants.textGlow,
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
}
