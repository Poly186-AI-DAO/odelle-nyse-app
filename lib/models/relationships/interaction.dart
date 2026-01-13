import 'contact.dart';

/// A touchpoint/interaction with a contact for the Bonds pillar.
/// Log when you connect with someone to track relationship health.
class Interaction {
  final int? id;
  final int contactId;
  final DateTime timestamp;
  final InteractionType type;
  final String? notes;
  final int quality; // 1-5 how meaningful was the interaction
  final Duration? duration;
  final String? location;
  final bool isInitiatedByMe;
  final DateTime createdAt;

  // Derived (for UI)
  final Contact? contact;

  Interaction({
    this.id,
    required this.contactId,
    required this.timestamp,
    this.type = InteractionType.text,
    this.notes,
    this.quality = 3,
    this.duration,
    this.location,
    this.isInitiatedByMe = true,
    DateTime? createdAt,
    this.contact,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory Interaction.fromMap(Map<String, dynamic> map) {
    return Interaction(
      id: map['id'] as int?,
      contactId: (map['contact_id'] as int?) ?? 0,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: _parseInteractionType(map['type'] as String?),
      notes: map['notes'] as String?,
      quality: (map['quality'] as int?) ?? 3,
      duration: map['duration_minutes'] != null
          ? Duration(minutes: map['duration_minutes'] as int)
          : null,
      location: map['location'] as String?,
      isInitiatedByMe: _parseBool(map['is_initiated_by_me'], defaultValue: true),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'contact_id': contactId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'notes': notes,
      'quality': quality,
      'duration_minutes': duration?.inMinutes,
      'location': location,
      'is_initiated_by_me': isInitiatedByMe ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Interaction.fromJson(Map<String, dynamic> json) =>
      Interaction.fromMap(json);

  /// Copy with modifications.
  Interaction copyWith({
    int? id,
    int? contactId,
    DateTime? timestamp,
    InteractionType? type,
    String? notes,
    int? quality,
    Duration? duration,
    String? location,
    bool? isInitiatedByMe,
    DateTime? createdAt,
    Contact? contact,
  }) {
    return Interaction(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      quality: quality ?? this.quality,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      isInitiatedByMe: isInitiatedByMe ?? this.isInitiatedByMe,
      createdAt: createdAt ?? this.createdAt,
      contact: contact ?? this.contact,
    );
  }

  /// Get emoji for interaction type.
  String get typeEmoji {
    switch (type) {
      case InteractionType.call:
        return '📞';
      case InteractionType.videoCall:
        return '📹';
      case InteractionType.text:
        return '💬';
      case InteractionType.email:
        return '📧';
      case InteractionType.inPerson:
        return '🤝';
      case InteractionType.social:
        return '📱';
      case InteractionType.gift:
        return '🎁';
      case InteractionType.other:
        return '💭';
    }
  }

  /// Get quality label.
  String get qualityLabel {
    switch (quality) {
      case 1:
        return 'Brief';
      case 2:
        return 'Light';
      case 3:
        return 'Good';
      case 4:
        return 'Meaningful';
      case 5:
        return 'Deep';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'Interaction(id: $id, contactId: $contactId, type: ${type.name})';
  }
}

enum InteractionType {
  call, // Phone call
  videoCall, // FaceTime, Zoom, etc.
  text, // SMS, iMessage, WhatsApp
  email, // Email communication
  inPerson, // Face-to-face meeting
  social, // Social media interaction
  gift, // Sent/received a gift
  other;
}

InteractionType _parseInteractionType(String? value) {
  if (value == null || value.isEmpty) return InteractionType.text;
  return InteractionType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => InteractionType.text,
  );
}

bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
  }
  return defaultValue;
}
