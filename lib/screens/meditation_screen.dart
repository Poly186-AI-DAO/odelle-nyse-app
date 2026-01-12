import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import '../models/tracking/meditation_log.dart';
import '../widgets/atoms/odelle_button.dart';
import 'meditation_detail_screen.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  // Mock data for suggestions
  final List<Map<String, dynamic>> _suggestions = [
    {
      'title': 'Gentle Grounding',
      'duration': 10,
      'type': MeditationType.mindfulness,
      'tags': ['Calm', 'Breath', 'Presence'],
      'image': 'assets/images/meditation_grounding.png', // Placeholder
    },
    {
      'title': 'Sleep Preparation',
      'duration': 15,
      'type': MeditationType.bodyScan,
      'tags': ['Sleep', 'Relax', 'Body Scan'],
      'image': 'assets/images/meditation_sleep.png', // Placeholder
    },
    {
      'title': 'Morning Energy',
      'duration': 5,
      'type': MeditationType.breathing,
      'tags': ['Energy', 'Focus', 'Morning'],
      'image': 'assets/images/meditation_morning.png', // Placeholder
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.panelWhite,
      appBar: AppBar(
        backgroundColor: ThemeConstants.panelWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ThemeConstants.textOnLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Meditation',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.textOnLight,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: ThemeConstants.textOnLight),
            onPressed: () {
              // TODO: Navigate to history
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card "Find your peaceful moment"
            _buildHeroCard(),
            const SizedBox(height: 32),

            // Today's Recommendation
            Text(
              "TODAY'S MEDITATION",
              style: ThemeConstants.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeaturedCard(),
            const SizedBox(height: 32),

            // Suggestions List
            Text(
              "SUGGESTIONS FOR YOU",
              style: ThemeConstants.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ..._suggestions.map((data) => _buildSuggestionCard(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConstants.polyPurple400,
            ThemeConstants.deepNavy,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Find your peaceful moment',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a few quiet moments to return to yourself.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    final data = _suggestions[0];
    return GestureDetector(
      onTap: () => _navigateToDetail(data),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: ThemeConstants.glassBorderWeak),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['title'],
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                Text(
                  '${data['duration']} mins',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFFB347), // Orange accent
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Release the weight of the day and settle into peaceful stillness. A gentle guided journey to help you transition into rest.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ThemeConstants.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: (data['tags'] as List).map<Widget>((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            OdelleButtonFullWidth.primary(
              text: 'Begin Meditation',
              onPressed: () => _navigateToDetail(data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => _navigateToDetail(data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeConstants.glassBorderWeak),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ThemeConstants.polyMint400.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.self_improvement,
                color: ThemeConstants.polyMint400,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeConstants.textOnLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data['duration']} mins • ${(data['type'] as MeditationType).displayName}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ThemeConstants.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MeditationDetailScreen(
          title: data['title'],
          duration: data['duration'],
          type: data['type'],
        ),
      ),
    );
  }
}
