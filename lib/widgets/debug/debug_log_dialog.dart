import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/logger.dart';
import '../../constants/theme_constants.dart';

/// A beautiful debug log dialog for troubleshooting on devices.
/// 
/// Shows recent logs with color-coded levels and allows copying/clearing.
class DebugLogDialog extends StatefulWidget {
  const DebugLogDialog({super.key});

  /// Show the debug log dialog
  static void show(BuildContext context) {
    HapticFeedback.mediumImpact(); // Haptic feedback to confirm trigger
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DebugLogDialog(),
    );
  }

  @override
  State<DebugLogDialog> createState() => _DebugLogDialogState();
}

class _DebugLogDialogState extends State<DebugLogDialog> {
  List<LogEntry> _logs = [];
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logs = Logger.logs.reversed.toList(); // Most recent first
    });
  }

  List<LogEntry> get _filteredLogs {
    if (_filter == 'ALL') return _logs;
    return _logs.where((log) => log.level == _filter).toList();
  }

  Color _colorForLevel(String level) {
    switch (level) {
      case 'ERROR':
        return const Color(0xFFEF4444);
      case 'WARN':
        return const Color(0xFFF59E0B);
      case 'INFO':
        return const Color(0xFF22C55E);
      case 'DEBUG':
        return const Color(0xFF3B82F6);
      default:
        return Colors.white70;
    }
  }

  void _copyAllLogs() {
    final text = _filteredLogs.map((e) => e.formatted).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_filteredLogs.length} logs copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ThemeConstants.accentGreen,
      ),
    );
  }

  void _clearLogs() {
    Logger.clearLogs();
    _refreshLogs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs cleared'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Debug Logs',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: _refreshLogs,
                      tooltip: 'Refresh',
                    ),
                    // Copy button
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      onPressed: _copyAllLogs,
                      tooltip: 'Copy all',
                    ),
                    // Clear button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white70),
                      onPressed: _clearLogs,
                      tooltip: 'Clear',
                    ),
                  ],
                ),
              ),

              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('ALL'),
                    const SizedBox(width: 8),
                    _buildFilterChip('ERROR'),
                    const SizedBox(width: 8),
                    _buildFilterChip('WARN'),
                    const SizedBox(width: 8),
                    _buildFilterChip('INFO'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Log count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filteredLogs.length} entries',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Log list
              Expanded(
                child: _filteredLogs.isEmpty
                    ? Center(
                        child: Text(
                          'No logs yet',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          return _buildLogEntry(log);
                        },
                      ),
              ),

              // Safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String level) {
    final isSelected = _filter == level;
    return GestureDetector(
      onTap: () => setState(() => _filter = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _colorForLevel(level).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? _colorForLevel(level)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          level,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? _colorForLevel(level) : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: _colorForLevel(log.level),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _colorForLevel(log.level).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.level,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _colorForLevel(log.level),
                  ),
                ),
              ),
              if (log.tag != null) ...[
                const SizedBox(width: 8),
                Text(
                  log.tag!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            log.message,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
