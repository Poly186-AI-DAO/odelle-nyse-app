import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';
import '../../constants/strings.dart';

class ConnectingOverlay extends StatelessWidget {
  final String message;

  const ConnectingOverlay({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ThemeConstants.primaryColor.withAlpha(179),
                  width: 2,
                ),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ThemeConstants.primaryColor,
              ),
            ),
            Text(
              Strings.chatInitializing,
              style: GoogleFonts.pressStart2p(
                color: Colors.white.withAlpha(230),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Strings.chatNeuralSequence,
              style: GoogleFonts.pressStart2p(
                color: Colors.white.withAlpha(179),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Strings.chatProgressIndicator,
              style: GoogleFonts.pressStart2p(
                color: ThemeConstants.primaryColor.withAlpha(128),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
