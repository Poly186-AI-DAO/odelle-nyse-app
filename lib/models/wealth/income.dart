/// Income source for the Wealth pillar.
/// Examples: Salary, freelance, investments, side projects.
class Income {
  final int? id;
  final String source; // Job title, client name, or income source
  final double amount;
  final String currency;
  final IncomeFrequency frequency;
  final IncomeType type;
  final DateTime? lastReceived;
  final DateTime? nextExpected;
  final bool isRecurring;
  final bool isActive;
  final String? notes;
  final String? employer;
  final DateTime createdAt;

  Income({
    this.id,
    required this.source,
    required this.amount,
    this.currency = 'USD',
    this.frequency = IncomeFrequency.monthly,
    this.type = IncomeType.salary,
    this.lastReceived,
    this.nextExpected,
    this.isRecurring = true,
    this.isActive = true,
    this.notes,
    this.employer,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      source: (map['source'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: (map['currency'] as String?) ?? 'USD',
      frequency: _parseIncomeFrequency(map['frequency'] as String?),
      type: _parseIncomeType(map['type'] as String?),
      lastReceived: map['last_received'] != null
          ? DateTime.parse(map['last_received'] as String)
          : null,
      nextExpected: map['next_expected'] != null
          ? DateTime.parse(map['next_expected'] as String)
          : null,
      isRecurring: _parseBool(map['is_recurring'], defaultValue: true),
      isActive: _parseBool(map['is_active'], defaultValue: true),
      notes: map['notes'] as String?,
      employer: map['employer'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'source': source,
      'amount': amount,
      'currency': currency,
      'frequency': frequency.name,
      'type': type.name,
      'last_received': lastReceived?.toIso8601String(),
      'next_expected': nextExpected?.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'employer': employer,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Income.fromJson(Map<String, dynamic> json) => Income.fromMap(json);

  /// Copy with modifications.
  Income copyWith({
    int? id,
    String? source,
    double? amount,
    String? currency,
    IncomeFrequency? frequency,
    IncomeType? type,
    DateTime? lastReceived,
    DateTime? nextExpected,
    bool? isRecurring,
    bool? isActive,
    String? notes,
    String? employer,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      type: type ?? this.type,
      lastReceived: lastReceived ?? this.lastReceived,
      nextExpected: nextExpected ?? this.nextExpected,
      isRecurring: isRecurring ?? this.isRecurring,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      employer: employer ?? this.employer,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate monthly income for comparison.
  double get monthlyAmount {
    switch (frequency) {
      case IncomeFrequency.weekly:
        return amount * 4.33;
      case IncomeFrequency.biweekly:
        return amount * 2.17;
      case IncomeFrequency.monthly:
        return amount;
      case IncomeFrequency.quarterly:
        return amount / 3;
      case IncomeFrequency.yearly:
        return amount / 12;
      case IncomeFrequency.oneTime:
        return 0; // One-time doesn't contribute to monthly
    }
  }

  /// Calculate yearly income.
  double get yearlyAmount {
    if (frequency == IncomeFrequency.oneTime) return amount;
    return monthlyAmount * 12;
  }

  @override
  String toString() {
    return 'Income(id: $id, source: $source, amount: $amount, type: ${type.name})';
  }
}

enum IncomeFrequency {
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
  oneTime;
}

enum IncomeType {
  salary, // Full-time employment
  freelance, // Contract work, gig economy
  business, // Business income, self-employment
  investment, // Dividends, interest
  rental, // Real estate income
  side, // Side projects, passive income
  other;
}

IncomeFrequency _parseIncomeFrequency(String? value) {
  if (value == null || value.isEmpty) return IncomeFrequency.monthly;
  return IncomeFrequency.values.firstWhere(
    (freq) => freq.name == value,
    orElse: () => IncomeFrequency.monthly,
  );
}

IncomeType _parseIncomeType(String? value) {
  if (value == null || value.isEmpty) return IncomeType.salary;
  return IncomeType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => IncomeType.salary,
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
