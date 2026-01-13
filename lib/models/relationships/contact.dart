/// A person in your life for the Bonds pillar.
/// Track relationships and stay connected with the people who matter.
class Contact {
  final int? id;
  final String name;
  final String? nickname;
  final RelationshipType relationship;
  final int priority; // 1-5 (5 = most important)
  final DateTime? lastContact;
  final int contactFrequencyDays; // Target: reach out every N days
  final String? notes;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final DateTime? birthday;
  final bool isActive;
  final DateTime createdAt;

  Contact({
    this.id,
    required this.name,
    this.nickname,
    this.relationship = RelationshipType.friend,
    this.priority = 3,
    this.lastContact,
    this.contactFrequencyDays = 30, // Default: monthly
    this.notes,
    this.phone,
    this.email,
    this.photoUrl,
    this.birthday,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      nickname: map['nickname'] as String?,
      relationship: _parseRelationshipType(map['relationship'] as String?),
      priority: (map['priority'] as int?) ?? 3,
      lastContact: map['last_contact'] != null
          ? DateTime.parse(map['last_contact'] as String)
          : null,
      contactFrequencyDays: (map['contact_frequency_days'] as int?) ?? 30,
      notes: map['notes'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photo_url'] as String?,
      birthday: map['birthday'] != null
          ? DateTime.parse(map['birthday'] as String)
          : null,
      isActive: _parseBool(map['is_active'], defaultValue: true),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'nickname': nickname,
      'relationship': relationship.name,
      'priority': priority,
      'last_contact': lastContact?.toIso8601String(),
      'contact_frequency_days': contactFrequencyDays,
      'notes': notes,
      'phone': phone,
      'email': email,
      'photo_url': photoUrl,
      'birthday': birthday?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Contact.fromJson(Map<String, dynamic> json) => Contact.fromMap(json);

  /// Copy with modifications.
  Contact copyWith({
    int? id,
    String? name,
    String? nickname,
    RelationshipType? relationship,
    int? priority,
    DateTime? lastContact,
    int? contactFrequencyDays,
    String? notes,
    String? phone,
    String? email,
    String? photoUrl,
    DateTime? birthday,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      lastContact: lastContact ?? this.lastContact,
      contactFrequencyDays: contactFrequencyDays ?? this.contactFrequencyDays,
      notes: notes ?? this.notes,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      birthday: birthday ?? this.birthday,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get display name (nickname or name).
  String get displayName => nickname ?? name;

  /// Days since last contact.
  int? get daysSinceContact {
    if (lastContact == null) return null;
    return DateTime.now().difference(lastContact!).inDays;
  }

  /// Check if contact is overdue for reaching out.
  bool get isOverdue {
    if (lastContact == null) return true; // Never contacted
    final days = daysSinceContact ?? 0;
    return days > contactFrequencyDays;
  }

  /// Days until overdue (negative if already overdue).
  int get daysUntilOverdue {
    if (lastContact == null) return -contactFrequencyDays;
    return contactFrequencyDays - (daysSinceContact ?? 0);
  }

  /// Check if birthday is coming up in the next N days.
  bool hasBirthdaySoon(int days) {
    if (birthday == null) return false;
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, birthday!.month, birthday!.day);
    final nextBirthday = thisYearBirthday.isBefore(now)
        ? DateTime(now.year + 1, birthday!.month, birthday!.day)
        : thisYearBirthday;
    return nextBirthday.difference(now).inDays <= days;
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, relationship: ${relationship.name})';
  }
}

enum RelationshipType {
  family, // Immediate and extended family
  friend, // Close friends
  acquaintance, // Casual acquaintances
  colleague, // Work relationships
  mentor, // Mentors and advisors
  mentee, // People you mentor
  partner, // Romantic partner
  client, // Business clients
  other;
}

RelationshipType _parseRelationshipType(String? value) {
  if (value == null || value.isEmpty) return RelationshipType.friend;
  return RelationshipType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => RelationshipType.friend,
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
