import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../widgets/widgets.dart';
import '../widgets/effects/breathing_card.dart';
import '../providers/service_providers.dart';
import '../providers/viewmodels/viewmodels.dart';
import '../services/psychograph_service.dart';

import 'chat_screen.dart';
import 'meditation_detail_screen.dart';
import 'meditation_screen.dart';

class SoulScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const SoulScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<SoulScreen> createState() => _SoulScreenState();
}

class _SoulScreenState extends ConsumerState<SoulScreen> {
  final PageController _mantraController =
      PageController(viewportFraction: 0.9);
  static const List<String> _galleryAssets = [
    'assets/icons/brain_icon.png',
    'assets/icons/yin_yang_icon.png',
    'assets/icons/wealth_icon.png',
    'assets/icons/bonds_icon.png',
    'assets/icons/body_powerlifting_icon.png',
    'assets/icons/mind_meditate_icon.png',
    'assets/icons/body_gym_icon.png',
    'assets/icons/body_icon.png',
  ];

  @override
  void initState() {
    super.initState();
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mindViewModelProvider.notifier).loadData(DateTime.now());
    });
  }

  @override
  void dispose() {
    _mantraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mindViewModelProvider);
    final viewModel = ref.read(mindViewModelProvider.notifier);
    final dailyState = ref.watch(dailyContentViewModelProvider);
    final psychographState = ref.watch(psychographStateStreamProvider);
    final prophecyState = ref.watch(dailyProphecyProvider);

    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;

    // Min panel: 38% of screen
    final minPanelHeight = screenHeight * 0.38;
    // Max panel: Leave room for nav bar + compact stats + padding
    final maxPanelHeight = screenHeight - safeTop - 70 - 100;

    // Calculate stats card position using BOTTOM coordinate
    // At rest: card's bottom edge is 20px above panel top
    // At expanded: card sits 16px above the expanded panel
    final cardBottomAtRest = minPanelHeight + 20;
    final cardBottomAtExpanded = maxPanelHeight + 16;

    // Smoothly interpolate using bottom coordinate
    final cardBottom = cardBottomAtRest +
        (state.panelProgress * (cardBottomAtExpanded - cardBottomAtRest));

    // Content crossfade (full card content vs compact bar content)
    final showFullCard = state.panelProgress < 0.6;

    return TwoToneSplitLayout(
      panelVisibility: widget.panelVisibility,
      bottomPanelMinHeight: minPanelHeight,
      bottomPanelMaxHeight: maxPanelHeight,
      bottomPanelShowHandle: true,
      bottomPanelPulseEnabled: true,
      bottomPanelProgressChanged: (progress) {
        viewModel.setPanelProgress(progress);
      },
      bottomPanel: _buildBottomPanelContent(
        context,
        state,
        viewModel,
        dailyState,
        psychographState,
        prophecyState,
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Hero content - always shown, animates with panel
            if (!state.isLoading)
              Positioned(
                left: 20,
                right: 20,
                bottom: cardBottom,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: showFullCard
                      ? _buildHeroContent(state)
                      : _buildCompactCosmicBar(state),
                ),
              ),

            // Loading indicator
            if (state.isLoading && state.identityData == null)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  /// Hero content (Identity Matrix on dark breathing card)
  Widget _buildHeroContent(MindState state) {
    if (state.identityData == null) {
      return Container(
        key: const ValueKey('full-empty'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: ThemeConstants.borderRadiusXL,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          'Good Evening',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      );
    }

    final identity = state.identityData!;
    final astrology = Map<String, String>.from(identity['astrology'] ?? {});

    // Archetypes logic
    final archetypesRaw = identity['archetypes'];
    List<String> archetypes = [];
    if (archetypesRaw is Map) {
      final archetypeMap = Map<String, dynamic>.from(archetypesRaw);
      if (archetypeMap['ego'] != null) {
        archetypes.add(archetypeMap['ego'].toString());
      }
      if (archetypeMap['soul'] != null) {
        archetypes.add(archetypeMap['soul'].toString());
      }
      if (archetypeMap['self'] != null) {
        archetypes.add(archetypeMap['self'].toString());
      }
    } else if (archetypesRaw is List) {
      archetypes = List<String>.from(archetypesRaw);
    }

    final numerology = Map<String, dynamic>.from(identity['numerology'] ?? {});
    final lifePath = (numerology['lifePath'] as num?)?.toInt();
    final destiny = (numerology['destiny'] as num?)?.toInt();
    final birthNumber = (numerology['birthNumber'] as num?)?.toInt() ??
        (numerology['lifePath'] as num?)?.toInt();
    final mbti = identity['mbti']?.toString() ?? '';

    return Column(
      key: const ValueKey('full'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'COSMIC STATS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        _buildCosmicStatsCard(
          astrology: astrology,
          lifePath: lifePath,
          destiny: destiny,
          birthNumber: birthNumber,
          mbti: mbti,
        ),
        if (archetypes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: archetypes
                .map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        a.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  /// Compact cosmic bar - shown when panel is expanded
  Widget _buildCompactCosmicBar(MindState state) {
    if (state.identityData == null) {
      return Container(
        key: const ValueKey('compact-empty'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          '✨ Loading...',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      );
    }

    final identity = state.identityData!;
    final astrology = Map<String, String>.from(identity['astrology'] ?? {});
    final numerology = Map<String, dynamic>.from(identity['numerology'] ?? {});
    final lifePath = (numerology['lifePath'] as num?)?.toInt();
    final mbti = identity['mbti']?.toString() ?? '';

    return Container(
      key: const ValueKey('compact'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat('☀️', astrology['sun'] ?? '--'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat('🔢', lifePath?.toString() ?? '--'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat('🧠', mbti.isNotEmpty ? mbti : '--'),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCosmicStatsCard({
    required Map<String, String> astrology,
    required int? lifePath,
    required int? destiny,
    required int? birthNumber,
    required String mbti,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: ThemeConstants.borderRadiusXL,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCosmicValue('BIRTH #', _formatNumber(birthNumber)),
              _buildCosmicValue('LIFE PATH', _formatNumber(lifePath)),
              _buildCosmicValue('DESTINY', _formatNumber(destiny)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCosmicValue('SUN', astrology['sun'] ?? '--'),
              _buildCosmicValue('MOON', astrology['moon'] ?? '--'),
              _buildCosmicValue('RISING', astrology['rising'] ?? '--'),
            ],
          ),
          if (mbti.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildCosmicTag('MBTI', mbti),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCosmicValue(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCosmicTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$label $value',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _formatNumber(int? value) {
    if (value == null || value <= 0) return '--';
    return value.toString();
  }

  /// Bottom panel content
  Widget _buildBottomPanelContent(
    BuildContext context,
    MindState state,
    MindViewModel viewModel,
    DailyContentState dailyState,
    AsyncValue<PsychographState> psychographState,
    AsyncValue<String> prophecyState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(context, dailyState.isGenerating),
        const SizedBox(height: 16),

        // HealthKit Quick Stats
        // Show if we have any data
        if (state.mindfulMinutes != null || state.restingHeartRate != null) ...[
          _buildHealthKitMindStats(state),
          const SizedBox(height: 16),
        ],

        // Schedule / Week Day Picker
        WeekDayPicker(
          selectedDate: state.selectedDate,
          headerText: "Your day ahead",
          onDateSelected: (date) {
            viewModel.selectDate(date);
            ref
                .read(dailyContentViewModelProvider.notifier)
                .refreshForDate(date);
          },
        ),

        const SizedBox(height: 16),

        _buildSectionHeader('DAILY MANTRAS'),
        const SizedBox(height: 12),
        _buildMantraStacker(dailyState),

        const SizedBox(height: 20),

        // Sleep Card
        _buildSleepCard(state),

        const SizedBox(height: 24),

        _buildSectionHeader('MEDITATION CARDS'),
        const SizedBox(height: 12),
        _buildMeditationCards(context, dailyState),

        const SizedBox(height: 24),

        _buildSectionHeader('INSIGHTS'),
        const SizedBox(height: 12),
        _buildInsightCards(psychographState),

        const SizedBox(height: 24),

        _buildSectionHeader('DAILY PROPHECY'),
        const SizedBox(height: 12),
        _buildProphecyCard(prophecyState),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context, bool isGenerating) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s make progress today',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textOnLight,
                ),
              ),
              if (isGenerating)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Generating your daily content...',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            _buildHeaderAction(
              icon: Icons.self_improvement,
              label: 'Meditate',
              color: ThemeConstants.polyPurple300,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MeditationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildHeaderAction(
              icon: Icons.chat_bubble_outline,
              label: 'NTS',
              color: ThemeConstants.accentBlue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildHeaderAction(
              icon: Icons.auto_fix_high,
              label: 'Prophecy',
              color: const Color(0xFFF59E0B),
              onTap: _showProphecySheet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(
            icon: icon,
            color: color,
            size: 34,
            iconSize: 18,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMantraStacker(DailyContentState dailyState) {
    final mantras = dailyState.mantras;
    if (mantras.isEmpty) {
      return _buildEmptyPanelCard('Daily mantras are warming up...');
    }

    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: _mantraController,
        itemCount: mantras.length,
        itemBuilder: (context, index) {
          final text = mantras[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ThemeConstants.polyMint400.withValues(alpha: 0.12),
                    ThemeConstants.polyPurple200.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                    color:
                        ThemeConstants.glassBorderWeak.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageStrip(text, count: 3, height: 48),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 16,
                        color: ThemeConstants.polyMint400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY MANTRA',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          color: ThemeConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      '"$text"',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: ThemeConstants.textOnLight,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Swipe for more',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeditationCards(
    BuildContext context,
    DailyContentState dailyState,
  ) {
    final meditations = dailyState.meditations;
    if (meditations.isEmpty) {
      return _buildEmptyPanelCard('Meditation cards are preparing...');
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: meditations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final meditation = meditations[index];
          return _buildMeditationCard(context, meditation);
        },
      ),
    );
  }

  Widget _buildMeditationCard(
    BuildContext context,
    DailyMeditation meditation,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MeditationDetailScreen(
              title: meditation.title,
              duration: meditation.durationMinutes,
              type: meditation.meditationType,
              audioPath: meditation.audioPath,
            ),
          ),
        );
      },
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ThemeConstants.glassBorderWeak),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: _buildMeditationImage(meditation.imagePath),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textOnLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meditation.durationMinutes} min · ${meditation.type}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meditation.description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ThemeConstants.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationImage(String? imagePath) {
    if (imagePath != null && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConstants.polyPurple300.withValues(alpha: 0.6),
            ThemeConstants.deepNavy,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.self_improvement,
          color: Colors.white70,
          size: 32,
        ),
      ),
    );
  }

  List<String> _pickGalleryAssets(String seed, int count) {
    if (_galleryAssets.isEmpty || count <= 0) return [];
    final start = seed.hashCode.abs() % _galleryAssets.length;
    return List.generate(
      count,
      (index) => _galleryAssets[(start + index) % _galleryAssets.length],
    );
  }

  LinearGradient _galleryGradientFor(String seed) {
    const palettes = [
      [ThemeConstants.polyPurple300, ThemeConstants.deepNavy],
      [ThemeConstants.polyMint400, ThemeConstants.polyBlue300],
      [ThemeConstants.polyPink400, ThemeConstants.polyPurple200],
      [ThemeConstants.sunsetGold, ThemeConstants.warmTaupe],
      [ThemeConstants.steelBlue, ThemeConstants.darkTeal],
    ];
    final palette = palettes[seed.hashCode.abs() % palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: palette,
    );
  }

  Widget _buildGalleryTile(String asset, {double radius = 12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          gradient: _galleryGradientFor(asset),
        ),
        child: Center(
          child: Image.asset(
            asset,
            width: 28,
            height: 28,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildImageStrip(String seed, {int count = 3, double height = 54}) {
    final assets = _pickGalleryAssets(seed, count);
    if (assets.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < assets.length; i++) ...[
            Expanded(child: _buildGalleryTile(assets[i], radius: 10)),
            if (i < assets.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildImageMosaic(String seed, {int count = 6}) {
    final assets = _pickGalleryAssets(seed, count);
    if (assets.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const gap = 12.0;
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final asset in assets)
              SizedBox(
                width: tileWidth,
                height: tileWidth * 0.75,
                child: _buildGalleryTile(asset, radius: 14),
              ),
          ],
        );
      },
    );
  }

  Widget _buildImagePromptList(List<String> prompts) {
    if (prompts.isEmpty) {
      return Text(
        'Image prompts are calibrating...',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: ThemeConstants.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < prompts.length; i++) ...[
          Text(
            '${i + 1}. ${prompts[i]}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: ThemeConstants.textSecondary,
              height: 1.35,
            ),
          ),
          if (i < prompts.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildInsightCategoryTag(InsightCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeConstants.polyPurple200.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: ThemeConstants.polyPurple400,
        ),
      ),
    );
  }

  Widget _buildInsightCards(AsyncValue<PsychographState> psychographState) {
    return psychographState.when(
      loading: () => _buildEmptyPanelCard('Insights are loading...'),
      error: (_, __) => _buildEmptyPanelCard('Insights unavailable right now.'),
      data: (state) {
        if (state.insights.isEmpty) {
          return _buildEmptyPanelCard('Insights are calibrating...');
        }

        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.insights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildInsightCard(state.insights[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(PsychographInsight insight) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showInsightSheet(insight),
        child: Container(
          width: 240,
          height: 210,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ThemeConstants.glassBorderWeak),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageStrip(insight.title, count: 3, height: 54),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildInsightCategoryTag(insight.category),
                  const Spacer(),
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: ThemeConstants.polyPurple400,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                insight.title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textOnLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  insight.body,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ThemeConstants.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Tap to explore',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: ThemeConstants.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProphecyCard(AsyncValue<String> prophecyState) {
    return prophecyState.when(
      loading: () => _buildEmptyPanelCard('Prophecy is weaving...'),
      error: (_, __) => _buildEmptyPanelCard('Prophecy unavailable right now.'),
      data: (prophecy) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _showProphecySheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ThemeConstants.glassBorderWeak),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageStrip(prophecy, count: 4, height: 62),
                  const SizedBox(height: 12),
                  Text(
                    prophecy,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ThemeConstants.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Tap to explore',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ThemeConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: ThemeConstants.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyPanelCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeConstants.glassBorderWeak),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: ThemeConstants.textSecondary,
        ),
      ),
    );
  }

  Future<void> _showInsightSheet(PsychographInsight insight) async {
    if (!mounted) return;

    final prompts = insight.imagePrompts
        .map((prompt) => prompt.trim())
        .where((prompt) => prompt.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: ThemeConstants.panelWhite,
                borderRadius: ThemeConstants.borderRadiusBottomSheet,
                boxShadow: ThemeConstants.cardShadow,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: ThemeConstants.spacingSmall),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ThemeConstants.textMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: ThemeConstants.spacingMedium),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeConstants.spacingLarge,
                      ),
                      child: Row(
                        children: [
                          _buildInsightCategoryTag(insight.category),
                          const Spacer(),
                          Text(
                            'Insight',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ThemeConstants.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ThemeConstants.spacingSmall),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          ThemeConstants.spacingLarge,
                          0,
                          ThemeConstants.spacingLarge,
                          ThemeConstants.spacingLarge,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageMosaic(insight.title, count: 6),
                            const SizedBox(height: 16),
                            _buildSectionHeader('IMAGE PROMPTS'),
                            const SizedBox(height: 8),
                            _buildImagePromptList(prompts),
                            const SizedBox(height: 18),
                            Text(
                              insight.title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: ThemeConstants.textOnLight,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              insight.body,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: ThemeConstants.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            if (insight.action.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildSectionHeader('SUGGESTED ACTION'),
                              const SizedBox(height: 8),
                              Text(
                                insight.action,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: ThemeConstants.textOnLight,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showProphecySheet() async {
    try {
      final prophecy = await ref.read(dailyProphecyProvider.future);
      final imagePromptsFuture =
          ref.read(dailyProphecyImagePromptsProvider.future);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: ThemeConstants.panelWhite,
                  borderRadius: ThemeConstants.borderRadiusBottomSheet,
                  boxShadow: ThemeConstants.cardShadow,
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: ThemeConstants.spacingSmall),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ThemeConstants.textMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: ThemeConstants.spacingMedium),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeConstants.spacingLarge,
                        ),
                        child: Text(
                          'Daily Prophecy',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ThemeConstants.textOnLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: ThemeConstants.spacingSmall),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            ThemeConstants.spacingLarge,
                            0,
                            ThemeConstants.spacingLarge,
                            ThemeConstants.spacingLarge,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<List<String>>(
                                future: imagePromptsFuture,
                                builder: (context, snapshot) {
                                  final prompts = snapshot.data ?? [];
                                  final count = prompts.isEmpty
                                      ? 6
                                      : (prompts.length.clamp(4, 6) as int);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildImageMosaic(prophecy, count: count),
                                      const SizedBox(height: 16),
                                      _buildSectionHeader('IMAGE PROMPTS'),
                                      const SizedBox(height: 8),
                                      if (snapshot.connectionState ==
                                              ConnectionState.waiting &&
                                          prompts.isEmpty)
                                        Text(
                                          'Image prompts are weaving...',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: ThemeConstants.textSecondary,
                                          ),
                                        )
                                      else
                                        _buildImagePromptList(prompts),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(
                                prophecy,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: ThemeConstants.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ThemeConstants.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSleepCard(MindState state) {
    // Prioritize HealthKit data
    if (state.sleepData != null) {
      final sleep = state.sleepData!;
      final totalMinutes = sleep.totalDuration.inMinutes;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      final awakeMinutes = sleep.awake?.inMinutes;
      final deepMinutes = sleep.deepSleep?.inMinutes;
      final hasDeepData = deepMinutes != null && totalMinutes > 0;
      final deepPercentage = hasDeepData ? deepMinutes / totalMinutes : 0.0;
      final deepLabel = hasDeepData ? null : 'Deep Sleep: --';

      return SleepCard(
        totalSleep: '${hours}h ${minutes}m',
        sleepScore: sleep.qualityScore,
        timeAsleep: '${hours}h ${minutes}m',
        timeAwake: awakeMinutes != null ? '${awakeMinutes}m' : '--',
        deepSleepPercentage: deepPercentage,
        deepSleepLabel: deepLabel,
      );
    }

    // Fallback to JSON data
    if (state.sleepLogFallback != null) {
      final sleepLog = state.sleepLogFallback!;
      final startTime =
          DateTime.tryParse((sleepLog['start_time'] ?? '') as String);
      final endTime = DateTime.tryParse((sleepLog['end_time'] ?? '') as String);
      final durationMin = startTime != null && endTime != null
          ? endTime.difference(startTime).inMinutes
          : ((sleepLog['duration_minutes'] ?? 0) as num).toInt();
      final deepMinutes = (sleepLog['deep_sleep_minutes'] as num?)?.toInt();
      final hasDeepData = deepMinutes != null && durationMin > 0;
      final deepPercentage = hasDeepData ? deepMinutes / durationMin : 0.0;
      final deepLabel = hasDeepData ? null : 'Deep Sleep: --';
      return SleepCard(
        totalSleep: '${durationMin ~/ 60}h ${durationMin % 60}m',
        sleepScore: ((sleepLog['quality_score'] ?? 85) as num).toInt(),
        timeAsleep: '${durationMin ~/ 60}h ${durationMin % 60}m',
        timeAwake: '--',
        deepSleepPercentage: deepPercentage,
        deepSleepLabel: deepLabel,
      );
    }

    // No sleep data available
    return const SizedBox.shrink();
  }

  Widget _buildHealthKitMindStats(MindState state) {
    return Row(
      children: [
        Expanded(
          child: _buildMindStatCard(
            Icons.self_improvement,
            ThemeConstants.polyMint400,
            '${state.mindfulMinutes?.inMinutes ?? 0}',
            'mindful min',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMindStatCard(
            Icons.favorite,
            const Color(0xFFEF4444),
            '${state.restingHeartRate ?? '--'}',
            'resting HR',
          ),
        ),
      ],
    );
  }

  Widget _buildMindStatCard(
      IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeConstants.glassBorderWeak),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.textOnLight,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: ThemeConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
