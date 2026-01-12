import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

enum StatusType { complete, partial, empty, locked }

class StatusDot extends StatelessWidget {
  final StatusType status;
  final double size;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColor(),
        shape: BoxShape.circle,
        border: status == StatusType.empty || status == StatusType.locked
            ? Border.all(color: ThemeConstants.glassBorderStrong, width: 1.5)
            : null,
      ),
      child: status == StatusType.locked
          ? Icon(Icons.lock, size: size * 0.6, color: ThemeConstants.textMuted)
          : null,
    );
  }

  Color _getColor() {
    switch (status) {
      case StatusType.complete:
        return ThemeConstants.accentGreen;
      case StatusType.partial:
        return ThemeConstants.uiWarning;
      case StatusType.empty:
        return Colors.transparent;
      case StatusType.locked:
        return ThemeConstants.glassBackgroundWeak;
    }
  }
}
