import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/theme_constants.dart';
import '../providers/viewmodels/chat_viewmodel.dart';
import '../widgets/effects/breathing_card.dart';

/// Chat Screen - Text-based conversation with the AI (Digital Twin)
/// Design matches the app's floating hero card pattern with white bottom panel
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Colors.grey.shade300,
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
                    style: GoogleFonts.inter(color: Colors.grey)),
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
                    style: GoogleFonts.inter(color: Colors.grey)),
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
    final screenHeight = MediaQuery.of(context).size.height;
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
            bottom: screenHeight * 0.42, // Leave room for white panel
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
                // Header
                _buildHeader(state),

                // Messages area (in the dark card)
                Expanded(
                  flex: 58, // ~58% for dark area
                  child: state.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessagesList(state),
                ),

                // White bottom panel (input area)
                Expanded(
                  flex: 42, // ~42% for white panel
                  child: _buildWhitePanel(state),
                ),
              ],
            ),
          ),

          // Error overlay
          if (state.error != null)
            Positioned(
              top: safeTop + 60,
              left: 16,
              right: 16,
              child: _buildErrorBanner(state.error!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ChatState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                'Note to Self',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!state.isInitialized)
                Text(
                  'Loading...',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined,
                color: Colors.white70, size: 20),
            onPressed: () {
              ref.read(chatViewModelProvider.notifier).clearConversation();
            },
            tooltip: 'New conversation',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return _ChatBubble(message: message);
      },
    );
  }

  Widget _buildWhitePanel(ChatState state) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 16),

            // Pending image preview
            if (state.hasPendingImage)
              _buildPendingImagePreview(state.pendingImage!),

            // Recent AI messages in white panel (last 2)
            Expanded(
              child: _buildRecentResponses(state),
            ),

            // Input area
            _buildInputArea(state),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingImagePreview(Uint8List bytes) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
            onPressed: () {
              ref.read(chatViewModelProvider.notifier).clearPendingImage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResponses(ChatState state) {
    // Show recent AI responses in the white panel for visibility
    // Include streaming messages (have content, but may still be loading)
    final aiMessages = state.messages
        .where((m) => !m.isUser && (m.content.isNotEmpty || m.isThinking))
        .toList();

    if (aiMessages.isEmpty) {
      // Check if there's a loading message
      final isStreaming = state.messages.any((m) => m.isLoading && !m.isUser);
      if (isStreaming) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thinking...',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Send a message to start the conversation',
            style: GoogleFonts.inter(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Show last AI response (may be still streaming)
    final lastResponse = aiMessages.last;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      ThemeConstants.polyPurple500,
                      ThemeConstants.polyBlue500,
                    ],
                  ),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Odelle',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (lastResponse.isLoading) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: ThemeConstants.polyPurple500,
                  ),
                ),
              ],
            ],
          ),
          // Show thinking content if available
          if (lastResponse.isThinking &&
              lastResponse.thinkingContent != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ThemeConstants.polyPurple500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology,
                      size: 16, color: ThemeConstants.polyPurple500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastResponse.thinkingContent!.length > 150
                          ? '${lastResponse.thinkingContent!.substring(0, 150)}...'
                          : lastResponse.thinkingContent!,
                      style: GoogleFonts.inter(
                        color: ThemeConstants.polyPurple700,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            lastResponse.content.isNotEmpty
                ? lastResponse.content
                : (lastResponse.isThinking ? 'Processing...' : ''),
            style: GoogleFonts.inter(
              color: ThemeConstants.textOnLight,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatState state) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image picker button
          IconButton(
            icon: Icon(
              Icons.add_photo_alternate_outlined,
              color: state.hasPendingImage
                  ? ThemeConstants.polyPurple500
                  : Colors.grey.shade600,
            ),
            onPressed: _showImagePicker,
          ),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: GoogleFonts.inter(
                  color: ThemeConstants.textOnLight,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: state.hasPendingImage
                      ? 'Add a message...'
                      : 'What\'s on your mind?',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: state.isLoading ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: state.isLoading
                    ? null
                    : LinearGradient(
                        colors: [
                          ThemeConstants.polyPurple500,
                          ThemeConstants.polyBlue500,
                        ],
                      ),
                color: state.isLoading ? Colors.grey.shade300 : null,
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
      ),
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
class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _ChatBubble({required this.message});

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
              _buildContentBubble(isUser),
          ],
        ),
      ),
    );
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

  Widget _buildContentBubble(bool isUser) {
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
      child: message.isLoading
          ? const _PulsingDots()
          : Text(
              message.content,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
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
      imageWidget = Image.file(
        File(message.imagePath!),
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
