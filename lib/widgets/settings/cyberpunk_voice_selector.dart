import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';
import '../../models/digital_worker_voice.dart';

class CyberpunkVoiceSelector extends StatelessWidget {
  final DigitalWorkerVoice selectedVoice;
  final Function(DigitalWorkerVoice) onVoiceSelected;

  const CyberpunkVoiceSelector({
    super.key,
    required this.selectedVoice,
    required this.onVoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMedium,
        vertical: ThemeConstants.spacingSmall,
      ),
      padding: const EdgeInsets.all(ThemeConstants.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(
          color: ThemeConstants.borderColor,
          width: ThemeConstants.borderWidth,
        ),
        color: Colors.black87,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOICE MODEL',
            style: GoogleFonts.pressStart2p(
              color: ThemeConstants.secondaryTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingMedium),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeConstants.spacingMedium,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: ThemeConstants.primaryColor,
                width: 1,
              ),
            ),
            child: DropdownButton<DigitalWorkerVoice>(
              value: selectedVoice,
              isExpanded: true,
              dropdownColor: Colors.black87,
              underline: const SizedBox(),
              style: GoogleFonts.pressStart2p(
                color: ThemeConstants.primaryColor,
                fontSize: 10,
              ),
              items: DigitalWorkerVoice.values.map((voice) {
                return DropdownMenuItem(
                  value: voice,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: ThemeConstants.spacingSmall,
                    ),
                    child: Text(voice.description),
                  ),
                );
              }).toList(),
              onChanged: (voice) {
                if (voice != null) {
                  onVoiceSelected(voice);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
