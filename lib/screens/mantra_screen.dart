import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../database/app_database.dart';
import '../models/mantra.dart';
import '../utils/logger.dart';
import '../widgets/atoms/odelle_button.dart';
import '../widgets/effects/breathing_card.dart';

/// Mantra Screen with Z-stacked vertical card swipe
/// Cards stack on top of each other, swipe up/down to navigate
class MantraScreen extends ConsumerStatefulWidget {
  final double panelVisibility;
  final bool showBackButton;

  const MantraScreen({
    super.key,
    this.panelVisibility = 1.0,
    this.showBackButton = true,
  });

  @override
  ConsumerState<MantraScreen> createState() => _MantraScreenState();
}

class _MantraScreenState extends ConsumerState<MantraScreen>
    with TickerProviderStateMixin {
  static const String _tag = 'MantraScreen';

  // Data
  List<Mantra> _mantras = [];
  bool _isLoading = true;
  String? _selectedCategory;

  // Card stack state
  int _currentIndex = 0;
  double _dragOffset = 0;

  // Auto-advance
  late AnimationController _autoAdvanceController;
  bool _isAutoAdvancing = true;
  static const Duration _autoAdvanceInterval = Duration(seconds: 8);

  // Card animation
  late AnimationController _cardAnimController;



  @override
  void initState() {
    super.initState();

    _autoAdvanceController = AnimationController(
      vsync: this,
      duration: _autoAdvanceInterval,
    );
    _autoAdvanceController.addStatusListener(_onAutoAdvanceComplete);

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadMantras();
  }

  void _onAutoAdvanceComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isAutoAdvancing && mounted) {
      _goToNext();
      _autoAdvanceController.forward(from: 0);
    }
  }

  void _pauseAutoAdvance() {
    _isAutoAdvancing = false;
    _autoAdvanceController.stop();
  }

  void _resumeAutoAdvance() {
    _isAutoAdvancing = true;
    _autoAdvanceController.forward(from: 0);
  }

  Future<void> _loadMantras() async {
    try {
      final db = AppDatabase.instance;
      final mantras = await db.getMantras(activeOnly: true);

      if (mounted) {
        setState(() {
          _mantras = mantras;
          _isLoading = false;
        });

        if (_mantras.isNotEmpty) {
          _autoAdvanceController.forward();
        }
      }

      Logger.debug('Loaded ${mantras.length} mantras', tag: _tag);
    } catch (e) {
      Logger.error('Failed to load mantras: $e', tag: _tag);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Mantra> get _filteredMantras {
    if (_selectedCategory == null) return _mantras;
    return _mantras.where((m) => m.category == _selectedCategory).toList();
  }

  void _goToNext() {
    if (_filteredMantras.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _filteredMantras.length;
    });
    HapticFeedback.selectionClick();
  }

  void _goToPrevious() {
    if (_filteredMantras.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _filteredMantras.length) %
          _filteredMantras.length;
    });
    HapticFeedback.selectionClick();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _pauseAutoAdvance();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    // Swipe up = next, swipe down = previous
    if (_dragOffset < -50 || velocity < -500) {
      _goToNext();
    } else if (_dragOffset > 50 || velocity > 500) {
      _goToPrevious();
    }

    setState(() => _dragOffset = 0);
    _resumeAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceController.removeStatusListener(_onAutoAdvanceComplete);
    _autoAdvanceController.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      bottomPercentage: 0.0,
      bottomPanel: null,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 70),

              // Z-stacked cards
              Expanded(
                child: _isLoading
                    ? _buildLoading()
                    : _filteredMantras.isEmpty
                        ? _buildEmpty()
                        : _buildCardStack(),
              ),

              // Progress indicator
              if (_filteredMantras.isNotEmpty) _buildProgressIndicator(),

              const SizedBox(height: 16),

              // Floating action buttons (voice screen style)
              _buildFloatingActionButtons(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    final mantras = _filteredMantras;
    if (mantras.isEmpty) return _buildEmpty();

    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background cards (stacked behind)
          for (int i = 2; i >= 1; i--)
            if (_currentIndex + i < mantras.length ||
                mantras.length > 2) // Show stack preview
              _buildStackedCard(
                mantras[(_currentIndex + i) % mantras.length],
                stackPosition: i,
              ),

          // Current card (top of stack)
          _buildCurrentCard(mantras[_currentIndex]),
        ],
      ),
    );
  }

  Widget _buildStackedCard(Mantra mantra, {required int stackPosition}) {
    // Cards behind are smaller and offset down
    final scale = 1.0 - (stackPosition * 0.05);
    final yOffset = stackPosition * 12.0;
    final opacity = 1.0 - (stackPosition * 0.2);

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: _buildCardContent(mantra, isBackground: true),
        ),
      ),
    );
  }

  Widget _buildCurrentCard(Mantra mantra) {
    // Animate based on drag
    final dragProgress = (_dragOffset / 150).clamp(-1.0, 1.0);
    final rotation = dragProgress * 0.02;
    final yOffset = _dragOffset * 0.3;

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.rotate(
        angle: rotation,
        child: _buildCardContent(mantra, isBackground: false),
      ),
    );
  }

  Widget _buildCardContent(Mantra mantra, {required bool isBackground}) {
    final categoryColor = _getCategoryColor(mantra.category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: isBackground ? 0.08 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(mantra.category),
                  size: 14,
                  color: categoryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  (mantra.category ?? 'mantra').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Mantra text
          Text(
            '"${mantra.text}"',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Swipe hint
          if (!isBackground)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  'Swipe to explore',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'morning':
        return const Color(0xFFFFB347);
      case 'focus':
        return ThemeConstants.accentBlue;
      case 'motivation':
        return const Color(0xFFFF6B6B);
      case 'meditation':
        return const Color(0xFF9B59B6);
      case 'stress':
        return const Color(0xFF26C6DA);
      case 'evening':
        return const Color(0xFF5C6BC0);
      default:
        return ThemeConstants.polyMint400;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'focus':
        return Icons.center_focus_strong_outlined;
      case 'motivation':
        return Icons.flash_on_outlined;
      case 'meditation':
        return Icons.self_improvement_outlined;
      case 'stress':
        return Icons.spa_outlined;
      case 'evening':
        return Icons.nightlight_round_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            'Loading mantras...',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory != null
                ? 'No mantras in this category'
                : 'No mantras yet',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFloatingPillButton(
          icon: Icons.add_rounded,
          label: 'Add',
          onTap: _showAddMantraDialog,
        ),
        const SizedBox(width: 12),
        _buildFloatingPillButton(
          icon: _isAutoAdvancing
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: _isAutoAdvancing ? 'Pause' : 'Play',
          onTap: () {
            setState(() {
              if (_isAutoAdvancing) {
                _pauseAutoAdvance();
              } else {
                _resumeAutoAdvance();
              }
            });
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(width: 12),
        _buildFloatingPillButton(
          icon: Icons.shuffle_rounded,
          label: 'Shuffle',
          onTap: _shuffleToRandom,
        ),
      ],
    );
  }

  Widget _buildFloatingPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final mantras = _filteredMantras;
    final currentIndex = _currentIndex % mantras.length;

    const maxDots = 5;
    final showEllipsis = mantras.length > maxDots;
    final dotsToShow = showEllipsis ? maxDots : mantras.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotsToShow, (index) {
        int dotIndex;
        if (showEllipsis) {
          final offset = currentIndex - (maxDots ~/ 2);
          dotIndex = (offset + index) % mantras.length;
          if (dotIndex < 0) dotIndex += mantras.length;
        } else {
          dotIndex = index;
        }

        final isActive = dotIndex == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  void _showAddMantraDialog() {
    final textController = TextEditingController();
    String selectedCategory = 'morning';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Add New Mantra',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textOnLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: ThemeConstants.textOnLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your affirmation...',
                        hintStyle:
                            GoogleFonts.inter(color: ThemeConstants.textMuted),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'morning',
                        'focus',
                        'motivation',
                        'meditation',
                        'stress',
                        'evening'
                      ].map((cat) {
                        final isSelected = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ThemeConstants.accentBlue
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : ThemeConstants.textSecondary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    OdelleButtonFullWidth.dark(
                      text: 'Save Mantra',
                      onPressed: () async {
                        if (textController.text.trim().isEmpty) return;
                        final mantra = Mantra(
                          text: textController.text.trim(),
                          category: selectedCategory,
                          isActive: true,
                        );
                        await AppDatabase.instance.insertMantra(mantra);
                        await _loadMantras();
                        if (context.mounted) Navigator.of(context).pop();
                        HapticFeedback.mediumImpact();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _shuffleToRandom() {
    if (_filteredMantras.isEmpty) return;
    final random = math.Random();
    setState(() {
      _currentIndex = random.nextInt(_filteredMantras.length);
    });
    HapticFeedback.mediumImpact();
  }
}
