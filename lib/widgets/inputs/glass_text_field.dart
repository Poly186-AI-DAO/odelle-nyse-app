import 'package:flutter/material.dart';
import '../../constants/design_constants.dart';
import '../../constants/theme_constants.dart';

class GlassTextField extends StatelessWidget {
  final String hintText;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;

  const GlassTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackground,
        borderRadius: BorderRadius.circular(DesignConstants.radiusLarge),
        border: Border.all(
          color: ThemeConstants.glassBorder,
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: DesignConstants.bodyM.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: DesignConstants.bodyM.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: Colors.white.withValues(alpha: 0.7),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spaceM,
            vertical: DesignConstants.spaceM,
          ),
        ),
      ),
    );
  }
}
