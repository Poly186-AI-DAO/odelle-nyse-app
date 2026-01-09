import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';
import '../../constants/strings.dart';
import '../../bloc/digital_worker_chat/digital_worker_chat_bloc.dart';
import '../../bloc/digital_worker_chat/digital_worker_chat_event.dart';

class VoiceInputSection extends StatelessWidget {
  final String currentTranscript;
  final bool isRecording;

  const VoiceInputSection({
    super.key,
    required this.currentTranscript,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: ThemeConstants.paddingMedium,
      padding: ThemeConstants.paddingMedium,
      decoration: ThemeConstants.primaryContainerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                Strings.chatVoiceInput,
                style: GoogleFonts.pressStart2p(
                  color: ThemeConstants.primaryColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: ThemeConstants.spacingMedium),
              if (isRecording)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ThemeConstants.errorColor,
                    shape: BoxShape.circle,
                    boxShadow: ThemeConstants.errorGlowShadow,
                  ),
                ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingMedium),
          Text(
            currentTranscript.isEmpty
                ? Strings.chatWaitingForInput
                : currentTranscript,
            style: GoogleFonts.sourceCodePro(
              color: ThemeConstants.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRecordButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isRecording) {
          context.read<DigitalWorkerChatBloc>().add(StopRecording());
        } else {
          context.read<DigitalWorkerChatBloc>().add(StartRecording());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingXLarge,
          vertical: ThemeConstants.spacingMedium,
        ),
        decoration: isRecording
            ? ThemeConstants.errorContainerDecoration
            : ThemeConstants.primaryContainerDecoration,
        child: Text(
          isRecording ? Strings.chatStop : Strings.chatStart,
          style: GoogleFonts.pressStart2p(
            color: isRecording
                ? ThemeConstants.errorColor.withAlpha(200)
                : ThemeConstants.primaryColor.withAlpha(200),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
