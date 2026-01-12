import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';

class ContentCard extends StatelessWidget {
  final String title;
  final String author;
  final String duration;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isLocked;

  const ContentCard({
    super.key,
    required this.title,
    required this.author,
    required this.duration,
    this.imageUrl,
    this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: ThemeConstants.glassBackground, // Fallback
                borderRadius: ThemeConstants.borderRadius,
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                        colorFilter: isLocked
                            ? ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.5), BlendMode.darken)
                            : null,
                      )
                    : null,
                boxShadow: imageUrl != null ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: isLocked
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock, color: Colors.white, size: 20),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: ThemeConstants.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Meta
            Row(
              children: [
                Text(
                  duration,
                  style: ThemeConstants.captionStyle.copyWith(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                      color: ThemeConstants.textMuted, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    author,
                    style: ThemeConstants.captionStyle.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
