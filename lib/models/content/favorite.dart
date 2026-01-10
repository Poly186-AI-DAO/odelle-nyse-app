import 'program.dart';
import 'session.dart';

/// User's favorited/saved sessions and programs.
class Favorite {
  final int? id;
  final int userId;
  final FavoriteType type;
  final int itemId;
  final DateTime createdAt;

  // Loaded separately
  Session? session;
  Program? program;

  Favorite({
    this.id,
    required this.userId,
    required this.type,
    required this.itemId,
    DateTime? createdAt,
    this.session,
    this.program,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      type: _parseFavoriteType(map['favorite_type'] as String?),
      itemId: (map['item_id'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'favorite_type': type.name,
      'item_id': itemId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite.fromMap(json);
  }

  /// Copy with modifications.
  Favorite copyWith({
    int? id,
    int? userId,
    FavoriteType? type,
    int? itemId,
    DateTime? createdAt,
    Session? session,
    Program? program,
  }) {
    return Favorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      createdAt: createdAt ?? this.createdAt,
      session: session ?? this.session,
      program: program ?? this.program,
    );
  }

  @override
  String toString() {
    return 'Favorite(id: $id, type: ${type.name}, itemId: $itemId)';
  }
}

enum FavoriteType { session, program }

FavoriteType _parseFavoriteType(String? value) {
  if (value == null || value.isEmpty) return FavoriteType.session;
  return FavoriteType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => FavoriteType.session,
  );
}
