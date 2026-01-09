import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Large animated number display for hero stats
/// Supports decimal superscript and count-up animation
class HeroNumber extends StatefulWidget {
  final double value;
  final String prefix; // e.g., "$"
  final String? suffix; // e.g., "XP"
  final int decimalPlaces;
  final bool animate;
  final Duration animationDuration;
  final Color color;
  final double fontSize;

  const HeroNumber({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix,
    this.decimalPlaces = 0,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.color = Colors.white,
    this.fontSize = 48,
  });

  @override
  State<HeroNumber> createState() => _HeroNumberState();
}

class _HeroNumberState extends State<HeroNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _animation.addListener(() {
      setState(() {
        _displayValue = _animation.value;
      });
    });

    if (widget.animate) {
      _controller.forward();
    } else {
      _displayValue = widget.value;
    }
  }

  @override
  void didUpdateWidget(HeroNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _displayValue, end: widget.value)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedValue = _formatNumber(_displayValue);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prefix
        if (widget.prefix.isNotEmpty)
          Text(
            widget.prefix,
            style: GoogleFonts.inter(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w700,
              color: widget.color,
              letterSpacing: -2,
            ),
          ),
        // Main number
        Text(
          formattedValue.main,
          style: GoogleFonts.inter(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            color: widget.color,
            letterSpacing: -2,
          ),
        ),
        // Decimal (superscript)
        if (formattedValue.decimal.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              formattedValue.decimal,
              style: GoogleFonts.inter(
                fontSize: widget.fontSize * 0.5,
                fontWeight: FontWeight.w500,
                color: widget.color.withValues(alpha: 0.7),
              ),
            ),
          ),
        // Suffix
        if (widget.suffix != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              widget.suffix!,
              style: GoogleFonts.inter(
                fontSize: widget.fontSize * 0.4,
                fontWeight: FontWeight.w500,
                color: widget.color.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  _FormattedNumber _formatNumber(double value) {
    if (widget.decimalPlaces == 0) {
      return _FormattedNumber(
        main: _addCommas(value.round()),
        decimal: '',
      );
    }

    final parts = value.toStringAsFixed(widget.decimalPlaces).split('.');
    return _FormattedNumber(
      main: _addCommas(int.parse(parts[0])),
      decimal: '.${parts[1]}',
    );
  }

  String _addCommas(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }

    return buffer.toString();
  }
}

class _FormattedNumber {
  final String main;
  final String decimal;

  _FormattedNumber({required this.main, required this.decimal});
}

/// Section label above hero numbers
class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const SectionLabel({
    super.key,
    required this.text,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
        color: color.withValues(alpha: 0.6),
      ),
    );
  }
}
