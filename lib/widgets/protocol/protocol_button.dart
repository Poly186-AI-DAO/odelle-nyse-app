import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/protocol_entry.dart';

/// Quick-log protocol button (💪🥗💊🧘)
/// Used for rapid protocol logging on dashboard
class ProtocolButton extends StatefulWidget {
  final ProtocolType type;
  final ProtocolButtonState buttonState;
  final String? progressText; // e.g., "2/3"
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;

  const ProtocolButton({
    super.key,
    required this.type,
    this.buttonState = ProtocolButtonState.empty,
    this.progressText,
    this.onTap,
    this.onLongPress,
    this.size = 72,
  });

  @override
  State<ProtocolButton> createState() => _ProtocolButtonState();
}

class _ProtocolButtonState extends State<ProtocolButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    if (widget.buttonState == ProtocolButtonState.complete) {
      _checkController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ProtocolButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.buttonState == ProtocolButtonState.complete &&
        oldWidget.buttonState != ProtocolButtonState.complete) {
      _checkController.forward();
    } else if (widget.buttonState != ProtocolButtonState.complete &&
        oldWidget.buttonState == ProtocolButtonState.complete) {
      _checkController.reverse();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.buttonState) {
      case ProtocolButtonState.complete:
        return _getTypeColor().withValues(alpha: 0.2);
      case ProtocolButtonState.partial:
        return Colors.white.withValues(alpha: 0.08);
      case ProtocolButtonState.empty:
        return Colors.transparent;
    }
  }

  Color get _borderColor {
    switch (widget.buttonState) {
      case ProtocolButtonState.complete:
        return _getTypeColor().withValues(alpha: 0.5);
      case ProtocolButtonState.partial:
        return Colors.white.withValues(alpha: 0.2);
      case ProtocolButtonState.empty:
        return Colors.white.withValues(alpha: 0.15);
    }
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case ProtocolType.gym:
        return const Color(0xFF22C55E); // Green
      case ProtocolType.meal:
        return const Color(0xFFF59E0B); // Amber
      case ProtocolType.dose:
        return const Color(0xFF3B82F6); // Blue
      case ProtocolType.meditation:
        return const Color(0xFF8B5CF6); // Purple
      case ProtocolType.focus:
        return const Color(0xFFEC4899); // Pink
      case ProtocolType.sleep:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress?.call();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            // Use soft pastel background based on type color
            color: _getTypeColor().withValues(alpha: 0.15),
            // More rounded, organic shape - less boxy
            borderRadius: BorderRadius.circular(widget.size * 0.35),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji icon
              Text(
                widget.type.emoji,
                style: TextStyle(
                  fontSize: widget.size * 0.3,
                ),
              ),
              const SizedBox(height: 4),
              // Label - dark text for visibility on light panel
              Text(
                widget.type.displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: widget.size * 0.11,
                  fontWeight: FontWeight.w600,
                  color: _getTypeColor().withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              // Status indicator
              _buildStatusIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    switch (widget.buttonState) {
      case ProtocolButtonState.complete:
        return ScaleTransition(
          scale: _checkAnimation,
          child: Icon(
            Icons.check,
            size: widget.size * 0.18,
            color: _getTypeColor(),
          ),
        );
      case ProtocolButtonState.partial:
        return Text(
          widget.progressText ?? '',
          style: TextStyle(
            fontSize: widget.size * 0.12,
            fontWeight: FontWeight.w500,
            color: _getTypeColor().withValues(alpha: 0.7),
          ),
        );
      case ProtocolButtonState.empty:
        return const SizedBox.shrink();
    }
  }
}

/// Protocol button states
enum ProtocolButtonState {
  empty, // Not started
  partial, // In progress (e.g., 2/3 meals)
  complete, // Done for the day
}

/// Row of protocol buttons for quick logging
class ProtocolButtonRow extends StatelessWidget {
  final Map<ProtocolType, ProtocolButtonState> states;
  final Map<ProtocolType, String>? progressTexts;
  final Function(ProtocolType) onTap;
  final Function(ProtocolType)? onLongPress;
  final List<ProtocolType> types;
  final double buttonSize;
  final double spacing;

  const ProtocolButtonRow({
    super.key,
    required this.states,
    this.progressTexts,
    required this.onTap,
    this.onLongPress,
    this.types = const [
      ProtocolType.gym,
      ProtocolType.meal,
      ProtocolType.dose,
      ProtocolType.meditation,
    ],
    this.buttonSize = 72,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: types.map((type) {
        return ProtocolButton(
          type: type,
          buttonState: states[type] ?? ProtocolButtonState.empty,
          progressText: progressTexts?[type],
          onTap: () => onTap(type),
          onLongPress: onLongPress != null ? () => onLongPress!(type) : null,
          size: buttonSize,
        );
      }).toList(),
    );
  }
}
