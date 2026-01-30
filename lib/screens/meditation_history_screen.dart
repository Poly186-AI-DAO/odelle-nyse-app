import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../providers/viewmodels/daily_content_viewmodel.dart';
import '../providers/service_providers.dart';
import '../utils/logger.dart';
import 'meditation_detail_screen.dart';

/// Meditation History Screen - Browse and replay past meditation sessions.
/// Groups meditations by date with insights summary.
class MeditationHistoryScreen extends ConsumerStatefulWidget {
  const MeditationHistoryScreen({super.key});

  @override
  ConsumerState<MeditationHistoryScreen> createState() =>
      _MeditationHistoryScreenState();
}

class _MeditationHistoryScreenState
    extends ConsumerState<MeditationHistoryScreen> {
  Map<String, List<DailyMeditation>> _meditationsByDate = {};
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final viewModel = ref.read(dailyContentViewModelProvider.notifier);
      final history = await viewModel.fetchMeditationHistory(limit: 100);
      if (mounted) {
        setState(() {
          _meditationsByDate = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading meditation history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncFromElevenLabs() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final dailyContentService = ref.read(dailyContentServiceProvider);
      final result = await dailyContentService.syncFromElevenLabsHistory(
        daysBack: 30,
        uploadToFirebase: true,
        forceResync: true, // Force to fix corrupted data
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.synced > 0
                  ? 'Synced ${result.synced} audio files from ElevenLabs'
                  : 'No audio to sync - all files up to date',
            ),
            backgroundColor:
                result.synced > 0 ? Colors.green : ThemeConstants.accentBlue,
          ),
        );

        // Reload history to show updated audio availability
        if (result.synced > 0) {
          await _loadHistory();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  String _formatDateDisplay(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _getMeditationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'morning':
        return '🌅';
      case 'focus':
        return '🎯';
      case 'evening':
        return '🌙';
      case 'sleep':
        return '😴';
      case 'stress':
        return '🧘';
      default:
        return '🧠';
    }
  }

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
          'Meditation History',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.textOnLight,
          ),
        ),
        centerTitle: true,
        actions: [
          // Sync button to recover audio from ElevenLabs
          IconButton(
            icon: _isSyncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ThemeConstants.accentBlue,
                    ),
                  )
                : Icon(Icons.cloud_sync, color: ThemeConstants.accentBlue),
            tooltip: 'Sync audio from ElevenLabs',
            onPressed: _isSyncing ? null : _syncFromElevenLabs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_meditationsByDate.isEmpty) {
      return _buildEmptyState();
    }

    final sortedKeys = _meditationsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final totalSessions =
        _meditationsByDate.values.fold(0, (sum, list) => sum + list.length);
    final totalMinutes = _meditationsByDate.values.fold(
      0,
      (sum, list) => sum + list.fold(0, (s, m) => s + (m.durationMinutes)),
    );
    final uniqueDays = sortedKeys.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insights summary
          _buildInsightsSummary(
            totalSessions: totalSessions,
            totalMinutes: totalMinutes,
            uniqueDays: uniqueDays,
          ),
          const SizedBox(height: 24),

          // Section header
          _buildSectionHeader('PAST SESSIONS'),
          const SizedBox(height: 12),

          // Grouped meditation cards
          ...sortedKeys.map((dateKey) {
            final meditations = _meditationsByDate[dateKey]!;
            return _buildDayCard(dateKey, meditations);
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🧘',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            'No meditation history yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textOnLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a meditation to see it here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: ThemeConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSummary({
    required int totalSessions,
    required int totalMinutes,
    required int uniqueDays,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            '🧘',
            '$totalSessions',
            'sessions',
            const Color(0xFFE8F5E9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightCard(
            '⏱️',
            '$totalMinutes',
            'minutes',
            const Color(0xFFE3F2FD),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInsightCard(
            '📅',
            '$uniqueDays',
            'days',
            const Color(0xFFFFF3E0),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String emoji,
    String value,
    String label,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ThemeConstants.textOnLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ThemeConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: ThemeConstants.captionStyle.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDayCard(String dateKey, List<DailyMeditation> meditations) {
    final totalMinutes =
        meditations.fold(0, (sum, m) => sum + m.durationMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateDisplay(dateKey),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalMinutes min',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meditation items
          ...meditations.map((meditation) => _buildMeditationRow(meditation)),
        ],
      ),
    );
  }

  Widget _buildMeditationRow(DailyMeditation meditation) {
    final hasAudio =
        (meditation.audioPath != null && meditation.audioPath!.isNotEmpty) ||
            (meditation.audioUrl != null && meditation.audioUrl!.isNotEmpty);
    final hasImage =
        (meditation.imagePath != null && meditation.imagePath!.isNotEmpty) ||
            (meditation.imageUrl != null && meditation.imageUrl!.isNotEmpty);

    return InkWell(
      onTap: () => _openMeditation(meditation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: const Color(0xFFF5F5F5)),
          ),
        ),
        child: Row(
          children: [
            // Icon with image indicator
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getMeditationIcon(meditation.type),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                // Image indicator badge
                if (hasImage)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Title and duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meditation.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ThemeConstants.textOnLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${meditation.durationMinutes} min • ${meditation.type.toLowerCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: ThemeConstants.textSecondary,
                        ),
                      ),
                      // Audio availability indicator
                      if (!hasAudio) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.volume_off,
                          size: 14,
                          color: Colors.orange.shade400,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Play indicator (colored based on audio availability)
            Icon(
              hasAudio ? Icons.play_circle_outline : Icons.play_circle_outline,
              color: hasAudio
                  ? ThemeConstants.accentBlue
                  : ThemeConstants.textMuted,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _openMeditation(DailyMeditation meditation) {
    Logger.debug('Opening meditation from history', tag: 'AudioDebug', data: {
      'title': meditation.title,
      'audioPath': meditation.audioPath,
      'audioUrl': meditation.audioUrl,
      'imagePath': meditation.imagePath,
      'imageUrl': meditation.imageUrl,
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MeditationDetailScreen(
          title: meditation.title,
          duration: meditation.durationMinutes,
          type: meditation.meditationType,
          audioPath: meditation.audioPath,
          audioUrl: meditation.audioUrl,
          imagePath: meditation.imagePath,
          imageUrl: meditation.imageUrl,
        ),
      ),
    );
  }
}
