part of 'app_database.dart';

/// Chat message model for persistence
class ChatMessageRecord {
  final int? id;
  final String conversationId;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final String? imagePath; // Local path to attached image

  const ChatMessageRecord({
    this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (imagePath != null) 'image_path': imagePath,
      };

  factory ChatMessageRecord.fromMap(Map<String, dynamic> map) =>
      ChatMessageRecord(
        id: map['id'] as int?,
        conversationId: map['conversation_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        imagePath: map['image_path'] as String?,
      );
}

/// Chat conversation metadata
class ChatConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  const ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messageCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'last_message_at': lastMessageAt.toIso8601String(),
        'message_count': messageCount,
      };

  factory ChatConversation.fromMap(Map<String, dynamic> map) =>
      ChatConversation(
        id: map['id'] as String,
        title: map['title'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        lastMessageAt: DateTime.parse(map['last_message_at'] as String),
        messageCount: map['message_count'] as int? ?? 0,
      );
}

/// CRUD operations for chat messages
mixin ChatMessageCrud on AppDatabaseBase {
  static const String _tag = 'ChatMessageCrud';

  /// Insert a new chat message
  Future<int> insertChatMessage(ChatMessageRecord message) async {
    final db = await database;
    final id = await db.insert('chat_messages', message.toMap());
    Logger.debug('Inserted chat message: $id', tag: _tag);

    // Update conversation last_message_at and message_count
    await db.rawUpdate('''
      UPDATE chat_conversations 
      SET last_message_at = ?, message_count = message_count + 1
      WHERE id = ?
    ''', [message.timestamp.toIso8601String(), message.conversationId]);

    return id;
  }

  /// Get all messages for a conversation
  Future<List<ChatMessageRecord>> getChatMessages(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return results.map(ChatMessageRecord.fromMap).toList();
  }

  /// Create a new conversation
  Future<void> createConversation(ChatConversation conversation) async {
    final db = await database;
    await db.insert(
      'chat_conversations',
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    Logger.debug('Created conversation: ${conversation.id}', tag: _tag);
  }

  /// Get a conversation by ID
  Future<ChatConversation?> getConversation(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'chat_conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ChatConversation.fromMap(results.first);
  }

  /// Get most recent conversation (for continuing last chat)
  Future<ChatConversation?> getMostRecentConversation() async {
    final db = await database;
    final results = await db.query(
      'chat_conversations',
      orderBy: 'last_message_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ChatConversation.fromMap(results.first);
  }

  /// Get all conversations (for history view)
  Future<List<ChatConversation>> getAllConversations() async {
    final db = await database;
    final results = await db.query(
      'chat_conversations',
      orderBy: 'last_message_at DESC',
    );
    return results.map(ChatConversation.fromMap).toList();
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
    await db.delete(
      'chat_conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
    Logger.debug('Deleted conversation: $conversationId', tag: _tag);
  }

  /// Update conversation title
  Future<void> updateConversationTitle(
      String conversationId, String title) async {
    final db = await database;
    await db.update(
      'chat_conversations',
      {'title': title},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }
}
