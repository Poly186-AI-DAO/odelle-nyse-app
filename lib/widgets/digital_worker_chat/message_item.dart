import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';
import '../../services/openai_realtime/models/openai/base_models.dart';

class ChatMessageItem extends StatelessWidget {
  final ConversationItemCreatedEvent message;

  const ChatMessageItem({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final content = message.item.content?.firstWhere(
      (content) => content.type == 'text',
      orElse: () => MessageContent(type: 'text', text: ''),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConstants.spacingSmall),
      padding: ThemeConstants.paddingSmall,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ThemeConstants.borderColor,
          width: ThemeConstants.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.item.role != null)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: ThemeConstants.spacingSmall),
              child: Text(
                message.item.role!.toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  color: message.item.role == 'assistant'
                      ? ThemeConstants.primaryColor
                      : ThemeConstants.secondaryTextColor,
                  fontSize: 10,
                ),
              ),
            ),
          Text(
            content?.text ?? '',
            style: GoogleFonts.sourceCodePro(
              color: ThemeConstants.textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
