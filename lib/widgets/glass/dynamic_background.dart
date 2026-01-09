import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import '../../constants/design_constants.dart';

/// Dynamic background that changes per screen
/// Supports gradients and images with blur
enum BackgroundType {
  login,
  chat,
  workers,
  tasks,
  settings,
}

class DynamicBackground extends StatelessWidget {
  final BackgroundType type;
  final Widget child;
  final bool animate;
  final String? backgroundImage;
  final double blur;

  const DynamicBackground({
    super.key,
    required this.type,
    required this.child,
    this.animate = true,
    this.backgroundImage,
    this.blur = 20.0,
  });

  Gradient _getGradient() {
    switch (type) {
      case BackgroundType.login:
        return ThemeConstants.loginGradient;
      case BackgroundType.chat:
        return ThemeConstants.chatGradient;
      case BackgroundType.workers:
        return ThemeConstants.workersGradient;
      case BackgroundType.tasks:
        return ThemeConstants.tasksGradient;
      case BackgroundType.settings:
        return ThemeConstants.loginGradient;
    }
  }

  String? _getBackgroundImage() {
    if (backgroundImage != null) return backgroundImage;

    switch (type) {
      case BackgroundType.login:
        return DesignConstants.defaultBackgroundImage;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgImage = _getBackgroundImage();

    return Stack(
      children: [
        // Base Layer (Image or Gradient)
        Positioned.fill(
          child: bgImage != null
              ? Image.network(
                  bgImage,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(gradient: _getGradient()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(gradient: _getGradient()),
                    );
                  },
                )
              : AnimatedContainer(
                  duration:
                      animate ? ThemeConstants.animationSlow : Duration.zero,
                  decoration: BoxDecoration(
                    gradient: _getGradient(),
                  ),
                ),
        ),

        // Ambient Orbs (for Chat/Home)
        if (type == BackgroundType.chat && bgImage == null)
          const Positioned.fill(
            child: GradientOrbs(orbCount: 2),
          ),

        // Blur Effect (only for images)
        if (bgImage != null && blur > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                color: Colors.black.withOpacity(0.2), // Slight dimming
              ),
            ),
          ),

        // Gradient Overlay for depth/readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}

/// A glassmorphic screen wrapper with dynamic background
class GlassScreen extends StatelessWidget {
  final BackgroundType backgroundType;
  final Widget child;
  final bool useSafeArea;

  const GlassScreen({
    super.key,
    required this.backgroundType,
    required this.child,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = DynamicBackground(
      type: backgroundType,
      child: child,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: useSafeArea ? SafeArea(child: content) : content,
    );
  }
}

/// Animated gradient orbs for ambient background effects
class GradientOrbs extends StatefulWidget {
  final int orbCount;
  final Duration duration;

  const GradientOrbs({
    super.key,
    this.orbCount = 3,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<GradientOrbs> createState() => _GradientOrbsState();
}

class _GradientOrbsState extends State<GradientOrbs>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Alignment>> _alignments;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.orbCount,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      )..repeat(reverse: true),
    );

    _alignments = _controllers.map((controller) {
      final random = (controller.hashCode % 4);
      final begin = _getRandomAlignment(random);
      final end = _getRandomAlignment((random + 2) % 4);
      return Tween<Alignment>(begin: begin, end: end).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  Alignment _getRandomAlignment(int index) {
    switch (index) {
      case 0:
        return Alignment.topLeft;
      case 1:
        return Alignment.topRight;
      case 2:
        return Alignment.bottomLeft;
      case 3:
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.orbCount, (index) {
        final colors = [
          [ThemeConstants.polyPurple500, ThemeConstants.polyBlue500],
          [ThemeConstants.polyPink400, ThemeConstants.polyPurple600],
          [ThemeConstants.polyMint400, ThemeConstants.polyBlue400],
        ];

        return AnimatedBuilder(
          animation: _alignments[index],
          builder: (context, child) {
            return Align(
              alignment: _alignments[index].value,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors[index % colors.length][0].withOpacity(0.3),
                      colors[index % colors.length][1].withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
