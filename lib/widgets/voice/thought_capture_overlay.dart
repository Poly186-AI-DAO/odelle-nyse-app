import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../providers/viewmodels/voice_viewmodel.dart';
import '../feedback/app_toast.dart';
import 'voice_waveform_animated.dart';

/// Full-screen overlay for voice transcription
/// Shows blur background + centered card with live transcription
/// Dismisses when recording stops and user finishes review
class ThoughtCaptureOverlay extends ConsumerStatefulWidget {
  final VoidCallback? onRequestStopRecording;
  final VoidCallback? onRequestDismiss;

  const ThoughtCaptureOverlay({
    super.key,
    this.onRequestStopRecording,
    this.onRequestDismiss,
  });

  @override
  ConsumerState<ThoughtCaptureOverlay> createState() =>
      _ThoughtCaptureOverlayState();
}

class _ThoughtCaptureOverlayState extends ConsumerState<ThoughtCaptureOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late final TextEditingController _textController;

  bool _hasEdited = false;
  Uint8List? _imageBytes;
  String? _imageMimeType;
  String? _imageName;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final mimeType = _mimeTypeFromPath(image.path);
    setState(() {
      _imageBytes = bytes;
      _imageMimeType = mimeType;
      _imageName = path.basename(image.path);
    });
  }

  String _mimeTypeFromPath(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _sendCapture() async {
    final transcription = _textController.text.trim();
    if (transcription.isEmpty) {
      AppToast.warning(context, 'Add a transcription to send');
      return;
    }

    final voiceVM = ref.read(voiceViewModelProvider.notifier);
    final result = await voiceVM.processCapture(
      transcription: transcription,
      imageBytes: _imageBytes,
      imageMimeType: _imageMimeType,
    );

    if (!mounted) return;

    if (result == null) {
      AppToast.warning(context, 'Nothing to send');
      return;
    }

    if (result.success) {
      AppToast.success(context, result.message);
      widget.onRequestDismiss?.call();
      _clearLocalState();
    } else {
      AppToast.error(context, result.message);
    }
  }

  void _clearLocalState() {
    setState(() {
      _hasEdited = false;
      _imageBytes = null;
      _imageMimeType = null;
      _imageName = null;
      _textController.clear();
    });
  }

  void _handleBackgroundTap({
    required bool isRecording,
    required bool isConnecting,
  }) {
    if (isRecording || isConnecting) {
      widget.onRequestStopRecording?.call();
      return;
    }

    widget.onRequestDismiss?.call();
    _clearLocalState();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceViewModelProvider);
    final isRecording = voiceState.isRecording;
    final isConnecting = voiceState.isConnecting;
    final isReviewMode = !isRecording && !isConnecting;
    final isSending = voiceState.isProcessingAction;

    final transcription = voiceState.partialTranscription.isNotEmpty
        ? voiceState.partialTranscription
        : voiceState.currentTranscription;

    if (!_hasEdited && transcription.isNotEmpty) {
      if (_textController.text != transcription) {
        _textController.text = transcription;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
      }
    }

    return GestureDetector(
      onTap: () => _handleBackgroundTap(
        isRecording: isRecording,
        isConnecting: isConnecting,
      ),
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent dismiss when tapping card
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    constraints: const BoxConstraints(maxWidth: 380),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.97),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 60,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: isRecording ? 0.15 : 0.0),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated waveform indicator with pulse glow
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final glowOpacity = isRecording
                                ? 0.15 + (_pulseAnimation.value * 0.15)
                                : 0.0;
                            final scale = isRecording
                                ? 1.0 + (_pulseAnimation.value * 0.05)
                                : 1.0;

                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [
                                      Color(0xFFF0FDF4),
                                      Colors.white,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: isRecording
                                        ? const Color(0xFF22C55E)
                                            .withValues(alpha: 0.4)
                                        : const Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    if (isRecording)
                                      BoxShadow(
                                        color: const Color(0xFF22C55E)
                                            .withValues(alpha: glowOpacity),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: isConnecting
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Color(0xFF22C55E),
                                            ),
                                          ),
                                        )
                                      : VoiceWaveformAnimated(
                                          size: 32,
                                          color: const Color(0xFF1A1A1A),
                                          isActive: isRecording,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        Text(
                          isConnecting
                              ? 'Connecting...'
                              : isRecording
                                  ? 'Listening...'
                                  : 'Review capture',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (isReviewMode) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: TextField(
                              controller: _textController,
                              maxLines: 5,
                              minLines: 3,
                              onChanged: (_) => _hasEdited = true,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF1F2937),
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Edit transcription or add notes...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showImageSourceSheet,
                                  icon: const Icon(Icons.add_a_photo_outlined),
                                  label: const Text('Add photo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF111827),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    textStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_imageBytes != null)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _imageBytes = null;
                                      _imageMimeType = null;
                                      _imageName = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                  color: const Color(0xFF6B7280),
                                ),
                            ],
                          ),

                          if (_imageBytes != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                                image: DecorationImage(
                                  image: MemoryImage(_imageBytes!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _imageName ?? 'Attached photo',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    widget.onRequestDismiss?.call();
                                    _clearLocalState();
                                  },
                                  child: Text(
                                    'Dismiss',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isSending ? null : _sendCapture,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF111827),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    textStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: isSending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text('Send to GPT-5'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          if (transcription.isNotEmpty) ...[
                            Container(
                              constraints: const BoxConstraints(maxHeight: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: SingleChildScrollView(
                                reverse: true,
                                child: Text(
                                  transcription,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF4B5563),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 16,
                                color: const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tap button below to stop',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
