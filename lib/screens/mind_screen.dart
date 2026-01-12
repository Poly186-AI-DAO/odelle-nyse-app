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
import 'mantra_screen.dart';
import 'meditation_screen.dart';

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
  Map<String, dynamic>? _sleepLog; // Fallback JSON
  Map<String, dynamic>? _identityData;
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
          healthKit.getMindfulMinutes(now),
        ]);

        _healthKitSleep = results[0] as SleepData?;
        _restingHeartRate = results[1] as int?;
        _mindfulMinutes = results[2] as Duration?;

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

      // 3. Load Identity / Character Stats
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
    final screenHeight = MediaQuery.of(context).size.height;
    final minPanelHeight = screenHeight * 0.38;
    final maxPanelHeight = screenHeight * 0.78;

    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
      bottomPanelMinHeight: minPanelHeight,
      bottomPanelMaxHeight: maxPanelHeight,
      bottomPanelShowHandle: true,
      bottomPanelPulseEnabled: true,
      bottomPanel: _buildBottomPanelContent(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 80), // Space for nav bar
              // Hero content at top, not centered
              _buildHeroContent(),
            ],
          ),
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

    // Archetypes can be a Map {ego, soul, self} or a List - handle both
    final archetypesRaw = _identityData!['archetypes'];
    List<String> archetypes = [];
    if (archetypesRaw is Map) {
      // Extract archetype values (ego, soul, self) from the map
      final archetypeMap = Map<String, dynamic>.from(archetypesRaw);
      if (archetypeMap['ego'] != null) {
        archetypes.add(archetypeMap['ego'].toString());
      }
      if (archetypeMap['soul'] != null) {
        archetypes.add(archetypeMap['soul'].toString());
      }
      if (archetypeMap['self'] != null) {
        archetypes.add(archetypeMap['self'].toString());
      }
    } else if (archetypesRaw is List) {
      archetypes = List<String>.from(archetypesRaw);
    }

    final numerology =
        Map<String, dynamic>.from(_identityData!['numerology'] ?? {});
    final lifePath = (numerology['lifePath'] as num?)?.toInt();
    final destiny = (numerology['destiny'] as num?)?.toInt();
    final birthNumber = (numerology['birthNumber'] as num?)?.toInt() ??
        (numerology['lifePath'] as num?)?.toInt();
    final mbti = _identityData!['mbti']?.toString() ?? '';

    return Column(
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

  /// Bottom panel content (white panel with logs)
  Widget _buildBottomPanelContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HealthKit Quick Stats
        if (_healthKitAvailable) ...[
          _buildHealthKitMindStats(),
          const SizedBox(height: 20),
        ],

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

        const SizedBox(height: 24),

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
      final deepPercentage = hasDeepData ? deepMinutes / durationMin : 0.0;
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
    return Row(
      children: [
        Expanded(
          child: _buildMindStatCard(
            Icons.self_improvement,
            ThemeConstants.polyMint400,
            '${_mindfulMinutes?.inMinutes ?? 0}',
            'mindful min',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMindStatCard(
            Icons.favorite,
            const Color(0xFFEF4444),
            '${_restingHeartRate ?? '--'}',
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
