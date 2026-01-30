import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme_constants.dart';
import '../models/tracking/meditation_log.dart';
import '../services/media_storage_service.dart';
import '../utils/logger.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/widgets.dart';
import 'active_meditation_screen.dart';

/// Meditation Detail Screen - Preview before starting session
/// Uses two-tone hero card design with audio validation
class MeditationDetailScreen extends StatefulWidget {
  final String title;
  final int duration;
  final MeditationType type;
  final String? audioPath;
  final String? audioUrl; // Firebase Storage URL
  final String? imagePath;
  final String? imageUrl; // Firebase Storage URL

  const MeditationDetailScreen({
    super.key,
    required this.title,
    required this.duration,
    required this.type,
    this.audioPath,
    this.audioUrl,
    this.imagePath,
    this.imageUrl,
  });

  @override
  State<MeditationDetailScreen> createState() => _MeditationDetailScreenState();
}

class _MeditationDetailScreenState extends State<MeditationDetailScreen> {
  bool _audioExists = false;
  bool _isCheckingAudio = true;
  bool _isDownloading = false;
  String? _effectiveAudioPath; // Resolved path (local or downloaded)
  String? _effectiveImagePath; // Resolved path (local or downloaded)
  bool _isDownloadingImage = false;

  @override
  void initState() {
    super.initState();
    Logger.debug('MeditationDetailScreen opened', tag: 'AudioDebug', data: {
      'title': widget.title,
      'audioPath': widget.audioPath,
      'audioUrl': widget.audioUrl,
      'imagePath': widget.imagePath,
    });
    _resolveAudioPath();
    _resolveImagePath();
  }

  /// Resolves the image path - uses local if exists, downloads from Firebase if not.
  Future<void> _resolveImagePath() async {
    // Check local file first
    final localPath = widget.imagePath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _effectiveImagePath = localPath;
          });
        }
        return;
      }
    }

    // Local doesn't exist - try downloading from Firebase
    final firebaseUrl = widget.imageUrl;
    if (firebaseUrl != null && firebaseUrl.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isDownloadingImage = true;
        });
      }
      Logger.info('Downloading meditation image from Firebase',
          tag: 'MeditationDetail', data: {'title': widget.title});

      final downloadedPath =
          await MediaStorageService.instance.getLocalPath(firebaseUrl);

      if (mounted) {
        setState(() {
          _effectiveImagePath = downloadedPath;
          _isDownloadingImage = false;
        });
      }

      if (downloadedPath == null) {
        Logger.warning('Failed to download meditation image from Firebase',
            tag: 'MeditationDetail');
      }
      return;
    }

    // No local file and no Firebase URL - use default background
    Logger.debug('No image available for meditation: ${widget.title}',
        tag: 'MeditationDetail');
  }

  /// Resolves the audio path - uses local if exists, downloads from Firebase if not.
  Future<void> _resolveAudioPath() async {
    // Check local file first
    final localPath = widget.audioPath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _effectiveAudioPath = localPath;
            _audioExists = true;
            _isCheckingAudio = false;
          });
        }
        return;
      }
    }

    // Local doesn't exist - try downloading from Firebase
    final firebaseUrl = widget.audioUrl;
    if (firebaseUrl != null && firebaseUrl.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isDownloading = true;
          _isCheckingAudio = false;
        });
      }
      Logger.info('Downloading meditation audio from Firebase',
          tag: 'MeditationDetail', data: {'title': widget.title});

      final downloadedPath =
          await MediaStorageService.instance.downloadAudio(firebaseUrl);

      if (mounted) {
        setState(() {
          _effectiveAudioPath = downloadedPath;
          _audioExists = downloadedPath != null;
          _isDownloading = false;
        });
      }

      if (downloadedPath == null) {
        Logger.warning('Failed to download meditation audio from Firebase',
            tag: 'MeditationDetail');
      }
      return;
    }

    // No local file and no Firebase URL
    if (mounted) {
      setState(() {
        _audioExists = false;
        _isCheckingAudio = false;
      });
    }
    Logger.warning('No audio available for meditation: ${widget.title}',
        tag: 'MeditationDetail');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPanelHeight = screenHeight * 0.32;

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

          // Bottom Panel: Session info and start button
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
    return BreathingCard(
      borderRadius: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or gradient (uses resolved path with Firebase fallback)
          if (_effectiveImagePath != null && _effectiveImagePath!.isNotEmpty)
            Image.file(
              File(_effectiveImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefaultBackground(),
            )
          else if (_isDownloadingImage)
            Stack(
              fit: StackFit.expand,
              children: [
                _buildDefaultBackground(),
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
              ],
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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              // Session info row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInfoChip(
                    icon: Icons.timer_outlined,
                    label: '${widget.duration} min',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoChip(
                    icon: Icons.self_improvement_rounded,
                    label: widget.type.displayName,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Audio status indicator
              if (_isCheckingAudio || _isDownloading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ThemeConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isDownloading
                            ? 'Downloading audio...'
                            : 'Checking audio...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ThemeConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (!_audioExists)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volume_off_rounded,
                          size: 18, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Text(
                        'Audio unavailable - silent session',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Start button
              OdelleButtonFullWidth.dark(
                text: 'Start Session',
                icon: Icons.play_arrow_rounded,
                onPressed:
                    (_isCheckingAudio || _isDownloading) ? null : _startSession,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeConstants.panelWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeConstants.glassBorderWeak),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: ThemeConstants.steelBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeConstants.textOnLight,
            ),
          ),
        ],
      ),
    );
  }

  void _startSession() {
    Logger.debug('Starting meditation session', tag: 'AudioDebug', data: {
      'title': widget.title,
      'effectiveAudioPath': _effectiveAudioPath,
      'originalAudioPath': widget.audioPath,
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ActiveMeditationScreen(
          title: widget.title,
          durationSeconds: widget.duration * 60,
          type: widget.type,
          audioPath: _effectiveAudioPath, // Uses local or downloaded path
          imagePath: _effectiveImagePath ?? widget.imagePath,
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
