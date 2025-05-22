import 'package:flutter/material.dart';
import 'package:odelle_nyse/widgets/voice_assistant_button.dart';
import 'package:odelle_nyse/constants/colors.dart';
import 'package:odelle_nyse/widgets/glassmorphism.dart';
import 'package:odelle_nyse/widgets/hero_journey_card.dart';
import 'package:odelle_nyse/widgets/recent_insights_card.dart';
import 'package:odelle_nyse/widgets/daily_affirmation_card.dart';
import 'package:odelle_nyse/widgets/thought_emotion_behavior_card.dart';
import 'package:odelle_nyse/services/logging_service.dart'; // Import LoggingService
import 'package:odelle_nyse/models/journey_model.dart';
import 'package:odelle_nyse/models/insights_model.dart';
import 'package:odelle_nyse/models/affirmation_model.dart';
import 'package:odelle_nyse/models/cbt_model.dart';

class _HomeContent extends StatelessWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Load sample data
    final heroJourney = HeroJourney.example();
    final insightEntry = UserInsights.example().mostRecent!;
    final affirmation = Affirmation.today();
    final cbtEntry = ThoughtEmotionBehavior.getMostRecent()!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeroJourneyCard(journey: heroJourney),
        const SizedBox(height: 16),
        RecentInsightsCard(insightEntry: insightEntry),
        const SizedBox(height: 16),
        DailyAffirmationCard(affirmation: affirmation),
        const SizedBox(height: 16),
        ThoughtEmotionBehaviorCard(entry: cbtEntry),
        const SizedBox(height: 80), // Space for floating action button
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LoggingService.info("HomeScreen built"); // Add logging
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: GlassMorphism(
          blur: 18,
          opacity: 0.13,
          color: AppColors.background,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'ODELLE NYSE',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 24,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.mintLight,  // Light teal at top
              AppColors.primary,    // Mint in the upper middle
              AppColors.secondary,  // Purple in the lower middle  
              AppColors.accent1,    // Orange at the bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: const _HomeContent(),
        ),
      ),
      floatingActionButton: const VoiceAssistantButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
