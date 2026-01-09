import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centered conversational text for voice AI responses
/// Displays typing animation and smooth text transitions
class ConversationText extends StatefulWidget {
  final String text;
  final bool isTyping;
  final Duration typingSpeed;
  final TextAlign textAlign;
  final Color textColor;
  final double fontSize;

  const ConversationText({
    super.key,
    required this.text,
    this.isTyping = false,
    this.typingSpeed = const Duration(milliseconds: 30),
    this.textAlign = TextAlign.center,
    this.textColor = Colors.white,
    this.fontSize = 20,
  });

  @override
  State<ConversationText> createState() => _ConversationTextState();
}

class _ConversationTextState extends State<ConversationText> {
  String _displayedText = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isTyping) {
      _startTyping();
    } else {
      _displayedText = widget.text;
    }
  }

  @override
  void didUpdateWidget(ConversationText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _charIndex = 0;
      if (widget.isTyping) {
        _displayedText = '';
        _startTyping();
      } else {
        _displayedText = widget.text;
      }
    }
  }

  void _startTyping() async {
    while (_charIndex < widget.text.length && mounted) {
      await Future.delayed(widget.typingSpeed);
      if (mounted) {
        setState(() {
          _charIndex++;
          _displayedText = widget.text.substring(0, _charIndex);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _displayedText,
        key: ValueKey(widget.text),
        textAlign: widget.textAlign,
        style: GoogleFonts.inter(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w400,
          color: widget.textColor.withValues(alpha: 0.9),
          height: 1.5,
        ),
      ),
    );
  }
}

/// Greeting text with name highlight
class GreetingText extends StatelessWidget {
  final String greeting; // e.g., "Hello"
  final String name; // e.g., "Alex"
  final String? subtitle; // Optional subtitle message
  final Color textColor;

  const GreetingText({
    super.key,
    required this.greeting,
    required this.name,
    this.subtitle,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: textColor,
              height: 1.4,
            ),
            children: [
              TextSpan(text: '$greeting '),
              TextSpan(
                text: '$name,',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: textColor.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Voice status indicator text
class VoiceStatusText extends StatelessWidget {
  final VoiceStatus status;
  final String? customText;
  final Color textColor;

  const VoiceStatusText({
    super.key,
    required this.status,
    this.customText,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final text = customText ?? _getStatusText();
    final opacity = _getOpacity();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        text,
        key: ValueKey(status),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor.withValues(alpha: opacity),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (status) {
      case VoiceStatus.idle:
        return 'Tap to speak';
      case VoiceStatus.listening:
        return 'Listening...';
      case VoiceStatus.processing:
        return 'Processing...';
      case VoiceStatus.responding:
        return '';
      case VoiceStatus.error:
        return 'Try again';
    }
  }

  double _getOpacity() {
    switch (status) {
      case VoiceStatus.idle:
        return 0.5;
      case VoiceStatus.listening:
        return 0.8;
      case VoiceStatus.processing:
        return 0.6;
      case VoiceStatus.responding:
        return 0.0;
      case VoiceStatus.error:
        return 0.8;
    }
  }
}

enum VoiceStatus {
  idle,
  listening,
  processing,
  responding,
  error,
}
