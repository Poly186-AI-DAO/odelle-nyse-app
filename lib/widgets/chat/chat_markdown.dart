import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/theme_constants.dart';

MarkdownStyleSheet buildChatMarkdownStyleSheet(
  BuildContext context, {
  required TextStyle baseStyle,
  Color? secondaryTextColor,
}) {
  final muted = secondaryTextColor ?? ThemeConstants.secondaryTextColor;
  return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
    p: baseStyle,
    strong: baseStyle.copyWith(fontWeight: FontWeight.w600),
    em: baseStyle.copyWith(fontStyle: FontStyle.italic),
    listBullet: baseStyle.copyWith(color: muted),
    a: baseStyle.copyWith(
      color: muted,
      decoration: TextDecoration.underline,
    ),
    code: baseStyle.copyWith(
      color: muted,
      backgroundColor: ThemeConstants.glassBackground,
    ),
    codeblockPadding: const EdgeInsets.all(8),
    codeblockDecoration: BoxDecoration(
      color: ThemeConstants.glassBackground,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ThemeConstants.glassBorderWeak),
    ),
    blockquote: baseStyle.copyWith(color: muted),
    blockquoteDecoration: BoxDecoration(
      color: ThemeConstants.glassBackgroundWeak,
      borderRadius: BorderRadius.circular(8),
      border: Border(
        left: BorderSide(
          color: ThemeConstants.glassBorderStrong,
          width: 2,
        ),
      ),
    ),
  );
}

Future<void> handleMarkdownLinkTap(
  BuildContext context,
  String? href,
) async {
  if (href == null || href.isEmpty) return;
  final uri = Uri.tryParse(href);
  if (uri == null) {
    _showLinkError(context);
    return;
  }
  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!launched && context.mounted) {
    _showLinkError(context);
  }
}

void _showLinkError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Unable to open link.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
