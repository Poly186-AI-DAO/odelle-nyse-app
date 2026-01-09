import 'package:flutter/material.dart';
import '../constants/design_constants.dart';
import '../constants/theme_constants.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const ActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? ThemeConstants.primaryColor : Colors.transparent,
          foregroundColor:
              isPrimary ? ThemeConstants.polyBlack : ThemeConstants.polyWhite,
          elevation: isPrimary ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: ThemeConstants.polyWhite.withOpacity(0.3)),
          ),
        ),
        child: Text(
          label,
          style: DesignConstants.bodyL.copyWith(
            fontWeight: FontWeight.bold,
            color:
                isPrimary ? ThemeConstants.polyBlack : ThemeConstants.polyWhite,
          ),
        ),
      ),
    );
  }
}
