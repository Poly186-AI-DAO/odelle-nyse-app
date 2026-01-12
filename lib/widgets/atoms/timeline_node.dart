import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class TimelineNode extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isActive;
  final Color? color;
  final double dotSize;
  final double lineWidth;

  const TimelineNode({
    super.key,
    this.isFirst = false,
    this.isLast = false,
    this.isActive = false,
    this.color,
    this.dotSize = 12.0,
    this.lineWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.primaryColor;
    
    return SizedBox(
      width: dotSize * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isFirst)
            Positioned(
              top: 0,
              bottom: dotSize,
              child: Container(
                width: lineWidth,
                color: ThemeConstants.glassBorderWeak,
              ),
            ),
          if (!isLast)
            Positioned(
              top: dotSize,
              bottom: 0,
              child: Container(
                width: lineWidth,
                color: ThemeConstants.glassBorderWeak,
              ),
            ),
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: isActive ? effectiveColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? effectiveColor : ThemeConstants.glassBorderStrong,
                width: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
