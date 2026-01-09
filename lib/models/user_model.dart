class Wallet {
  final String publicKey;
  final String type;
  final String curve;

  Wallet({
    required this.publicKey,
    required this.type,
    required this.curve,
  });

  Map<String, dynamic> toJson() => {
        'public_key': publicKey,
        'type': type,
        'curve': curve,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        publicKey: json['public_key'] as String,
        type: json['type'] as String,
        curve: json['curve'] as String,
      );
}

class Notifications {
  final bool email;
  final bool push;
  final bool sms;

  Notifications({
    required this.email,
    required this.push,
    required this.sms,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'push': push,
        'sms': sms,
      };

  factory Notifications.fromJson(Map<String, dynamic> json) => Notifications(
        email: json['email'] as bool,
        push: json['push'] as bool,
        sms: json['sms'] as bool,
      );
}

class BillingAddress {
  final String street;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  BillingAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
      };

  factory BillingAddress.fromJson(Map<String, dynamic> json) => BillingAddress(
        street: json['street'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        country: json['country'] as String,
        postalCode: json['postalCode'] as String,
      );
}

class UserModel {
  String id;
  String email;
  String? name;
  String? profileImage;
  String? originalProfileImageUrl;
  String? authProvider;
  String? providerId;
  List<String> linkedProviders;
  List<String> credentialIds;
  String? appToken;
  DateTime? appTokenExpires;
  String verifier;
  String verifierId;
  bool? isNewUser;
  bool isEnterprise;
  String? company; // UUID of the company
  String role;
  DateTime? lastLogin;
  String accountStatus;
  DateTime createdAt;
  DateTime updatedAt;

  // Subscription information
  String subscriptionPlan;
  String subscriptionStatus;
  DateTime? subscriptionStartDate;
  DateTime? subscriptionEndDate;
  String? billingCycle;

  // Platform tokens and usage metrics
  int polyTokens;
  DateTime? lastTokenRefill;
  int lifetimeTokensUsed;
  double lifetimeCostUsd;
  int monthlyTokensUsed;
  double monthlyCostUsd;
  int totalLlmCalls;
  int monthlyLlmCalls;
  DateTime? lastUsageReset;
  Map<String, Map<String, dynamic>> providerUsageStats;
  int workflowsExecuted;
  double workflowExecutionCost;
  double estimatedLaborValueDelivered;
  int? monthlyTokenQuota;
  int? monthlyWorkflowQuota;
  int quotaExceededCount;
  double? averageCostPerInteraction;
  double? mostExpensiveSessionCost;
  String? mostTokenHeavyAction;
  int? highestSingleCallTokens;

  // User preferences
  String? language;
  String? timezone;
  Notifications notifications;

  // Usage statistics
  DateTime? lastActive;
  int loginCount;
  double totalUsageTime;

  // Security
  bool twoFactorEnabled;
  DateTime? lastPasswordChange;

  // Permissions and features
  List<String> allowedFeatures;
  Map<String, bool> customPermissions;

  // Billing information
  BillingAddress? billingAddress;
  String? paymentMethod;
  DateTime? lastBillingDate;
  DateTime? nextBillingDate;

  // Legacy Web3Auth specific fields
  String? aggregateVerifier;
  String? dappShare;
  String? idToken;
  String? oAuthIdToken;
  String? oAuthAccessToken;
  String? appState;
  String? touchIDPreference;
  List<Wallet>? wallets;
  String? appScopedPrivateKey;
  String? appScopedPublicKey;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.profileImage,
    this.originalProfileImageUrl,
    this.authProvider,
    this.providerId,
    List<String>? linkedProviders,
    List<String>? credentialIds,
    this.appToken,
    this.appTokenExpires,
    required this.verifier,
    required this.verifierId,
    this.isNewUser,
    required this.isEnterprise,
    this.company,
    required this.role,
    this.lastLogin,
    required this.accountStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.billingCycle,
    required this.polyTokens,
    this.lastTokenRefill,
    required this.lifetimeTokensUsed,
    required this.lifetimeCostUsd,
    required this.monthlyTokensUsed,
    required this.monthlyCostUsd,
    required this.totalLlmCalls,
    required this.monthlyLlmCalls,
    this.lastUsageReset,
    Map<String, Map<String, dynamic>>? providerUsageStats,
    required this.workflowsExecuted,
    required this.workflowExecutionCost,
    required this.estimatedLaborValueDelivered,
    this.monthlyTokenQuota,
    this.monthlyWorkflowQuota,
    required this.quotaExceededCount,
    this.averageCostPerInteraction,
    this.mostExpensiveSessionCost,
    this.mostTokenHeavyAction,
    this.highestSingleCallTokens,
    this.language,
    this.timezone,
    required this.notifications,
    this.lastActive,
    required this.loginCount,
    required this.totalUsageTime,
    required this.twoFactorEnabled,
    this.lastPasswordChange,
    required this.allowedFeatures,
    required this.customPermissions,
    this.billingAddress,
    this.paymentMethod,
    this.lastBillingDate,
    this.nextBillingDate,
    this.aggregateVerifier,
    this.dappShare,
    this.idToken,
    this.oAuthIdToken,
    this.oAuthAccessToken,
    this.appState,
    this.touchIDPreference,
    this.wallets,
    this.appScopedPrivateKey,
    this.appScopedPublicKey,
  })  : linkedProviders = linkedProviders ?? [],
        credentialIds = credentialIds ?? [],
        providerUsageStats = providerUsageStats ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'profileImage': profileImage,
        'original_profile_image_url': originalProfileImageUrl,
        'authProvider': authProvider,
        'providerId': providerId,
        'linked_providers': linkedProviders,
        'credential_ids': credentialIds,
        'appToken': appToken,
        'appTokenExpires': appTokenExpires?.toIso8601String(),
        'verifier': verifier,
        'verifierId': verifierId,
        'isNewUser': isNewUser,
        'isEnterprise': isEnterprise,
        'company': company,
        'role': role,
        'lastLogin': lastLogin?.toIso8601String(),
        'accountStatus': accountStatus,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'subscriptionPlan': subscriptionPlan,
        'subscriptionStatus': subscriptionStatus,
        'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
        'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
        'billingCycle': billingCycle,
        'polyTokens': polyTokens,
        'lastTokenRefill': lastTokenRefill?.toIso8601String(),
        'lifetime_tokens_used': lifetimeTokensUsed,
        'lifetime_cost_usd': lifetimeCostUsd,
        'monthly_tokens_used': monthlyTokensUsed,
        'monthly_cost_usd': monthlyCostUsd,
        'total_llm_calls': totalLlmCalls,
        'monthly_llm_calls': monthlyLlmCalls,
        'last_usage_reset': lastUsageReset?.toIso8601String(),
        'provider_usage_stats': providerUsageStats,
        'workflows_executed': workflowsExecuted,
        'workflow_execution_cost': workflowExecutionCost,
        'estimated_labor_value_delivered': estimatedLaborValueDelivered,
        'monthly_token_quota': monthlyTokenQuota,
        'monthly_workflow_quota': monthlyWorkflowQuota,
        'quota_exceeded_count': quotaExceededCount,
        'average_cost_per_interaction': averageCostPerInteraction,
        'most_expensive_session_cost': mostExpensiveSessionCost,
        'most_token_heavy_action': mostTokenHeavyAction,
        'highest_single_call_tokens': highestSingleCallTokens,
        'language': language,
        'timezone': timezone,
        'notifications': notifications.toJson(),
        'lastActive': lastActive?.toIso8601String(),
        'loginCount': loginCount,
        'totalUsageTime': totalUsageTime,
        'twoFactorEnabled': twoFactorEnabled,
        'lastPasswordChange': lastPasswordChange?.toIso8601String(),
        'allowedFeatures': allowedFeatures,
        'customPermissions': customPermissions,
        'billingAddress': billingAddress?.toJson(),
        'paymentMethod': paymentMethod,
        'lastBillingDate': lastBillingDate?.toIso8601String(),
        'nextBillingDate': nextBillingDate?.toIso8601String(),
        'aggregateVerifier': aggregateVerifier,
        'dappShare': dappShare,
        'idToken': idToken,
        'oAuthIdToken': oAuthIdToken,
        'oAuthAccessToken': oAuthAccessToken,
        'appState': appState,
        'touchIDPreference': touchIDPreference,
        'wallets': wallets?.map((w) => w.toJson()).toList(),
        'appScopedPrivateKey': appScopedPrivateKey,
        'appScopedPublicKey': appScopedPublicKey,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['user_id'] as String?) ?? (json['id'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        name: json['name'] as String?,
        profileImage: json['profileImage'] as String?,
        originalProfileImageUrl:
            (json['original_profile_image_url'] as String?) ??
                (json['originalProfileImageUrl'] as String?),
        authProvider:
            (json['provider'] as String?) ?? (json['authProvider'] as String?),
        providerId: json['providerId'] as String?,
        linkedProviders: _parseStringList(
          json['linked_providers'] ?? json['linkedProviders'],
        ),
        credentialIds: _parseStringList(
          json['credential_ids'] ?? json['credentialIds'],
        ),
        appToken: (json['appToken'] as String?) ?? (json['token'] as String?),
        appTokenExpires: _parseDateTime(
          json['appTokenExpires'] ?? json['app_token_expires'],
        ),
        verifier: (json['verifier'] as String?) ??
            (json['provider'] as String?) ??
            'unknown',
        verifierId: (json['verifierId'] as String?) ??
            (json['verifier_id'] as String?) ??
            (json['id'] as String?) ??
            '',
        isNewUser: (json['isNewUser'] as bool?) ??
            (json['is_new_user'] as bool?) ??
            false,
        isEnterprise: (json['isEnterprise'] as bool?) ?? false,
        company: json['company'] as String?,
        role: (json['role'] as String?) ?? 'user',
        lastLogin: _parseDateTime(json['lastLogin']),
        accountStatus: (json['accountStatus'] as String?) ?? 'active',
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
        subscriptionPlan: (json['subscriptionPlan'] as String?) ?? 'free',
        subscriptionStatus: (json['subscriptionStatus'] as String?) ?? 'active',
        subscriptionStartDate: _parseDateTime(json['subscriptionStartDate']),
        subscriptionEndDate: _parseDateTime(json['subscriptionEndDate']),
        billingCycle: json['billingCycle'] as String?,
        polyTokens: _parseInt(json['polyTokens'] ?? json['poly_tokens']) ?? 0,
        lastTokenRefill: _parseDateTime(
            json['lastTokenRefill'] ?? json['last_token_refill']),
        lifetimeTokensUsed: _parseInt(
                json['lifetime_tokens_used'] ?? json['lifetimeTokensUsed']) ??
            0,
        lifetimeCostUsd: _parseDouble(
                json['lifetime_cost_usd'] ?? json['lifetimeCostUsd']) ??
            0.0,
        monthlyTokensUsed: _parseInt(
                json['monthly_tokens_used'] ?? json['monthlyTokensUsed']) ??
            0,
        monthlyCostUsd:
            _parseDouble(json['monthly_cost_usd'] ?? json['monthlyCostUsd']) ??
                0.0,
        totalLlmCalls:
            _parseInt(json['total_llm_calls'] ?? json['totalLlmCalls']) ?? 0,
        monthlyLlmCalls:
            _parseInt(json['monthly_llm_calls'] ?? json['monthlyLlmCalls']) ??
                0,
        lastUsageReset:
            _parseDateTime(json['last_usage_reset'] ?? json['lastUsageReset']),
        providerUsageStats: _parseNestedMap(
          json['provider_usage_stats'] ?? json['providerUsageStats'],
        ),
        workflowsExecuted: _parseInt(
                json['workflows_executed'] ?? json['workflowsExecuted']) ??
            0,
        workflowExecutionCost: _parseDouble(
              json['workflow_execution_cost'] ?? json['workflowExecutionCost'],
            ) ??
            0.0,
        estimatedLaborValueDelivered: _parseDouble(
              json['estimated_labor_value_delivered'] ??
                  json['estimatedLaborValueDelivered'],
            ) ??
            0.0,
        monthlyTokenQuota: _parseInt(
          json['monthly_token_quota'] ?? json['monthlyTokenQuota'],
        ),
        monthlyWorkflowQuota: _parseInt(
          json['monthly_workflow_quota'] ?? json['monthlyWorkflowQuota'],
        ),
        quotaExceededCount: _parseInt(
              json['quota_exceeded_count'] ?? json['quotaExceededCount'],
            ) ??
            0,
        averageCostPerInteraction: _parseDouble(
          json['average_cost_per_interaction'] ??
              json['averageCostPerInteraction'],
        ),
        mostExpensiveSessionCost: _parseDouble(
          json['most_expensive_session_cost'] ??
              json['mostExpensiveSessionCost'],
        ),
        mostTokenHeavyAction: (json['most_token_heavy_action'] as String?) ??
            (json['mostTokenHeavyAction'] as String?),
        highestSingleCallTokens: _parseInt(
          json['highest_single_call_tokens'] ?? json['highestSingleCallTokens'],
        ),
        language: json['language'] as String?,
        timezone: json['timezone'] as String?,
        notifications: json['notifications'] != null
            ? Notifications.fromJson(
                json['notifications'] as Map<String, dynamic>)
            : Notifications(email: true, push: true, sms: false),
        lastActive: _parseDateTime(json['lastActive']),
        loginCount: _parseInt(json['loginCount']) ?? 0,
        totalUsageTime:
            _parseDouble(json['totalUsageTime'] ?? json['total_usage_time']) ??
                0,
        twoFactorEnabled: (json['twoFactorEnabled'] as bool?) ?? false,
        lastPasswordChange: _parseDateTime(json['lastPasswordChange']),
        allowedFeatures: json['allowedFeatures'] != null
            ? (json['allowedFeatures'] as List<dynamic>)
                .map((e) => e as String)
                .toList()
            : [],
        customPermissions: json['customPermissions'] != null
            ? Map<String, bool>.from(
                (json['customPermissions'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value as bool),
                ),
              )
            : {},
        billingAddress: json['billingAddress'] != null
            ? BillingAddress.fromJson(
                json['billingAddress'] as Map<String, dynamic>)
            : null,
        paymentMethod: json['paymentMethod'] as String?,
        lastBillingDate: _parseDateTime(json['lastBillingDate']),
        nextBillingDate: _parseDateTime(json['nextBillingDate']),
        aggregateVerifier: json['aggregateVerifier'] as String?,
        dappShare: json['dappShare'] as String?,
        idToken:
            (json['idToken'] as String?) ?? (json['access_token'] as String?),
        oAuthIdToken: json['oAuthIdToken'] as String?,
        oAuthAccessToken: json['oAuthAccessToken'] as String?,
        appState: json['appState'] as String?,
        touchIDPreference: json['touchIDPreference'] as String?,
        wallets: json['wallets'] != null
            ? (json['wallets'] as List<dynamic>)
                .map((w) => Wallet.fromJson(w as Map<String, dynamic>))
                .toList()
            : null,
        appScopedPrivateKey: json['appScopedPrivateKey'] as String?,
        appScopedPublicKey: json['appScopedPublicKey'] as String?,
      );
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return _dateTimeFromEpoch(value);
  if (value is num) return _dateTimeFromEpoch(value.toInt());
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
    final numeric = int.tryParse(value);
    if (numeric != null) {
      return _dateTimeFromEpoch(numeric);
    }
  }
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return [];
}

Map<String, Map<String, dynamic>> _parseNestedMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nested) => MapEntry(
        key.toString(),
        nested is Map
            ? Map<String, dynamic>.from(nested as Map)
            : {'value': nested},
      ),
    );
  }
  return {};
}

DateTime _dateTimeFromEpoch(int value) {
  final normalized = value.abs().toString().length <= 10 ? value * 1000 : value;
  return DateTime.fromMillisecondsSinceEpoch(normalized);
}
