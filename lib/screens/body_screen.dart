import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../database/app_database.dart';
import '../models/character_stats.dart';
import '../models/protocol_entry.dart';
import '../widgets/protocol/protocol_button.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/dashboard/hero_number.dart';
import '../widgets/panels/bottom_panel.dart';
import '../widgets/list/expandable_list_item.dart';

/// Body Screen - Physical tracking pillar
/// Gym, Meal, Dose protocols with XP tracking
class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  CharacterStats? _stats;
  List<ProtocolEntry> _todayProtocols = [];

  // Protocol definitions
  static const List<ProtocolType> _protocolTypes = [
    ProtocolType.gym,
    ProtocolType.meal,
    ProtocolType.dose,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    final stats = await db.getTodayStats();
    final protocols = await db.getTodayProtocolEntries();

    if (mounted) {
      setState(() {
        _stats = stats;
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
    if (count >= 3) return ProtocolButtonState.complete;
    return ProtocolButtonState.partial;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Hero XP display
        _buildHeroXP(),

        const Spacer(),

        // Bottom panel with protocols
        _buildBottomPanel(),
      ],
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

        // Level indicator
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

  Widget _buildBottomPanel() {
    return BottomPanel(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Protocol buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _protocolTypes.map((type) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ProtocolButton(
                    type: type,
                    buttonState: _getProtocolState(type),
                    onTap: () => _logProtocol(type),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Today\'s Logs',
                  value: _todayProtocols.length.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Level',
                  value: '${_stats?.level ?? 1}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Today's activity header
          Text(
            'TODAY',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textSecondary,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Protocol entries list
          SizedBox(
            height: 160,
            child: _todayProtocols.isEmpty
                ? Center(
                    child: Text(
                      'No logs yet today.\nTap a protocol to start!',
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
