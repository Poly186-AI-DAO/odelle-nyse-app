import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import '../models/tracking/meditation_log.dart';

class MeditationCompletionScreen extends StatefulWidget {
  final String sessionTitle;
  final int durationMinutes;
  final MeditationType type;
  final DateTime startTime;

  const MeditationCompletionScreen({
    super.key,
    required this.sessionTitle,
    required this.durationMinutes,
    required this.type,
    required this.startTime,
  });

  @override
  State<MeditationCompletionScreen> createState() =>
      _MeditationCompletionScreenState();
}

class _MeditationCompletionScreenState
    extends State<MeditationCompletionScreen> {
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedSentiments = {};
  bool _isSaving = false;

  final List<String> _sentiments = [
    'Calm 😌',
    'Lighter 🕊️',
    'Grounded 🌳',
    'Reflective 🤔',
    'Neutral 😐',
    'Energized ⚡',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    setState(() => _isSaving = true);

    // Create the log object
    // ignore: unused_local_variable
    final log = MeditationLog(
      startTime: widget.startTime,
      endTime: DateTime.now(),
      durationMinutes: widget.durationMinutes,
      type: widget.type,
      notes: _noteController.text,
      guidedSession: true,
      technique: 'Guided',
    );

    // TODO: Save to database / HealthKit via ServiceProvider
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.settings.name == null && route.isFirst == false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.panelWhite,
      appBar: AppBar(
        backgroundColor: ThemeConstants.panelWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: ThemeConstants.textOnLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ThemeConstants.polyPurple300,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Session Complete',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textOnLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Well done on completing your practice',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: ThemeConstants.polyPurple400,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 48),

              // Sentiment
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'How do you feel right now?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _sentiments.map((sentiment) {
                  final isSelected = _selectedSentiments.contains(sentiment);
                  return FilterChip(
                    label: Text(sentiment),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSentiments.add(sentiment);
                        } else {
                          _selectedSentiments.remove(sentiment);
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: ThemeConstants.polyPurple200,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isSelected ? ThemeConstants.deepNavy : ThemeConstants.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? ThemeConstants.polyPurple300 : ThemeConstants.glassBorderWeak,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                "There's no right answer.",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: ThemeConstants.textMuted,
                ),
              ),

              const SizedBox(height: 32),

              // Note Input
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a note (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'How did this session make you feel?',
                  hintStyle: GoogleFonts.inter(color: ThemeConstants.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: ThemeConstants.glassBorderWeak),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: ThemeConstants.glassBorderWeak),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: ThemeConstants.polyPurple300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 48),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAndExit,
                  icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.home, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Return Home',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.deepNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: ThemeConstants.deepNavy.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
