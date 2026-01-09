import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/theme_constants.dart';
import '../widgets/navigation/pillar_nav_bar.dart';
import '../widgets/voice/voice_button.dart';
import 'body_screen.dart';
import 'voice_screen.dart';
import 'mind_screen.dart';

/// Main home screen with horizontal pager navigation
/// 3 Pillars: Body (left) | Voice (center/default) | Mind (right)
/// Voice button persists across all pages
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 1; // Start on Voice (center)

  // Pillar definitions
  static const List<PillarItem> _pillars = [
    PillarItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Body',
    ),
    PillarItem(
      icon: Icons.graphic_eq_outlined,
      activeIcon: Icons.graphic_eq,
      label: 'Voice',
    ),
    PillarItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'Mind',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.selectionClick();
  }

  void _onPillarTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onVoiceButtonTap() {
    // Navigate to voice page if not already there
    if (_currentPage != 1) {
      _onPillarTapped(1);
    }
    // TODO: Start voice recording
  }

  void _onVoiceButtonLongPressStart() {
    // Start recording
    HapticFeedback.mediumImpact();
  }

  void _onVoiceButtonLongPressEnd() {
    // Stop recording
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.deepNavy,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: ThemeConstants.fintechDarkGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top navigation bar with pillar icons
              PillarNavBar(
                pillars: _pillars,
                currentIndex: _currentPage,
                onPillarTapped: _onPillarTapped,
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: const [
                    BodyScreen(),
                    VoiceScreen(),
                    MindScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Persistent voice button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: VoiceButton(
          size: 64,
          onTap: _onVoiceButtonTap,
          onLongPressStart: _onVoiceButtonLongPressStart,
          onLongPressEnd: _onVoiceButtonLongPressEnd,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
