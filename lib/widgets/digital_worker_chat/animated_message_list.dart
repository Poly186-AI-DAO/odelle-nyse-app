import 'package:flutter/material.dart';
import '../../services/openai_realtime/models/openai/base_models.dart';
import 'message_item.dart';

class AnimatedMessageList extends StatefulWidget {
  final List<ConversationItemCreatedEvent> messages;

  const AnimatedMessageList({
    super.key,
    required this.messages,
  });

  @override
  State<AnimatedMessageList> createState() => _AnimatedMessageListState();
}

class _AnimatedMessageListState extends State<AnimatedMessageList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<ConversationItemCreatedEvent> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [];
    // Add initial messages with animation
    _addMessages(widget.messages);
  }

  @override
  void didUpdateWidget(AnimatedMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle updates to the messages list
    if (widget.messages.length > _messages.length) {
      final newMessages = widget.messages.sublist(_messages.length);
      _addMessages(newMessages);
    }
  }

  void _addMessages(List<ConversationItemCreatedEvent> newMessages) {
    for (var i = 0; i < newMessages.length; i++) {
      _messages.add(newMessages[i]);
      if (_listKey.currentState != null) {
        _listKey.currentState!.insertItem(_messages.length - 1);
      }
    }
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: animation.drive(
          Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: ChatMessageItem(message: _messages[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _messages.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index, animation) {
        return _buildItem(context, index, animation);
      },
    );
  }
}
