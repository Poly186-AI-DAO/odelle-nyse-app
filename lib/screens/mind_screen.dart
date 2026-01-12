import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../widgets/widgets.dart';
import '../widgets/effects/breathing_card.dart';
import '../services/health_kit_service.dart';
import '../providers/service_providers.dart';

class MindScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const MindScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends ConsumerState<MindScreen> {
  // Data State
  SleepData? _healthKitSleep; // From HealthKit
  bool _healthKitAvailable = false;
  int? _restingHeartRate;
  int _steps = 0;
  Map<String, dynamic>? _sleepLog; // Fallback JSON
  Map<String, dynamic>? _identityData;
  List<dynamic> _lessons = [];
  Duration? _mindfulMinutes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Try to get health data from HealthKit first
      final healthKit = ref.read(healthKitServiceProvider);
      final authorized = await healthKit.requestAuthorization();

      if (authorized) {
        _healthKitAvailable = true;
        final now = DateTime.now();

        // Fetch all mind-related health data in parallel
        final results = await Future.wait([
          healthKit.getLastNightSleep(),
          healthKit.getRestingHeartRate(),
          healthKit.getSteps(now),
          healthKit.getMindfulMinutes(now),
        ]);

        _healthKitSleep = results[0] as SleepData?;
        _restingHeartRate = results[1] as int?;
        _steps = results[2] as int;
        _mindfulMinutes = results[3] as Duration?;

        debugPrint(
            '[MindScreen] HealthKit sleep: ${_healthKitSleep?.totalDuration.inMinutes} min');
        debugPrint('[MindScreen] HealthKit resting HR: $_restingHeartRate bpm');
        debugPrint(
            '[MindScreen] HealthKit mindful: ${_mindfulMinutes?.inMinutes} min');
      }

      // 2. Fallback to JSON if no HealthKit data
      if (_healthKitSleep == null) {
        final sleepJson =
            await rootBundle.loadString('data/tracking/sleep_log.json');
        final List<dynamic> sleepList = json.decode(sleepJson);
        if (sleepList.isNotEmpty) {
          _sleepLog = sleepList.last;
        }
      }

      // 3. Load Content (Lessons)
      final lessonJson =
          await rootBundle.loadString('data/content/lesson.json');
      _lessons = json.decode(lessonJson);

      // 4. Load Identity / Character Stats
      final identityJson =
          await rootBundle.loadString('data/misc/character_stats.json');
      final List<dynamic> identityList = json.decode(identityJson);
      if (identityList.isNotEmpty) {
        _identityData = identityList.last;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mind data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
      bottomPanelMinHeight: MediaQuery.of(context).size.height * 0.38,
      bottomPanelMaxHeight: MediaQuery.of(context).size.height * 0.78,
      bottomPanelShowHandle: true,
      bottomPanelPulseEnabled: true,
      bottomPanel: _buildBottomPanelContent(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 70),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildHeroContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hero content (Identity Matrix on dark breathing card)
  Widget _buildHeroContent() {
    if (_identityData == null) {
      return Text(
        'Good Evening',
        style: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: Colors.white,
        ),
      );
    }

    final astrology =
        Map<String, String>.from(_identityData!['astrology'] ?? {});
    final archetypes = List<String>.from(_identityData!['archetypes'] ?? []);
    final lifePath = _identityData!['numerology']?['lifePath'] ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Archetype badges
        Wrap(
          spacing: 8,
          children: archetypes
              .map((a) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        const SizedBox(height: 24),

        // Astrology display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAstroColumn('☉', astrology['sun'] ?? '-'),
            const SizedBox(width: 32),
            _buildAstroColumn('☽', astrology['moon'] ?? '-'),
            const SizedBox(width: 32),
            _buildAstroColumn('↑', astrology['rising'] ?? '-'),
          ],
        ),
        const SizedBox(height: 24),

        // Life path
        Text(
          'LIFE PATH $lifePath',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.polyPurple300,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildAstroColumn(String symbol, String sign) {
    return Column(
      children: [
        Text(symbol,
            style: const TextStyle(fontSize: 24, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(
          sign,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Bottom panel content (white panel with logs)
  Widget _buildBottomPanelContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schedule / Week Day Picker
        WeekDayPicker(
          selectedDate: DateTime.now(),
          headerText: "Your day ahead",
          onDateSelected: (date) {
            // TODO: Filter data by selected date
          },
        ),

        const SizedBox(height: 20),

        // Sleep Card - prioritize HealthKit over JSON
        _buildSleepCard(),

        const SizedBox(height: 16),

        // HealthKit Quick Stats (if available)
        if (_healthKitAvailable) ...[
          _buildHealthKitMindStats(),
          const SizedBox(height: 24),
        ],

        // Protocols
        _buildSectionHeader('OPEN PROTOCOLS'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildProtocolButton(
                    'Journal', Icons.edit_note, Colors.amber, () {})),
            const SizedBox(width: 12),
            Expanded(
                child: _buildProtocolButton(
                    'Breathe', Icons.air, Colors.cyan, () {})),
          ],
        ),

        const SizedBox(height: 24),

        // Continue Learning
        _buildSectionHeader('CONTINUE LEARNING'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _lessons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              return ContentCard(
                title: lesson['title'] ?? 'Untitled',
                author: 'Dr. Huberman',
                duration:
                    '${lesson['duration_seconds'] != null ? lesson['duration_seconds'] ~/ 60 : 10} min',
                imageUrl: index % 2 == 0
                    ? 'https://images.unsplash.com/photo-1515023115689-589c33041697?auto=format&fit=crop&w=1200&q=80'
                    : 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?auto=format&fit=crop&w=1200&q=80',
                onTap: () {},
              );
            },
          ),
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
          color: ThemeConstants.glassBackgroundWeak,
          borderRadius: ThemeConstants.borderRadius,
          border: Border.all(color: ThemeConstants.glassBorderWeak),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: ThemeConstants.buttonTextStyle.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds SleepCard using HealthKit data if available, otherwise falls back to JSON
  Widget _buildSleepCard() {
    // Prioritize HealthKit data
    if (_healthKitSleep != null) {
      final sleep = _healthKitSleep!;
      final totalMinutes = sleep.totalDuration.inMinutes;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      final awakeMinutes = sleep.awake?.inMinutes;
      final deepMinutes = sleep.deepSleep?.inMinutes;
      final hasDeepData = deepMinutes != null && totalMinutes > 0;
      final deepPercentage =
          hasDeepData ? deepMinutes / totalMinutes : 0.0;
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
    if (_sleepLog != null) {
      final startTime =
          DateTime.tryParse((_sleepLog!['start_time'] ?? '') as String);
      final endTime =
          DateTime.tryParse((_sleepLog!['end_time'] ?? '') as String);
      final durationMin = startTime != null && endTime != null
          ? endTime.difference(startTime).inMinutes
          : ((_sleepLog!['duration_minutes'] ?? 0) as num).toInt();
      final deepMinutes = (_sleepLog!['deep_sleep_minutes'] as num?)?.toInt();
      final hasDeepData = deepMinutes != null && durationMin > 0;
      final deepPercentage =
          hasDeepData ? deepMinutes / durationMin : 0.0;
      final deepLabel = hasDeepData ? null : 'Deep Sleep: --';
      return SleepCard(
        totalSleep: '${durationMin ~/ 60}h ${durationMin % 60}m',
        sleepScore: ((_sleepLog!['quality_score'] ?? 85) as num).toInt(),
        timeAsleep: '${durationMin ~/ 60}h ${durationMin % 60}m',
        timeAwake: '--',
        deepSleepPercentage: deepPercentage,
        deepSleepLabel: deepLabel,
      );
    }

    // No sleep data available
    return const SizedBox.shrink();
  }

  /// Build HealthKit mind-related stats row
  Widget _buildHealthKitMindStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackgroundWeak,
        borderRadius: ThemeConstants.borderRadius,
        border: Border.all(color: ThemeConstants.glassBorderWeak),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMindStat(
              '🧘', '${_mindfulMinutes?.inMinutes ?? 0}', 'mindful min'),
          _buildMindStat('❤️', '${_restingHeartRate ?? '--'}', 'resting HR'),
          _buildMindStat('👟', '$_steps', 'steps'),
        ],
      ),
    );
  }

  Widget _buildMindStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
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
    );
  }
}
