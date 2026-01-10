import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../database/app_database.dart';
import '../models/protocol_entry.dart';
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
  List<ProtocolEntry> _todayProtocols = [];
  String _dailyMantra = '';

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
    final cardOffset = (1 - widget.panelVisibility) * 50;

    // Use FloatingHeroCard for the floating design
    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Account for SafeArea + nav bar overlay
            SizedBox(height: MediaQuery.of(context).padding.top + 70),

            // Daily mantra
            _buildMantraSection(),

            const Spacer(),

            // Bottom buttons and stats - slide + opacity
            Transform.translate(
              offset: Offset(0, cardOffset),
              child: _buildMindControls(),
            ),

            const SizedBox(height: 120), // Bottom padding for FAB
          ],
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

  Widget _buildMindControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meditation button (centered)
        Center(
          child: ProtocolButton(
            type: ProtocolType.meditation,
            buttonState: _getProtocolState(ProtocolType.meditation),
            onTap: () => _logProtocol(ProtocolType.meditation),
            size: 100, // Larger for prominence
          ),
        ),

        const SizedBox(height: 32),

        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildGlassStat(
                  'Sessions Today', _todayProtocols.length.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassStat(
                  'Mind Level', '${(_todayProtocols.length * 10) + 1}'),
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
            color: ThemeConstants.textOnDark.withValues(alpha: 0.7),
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
