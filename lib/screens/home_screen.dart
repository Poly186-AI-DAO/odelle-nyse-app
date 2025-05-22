import 'package:flutter/material.dart';
import 'package:odelle_nyse/widgets/voice_assistant_button.dart'; // Placeholder
import 'package:odelle_nyse/constants/colors.dart'; // Placeholder for AppColors
import 'package:odelle_nyse/widgets/glassmorphism.dart';
// import 'package:odelle_nyse/widgets/glassmorphic_card.dart'; // Placeholder
// import 'package:odelle_nyse/widgets/hero_journey_card.dart'; // Placeholder
// import 'package:odelle_nyse/widgets/recent_insights_card.dart'; // Placeholder
// import 'package:odelle_nyse/widgets/daily_affirmation_card.dart'; // Placeholder
// import 'package:odelle_nyse/widgets/thought_emotion_behavior_row.dart'; // Placeholder

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Odelle Nyse',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              GlassMorphism(
                child: SizedBox(
                  height: 160,
                  child: Center(child: Text("Hero's Journey Placeholder")),
                ),
              ),
              SizedBox(height: 16),
              GlassMorphism(
                child: SizedBox(
                  height: 120,
                  child: Center(child: Text("Recent Insights Placeholder")),
                ),
              ),
              SizedBox(height: 16),
              GlassMorphism(
                child: SizedBox(
                  height: 120,
                  child: Center(child: Text("Daily Affirmation Placeholder")),
                ),
              ),
              SizedBox(height: 16),
              GlassMorphism(
                child: SizedBox(
                  height: 100,
                  child: Center(child: Text("Thought/Emotion/Behavior Placeholder")),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const VoiceAssistantButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
