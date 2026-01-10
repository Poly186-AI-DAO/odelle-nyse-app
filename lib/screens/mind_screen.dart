import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../database/app_database.dart';
import '../models/protocol_entry.dart';
import '../utils/logger.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/protocol/protocol_button.dart';

/// Mind Screen - Mental/cognitive pillar
/// Meditation, mantras, mindset tracking
class MindScreen extends StatefulWidget {
  final double panelVisibility;

  const MindScreen({super.key, this.panelVisibility = 1.0});

  @override
  State<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends State<MindScreen> {
  static const String _tag = 'MindScreen';
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

  List<ProtocolEntry> _todayProtocols = [];
  String _dailyMantra = '';
  late DateTime _selectedDate;

  // Sample mantras - will be user-customizable later
  static const List<String> _mantras = [
    'I am focused and productive.',
    'I create value with every action.',
    'I am becoming the person I want to be.',
    'My potential is unlimited.',
    'I choose growth over comfort.',
    'I am in control of my thoughts.',
    'Today I make progress.',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizeDate(DateTime.now());
    _dailyMantra = _mantraForDate(_selectedDate);
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

  String _mantraForDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    final index = dayOfYear % _mantras.length;
    return _mantras[index];
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
      _dailyMantra = _mantraForDate(normalized);
    });

    Logger.info('Selected mind date changed',
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
    final db = context.read<AppDatabase>();
    final startOfDay = _selectedDate;
    final endOfDay = startOfDay.add(const Duration(days: 1));

    Logger.info('Loading mind data',
        tag: _tag, data: {'date': startOfDay.toIso8601String()});

    final protocols = await db.getProtocolEntries(
      type: ProtocolType.meditation,
      startDate: startOfDay,
      endDate: endOfDay,
    );

    if (mounted) {
      setState(() {
        _todayProtocols = protocols;
      });
    }
  }

  Future<void> _logProtocol(ProtocolType type) async {
    final db = context.read<AppDatabase>();
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
    if (count >= 1) return ProtocolButtonState.complete;
    return ProtocolButtonState.partial;
  }

  @override
  Widget build(BuildContext context) {
    // Use FloatingHeroCard for the floating design
    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
      bottomPanelPulseEnabled: true,
      bottomPanel: _buildBottomPanel(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 70), // Space for nav bar
              const SizedBox(height: 20),

              // Daily mantra
              _buildMantraSection(),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMantraSection() {
    return Column(
      children: [
        Text(
          'TODAY\'S MANTRA',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ThemeConstants.textOnDark.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),

        // Mantra text with quotes
        Text(
          '"$_dailyMantra"',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            color: ThemeConstants.textOnDark,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeekStrip(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEDITATION',
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
        Center(
          child: SizedBox(
            width: 120,
            child: _buildWhiteProtocolButton(ProtocolType.meditation),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Row(
              children: [
                Expanded(
                  child: _buildWhiteStat(
                    'SESSIONS TODAY',
                    _todayProtocols.length.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWhiteStat(
                    'MIND LEVEL',
                    '${(_todayProtocols.length * 10) + 1}',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'SESSIONS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_todayProtocols.isEmpty)
          Center(
            child: Text(
              'No meditation sessions yet.\nTap to log one!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _todayProtocols.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _todayProtocols[index];
              return _buildWhiteListItem(entry);
            },
          ),
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
          Text(
            entry.type.emoji,
            style: const TextStyle(fontSize: 20),
          ),
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

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
