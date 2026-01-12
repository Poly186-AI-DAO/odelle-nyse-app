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
    this.borderRadius = 40, // More rounded, less boxy
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, -8),
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
  final EdgeInsetsGeometry padding;
  final bool showHandle;
  final bool useSafeArea;
  final ScrollPhysics scrollPhysics;
  final bool pulseEnabled;
  final Duration pulseDuration;
  final double pulseAmplitude;
  final ValueChanged<double>? onProgressChanged;

  const DraggableBottomPanel({
    super.key,
    required this.child,
    this.expandedChild,
    this.minHeight = 300,
    this.maxHeight = 600,
    this.borderRadius = 32,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.showHandle = true,
    this.useSafeArea = true,
    this.scrollPhysics = const BouncingScrollPhysics(),
    this.pulseEnabled = false,
    this.pulseDuration = const Duration(milliseconds: 2800),
    this.pulseAmplitude = 6,
    this.onProgressChanged,
  });

  @override
  State<DraggableBottomPanel> createState() => _DraggableBottomPanelState();
}

class _DraggableBottomPanelState extends State<DraggableBottomPanel>
    with SingleTickerProviderStateMixin {
  late double _currentHeight;
  bool _isExpanded = false;
  bool _isDragging = false;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.minHeight;
    _configurePulse();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitProgress();
    });
  }

  @override
  void didUpdateWidget(DraggableBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseEnabled != widget.pulseEnabled ||
        oldWidget.pulseDuration != widget.pulseDuration ||
        oldWidget.pulseAmplitude != widget.pulseAmplitude) {
      _configurePulse();
    }
    if (oldWidget.minHeight != widget.minHeight ||
        oldWidget.maxHeight != widget.maxHeight) {
      _currentHeight =
          _currentHeight.clamp(widget.minHeight, widget.maxHeight);
      _emitProgress();
    }
  }

  void _emitProgress() {
    if (widget.onProgressChanged == null) return;
    final range = widget.maxHeight - widget.minHeight;
    final progress =
        range <= 0 ? 0.0 : (_currentHeight - widget.minHeight) / range;
    widget.onProgressChanged!(progress.clamp(0.0, 1.0));
  }

  void _configurePulse() {
    if (!widget.pulseEnabled) {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseAnimation = null;
      return;
    }

    _pulseController ??= AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    );
    _pulseController!.duration = widget.pulseDuration;
    _pulseAnimation = Tween<double>(
      begin: -widget.pulseAmplitude,
      end: widget.pulseAmplitude,
    ).animate(CurvedAnimation(
      parent: _pulseController!,
      curve: Curves.easeInOut,
    ));

    if (!_pulseController!.isAnimating && !_isDragging) {
      _pulseController!.repeat(reverse: true);
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (_isDragging) return;
    setState(() => _isDragging = true);
    _pulseController?.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentHeight -= details.delta.dy;
      _currentHeight = _currentHeight.clamp(widget.minHeight, widget.maxHeight);
    });
    _emitProgress();
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final midPoint = (widget.minHeight + widget.maxHeight) / 2;

    setState(() {
      _isDragging = false;
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
    _emitProgress();

    if (widget.pulseEnabled) {
      _pulseController?.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: widget.padding,
      child: _isExpanded && widget.expandedChild != null
          ? widget.expandedChild!
          : widget.child,
    );

    if (widget.useSafeArea) {
      content = SafeArea(top: false, left: false, right: false, child: content);
    }

    Widget panel = AnimatedContainer(
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
          if (widget.showHandle)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: Padding(
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
            ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: widget.scrollPhysics,
              child: content,
            ),
          ),
        ],
      ),
    );

    if (widget.pulseEnabled && _pulseController != null) {
      panel = AnimatedBuilder(
        animation: _pulseController!,
        child: panel,
        builder: (context, child) {
          final offset = _isDragging ? 0.0 : (_pulseAnimation?.value ?? 0.0);
          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
      );
    }

    return panel;
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }
}
