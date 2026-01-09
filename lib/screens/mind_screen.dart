import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../database/app_database.dart';
import '../models/protocol_entry.dart';
import '../widgets/protocol/protocol_button.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/panels/bottom_panel.dart';
import '../widgets/list/expandable_list_item.dart';

/// Mind Screen - Mental/cognitive pillar
/// Meditation, mantras, mindset tracking
class MindScreen extends StatefulWidget {
  const MindScreen({super.key});

  @override
  State<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends State<MindScreen> {
  List<ProtocolEntry> _todayProtocols = [];
  String _dailyMantra = '';

  // Mind-related protocols
  static const List<ProtocolType> _protocolTypes = [
    ProtocolType.meditation,
  ];

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
    _loadData();
    _selectDailyMantra();
  }

  void _selectDailyMantra() {
    // Select a mantra based on day of year for consistency
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final index = dayOfYear % _mantras.length;
    setState(() {
      _dailyMantra = _mantras[index];
    });
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    final protocols = await db.getTodayProtocolEntries();

    if (mounted) {
      setState(() {
        _todayProtocols =
            protocols.where((p) => p.type == ProtocolType.meditation).toList();
      });
    }
  }

  Future<void> _logProtocol(ProtocolType type) async {
    final db = context.read<AppDatabase>();
    await db.insertProtocolEntry(
      ProtocolEntry(
        timestamp: DateTime.now(),
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
    return Column(
      children: [
        const SizedBox(height: 40),

        // Daily mantra
        _buildMantraSection(),

        const Spacer(),

        // Bottom panel with protocols
        _buildBottomPanel(),
      ],
    );
  }

  Widget _buildMantraSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
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
      ),
    );
  }

  Widget _buildBottomPanel() {
    return BottomPanel(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meditation button (centered, properly sized)
          Center(
            child: ProtocolButton(
              type: ProtocolType.meditation,
              buttonState: _getProtocolState(ProtocolType.meditation),
              onTap: () => _logProtocol(ProtocolType.meditation),
              size: 100, // Larger for prominence
            ),
          ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Sessions Today',
                  value: _todayProtocols.length.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Mind Level',
                  value: '${(_todayProtocols.length * 10) + 1}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section header
          Text(
            'SESSIONS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textSecondary,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Sessions list
          SizedBox(
            height: 120,
            child: _todayProtocols.isEmpty
                ? Center(
                    child: Text(
                      'No meditation sessions yet.\nTap to log one!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: ThemeConstants.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _todayProtocols.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = _todayProtocols[index];
                      return ExpandableListItem(
                        leading: EmojiListIcon(emoji: entry.type.emoji),
                        title: entry.type.displayName,
                        subtitle: _formatTime(entry.timestamp),
                      );
                    },
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
