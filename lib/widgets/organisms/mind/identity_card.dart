import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';


class IdentityCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Map<String, String> astrology;
  final int lifePathNumber;
  final List<String> archetypes;
  final String psychograph;

  const IdentityCard({
    super.key,
    required this.stats,
    required this.astrology,
    required this.lifePathNumber,
    required this.archetypes,
    required this.psychograph,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D26), // Darker stats card
        borderRadius: ThemeConstants.borderRadiusXL,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IDENTITY MATRIX',
                style: ThemeConstants.captionStyle.copyWith(
                  letterSpacing: 2.0,
                  fontSize: 10,
                  color: ThemeConstants.accentBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildLifePathBadge(),
            ],
          ),
          const SizedBox(height: 24),
          
          // 3-Column Esoteric Data
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetaColumn('SUN', astrology['sun'] ?? '-'),
              _buildDivider(),
              _buildMetaColumn('MOON', astrology['moon'] ?? '-'),
              _buildDivider(),
              _buildMetaColumn('RISING', astrology['rising'] ?? '-'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Archetypes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: archetypes.map((arch) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                arch.toUpperCase(),
                style: ThemeConstants.captionStyle.copyWith(
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 24),

          // Psychograph Text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: ThemeConstants.borderRadius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 14, color: ThemeConstants.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'PSYCHOGRAPH',
                      style: ThemeConstants.captionStyle.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"$psychograph"',
                  style: ThemeConstants.bodyStyle.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifePathBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeConstants.polyPurple500.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeConstants.polyPurple500.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag, size: 12, color: ThemeConstants.polyPurple300),
          const SizedBox(width: 4),
          Text(
            'LIFE PATH $lifePathNumber',
            style: ThemeConstants.captionStyle.copyWith(
              fontSize: 10,
              color: ThemeConstants.polyPurple200,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: ThemeConstants.captionStyle.copyWith(
            fontSize: 10,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ThemeConstants.headingStyle.copyWith(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}
