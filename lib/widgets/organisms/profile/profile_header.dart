import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../atoms/avatar.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String bio;
  final String location;
  final String? avatarUrl;
  final int totalWorkouts;
  final int totalMindfulness;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.bio,
    required this.location,
    this.avatarUrl,
    this.totalWorkouts = 0,
    this.totalMindfulness = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Avatar(
          imageUrl: avatarUrl,
          fallbackText: name,
          size: 100,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: ThemeConstants.headingStyle.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          location,
          style: ThemeConstants.captionStyle,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            bio,
            textAlign: TextAlign.center,
            style: ThemeConstants.bodyStyle.copyWith(
              color: ThemeConstants.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat('Workouts', totalWorkouts.toString()),
            Container(
              height: 24,
              width: 1,
              color: ThemeConstants.glassBorderStrong,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            _buildStat('Mindfulness', totalMindfulness.toString()),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: ThemeConstants.headingStyle.copyWith(fontSize: 20),
        ),
        Text(
          label.toUpperCase(),
          style: ThemeConstants.captionStyle.copyWith(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
