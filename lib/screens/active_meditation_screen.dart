import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../constants/theme_constants.dart';
import '../models/tracking/meditation_log.dart';
import '../utils/audio_session_helper.dart';
import '../utils/logger.dart';
import '../widgets/effects/breathing_card.dart';
import 'meditation_completion_screen.dart';

/// Active Meditation Screen - Two-tone hero card design
/// Top: LLM-generated image with timer overlay
/// Bottom: Playback controls + waveform
class ActiveMeditationScreen extends StatefulWidget {
  final String title;
  final int durationSeconds;
  final MeditationType type;
  final String? audioPath;
  final String? imagePath;

  const ActiveMeditationScreen({
    super.key,
    required this.title,
    required this.durationSeconds,
    required this.type,
    this.audioPath,
    this.imagePath,
  });

  @override
  State<ActiveMeditationScreen> createState() => _ActiveMeditationScreenState();
}

class _ActiveMeditationScreenState extends State<ActiveMeditationScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  bool _isPlaying = true;
  bool _isMuted = false;
  late final AudioPlayer _audioPlayer;
  bool _audioReady = false;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _remainingSeconds = widget.durationSeconds;
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _startTimer();
    _prepareAudio();
  }

  Future<void> _prepareAudio() async {
    // Configure audio session to route through speaker (not earpiece)
    await AudioSessionHelper.configureForPlayback();

    final path = widget.audioPath;
    Logger.debug('ActiveMeditationScreen preparing audio',
        tag: 'AudioDebug',
        data: {
          'title': widget.title,
          'audioPath': path,
        });
    if (path == null || path.isEmpty) {
      Logger.warning('No audio path provided!', tag: 'AudioDebug');
      return;
    }

    try {
      await _audioPlayer.setFilePath(path);
      _audioReady = true;

      // Use actual audio duration if available
      final actualDuration = _audioPlayer.duration;
      if (actualDuration != null && actualDuration.inSeconds > 0) {
        Logger.debug('Using actual audio duration', tag: 'AudioDebug', data: {
          'presetSeconds': widget.durationSeconds,
          'actualSeconds': actualDuration.inSeconds,
        });
        if (mounted) {
          setState(() {
            _remainingSeconds = actualDuration.inSeconds;
          });
        }
      }

      await _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
      if (_isPlaying) {
        await _audioPlayer.play();
      }
    } catch (e) {
      Logger.warning('Failed to load meditation audio: $e',
          tag: 'ActiveMeditation');
    }
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
    if (_audioReady) {
      _audioPlayer.stop();
    }
    // Navigate to completion screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MeditationCompletionScreen(
          sessionTitle: widget.title,
          durationMinutes: (widget.durationSeconds / 60).round(),
          type: widget.type,
          startTime: DateTime.now()
              .subtract(Duration(seconds: widget.durationSeconds)),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_audioReady) {
      if (_isPlaying) {
        _audioPlayer.play();
      } else {
        _audioPlayer.pause();
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });

    if (_audioReady) {
      _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  void _endSessionEarly() {
    _timer.cancel();
    if (_audioReady) {
      _audioPlayer.stop();
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer.cancel();
    _waveformController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPanelHeight = screenHeight * 0.35;

    return Scaffold(
      backgroundColor: ThemeConstants.deepNavy,
      body: Stack(
        children: [
          // Top Section: Image with timer overlay
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            bottom: bottomPanelHeight - 32,
            child: _buildHeroImage(),
          ),

          // Bottom Panel: Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomPanelHeight,
            child: _buildBottomPanel(),
          ),

          // Close button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildCloseButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return BreathingCard(
      borderRadius: 48,
      animate: _isPlaying,
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

          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),

          // Dimming overlay when playing (for focus)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            color: _isPlaying
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.transparent,
          ),

          // Timer and title
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _formatTime(_remainingSeconds),
                  style: GoogleFonts.inter(
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPlaying ? 'Breathe' : 'Paused',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              // Waveform visualization
              _buildWaveform(),
              const Spacer(),

              // Playback controls
              _buildControls(),
              const SizedBox(height: 16),

              // Session info
              Text(
                widget.type.displayName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ThemeConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(32, (index) {
              final phase =
                  (_waveformController.value * 2 * pi) + (index * 0.3);
              final height = _isPlaying
                  ? 12 + (16 * (0.5 + 0.5 * sin(phase)).abs())
                  : 12.0;
              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: ThemeConstants.steelBlue.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute button
        _buildControlButton(
          icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          onPressed: _toggleMute,
          isSecondary: true,
        ),
        const SizedBox(width: 40),

        // Play/Pause button
        _buildControlButton(
          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onPressed: _togglePlayPause,
          isLarge: true,
        ),
        const SizedBox(width: 40),

        // Skip button
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: _finishSession,
          isSecondary: true,
        ),
      ],
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
        width: isLarge ? 72 : 48,
        height: isLarge ? 72 : 48,
        decoration: BoxDecoration(
          color: isLarge ? ThemeConstants.deepNavy : Colors.transparent,
          shape: BoxShape.circle,
          border: isSecondary
              ? Border.all(
                  color: ThemeConstants.steelBlue.withValues(alpha: 0.3),
                  width: 1.5)
              : null,
          boxShadow: isLarge
              ? [
                  BoxShadow(
                    color: ThemeConstants.deepNavy.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isLarge ? Colors.white : ThemeConstants.steelBlue,
          size: isLarge ? 36 : 24,
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: _endSessionEarly,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
