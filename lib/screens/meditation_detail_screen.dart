import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import '../models/tracking/meditation_log.dart';
import '../widgets/widgets.dart';
import 'active_meditation_screen.dart';

/// Meditation Detail Screen - Duration selection before starting
/// Uses two-tone hero card design
class MeditationDetailScreen extends StatefulWidget {
  final String title;
  final int duration;
  final MeditationType type;
  final String? audioPath;
  final String? imagePath;

  const MeditationDetailScreen({
    super.key,
    required this.title,
    required this.duration,
    required this.type,
    this.audioPath,
    this.imagePath,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPanelHeight = screenHeight * 0.45;

    return Scaffold(
      backgroundColor: ThemeConstants.deepNavy,
      body: Stack(
        children: [
          // Top Section: Image preview
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            bottom: bottomPanelHeight - 32,
            child: _buildHeroImage(),
          ),

          // Bottom Panel: Duration selector
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomPanelHeight,
            child: _buildBottomPanel(),
          ),

          // Back button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildBackButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(48),
        color: ThemeConstants.darkTeal,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(48),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
              Image.file(
                File(widget.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultBackground(),
              )
            else
              _buildDefaultBackground(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),

            // Title overlay
            Center(
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConstants.darkTeal,
            ThemeConstants.steelBlue,
            ThemeConstants.deepNavy,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              Text(
                'Set Duration',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textOnLight,
                ),
              ),
              const SizedBox(height: 24),

              // Duration Slider
              Expanded(
                child: DurationSlider(
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
              ),

              const SizedBox(height: 24),

              // Start button
              OdelleButtonFullWidth.primary(
                text: 'Start ${_selectedDuration}m Session',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ActiveMeditationScreen(
                        title: widget.title,
                        durationSeconds: _selectedDuration * 60,
                        type: widget.type,
                        audioPath: widget.audioPath,
                        imagePath: widget.imagePath,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
