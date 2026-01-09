import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class IconCyberButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isError;
  final double size;

  const IconCyberButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = true,
    this.isError = false,
    this.size = 24,
  });

  @override
  State<IconCyberButton> createState() => _IconCyberButtonState();
}

class _IconCyberButtonState extends State<IconCyberButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 8.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isActive) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isActive) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.isActive) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isError
        ? ThemeConstants.errorColor
        : ThemeConstants.primaryColor;
    final opacity = widget.isActive ? 1.0 : 0.5;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isActive ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(ThemeConstants.spacingMedium),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: ThemeConstants.borderRadius,
                border: Border.all(
                  color: color.withAlpha((0.5 * opacity * 255).toInt()),
                  width: ThemeConstants.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha((0.2 * opacity * 255).toInt()),
                    blurRadius: _isPressed
                        ? _glowAnimation.value
                        : ThemeConstants.glowShadow.first.blurRadius,
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: color.withAlpha((0.7 * opacity * 255).toInt()),
                size: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}
