/// Categories for organizing content (meditation, yoga, etc.).
class ContentCategory {
  final int? id;
  final String name;
  final String? slug;
  final String? description;
  final String? iconName;
  final String? iconUrl;
  final String colorHex;
  final int sortOrder;
  final bool isActive;
  final ContentType contentType;

  // Subcategories
  final int? parentCategoryId;

  ContentCategory({
    this.id,
    required this.name,
    this.slug,
    this.description,
    this.iconName,
    this.iconUrl,
    this.colorHex = '#FFFFFF',
    this.sortOrder = 0,
    this.isActive = true,
    required this.contentType,
    this.parentCategoryId,
  });

  /// Create from database map.
  factory ContentCategory.fromMap(Map<String, dynamic> map) {
    return ContentCategory(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      slug: map['slug'] as String?,
      description: map['description'] as String?,
      iconName: map['icon_name'] as String?,
      iconUrl: map['icon_url'] as String?,
      colorHex: (map['color_hex'] as String?) ?? '#FFFFFF',
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isActive: _parseBool(map['is_active'], defaultValue: true),
      contentType: _parseContentType(map['content_type'] as String?),
      parentCategoryId: map['parent_category_id'] as int?,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon_name': iconName,
      'icon_url': iconUrl,
      'color_hex': colorHex,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'content_type': contentType.name,
      'parent_category_id': parentCategoryId,
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory ContentCategory.fromJson(Map<String, dynamic> json) {
    return ContentCategory.fromMap(json);
  }

  /// Copy with modifications.
  ContentCategory copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? iconName,
    String? iconUrl,
    String? colorHex,
    int? sortOrder,
    bool? isActive,
    ContentType? contentType,
    int? parentCategoryId,
  }) {
    return ContentCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      iconUrl: iconUrl ?? this.iconUrl,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      contentType: contentType ?? this.contentType,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
    );
  }

  @override
  String toString() {
    return 'ContentCategory(id: $id, name: $name, type: ${contentType.name})';
  }
}

enum ContentType {
  meditation,
  breathwork,
  yoga,
  workout,
  stretching,
  sleep,
  focus,
  motivation,
  education;
}

ContentType _parseContentType(String? value) {
  if (value == null || value.isEmpty) return ContentType.meditation;
  return ContentType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => ContentType.meditation,
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
