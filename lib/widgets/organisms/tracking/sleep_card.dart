import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../atoms/icon_badge.dart';

class SleepCard extends StatelessWidget {
  final String totalSleep; // e.g. "7h 30m"
  final int sleepScore;    // 0-100
  final String timeAsleep;
  final String timeAwake;
  final double deepSleepPercentage; // 0.0 - 1.0 (for mini bar)

  const SleepCard({
    super.key,
    required this.totalSleep,
    required this.sleepScore,
    required this.timeAsleep,
    required this.timeAwake,
    this.deepSleepPercentage = 0.2, // Default 20%
  });

  @override
  Widget build(BuildContext context) {
    Color scoreColor = ThemeConstants.accentGreen;
    if (sleepScore < 60) scoreColor = ThemeConstants.uiError;
    else if (sleepScore < 80) scoreColor = ThemeConstants.uiWarning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10142C), // Deep midnight blue for Sleep context
        borderRadius: ThemeConstants.borderRadiusXL,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10142C).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const IconBadge(
                    icon: Icons.bedtime,
                    color: Color(0xFF7C8CFF), // Sleepy Lavender
                    size: 40,
                    isActive: false, 
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Night',
                        style: ThemeConstants.captionStyle.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                      Text(
                        totalSleep,
                        style: ThemeConstants.headingStyle.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Score $sleepScore',
                  style: ThemeConstants.captionStyle.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Mini sleep bar visualization
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(flex: (deepSleepPercentage * 100).toInt(), child: Container(height: 8, color: const Color(0xFF4A4E8C))), // Deep
                Expanded(flex: 100 - (deepSleepPercentage * 100).toInt(), child: Container(height: 8, color: const Color(0xFF7C8CFF))), // Light
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(deepSleepPercentage * 100).toInt()}% Deep Sleep', style: ThemeConstants.captionStyle.copyWith(color: Colors.white38, fontSize: 10)),
              Text('Awake: $timeAwake', style: ThemeConstants.captionStyle.copyWith(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
