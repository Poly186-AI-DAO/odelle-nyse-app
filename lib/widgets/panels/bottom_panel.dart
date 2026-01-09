import 'package:flutter/material.dart';

/// White bottom panel with rounded top corners
/// Primary content container for dashboard cards
class BottomPanel extends StatelessWidget {
  final Widget child;
  final double? minHeight;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final bool showHandle;

  const BottomPanel({
    super.key,
    required this.child,
    this.minHeight,
    this.borderRadius = 32,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor = Colors.white,
    this.showHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle) ...[
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Draggable bottom panel that can be swiped up/down
class DraggableBottomPanel extends StatefulWidget {
  final Widget child;
  final Widget? expandedChild;
  final double minHeight;
  final double maxHeight;
  final double borderRadius;
  final Color backgroundColor;

  const DraggableBottomPanel({
    super.key,
    required this.child,
    this.expandedChild,
    this.minHeight = 300,
    this.maxHeight = 600,
    this.borderRadius = 32,
    this.backgroundColor = Colors.white,
  });

  @override
  State<DraggableBottomPanel> createState() => _DraggableBottomPanelState();
}

class _DraggableBottomPanelState extends State<DraggableBottomPanel> {
  late double _currentHeight;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.minHeight;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentHeight -= details.delta.dy;
      _currentHeight = _currentHeight.clamp(widget.minHeight, widget.maxHeight);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final midPoint = (widget.minHeight + widget.maxHeight) / 2;

    setState(() {
      if (velocity < -500) {
        // Fast swipe up
        _currentHeight = widget.maxHeight;
        _isExpanded = true;
      } else if (velocity > 500) {
        // Fast swipe down
        _currentHeight = widget.minHeight;
        _isExpanded = false;
      } else {
        // Snap to nearest
        if (_currentHeight > midPoint) {
          _currentHeight = widget.maxHeight;
          _isExpanded = true;
        } else {
          _currentHeight = widget.minHeight;
          _isExpanded = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: _currentHeight,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(widget.borderRadius),
            topRight: Radius.circular(widget.borderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isExpanded && widget.expandedChild != null
                      ? widget.expandedChild!
                      : widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
