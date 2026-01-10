import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import '../../constants/design_constants.dart';
import '../glass/glass_card.dart';

class GlassChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime? timestamp;

  const GlassChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstants.spacingMedium,
            vertical: ThemeConstants.spacingSmall,
          ),
          borderRadius: DesignConstants.radiusLarge,
          backgroundColor: isUser
              ? ThemeConstants.polyPurple500.withValues(alpha: 0.2)
              : ThemeConstants.glassBackground,
          borderColor: isUser
              ? ThemeConstants.polyPurple300.withValues(alpha: 0.3)
              : ThemeConstants.glassBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: DesignConstants.bodyM.copyWith(
                  color: ThemeConstants.textColor,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTime(timestamp!),
                  style: DesignConstants.captionText.copyWith(
                    fontSize: 10,
                    color: ThemeConstants.mutedTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
