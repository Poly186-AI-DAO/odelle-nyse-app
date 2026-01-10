import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/theme_constants.dart';
import '../models/character_stats.dart';
import '../models/protocol_entry.dart';
import '../providers/service_providers.dart';
import '../utils/logger.dart';
import '../widgets/dashboard/hero_number.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/protocol/protocol_button.dart';

/// Body Screen - Physical tracking pillar
/// Gym, Meal, Dose protocols with XP tracking
class BodyScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const BodyScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  static const String _tag = 'BodyScreen';
  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _monthLabels = [
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
    'Dec',
  ];

  CharacterStats? _stats;
  List<ProtocolEntry> _todayProtocols = [];
  late DateTime _selectedDate;

  // Protocol definitions
  static const List<ProtocolType> _protocolTypes = [
    ProtocolType.gym,
    ProtocolType.meal,
    ProtocolType.dose,
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizeDate(DateTime.now());
    _loadData();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = _normalizeDate(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatSelectedDateLabel() {
    final today = _normalizeDate(DateTime.now());
    if (_isSameDay(_selectedDate, today)) {
      return 'Today';
    }

    final weekday = _weekdayLabels[_selectedDate.weekday - 1];
    final month = _monthLabels[_selectedDate.month - 1];
    return '$weekday, $month ${_selectedDate.day}';
  }

  Future<void> _setSelectedDate(DateTime date) async {
    final normalized = _normalizeDate(date);
    if (_isSameDay(normalized, _selectedDate)) {
      return;
    }

    setState(() {
      _selectedDate = normalized;
    });

    Logger.info('Selected body date changed',
        tag: _tag, data: {'date': normalized.toIso8601String()});
    await _loadData();
  }

  DateTime _timestampForSelectedDate() {
    final now = DateTime.now();
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final startOfDay = _selectedDate;
    final endOfDay = startOfDay.add(const Duration(days: 1));

    Logger.info('Loading body data',
        tag: _tag, data: {'date': startOfDay.toIso8601String()});

    final stats = await db.getCharacterStats(startOfDay);
    final protocols =
        await db.getProtocolEntries(startDate: startOfDay, endDate: endOfDay);

    if (mounted) {
      setState(() {
        _stats = stats ?? CharacterStats(date: startOfDay);
        _todayProtocols = protocols
            .where((p) =>
                p.type == ProtocolType.gym ||
                p.type == ProtocolType.meal ||
                p.type == ProtocolType.dose)
            .toList();
      });
    }
  }

  Future<void> _logProtocol(ProtocolType type) async {
    final db = ref.read(databaseProvider);
    await db.insertProtocolEntry(
      ProtocolEntry(
        timestamp: _timestampForSelectedDate(),
        type: type,
        notes: null,
      ),
    );
    await _loadData();
  }

  ProtocolButtonState _getProtocolState(ProtocolType type) {
    final count = _todayProtocols.where((p) => p.type == type).length;
    if (count == 0) return ProtocolButtonState.empty;
    if (count >= 3) return ProtocolButtonState.complete;
    return ProtocolButtonState.partial;
  }

  @override
  Widget build(BuildContext context) {
    // Use FloatingHeroCard with white bottom panel
    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
      bottomPanelPulseEnabled: true,
      // White bottom panel with stats and controls
      bottomPanel: _buildBottomPanel(),
      // Dark card content - Hero XP display at top
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 70), // Space for nav bar
            const SizedBox(height: 40),
            Center(child: _buildHeroXP()),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeekStrip(),
        const SizedBox(height: 16),
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROTOCOLS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _formatSelectedDateLabel(),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Protocol buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _protocolTypes.map((type) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildWhiteProtocolButton(type),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Stats row
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Row(
              children: [
                Expanded(
                    child: _buildWhiteStat(
                        'TODAY\'S LOGS', _todayProtocols.length.toString())),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildWhiteStat('LEVEL', '${_stats?.level ?? 1}')),
              ],
            ),
          ),
        ),

        // Recent activity
        if (_todayProtocols.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'RECENT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _todayProtocols.take(3).length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _todayProtocols[index];
              return _buildWhiteListItem(entry);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildWeekStrip() {
    final startOfWeek = _startOfWeek(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildDayChip(date),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayChip(DateTime date) {
    final isSelected = _isSameDay(date, _selectedDate);
    final label = _weekdayLabels[date.weekday - 1];

    return GestureDetector(
      onTap: () => _setSelectedDate(date),
      child: AnimatedContainer(
        key: ValueKey(date.toIso8601String()),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.grey[700] : Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.grey[900] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteProtocolButton(ProtocolType type) {
    final state = _getProtocolState(type);
    final isComplete = state == ProtocolButtonState.complete;

    return GestureDetector(
      onTap: () => _logProtocol(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isComplete ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isComplete ? const Color(0xFF81C784) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Column(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              type.displayName.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isComplete ? const Color(0xFF388E3C) : Colors.grey[600],
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteListItem(ProtocolEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(entry.type.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  _formatTime(entry.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroXP() {
    final xp = _stats?.totalXP ?? 0;

    return Column(
      children: [
        Text(
          'TOTAL XP',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ThemeConstants.textOnDark.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        HeroNumber(
          value: xp.toDouble(),
          decimalPlaces: 0,
          prefix: '',
          fontSize: 48,
          color: ThemeConstants.textOnDark,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: ThemeConstants.textOnDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Level ${_stats?.level ?? 1}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ThemeConstants.textOnDark.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
