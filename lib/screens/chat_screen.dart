import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/theme_constants.dart';
import '../providers/viewmodels/chat_viewmodel.dart';
import '../widgets/effects/breathing_card.dart';
import '../widgets/chat/chat_markdown.dart';

/// Chat Screen - Text-based conversation with the AI (Digital Twin)
/// Full-bleed conversation over the breathing background
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    final state = ref.read(chatViewModelProvider);

    if (text.isEmpty && !state.hasPendingImage) return;

    ref.read(chatViewModelProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _showImagePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ThemeConstants.panelWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeConstants.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ThemeConstants.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ThemeConstants.polyPurple500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      color: ThemeConstants.polyPurple500),
                ),
                title: Text('Take Photo',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                subtitle: Text('Use camera',
                    style: GoogleFonts.inter(color: ThemeConstants.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ThemeConstants.polyBlue500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      color: ThemeConstants.polyBlue500),
                ),
                title: Text('Photo Library',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                subtitle: Text('Choose existing',
                    style: GoogleFonts.inter(color: ThemeConstants.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final mimeType = _mimeTypeFromPath(image.path);

    ref.read(chatViewModelProvider.notifier).setPendingImage(bytes, mimeType);
  }

  String _mimeTypeFromPath(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatViewModelProvider);
    final safeTop = MediaQuery.of(context).padding.top;

    // Scroll to bottom when messages change or during streaming
    ref.listen(chatViewModelProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      } else if (next.messages.isNotEmpty) {
        // During streaming, the last message content grows
        final lastPrev = previous?.messages.lastOrNull;
        final lastNext = next.messages.last;
        if (lastPrev != null &&
            lastNext.content.length > lastPrev.content.length) {
          _scrollToBottom();
        }
      }
    });

    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Dark breathing card background
          Positioned(
            top: 6,
            left: 8,
            right: 8,
            bottom: 6,
            child: BreathingCard(
              borderRadius: 48,
              child: const SizedBox.expand(),
            ),
          ),

          // Content layer
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessagesList(state),
                ),
                _buildComposer(state),
              ],
            ),
          ),

          // Error overlay
          if (state.error != null)
            Positioned(
              top: safeTop + 12,
              left: 16,
              right: 16,
              child: _buildErrorBanner(state.error!),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 32,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Digital Twin',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Talk to the clearest version of yourself',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(ChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMedium,
        vertical: ThemeConstants.spacingSmall,
      ),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return _ChatBubble(message: message);
      },
    );
  }

  Widget _buildComposer(ChatState state) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ThemeConstants.spacingMedium,
        ThemeConstants.spacingSmall,
        ThemeConstants.spacingMedium,
        bottomInset + ThemeConstants.spacingMedium,
      ),
      child: BreathingCard(
        borderRadius: 28,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            ThemeConstants.spacingSmall,
            ThemeConstants.spacingSmall,
            ThemeConstants.spacingSmall,
            ThemeConstants.spacingSmall,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.hasPendingImage) ...[
                _buildPendingImagePreview(state.pendingImage!),
                const SizedBox(height: ThemeConstants.spacingSmall),
              ],
              _buildInputRow(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingImagePreview(Uint8List bytes) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackgroundStrong,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
        border: Border.all(
          color: ThemeConstants.glassBorder,
          width: ThemeConstants.borderWidth,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusSmall),
            child: Image.memory(
              bytes,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Image attached',
              style: GoogleFonts.inter(
                color: ThemeConstants.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: ThemeConstants.mutedTextColor,
              size: 20,
            ),
            onPressed: () {
              ref.read(chatViewModelProvider.notifier).clearPendingImage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(ChatState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Image picker button
        IconButton(
          icon: Icon(
            Icons.add_photo_alternate_outlined,
            color: state.hasPendingImage
                ? ThemeConstants.polyPurple500
                : ThemeConstants.mutedTextColor,
          ),
          onPressed: _showImagePicker,
        ),

        // Text input
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 100),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(ThemeConstants.radiusLarge),
              border: Border.all(
                color: ThemeConstants.glassBorder,
                width: ThemeConstants.borderWidthThin,
              ),
            ),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: GoogleFonts.inter(
                color: ThemeConstants.textColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: state.hasPendingImage
                    ? 'Add a message...'
                    : 'What\'s on your mind?',
                hintStyle: GoogleFonts.inter(
                  color: ThemeConstants.mutedTextColor,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstants.spacingMedium,
                  vertical: ThemeConstants.spacingSmall,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ),
        const SizedBox(width: ThemeConstants.spacingSmall),

        // Send button
        GestureDetector(
          onTap: state.isLoading ? null : _sendMessage,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: state.isLoading ? null : ThemeConstants.buttonGradient,
              color:
                  state.isLoading ? ThemeConstants.glassBackgroundStrong : null,
              shape: BoxShape.circle,
            ),
            child: state.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(chatViewModelProvider.notifier).clearError(),
              child: Icon(Icons.close, color: Colors.red.shade700, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat bubble for dark card area
class _ChatBubble extends StatefulWidget {
  final ChatMessageModel message;

  const _ChatBubble({required this.message});

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool _toolCallsExpanded = false;

  ChatMessageModel get message => widget.message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isUser ? 40 : 0,
        right: isUser ? 0 : 40,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Thinking indicator (for AI messages during reasoning)
            if (!isUser &&
                message.isThinking &&
                message.thinkingContent != null)
              _buildThinkingBubble(),

            // Image if present
            if (message.hasImage) _buildImageBubble(),

            // Text content (or loading indicator)
            if (message.isLoading && message.content.isEmpty)
              _buildLoadingBubble(isUser)
            else if (message.content.isNotEmpty &&
                message.content != '📷 Image')
              _buildContentBubble(context, isUser),

            // Tool calls indicator AFTER content (collapsible)
            if (!isUser && message.hasToolCalls) _buildToolCallsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCallsSection() {
    final toolCalls = message.toolCalls!;
    final hasExecuting = toolCalls.any((tc) => tc.isExecuting);
    final count = toolCalls.length;

    // If still executing, show all tool calls
    if (hasExecuting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: toolCalls.map((tc) => _buildToolCallChip(tc)).toList(),
      );
    }

    // If complete, show collapsed summary that can expand
    return GestureDetector(
      onTap: () => setState(() => _toolCallsExpanded = !_toolCallsExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ThemeConstants.polyPurple500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ThemeConstants.polyPurple500.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 12,
                  color: Colors.green.shade300,
                ),
                const SizedBox(width: 6),
                Text(
                  '$count tool${count > 1 ? 's' : ''} used',
                  style: GoogleFonts.inter(
                    color: ThemeConstants.polyPurple200.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _toolCallsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 14,
                  color: ThemeConstants.polyPurple200.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          if (_toolCallsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    toolCalls.map((tc) => _buildToolCallChip(tc)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolCallChip(ToolCallInfo toolCall) {
    final isExecuting = toolCall.isExecuting;
    final iconColor =
        isExecuting ? ThemeConstants.polyPurple300 : Colors.green.shade300;
    final label = _formatToolName(toolCall.name);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeConstants.polyPurple500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConstants.polyPurple500.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExecuting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          else
            Icon(Icons.check_circle_outline, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            isExecuting ? '$label...' : label,
            style: GoogleFonts.inter(
              color: ThemeConstants.polyPurple200,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatToolName(String name) {
    // Convert snake_case to readable format
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  Widget _buildThinkingBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeConstants.polyPurple500.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ThemeConstants.polyPurple500.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: ThemeConstants.polyPurple300,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message.thinkingContent!.length > 100
                  ? '${message.thinkingContent!.substring(0, 100)}...'
                  : message.thinkingContent!,
              style: GoogleFonts.inter(
                color: ThemeConstants.polyPurple200,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(4),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: const _PulsingDots(),
    );
  }

  Widget _buildContentBubble(BuildContext context, bool isUser) {
    final baseStyle = GoogleFonts.inter(
      color: Colors.white,
      fontSize: 15,
      height: 1.4,
    );
    return Container(
      margin: message.hasImage ? const EdgeInsets.only(top: 4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isUser ? 0.2 : 0.1),
        ),
      ),
      child: MarkdownBody(
        data: message.content,
        onTapLink: (_, href, __) => handleMarkdownLinkTap(context, href),
        styleSheet: buildChatMarkdownStyleSheet(
          context,
          baseStyle: baseStyle,
          secondaryTextColor: ThemeConstants.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildImageBubble() {
    Widget imageWidget;

    if (message.pendingImageBytes != null) {
      imageWidget = Image.memory(
        message.pendingImageBytes!,
        fit: BoxFit.cover,
      );
    } else if (message.imagePath != null) {
      final file = File(message.imagePath!);
      if (!file.existsSync()) {
        return _buildMissingImageBubble();
      }
      imageWidget = Image.file(
        file,
        fit: BoxFit.cover,
      );
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _buildMissingImageBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 16,
            color: ThemeConstants.secondaryTextColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Image unavailable',
            style: GoogleFonts.inter(
              color: ThemeConstants.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing dots for loading state
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity =
                0.3 + 0.7 * (0.5 + 0.5 * math.sin(value * 2 * math.pi));

            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
