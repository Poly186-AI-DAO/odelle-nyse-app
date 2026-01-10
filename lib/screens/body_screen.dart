import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../database/app_database.dart';
import '../models/character_stats.dart';
import '../models/protocol_entry.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/protocol/protocol_button.dart';
import '../widgets/dashboard/hero_number.dart';

/// Body Screen - Physical tracking pillar
/// Gym, Meal, Dose protocols with XP tracking
class BodyScreen extends StatefulWidget {
  final double panelVisibility;

  const BodyScreen({super.key, this.panelVisibility = 1.0});

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
    // Use FloatingHeroCard with white bottom panel
    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      // Dark card content - Hero XP display at top
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 70), // Space for nav bar
            const SizedBox(height: 40),
            _buildHeroXP(),
          ],
        ),
      ),
      // White bottom panel with stats and controls
      bottomPanel: _buildBottomPanel(),
    );
  }

  Widget _buildBottomPanel() {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  'Today',
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
            Row(
              children: [
                Expanded(
                    child: _buildWhiteStat(
                        'TODAY\'S LOGS', _todayProtocols.length.toString())),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildWhiteStat('LEVEL', '${_stats?.level ?? 1}')),
              ],
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
        children: [
          Text(
            label,
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
