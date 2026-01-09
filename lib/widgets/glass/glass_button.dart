import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import '../../constants/design_constants.dart';

/// A modern glassmorphic button with smooth animations
///
/// Features:
/// - Rounded corners (not oval)
/// - Press animation with scale effect
/// - Optional glow effect
/// - Loading state
/// - Disabled state with reduced opacity
class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool enableGlow;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final double borderRadius;
  final double? width;
  final double? height;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.enableGlow = true,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius = DesignConstants.radiusMedium,
    this.width,
    this.height,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ThemeConstants.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedOpacity(
            opacity: isEnabled ? 1.0 : 0.5,
            duration: ThemeConstants.animationFast,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.enableGlow && isEnabled
                    ? ThemeConstants.softGlow
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: ThemeConstants.blurStrength,
                    sigmaY: ThemeConstants.blurStrength,
                  ),
                  child: Container(
                    padding: widget.padding ?? ThemeConstants.paddingButton,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ??
                          ThemeConstants.glassBackgroundStrong,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: widget.borderColor ??
                            ThemeConstants.glassBorderStrong,
                        width: ThemeConstants.borderWidth,
                      ),
                      gradient: isEnabled ? ThemeConstants.glassGradient : null,
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ThemeConstants.primaryColor,
                                ),
                              ),
                            )
                          : DefaultTextStyle(
                              style: DesignConstants.buttonText,
                              child: widget.child,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A primary button with purple gradient
class PrimaryGlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double? width;
  final double? height;

  const PrimaryGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed != null && !isLoading ? onPressed : null,
      child: MouseRegion(
        cursor: onPressed != null && !isLoading
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedOpacity(
          opacity: onPressed != null && !isLoading ? 1.0 : 0.5,
          duration: ThemeConstants.animationFast,
          child: Container(
            width: width,
            height: height ?? 56,
            decoration: BoxDecoration(
              gradient: ThemeConstants.buttonGradient,
              borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
              boxShadow: onPressed != null ? ThemeConstants.purpleGlow : null,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : DefaultTextStyle(
                      style: DesignConstants.buttonText,
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A large circular button for voice interaction
class CircularGlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final bool isActive;
  final bool isPulsing;

  const CircularGlassButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 80.0,
    this.isActive = false,
    this.isPulsing = false,
  });

  @override
  State<CircularGlassButton> createState() => _CircularGlassButtonState();
}

class _CircularGlassButtonState extends State<CircularGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CircularGlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.isActive ? ThemeConstants.buttonGradient : null,
            boxShadow: widget.isActive
                ? ThemeConstants.purpleGlow
                : ThemeConstants.cardShadow,
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: ThemeConstants.blurStrength,
                sigmaY: ThemeConstants.blurStrength,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? null
                      : ThemeConstants.glassBackgroundStrong,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ThemeConstants.glassBorderStrong,
                    width: ThemeConstants.borderWidth,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: widget.size * 0.4,
                  color: ThemeConstants.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
