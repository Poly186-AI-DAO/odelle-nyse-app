import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../widgets/widgets.dart';
import '../widgets/effects/breathing_card.dart';
import '../providers/viewmodels/viewmodels.dart';
import 'chat_screen.dart';
import 'mantra_screen.dart';
import 'meditation_screen.dart';

class MindScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const MindScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends ConsumerState<MindScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mindViewModelProvider.notifier).loadData(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mindViewModelProvider);
    final viewModel = ref.read(mindViewModelProvider.notifier);

    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;

    // Min panel: 38% of screen
    final minPanelHeight = screenHeight * 0.38;
    // Max panel: Leave room for nav bar + compact stats + padding
    final maxPanelHeight = screenHeight - safeTop - 70 - 100;

    // Calculate stats card position using BOTTOM coordinate
    // At rest: card's bottom edge is 20px above panel top
    // At expanded: card sits 16px above the expanded panel
    final cardBottomAtRest = minPanelHeight + 20;
    final cardBottomAtExpanded = maxPanelHeight + 16;

    // Smoothly interpolate using bottom coordinate
    final cardBottom = cardBottomAtRest +
        (state.panelProgress * (cardBottomAtExpanded - cardBottomAtRest));

    // Content crossfade (full card content vs compact bar content)
    final showFullCard = state.panelProgress < 0.6;

    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
      bottomPanelMinHeight: minPanelHeight,
      bottomPanelMaxHeight: maxPanelHeight,
      bottomPanelShowHandle: true,
      bottomPanelPulseEnabled: true,
      bottomPanelProgressChanged: (progress) {
        viewModel.setPanelProgress(progress);
      },
      bottomPanel: _buildBottomPanelContent(context, state, viewModel),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Single animated stats card that moves and transforms
            if (!state.isLoading)
              Positioned(
                left: 20,
                right: 20,
                bottom: cardBottom,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: showFullCard
                      ? _buildHeroContent(state)
                      : _buildCompactCosmicBar(state),
                ),
              ),

            // Loading indicator
            if (state.isLoading && state.identityData == null)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  /// Hero content (Identity Matrix on dark breathing card)
  Widget _buildHeroContent(MindState state) {
    if (state.identityData == null) {
      return Container(
        key: const ValueKey('full-empty'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: ThemeConstants.borderRadiusXL,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          'Good Evening',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      );
    }

    final identity = state.identityData!;
    final astrology = Map<String, String>.from(identity['astrology'] ?? {});

    // Archetypes logic
    final archetypesRaw = identity['archetypes'];
    List<String> archetypes = [];
    if (archetypesRaw is Map) {
      final archetypeMap = Map<String, dynamic>.from(archetypesRaw);
      if (archetypeMap['ego'] != null)
        archetypes.add(archetypeMap['ego'].toString());
      if (archetypeMap['soul'] != null)
        archetypes.add(archetypeMap['soul'].toString());
      if (archetypeMap['self'] != null)
        archetypes.add(archetypeMap['self'].toString());
    } else if (archetypesRaw is List) {
      archetypes = List<String>.from(archetypesRaw);
    }

    final numerology = Map<String, dynamic>.from(identity['numerology'] ?? {});
    final lifePath = (numerology['lifePath'] as num?)?.toInt();
    final destiny = (numerology['destiny'] as num?)?.toInt();
    final birthNumber = (numerology['birthNumber'] as num?)?.toInt() ??
        (numerology['lifePath'] as num?)?.toInt();
    final mbti = identity['mbti']?.toString() ?? '';

    return Column(
      key: const ValueKey('full'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'COSMIC STATS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        _buildCosmicStatsCard(
          astrology: astrology,
          lifePath: lifePath,
          destiny: destiny,
          birthNumber: birthNumber,
          mbti: mbti,
        ),
        if (archetypes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: archetypes
                .map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        a.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  /// Compact cosmic bar - shown when panel is expanded
  Widget _buildCompactCosmicBar(MindState state) {
    if (state.identityData == null) {
      return Container(
        key: const ValueKey('compact-empty'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          '✨ Loading...',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      );
    }

    final identity = state.identityData!;
    final astrology = Map<String, String>.from(identity['astrology'] ?? {});
    final numerology = Map<String, dynamic>.from(identity['numerology'] ?? {});
    final lifePath = (numerology['lifePath'] as num?)?.toInt();
    final mbti = identity['mbti']?.toString() ?? '';

    return Container(
      key: const ValueKey('compact'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat('☀️', astrology['sun'] ?? '--'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat('🔢', lifePath?.toString() ?? '--'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat('🧠', mbti.isNotEmpty ? mbti : '--'),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCosmicStatsCard({
    required Map<String, String> astrology,
    required int? lifePath,
    required int? destiny,
    required int? birthNumber,
    required String mbti,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: ThemeConstants.borderRadiusXL,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCosmicValue('BIRTH #', _formatNumber(birthNumber)),
              _buildCosmicValue('LIFE PATH', _formatNumber(lifePath)),
              _buildCosmicValue('DESTINY', _formatNumber(destiny)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCosmicValue('SUN', astrology['sun'] ?? '--'),
              _buildCosmicValue('MOON', astrology['moon'] ?? '--'),
              _buildCosmicValue('RISING', astrology['rising'] ?? '--'),
            ],
          ),
          if (mbti.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildCosmicTag('MBTI', mbti),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCosmicValue(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCosmicTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$label $value',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _formatNumber(int? value) {
    if (value == null || value <= 0) return '--';
    return value.toString();
  }

  /// Bottom panel content
  Widget _buildBottomPanelContent(
      BuildContext context, MindState state, MindViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HealthKit Quick Stats
        // Show if we have any data
        if (state.mindfulMinutes != null || state.restingHeartRate != null) ...[
          _buildHealthKitMindStats(state),
          const SizedBox(height: 20),
        ],

        // Schedule / Week Day Picker
        WeekDayPicker(
          selectedDate: state.selectedDate,
          headerText: "Your day ahead",
          onDateSelected: (date) {
            viewModel.selectDate(date);
          },
        ),

        const SizedBox(height: 20),

        // Sleep Card
        _buildSleepCard(state),

        const SizedBox(height: 24),

        // Protocols
        _buildSectionHeader('OPEN PROTOCOLS'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildProtocolButton(
                    'NTS', Icons.sticky_note_2_outlined, Colors.amber, () {
              // Note to Self - digital twin reflection
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChatScreen(),
                ),
              );
            })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildProtocolButton(
                    'Breathe', Icons.air, Colors.cyan, () {})),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildProtocolButton(
                    'Mantras', Icons.auto_awesome, ThemeConstants.polyMint400,
                    () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MantraScreen(),
                ),
              );
            })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildProtocolButton('Meditate', Icons.self_improvement,
                    ThemeConstants.polyPurple300, () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MeditationScreen(),
                ),
              );
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ThemeConstants.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildProtocolButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: ThemeConstants.borderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: ThemeConstants.borderRadius,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ThemeConstants.textOnLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(MindState state) {
    // Prioritize HealthKit data
    if (state.sleepData != null) {
      final sleep = state.sleepData!;
      final totalMinutes = sleep.totalDuration.inMinutes;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      final awakeMinutes = sleep.awake?.inMinutes;
      final deepMinutes = sleep.deepSleep?.inMinutes;
      final hasDeepData = deepMinutes != null && totalMinutes > 0;
      final deepPercentage = hasDeepData ? deepMinutes / totalMinutes : 0.0;
      final deepLabel = hasDeepData ? null : 'Deep Sleep: --';

      return SleepCard(
        totalSleep: '${hours}h ${minutes}m',
        sleepScore: sleep.qualityScore,
        timeAsleep: '${hours}h ${minutes}m',
        timeAwake: awakeMinutes != null ? '${awakeMinutes}m' : '--',
        deepSleepPercentage: deepPercentage,
        deepSleepLabel: deepLabel,
      );
    }

    // Fallback to JSON data
    if (state.sleepLogFallback != null) {
      final sleepLog = state.sleepLogFallback!;
      final startTime =
          DateTime.tryParse((sleepLog['start_time'] ?? '') as String);
      final endTime = DateTime.tryParse((sleepLog['end_time'] ?? '') as String);
      final durationMin = startTime != null && endTime != null
          ? endTime.difference(startTime).inMinutes
          : ((sleepLog['duration_minutes'] ?? 0) as num).toInt();
      final deepMinutes = (sleepLog['deep_sleep_minutes'] as num?)?.toInt();
      final hasDeepData = deepMinutes != null && durationMin > 0;
      final deepPercentage = hasDeepData ? deepMinutes / durationMin : 0.0;
      final deepLabel = hasDeepData ? null : 'Deep Sleep: --';
      return SleepCard(
        totalSleep: '${durationMin ~/ 60}h ${durationMin % 60}m',
        sleepScore: ((sleepLog['quality_score'] ?? 85) as num).toInt(),
        timeAsleep: '${durationMin ~/ 60}h ${durationMin % 60}m',
        timeAwake: '--',
        deepSleepPercentage: deepPercentage,
        deepSleepLabel: deepLabel,
      );
    }

    // No sleep data available
    return const SizedBox.shrink();
  }

  Widget _buildHealthKitMindStats(MindState state) {
    return Row(
      children: [
        Expanded(
          child: _buildMindStatCard(
            Icons.self_improvement,
            ThemeConstants.polyMint400,
            '${state.mindfulMinutes?.inMinutes ?? 0}',
            'mindful min',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMindStatCard(
            Icons.favorite,
            const Color(0xFFEF4444),
            '${state.restingHeartRate ?? '--'}',
            'resting HR',
          ),
        ),
      ],
    );
  }

  Widget _buildMindStatCard(
      IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeConstants.glassBorderWeak),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textOnLight,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: ThemeConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
