import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../database/app_database.dart';
import '../models/character_stats.dart';
import '../models/protocol_entry.dart';
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
    // Calculate animation values
    final contentOffset = (1 - widget.panelVisibility) * 50; // Subtle slide
    final contentOpacity = widget.panelVisibility.clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Account for SafeArea + nav bar overlay
          SizedBox(height: MediaQuery.of(context).padding.top + 70),

          // Hero XP display - fade with visibility
          AnimatedOpacity(
            duration: Duration.zero,
            opacity: contentOpacity,
            child: _buildHeroXP(),
          ),

          const Spacer(),

          // Bottom buttons and stats - slide + opacity
          Transform.translate(
            offset: Offset(0, contentOffset),
            child: AnimatedOpacity(
              duration: Duration.zero,
              opacity: contentOpacity,
              child: _buildBodyControls(),
            ),
          ),
          
          const SizedBox(height: 120), // Bottom padding for FAB
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

  Widget _buildBodyControls() {
    return Column(
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

        // Stats row (using simplified glass look)
        Row(
          children: [
            Expanded(
              child: _buildGlassStat('Today\'s Logs', _todayProtocols.length.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassStat('Level', '${_stats?.level ?? 1}'),
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
            color: ThemeConstants.textOnDark.withValues(alpha: 0.7),
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 12),

        // Protocol entries list - transparent
        SizedBox(
          height: 160,
          child: _todayProtocols.isEmpty
              ? Center(
                  child: Text(
                    'No logs yet today.\nTap a protocol to start!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: ThemeConstants.textOnDark.withValues(alpha: 0.5),
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
                    return _buildDarkListItem(entry);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildGlassStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textOnDark.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textOnDark,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDarkListItem(ProtocolEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
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
                    color: ThemeConstants.textOnDark,
                  ),
                ),
                Text(
                  _formatTime(entry.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ThemeConstants.textOnDark.withValues(alpha: 0.5),
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
