import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import '../providers/viewmodels/viewmodels.dart';
import '../widgets/atoms/odelle_button.dart';
import 'meditation_detail_screen.dart';

class MeditationScreen extends ConsumerStatefulWidget {
  const MeditationScreen({super.key});

  @override
  ConsumerState<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends ConsumerState<MeditationScreen> {
  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyContentViewModelProvider);
    final meditations = dailyState.meditations;
    final featured = meditations.isNotEmpty ? meditations.first : null;
    final suggestions = meditations.length > 1
        ? meditations.sublist(1)
        : const <DailyMeditation>[];

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
            if (featured != null)
              _buildFeaturedCard(featured)
            else
              _buildEmptyCard('Today\'s meditation is still generating...'),
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
            if (suggestions.isEmpty)
              _buildEmptyCard('Meditation suggestions are on the way.')
            else
              ...suggestions.map((data) => _buildSuggestionCard(data)),
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

  Widget _buildFeaturedCard(DailyMeditation data) {
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
                  data.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                Text(
                  '${data.durationMinutes} mins',
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
              data.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ThemeConstants.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                _buildTag(data.type),
                _buildTag('${data.durationMinutes} min'),
              ],
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

  Widget _buildSuggestionCard(DailyMeditation data) {
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildThumbnail(data.imagePath),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ThemeConstants.textOnLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.durationMinutes} mins • ${data.meditationType.displayName}',
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

  void _navigateToDetail(DailyMeditation data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MeditationDetailScreen(
          title: data.title,
          duration: data.durationMinutes,
          type: data.meditationType,
          audioPath: data.audioPath,
          imagePath: data.imagePath,
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ThemeConstants.textSecondary,
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? imagePath) {
    if (imagePath != null && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      );
    }

    return Center(
      child: Icon(
        Icons.self_improvement,
        color: ThemeConstants.polyMint400,
        size: 28,
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ThemeConstants.glassBorderWeak),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: ThemeConstants.textSecondary,
        ),
      ),
    );
  }
}
