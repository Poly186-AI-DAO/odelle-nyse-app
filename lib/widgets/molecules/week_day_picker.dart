import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/theme_constants.dart';

/// A horizontal week day picker showing Mon-Sat/Sun with selected date highlighted
/// Based on the user's screenshot: "Let's make progress today!" with day pills
class WeekDayPicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final String? headerText;

  const WeekDayPicker({
    super.key,
    required this.selectedDate,
    this.onDateSelected,
    this.headerText,
  });

  @override
  Widget build(BuildContext context) {
    // Get the start of the week (Monday)
    final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header text
        if (headerText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  headerText!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: ThemeConstants.textMuted,
                ),
              ],
            ),
          ),
        
        // Day pills row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            final date = weekStart.add(Duration(days: index));
            final isSelected = date.day == selectedDate.day &&
                date.month == selectedDate.month &&
                date.year == selectedDate.year;
            final isToday = _isToday(date);
            
            return _buildDayPill(
              date: date,
              isSelected: isSelected,
              isToday: isToday,
            );
          }),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day && date.month == now.month && date.year == now.year;
  }

  Widget _buildDayPill({
    required DateTime date,
    required bool isSelected,
    required bool isToday,
  }) {
    final dayName = _getDayName(date.weekday);
    
    return GestureDetector(
      onTap: () => onDateSelected?.call(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.textOnLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ThemeConstants.textOnLight
                : ThemeConstants.glassBorderWeak,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : ThemeConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : ThemeConstants.textOnLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
