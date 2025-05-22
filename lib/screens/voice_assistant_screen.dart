import 'package:flutter/material.dart';
import 'package:odelle_nyse/constants/colors.dart';
import 'package:odelle_nyse/widgets/glassmorphism.dart';

class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: GlassMorphism(
          blur: 18,
          opacity: 0.13,
          color: AppColors.background,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: GlassMorphism(
                    child: Center(child: Text("AudioWaveformVisualizer Placeholder")),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  flex: 2,
                  child: GlassMorphism(
                    child: Center(child: Text("TranscriptionView Placeholder")),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: GlassMorphism(
                    child: Center(child: Text("VoiceControlBar Placeholder")),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
