import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Expandable list item with icon, title, subtitle, and expandable content
/// Used in dashboard lists for protocols, investments, etc.
class ExpandableListItem extends StatefulWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Color? trailingColor;
  final Widget? expandedContent;
  final bool initiallyExpanded;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final BorderRadius borderRadius;

  const ExpandableListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingColor,
    this.expandedContent,
    this.initiallyExpanded = false,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF0A1628),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<ExpandableListItem> createState() => _ExpandableListItemState();
}

class _ExpandableListItemState extends State<ExpandableListItem>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasExpandedContent = widget.expandedContent != null;

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: hasExpandedContent ? _toggleExpanded : widget.onTap,
            borderRadius: widget.borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Leading widget (icon/image)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: widget.leading,
                  ),
                  const SizedBox(width: 12),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.textColor,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: widget.textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Trailing text or chevron
                  if (widget.trailing != null) ...[
                    Text(
                      widget.trailing!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.trailingColor ?? const Color(0xFF22C55E),
                      ),
                    ),
                    if (hasExpandedContent) const SizedBox(width: 8),
                  ],
                  if (hasExpandedContent)
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.textColor.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (hasExpandedContent)
            SizeTransition(
              sizeFactor: _heightAnimation,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: widget.textColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: widget.expandedContent,
              ),
            ),
        ],
      ),
    );
  }
}

/// Icon badge for list items
class ListItemIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const ListItemIcon({
    super.key,
    required this.icon,
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.iconColor = const Color(0xFF0A1628),
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: size * 0.5,
      ),
    );
  }
}

/// Emoji badge for protocol items
class EmojiListIcon extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final double size;

  const EmojiListIcon({
    super.key,
    required this.emoji,
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}

/// List divider for consistent spacing
class ListItemDivider extends StatelessWidget {
  final Color color;
  final double indent;

  const ListItemDivider({
    super.key,
    this.color = const Color(0xFFE5E7EB),
    this.indent = 68,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: indent),
      height: 1,
      color: color,
    );
  }
}
