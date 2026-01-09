import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';
import '../../constants/strings.dart';
import '../../services/openai_realtime/models/openai/base_models.dart';
import 'message_item.dart';
import 'voice_input_section.dart';

class ChatInterface extends StatelessWidget {
  final List<ConversationItemCreatedEvent> messages;
  final String currentTranscript;
  final bool isRecording;
  final RTCVideoRenderer? webrtcRenderer;

  const ChatInterface({
    super.key,
    required this.messages,
    required this.currentTranscript,
    required this.isRecording,
    this.webrtcRenderer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildMessageList(),
        ),
        VoiceInputSection(
          currentTranscript: currentTranscript,
          isRecording: isRecording,
        ),
        // Hidden WebRTC renderer for audio
        if (webrtcRenderer != null)
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: RTCVideoView(webrtcRenderer!),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageList() {
    return Container(
      margin: ThemeConstants.paddingMedium,
      padding: ThemeConstants.paddingMedium,
      decoration: ThemeConstants.primaryContainerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Strings.chatConversationLog,
            style: GoogleFonts.pressStart2p(
              color: ThemeConstants.primaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingMedium),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) => ChatMessageItem(
                message: messages[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
