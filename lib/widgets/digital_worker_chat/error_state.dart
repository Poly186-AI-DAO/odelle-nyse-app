import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';
import '../../constants/strings.dart';
import '../../bloc/digital_worker_chat/digital_worker_chat_bloc.dart';
import '../../bloc/digital_worker_chat/digital_worker_chat_event.dart';

class ErrorState extends StatelessWidget {
  final String message;

  const ErrorState({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: ThemeConstants.paddingLarge,
            decoration: ThemeConstants.errorContainerDecoration,
            child: Column(
              children: [
                Text(
                  Strings.chatError,
                  style: GoogleFonts.pressStart2p(
                    color: ThemeConstants.errorColor,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: ThemeConstants.spacingMedium),
                Text(
                  message,
                  style: GoogleFonts.pressStart2p(
                    color: ThemeConstants.textColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ThemeConstants.spacingLarge),
                GestureDetector(
                  onTap: () {
                    context.read<DigitalWorkerChatBloc>().add(StartRecording());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConstants.spacingXLarge,
                      vertical: ThemeConstants.spacingMedium,
                    ),
                    decoration: ThemeConstants.primaryContainerDecoration,
                    child: Text(
                      Strings.chatInitializeConnection,
                      style: GoogleFonts.pressStart2p(
                        color: ThemeConstants.primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
