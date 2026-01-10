import 'dart:convert';

/// Instructor or guide who creates content.
class Instructor {
  final int? id;
  final String name;
  final String? title;
  final String? bio;
  final String? shortBio;
  final String? avatarUrl;
  final String? coverImageUrl;

  // Credentials
  final List<String>? certifications;
  final int? yearsExperience;

  // Social
  final String? instagramHandle;
  final String? websiteUrl;

  // Stats
  final int sessionsCount;
  final int followersCount;
  final double? averageRating;

  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;

  Instructor({
    this.id,
    required this.name,
    this.title,
    this.bio,
    this.shortBio,
    this.avatarUrl,
    this.coverImageUrl,
    this.certifications,
    this.yearsExperience,
    this.instagramHandle,
    this.websiteUrl,
    this.sessionsCount = 0,
    this.followersCount = 0,
    this.averageRating,
    this.isFeatured = false,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory Instructor.fromMap(Map<String, dynamic> map) {
    return Instructor(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      title: map['title'] as String?,
      bio: map['bio'] as String?,
      shortBio: map['short_bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      certifications: _parseStringList(map['certifications']),
      yearsExperience: map['years_experience'] as int?,
      instagramHandle: map['instagram_handle'] as String?,
      websiteUrl: map['website_url'] as String?,
      sessionsCount: (map['sessions_count'] as int?) ?? 0,
      followersCount: (map['followers_count'] as int?) ?? 0,
      averageRating: (map['average_rating'] as num?)?.toDouble(),
      isFeatured: _parseBool(map['is_featured']),
      isActive: _parseBool(map['is_active'], defaultValue: true),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'title': title,
      'bio': bio,
      'short_bio': shortBio,
      'avatar_url': avatarUrl,
      'cover_image_url': coverImageUrl,
      'certifications': _encodeStringList(certifications),
      'years_experience': yearsExperience,
      'instagram_handle': instagramHandle,
      'website_url': websiteUrl,
      'sessions_count': sessionsCount,
      'followers_count': followersCount,
      'average_rating': averageRating,
      'is_featured': isFeatured ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor.fromMap(json);
  }

  /// Copy with modifications.
  Instructor copyWith({
    int? id,
    String? name,
    String? title,
    String? bio,
    String? shortBio,
    String? avatarUrl,
    String? coverImageUrl,
    List<String>? certifications,
    int? yearsExperience,
    String? instagramHandle,
    String? websiteUrl,
    int? sessionsCount,
    int? followersCount,
    double? averageRating,
    bool? isFeatured,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Instructor(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      shortBio: shortBio ?? this.shortBio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      certifications: certifications ?? this.certifications,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      followersCount: followersCount ?? this.followersCount,
      averageRating: averageRating ?? this.averageRating,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Instructor(id: $id, name: $name, sessions: $sessionsCount)';
  }
}

List<String>? _parseStringList(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    if (value.isEmpty) return <String>[];
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded.map((item) => item.toString()).toList();
    }
  }
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return null;
}

String? _encodeStringList(List<String>? values) {
  if (values == null) return null;
  return jsonEncode(values);
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
