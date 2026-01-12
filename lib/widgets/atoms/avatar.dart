import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final double size;
  final Color? backgroundColor;

  const Avatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.size = 40.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? ThemeConstants.glassBackgroundStrong,
        shape: BoxShape.circle,
        border: Border.all(
          color: ThemeConstants.glassBorderWeak,
          width: 1.0,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        fallbackText != null && fallbackText!.isNotEmpty
            ? fallbackText!.substring(0, 1).toUpperCase()
            : "?",
        style: TextStyle(
          color: ThemeConstants.textColor,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
