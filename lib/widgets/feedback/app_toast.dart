import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Styled toast/snackbar that matches the app's design language
/// Glass morphism style with subtle blur
class AppToast {
  /// Show an info toast
  static void info(BuildContext context, String message, {Duration? duration}) {
    _show(context, message, _ToastType.info, duration: duration);
  }

  /// Show a success toast
  static void success(BuildContext context, String message,
      {Duration? duration}) {
    _show(context, message, _ToastType.success, duration: duration);
  }

  /// Show an error toast
  static void error(BuildContext context, String message,
      {Duration? duration}) {
    _show(context, message, _ToastType.error, duration: duration);
  }

  /// Show a warning toast
  static void warning(BuildContext context, String message,
      {Duration? duration}) {
    _show(context, message, _ToastType.warning, duration: duration);
  }

  static void _show(
    BuildContext context,
    String message,
    _ToastType type, {
    Duration? duration,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () => entry.remove(),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );

    overlay.insert(entry);
  }
}

enum _ToastType { info, success, error, warning }

class _ToastWidget extends StatefulWidget {
  final String message;
  final _ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case _ToastType.info:
        return const Color(0xFF1E293B);
      case _ToastType.success:
        return const Color(0xFF065F46);
      case _ToastType.error:
        return const Color(0xFF7F1D1D);
      case _ToastType.warning:
        return const Color(0xFF78350F);
    }
  }

  Color get _borderColor {
    switch (widget.type) {
      case _ToastType.info:
        return const Color(0xFF3B82F6).withValues(alpha: 0.3);
      case _ToastType.success:
        return const Color(0xFF10B981).withValues(alpha: 0.3);
      case _ToastType.error:
        return const Color(0xFFEF4444).withValues(alpha: 0.3);
      case _ToastType.warning:
        return const Color(0xFFF59E0B).withValues(alpha: 0.3);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case _ToastType.info:
        return Icons.info_outline_rounded;
      case _ToastType.success:
        return Icons.check_circle_outline_rounded;
      case _ToastType.error:
        return Icons.error_outline_rounded;
      case _ToastType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            onHorizontalDragEnd: (_) => _dismiss(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _backgroundColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _icon,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ],
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
