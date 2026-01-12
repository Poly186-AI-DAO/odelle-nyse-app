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
import '../widgets/organisms/mind/mantra_card.dart';

/// A beautiful infinite carousel screen for mantras and affirmations
///
/// Features:
/// - Infinite scrolling in both directions
/// - 3D card perspective animations
/// - Auto-advance with pause on touch
/// - Category filtering
/// - Add/edit mantras
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

  // Carousel state
  late PageController _pageController;
  double _currentPage = 0;
  int _virtualPage = 10000; // Start in the middle for infinite scroll

  // Auto-advance
  late AnimationController _autoAdvanceController;
  bool _isAutoAdvancing = true;
  static const Duration _autoAdvanceInterval = Duration(seconds: 8);

  // Categories for filtering
  final List<String?> _categories = [
    null, // All
    'morning',
    'focus',
    'motivation',
    'meditation',
    'stress',
    'evening',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _virtualPage,
      viewportFraction: 0.92, // Show peek of adjacent cards
    );
    _pageController.addListener(_onScroll);

    // Auto-advance timer
    _autoAdvanceController = AnimationController(
      vsync: this,
      duration: _autoAdvanceInterval,
    );
    _autoAdvanceController.addStatusListener(_onAutoAdvanceComplete);

    _loadMantras();
  }

  void _onScroll() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  void _onAutoAdvanceComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isAutoAdvancing && mounted) {
      _advanceToNextCard();
      _autoAdvanceController.forward(from: 0);
    }
  }

  void _advanceToNextCard() {
    if (_mantras.isEmpty) return;
    _pageController.animateToPage(
      _virtualPage + 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    _virtualPage++;
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

        // Start auto-advance after loading
        if (_mantras.isNotEmpty) {
          _autoAdvanceController.forward();
        }
      }

      Logger.debug('Loaded ${mantras.length} mantras', tag: _tag);
    } catch (e) {
      Logger.error('Failed to load mantras: $e', tag: _tag);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Mantra> get _filteredMantras {
    if (_selectedCategory == null) return _mantras;
    return _mantras.where((m) => m.category == _selectedCategory).toList();
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _autoAdvanceController.removeStatusListener(_onAutoAdvanceComplete);
    _autoAdvanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardOffset = (1 - widget.panelVisibility) * 50;
    final cardOpacity = widget.panelVisibility.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0), // Light silver background
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background breathing card
          Positioned(
            top: 6,
            left: 8,
            right: 8,
            bottom: MediaQuery.of(context).size.height * 0.18,
            child: Transform.translate(
              offset: Offset(0, cardOffset),
              child: Opacity(
                opacity: cardOpacity,
                child: BreathingCard(
                  borderRadius: 48,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: 16),

                // Category filter pills
                _buildCategoryFilter(),

                const SizedBox(height: 24),

                // Main carousel
                Expanded(
                  child: _isLoading
                      ? _buildLoading()
                      : _filteredMantras.isEmpty
                          ? _buildEmpty()
                          : _buildCarousel(),
                ),

                // Bottom spacer for visual balance
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
              ],
            ),
          ),

          // Bottom panel with controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: widget.showBackButton
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Text(
                  'MANTRAS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily Affirmations',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Auto-advance toggle
          IconButton(
            icon: Icon(
              _isAutoAdvancing
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              color: Colors.white.withValues(alpha: 0.8),
              size: 28,
            ),
            onPressed: () {
              setState(() {
                if (_isAutoAdvancing) {
                  _pauseAutoAdvance();
                } else {
                  _resumeAutoAdvance();
                }
              });
            },
            tooltip:
                _isAutoAdvancing ? 'Pause auto-advance' : 'Resume auto-advance',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          final label = category?.toUpperCase() ?? 'ALL';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  // Reset to first card when filter changes
                  _virtualPage = 10000;
                  _pageController.jumpToPage(_virtualPage);
                });
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarousel() {
    final mantras = _filteredMantras;

    return GestureDetector(
      // Pause auto-advance on touch
      onPanDown: (_) => _pauseAutoAdvance(),
      onPanEnd: (_) => _resumeAutoAdvance(),
      onPanCancel: () => _resumeAutoAdvance(),
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (page) {
          _virtualPage = page;
          HapticFeedback.selectionClick();
        },
        itemBuilder: (context, index) {
          // Infinite loop through mantras
          final mantraIndex = index % mantras.length;
          final mantra = mantras[mantraIndex];

          // Calculate scroll offset for animations (-1 to 1)
          final offset = (_currentPage - index).clamp(-1.0, 1.0);

          return MantraCard(
            mantra: mantra,
            scrollOffset: offset,
            index: mantraIndex,
            totalCount: mantras.length,
            isActive: offset.abs() < 0.5,
            onTap: () {
              // Copy to clipboard on tap
              Clipboard.setData(ClipboardData(text: mantra.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Mantra copied to clipboard',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: ThemeConstants.deepNavy,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
              HapticFeedback.mediumImpact();
            },
            onDoubleTap: () {
              // Favorite/unfavorite on double tap
              HapticFeedback.heavyImpact();
              // TODO: Implement favorite functionality
            },
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
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
            size: 64,
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
          const SizedBox(height: 8),
          Text(
            'Add your first affirmation',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.18,
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            children: [
              // Progress dots
              if (_filteredMantras.isNotEmpty) _buildProgressDots(),

              const Spacer(),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.add_rounded,
                    label: 'Add',
                    onTap: _showAddMantraDialog,
                  ),
                  _buildActionButton(
                    icon: Icons.shuffle_rounded,
                    label: 'Shuffle',
                    onTap: _shuffleToRandom,
                  ),
                  _buildActionButton(
                    icon: Icons.volume_up_rounded,
                    label: 'Speak',
                    onTap: _speakCurrentMantra,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    final mantras = _filteredMantras;
    final currentIndex = _virtualPage % mantras.length;

    // Show max 7 dots with ellipsis behavior
    const maxDots = 7;
    final showEllipsis = mantras.length > maxDots;
    final dotsToShow = showEllipsis ? maxDots : mantras.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotsToShow, (index) {
        // Calculate which dot should be active
        int dotIndex;
        if (showEllipsis) {
          // Center the current page in the dot display
          final offset = currentIndex - (maxDots ~/ 2);
          dotIndex = (offset + index) % mantras.length;
          if (dotIndex < 0) dotIndex += mantras.length;
        } else {
          dotIndex = index;
        }

        final isActive = dotIndex == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? ThemeConstants.accentBlue
                : ThemeConstants.textMuted.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ThemeConstants.deepNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 24,
              color: ThemeConstants.deepNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ThemeConstants.textSecondary,
            ),
          ),
        ],
      ),
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
                    // Handle
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
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textOnLight,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Text input
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: ThemeConstants.textOnLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your affirmation...',
                        hintStyle: GoogleFonts.inter(
                          color: ThemeConstants.textMuted,
                        ),
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

                    // Category selector
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
                          onTap: () {
                            setSheetState(() {
                              selectedCategory = cat;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
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

                    // Save button
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

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }

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
    final randomOffset = random.nextInt(_filteredMantras.length);

    _pageController.animateToPage(
      _virtualPage + randomOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
    _virtualPage += randomOffset;

    HapticFeedback.mediumImpact();
  }

  void _speakCurrentMantra() {
    if (_filteredMantras.isEmpty) return;

    final currentIndex = _virtualPage % _filteredMantras.length;
    final mantra = _filteredMantras[currentIndex];

    // TODO: Integrate with TTS service (ElevenLabs)
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Speaking: "${mantra.text.substring(0, math.min(50, mantra.text.length))}..."',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: ThemeConstants.deepNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    HapticFeedback.selectionClick();
  }
}
