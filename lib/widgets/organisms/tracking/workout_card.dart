import 'dart:io';
import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';

class WorkoutCard extends StatelessWidget {
  final String title;
  final String duration;
  final int exerciseCount;
  final String? imageUrl;
  final int? calories;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final bool isFeatured;

  const WorkoutCard({
    super.key,
    required this.title,
    required this.duration,
    required this.exerciseCount,
    this.imageUrl,
    this.calories,
    this.onTap,
    this.onStart,
    this.isFeatured = false,
  });

  /// Determine correct ImageProvider based on path type
  ImageProvider? _getImageProvider() {
    if (imageUrl == null) return null;

    // Check if it's a network URL or local file path
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return NetworkImage(imageUrl!);
    } else {
      // Local file path
      final file = File(imageUrl!);
      if (file.existsSync()) {
        return FileImage(file);
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _getImageProvider();
    final hasImage = imageProvider != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 180, // Fixed height for carousel usage
        decoration: BoxDecoration(
          color: ThemeConstants.panelWhite,
          borderRadius: ThemeConstants.borderRadiusXL,
          border: Border.all(color: ThemeConstants.glassBorderWeak),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          image: hasImage
              ? DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isFeatured) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ThemeConstants.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    title,
                    style: ThemeConstants.headingStyle.copyWith(
                      color:
                          hasImage ? Colors.white : ThemeConstants.textOnLight,
                      fontSize: 20,
                      shadows: hasImage
                          ? [
                              Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4),
                            ]
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14,
                          color: hasImage
                              ? Colors.white70
                              : ThemeConstants.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: ThemeConstants.captionStyle.copyWith(
                          color: hasImage
                              ? Colors.white70
                              : ThemeConstants.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: hasImage
                                ? Colors.white54
                                : ThemeConstants.textMuted,
                            shape: BoxShape.circle,
                          )),
                      const SizedBox(width: 12),
                      Text(
                        '$exerciseCount exercises',
                        style: ThemeConstants.captionStyle.copyWith(
                          color: hasImage
                              ? Colors.white70
                              : ThemeConstants.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Start Button overlay
            if (onStart != null)
              Positioned(
                bottom: 16,
                right: 16,
                child: InkWell(
                  onTap: onStart,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ThemeConstants.polyBlue500,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color:
                              ThemeConstants.polyBlue500.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Start',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
