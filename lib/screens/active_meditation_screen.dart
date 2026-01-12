import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import '../models/tracking/meditation_log.dart';
import '../widgets/effects/breathing_card.dart';
import 'meditation_completion_screen.dart';

class ActiveMeditationScreen extends StatefulWidget {
  final String title;
  final int durationSeconds;
  final MeditationType type;

  const ActiveMeditationScreen({
    super.key,
    required this.title,
    required this.durationSeconds,
    required this.type,
  });

  @override
  State<ActiveMeditationScreen> createState() => _ActiveMeditationScreenState();
}

class _ActiveMeditationScreenState extends State<ActiveMeditationScreen> {
  late Timer _timer;
  late int _remainingSeconds;
  bool _isPlaying = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) return;

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _finishSession();
        }
      });
    });
  }

  void _finishSession() {
    _timer.cancel();
    // Navigate to completion screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MeditationCompletionScreen(
          sessionTitle: widget.title,
          durationMinutes: (widget.durationSeconds / 60).round(),
          type: widget.type,
          startTime:
              DateTime.now().subtract(Duration(seconds: widget.durationSeconds)),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _endSessionEarly() {
    _timer.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.panelWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: ThemeConstants.textSecondary),
                    onPressed: _endSessionEarly,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Meditation Session',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ThemeConstants.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for close button
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ThemeConstants.textOnLight,
              ),
            ),

            const Spacer(),

            // Breathing Card Visualization
            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: BreathingCard(
                  borderRadius: 150, // Circular
                  animate: _isPlaying,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.type == MeditationType.breathing
                              ? 'Inhale slowly' // Placeholder logic
                              : 'Breathe',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Waveform visual placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                    20,
                    (index) => Container(
                      width: 4,
                      height: 10 + (index % 5) * 6.0,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: ThemeConstants.polyPurple200.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                  onPressed: _toggleMute,
                  isSecondary: true,
                ),
                const SizedBox(width: 32),
                _buildControlButton(
                  icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                  onPressed: _togglePlayPause,
                  isLarge: true,
                  isSecondary: false,
                ),
                const SizedBox(width: 32),
                _buildControlButton(
                  icon: Icons.skip_next,
                  onPressed: _finishSession, // For testing/skipping
                  isSecondary: true,
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Instructional text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Inhale slowly through your nose, filling your lungs completely with fresh energy',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ThemeConstants.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isLarge = false,
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isLarge ? 80 : 48,
        height: isLarge ? 80 : 48,
        decoration: BoxDecoration(
          color: isLarge ? ThemeConstants.polyPurple300 : Colors.transparent,
          shape: BoxShape.circle,
          border: isSecondary ? Border.all(color: ThemeConstants.polyPurple200) : null,
          boxShadow: isLarge
              ? [
                  BoxShadow(
                    color: ThemeConstants.polyPurple300.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isLarge ? Colors.white : ThemeConstants.polyPurple300,
          size: isLarge ? 40 : 24,
        ),
      ),
    );
  }
}
