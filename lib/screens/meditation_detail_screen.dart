import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import '../models/tracking/meditation_log.dart';
import '../widgets/widgets.dart';
import 'active_meditation_screen.dart';

class MeditationDetailScreen extends StatefulWidget {
  final String title;
  final int duration;
  final MeditationType type;

  const MeditationDetailScreen({
    super.key,
    required this.title,
    required this.duration,
    required this.type,
  });

  @override
  State<MeditationDetailScreen> createState() => _MeditationDetailScreenState();
}

class _MeditationDetailScreenState extends State<MeditationDetailScreen> {
  late int _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    Text(
                      'Set Your Duration',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Slide to choose how long you want to meditate',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Duration Slider Component
                    DurationSlider(
                      initialMinutes: _selectedDuration,
                      minMinutes: 1,
                      maxMinutes: 60,
                      stepMinutes: 1,
                      onChanged: (minutes) {
                        setState(() {
                          _selectedDuration = minutes;
                        });
                      },
                    ),

                    const SizedBox(height: 48),

                    // Preview of what the timer will look like
                    Text(
                      'Session Preview',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Circular Timer Preview (static, not running)
                    CircularTimer(
                      durationSeconds: _selectedDuration * 60,
                      mode: TimerMode.countdown,
                      size: 200,
                      showControls: false,
                      label: widget.type.displayName.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: OdelleButtonFullWidth.dark(
                text: 'Start ${_selectedDuration}m Session',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ActiveMeditationScreen(
                        title: widget.title,
                        durationSeconds: _selectedDuration * 60,
                        type: widget.type,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
