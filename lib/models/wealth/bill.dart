/// Recurring bill for the Wealth pillar.
/// Examples: Rent, utilities, insurance, car payment.
class Bill {
  final int? id;
  final String name;
  final double amount;
  final String currency;
  final BillFrequency frequency;
  final int dueDay; // Day of month (1-31)
  final DateTime? nextDueDate;
  final BillCategory category;
  final bool autopay;
  final bool isActive;
  final String? notes;
  final String? payee; // Who you pay (landlord, utility company)
  final String? accountNumber;
  final DateTime createdAt;

  Bill({
    this.id,
    required this.name,
    required this.amount,
    this.currency = 'USD',
    required this.frequency,
    required this.dueDay,
    this.nextDueDate,
    this.category = BillCategory.other,
    this.autopay = false,
    this.isActive = true,
    this.notes,
    this.payee,
    this.accountNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from database map.
  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: (map['currency'] as String?) ?? 'USD',
      frequency: _parseBillFrequency(map['frequency'] as String?),
      dueDay: (map['due_day'] as int?) ?? 1,
      nextDueDate: map['next_due_date'] != null
          ? DateTime.parse(map['next_due_date'] as String)
          : null,
      category: _parseBillCategory(map['category'] as String?),
      autopay: _parseBool(map['autopay']),
      isActive: _parseBool(map['is_active'], defaultValue: true),
      notes: map['notes'] as String?,
      payee: map['payee'] as String?,
      accountNumber: map['account_number'] as String?,
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
      'due_day': dueDay,
      'next_due_date': nextDueDate?.toIso8601String(),
      'category': category.name,
      'autopay': autopay ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'payee': payee,
      'account_number': accountNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON map for API usage.
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON map.
  factory Bill.fromJson(Map<String, dynamic> json) => Bill.fromMap(json);

  /// Copy with modifications.
  Bill copyWith({
    int? id,
    String? name,
    double? amount,
    String? currency,
    BillFrequency? frequency,
    int? dueDay,
    DateTime? nextDueDate,
    BillCategory? category,
    bool? autopay,
    bool? isActive,
    String? notes,
    String? payee,
    String? accountNumber,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      dueDay: dueDay ?? this.dueDay,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      category: category ?? this.category,
      autopay: autopay ?? this.autopay,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      payee: payee ?? this.payee,
      accountNumber: accountNumber ?? this.accountNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if bill is due within the next N days.
  bool isDueSoon(int days) {
    if (nextDueDate == null) return false;
    final now = DateTime.now();
    return nextDueDate!.difference(now).inDays <= days;
  }

  /// Check if bill is overdue.
  bool get isOverdue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  @override
  String toString() {
    return 'Bill(id: $id, name: $name, amount: $amount, frequency: ${frequency.name})';
  }
}

enum BillFrequency {
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
  custom;
}

enum BillCategory {
  housing, // Rent, mortgage
  utilities, // Electric, water, gas, internet
  insurance, // Health, car, home
  transportation, // Car payment, transit pass
  debt, // Credit card, loans
  subscription, // Link to subscriptions
  other;
}

BillFrequency _parseBillFrequency(String? value) {
  if (value == null || value.isEmpty) return BillFrequency.monthly;
  return BillFrequency.values.firstWhere(
    (freq) => freq.name == value,
    orElse: () => BillFrequency.monthly,
  );
}

BillCategory _parseBillCategory(String? value) {
  if (value == null || value.isEmpty) return BillCategory.other;
  return BillCategory.values.firstWhere(
    (cat) => cat.name == value,
    orElse: () => BillCategory.other,
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
