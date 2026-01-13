/// SaaS subscription or recurring service for the Wealth pillar.
/// Examples: Netflix, Spotify, gym membership, cloud services.
class Subscription {
  final int? id;
  final String name;
  final double amount;
  final String currency;
  final SubscriptionFrequency frequency;
  final DateTime startDate;
  final DateTime? renewalDate;
  final DateTime? cancellationDate;
  final SubscriptionCategory category;
  final bool isActive;
  final String? notes;
  final String? url; // Service URL
  final String? logoUrl;
  final DateTime createdAt;

  Subscription({
    this.id,
    required this.name,
    required this.amount,
    this.currency = 'USD',
    this.frequency = SubscriptionFrequency.monthly,
    required this.startDate,
    this.renewalDate,
    this.cancellationDate,
    this.category = SubscriptionCategory.other,
    this.isActive = true,
    this.notes,
    this.url,
    this.logoUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: (map['currency'] as String?) ?? 'USD',
      frequency: _parseSubscriptionFrequency(map['frequency'] as String?),
      startDate: DateTime.parse(map['start_date'] as String),
      renewalDate: map['renewal_date'] != null
          ? DateTime.parse(map['renewal_date'] as String)
          : null,
      cancellationDate: map['cancellation_date'] != null
          ? DateTime.parse(map['cancellation_date'] as String)
          : null,
      category: _parseSubscriptionCategory(map['category'] as String?),
      isActive: _parseBool(map['is_active'], defaultValue: true),
      notes: map['notes'] as String?,
      url: map['url'] as String?,
      logoUrl: map['logo_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String(),
      'renewal_date': renewalDate?.toIso8601String(),
      'cancellation_date': cancellationDate?.toIso8601String(),
      'category': category.name,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'url': url,
      'logo_url': logoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Subscription.fromJson(Map<String, dynamic> json) =>
      Subscription.fromMap(json);

  /// Copy with modifications.
  Subscription copyWith({
    int? id,
    String? name,
    double? amount,
    String? currency,
    SubscriptionFrequency? frequency,
    DateTime? startDate,
    DateTime? renewalDate,
    DateTime? cancellationDate,
    SubscriptionCategory? category,
    bool? isActive,
    String? notes,
    String? url,
    String? logoUrl,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      renewalDate: renewalDate ?? this.renewalDate,
      cancellationDate: cancellationDate ?? this.cancellationDate,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      url: url ?? this.url,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate monthly cost for comparison.
  double get monthlyCost {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 4.33; // Average weeks per month
      case SubscriptionFrequency.monthly:
        return amount;
      case SubscriptionFrequency.quarterly:
        return amount / 3;
      case SubscriptionFrequency.yearly:
        return amount / 12;
    }
  }

  /// Calculate yearly cost.
  double get yearlyCost => monthlyCost * 12;

  /// Check if subscription renews soon.
  bool renewsSoon(int days) {
    if (renewalDate == null) return false;
    final now = DateTime.now();
    return renewalDate!.difference(now).inDays <= days;
  }

  @override
  String toString() {
    return 'Subscription(id: $id, name: $name, amount: $amount, frequency: ${frequency.name})';
  }
}

enum SubscriptionFrequency {
  weekly,
  monthly,
  quarterly,
  yearly;
}

enum SubscriptionCategory {
  entertainment, // Netflix, Spotify, gaming
  productivity, // Notion, Todoist, cloud storage
  health, // Gym, meditation apps
  education, // Courses, learning platforms
  software, // SaaS tools, developer tools
  news, // Newspapers, magazines
  social, // Dating apps, social platforms
  other;
}

SubscriptionFrequency _parseSubscriptionFrequency(String? value) {
  if (value == null || value.isEmpty) return SubscriptionFrequency.monthly;
  return SubscriptionFrequency.values.firstWhere(
    (freq) => freq.name == value,
    orElse: () => SubscriptionFrequency.monthly,
  );
}

SubscriptionCategory _parseSubscriptionCategory(String? value) {
  if (value == null || value.isEmpty) return SubscriptionCategory.other;
  return SubscriptionCategory.values.firstWhere(
    (cat) => cat.name == value,
    orElse: () => SubscriptionCategory.other,
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
