import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import '../providers/viewmodels/viewmodels.dart';
import '../widgets/atoms/odelle_button.dart';
import 'meditation_detail_screen.dart';
import 'meditation_history_screen.dart';

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
    final pendingGeneration = dailyState.pendingGeneration;
    final isGenerating = dailyState.isGenerating;
    final quotaInfo = dailyState.quotaInfo;

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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MeditationHistoryScreen(),
                ),
              );
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

            // Pending Generation Approval Card
            if (pendingGeneration && !isGenerating)
              _buildPendingGenerationCard(quotaInfo),
            if (isGenerating) _buildGeneratingCard(),

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
            else if (pendingGeneration || isGenerating)
              _buildEmptyCard(isGenerating
                  ? 'Generating your meditation...'
                  : 'Tap above to generate today\'s meditation')
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

  Widget _buildPendingGenerationCard(Map<String, dynamic>? quotaInfo) {
    final remaining = quotaInfo?['remaining'];
    final quotaText = remaining != null
        ? '${(remaining / 1000).toStringAsFixed(0)}k characters remaining'
        : 'Quota info unavailable';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8F5E9),
            const Color(0xFFC8E6C9),
          ],
        ),
        border: Border.all(color: const Color(0xFF81C784), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate Today\'s Meditations',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textOnLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quotaText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Create personalized meditation sessions with AI-generated scripts and calming voice guidance.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: ThemeConstants.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(dailyContentViewModelProvider.notifier)
                    .generateContent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Generate Meditations',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generating your meditations...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creating scripts and voice audio. This may take a moment.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ThemeConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          audioUrl: data.audioUrl,
          imagePath: data.imagePath,
          imageUrl: data.imageUrl,
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
