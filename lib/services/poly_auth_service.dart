import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/social_auth_provider.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'backend_api_service.dart';

class PolyAuthService {
  static const String _tokenKey = 'poly_app_token';
  static const String _tokenExpiryKey = 'poly_app_token_expires';
  static const String _providerKey = 'poly_auth_provider';
  static const String _userKey = 'poly_user_data';

  final BackendApiService _backendApi;
  final FlutterSecureStorage _storage;

  PolyAuthService({
    required String baseUrl,
    BackendApiService? backendApi,
    FlutterSecureStorage? storage,
  })  : _backendApi = backendApi ?? BackendApiService(baseUrl: baseUrl),
        _storage = storage ?? const FlutterSecureStorage();

  Future<UserModel> loginWithProvider({
    required SocialAuthProvider provider,
    required String token,
    required Map<String, dynamic> user,
    Map<String, dynamic>? account,
  }) async {
    final backendUser = await _backendApi.loginWithProvider(
      provider: provider,
      token: token,
      user: user,
      account: account,
    );

    await _persistSession(backendUser, provider);
    return backendUser;
  }

  Future<UserModel> loginWithDevToken({
    required String token,
    required String userId,
    required String email,
  }) async {
    final devUser = UserModel(
      id: userId,
      email: email,
      name: 'Dev User',
      appToken: token,
      appTokenExpires: DateTime.now().add(const Duration(days: 365)),
      role: 'admin',
      isEnterprise: false,
      subscriptionPlan: 'pro',
      subscriptionStatus: 'active',
      verifier: 'dev',
      verifierId: userId,
      accountStatus: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      polyTokens: 1000000,
      lifetimeTokensUsed: 0,
      lifetimeCostUsd: 0.0,
      monthlyTokensUsed: 0,
      monthlyCostUsd: 0.0,
      totalLlmCalls: 0,
      monthlyLlmCalls: 0,
      workflowsExecuted: 0,
      workflowExecutionCost: 0.0,
      estimatedLaborValueDelivered: 0.0,
      quotaExceededCount: 0,
      loginCount: 1,
      totalUsageTime: 0.0,
      twoFactorEnabled: false,
      allowedFeatures: ['all'],
      customPermissions: {'all': true},
      notifications: Notifications(email: true, push: true, sms: false),
    );

    await _persistSession(devUser, SocialAuthProvider.google);
    return devUser;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    final expiresAt =
        int.tryParse(await _storage.read(key: _tokenExpiryKey) ?? '');
    if (token == null || token.isEmpty || expiresAt == null) {
      return false;
    }

    return expiresAt > DateTime.now().millisecondsSinceEpoch;
  }

  Future<String?> getAuthToken() => _storage.read(key: _tokenKey);

  Future<int?> getTokenExpiry() async {
    final raw = await _storage.read(key: _tokenExpiryKey);
    return int.tryParse(raw ?? '');
  }

  Future<SocialAuthProvider?> getStoredProvider() async {
    final stored = await _storage.read(key: _providerKey);
    if (stored == null) return null;
    try {
      return SocialAuthProvider.values.firstWhere(
        (provider) => provider.headerValue == stored,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUserData() async {
    final stored = await _storage.read(key: _userKey);
    if (stored == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (error, stacktrace) {
      Logger.error(
        'Failed to parse stored user data',
        error: error,
        stackTrace: stacktrace,
      );
      return null;
    }
  }

  Future<void> storeUserData(UserModel user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<UserModel> refreshCurrentUser() async {
    final token = await getAuthToken();
    final provider = await getStoredProvider();
    if (token == null || provider == null) {
      throw Exception('No stored session');
    }

    final user = await _backendApi.getUserDetails(
      appToken: token,
      provider: provider,
    );
    await storeUserData(user);
    return user;
  }

  Future<void> logout() async {
    final token = await getAuthToken();
    final provider = await getStoredProvider();

    if (token != null && provider != null) {
      try {
        await _backendApi.logout(appToken: token, provider: provider);
      } catch (error, stacktrace) {
        Logger.error(
          'Backend logout failed',
          error: error,
          stackTrace: stacktrace,
        );
      }
    }

    await clearSession();
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _storage.delete(key: _providerKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> _persistSession(
    UserModel user,
    SocialAuthProvider provider,
  ) async {
    final token = user.appToken;
    final expires = user.appTokenExpires?.millisecondsSinceEpoch;

    if (token == null || token.isEmpty) {
      throw Exception('Backend did not return an app token.');
    }
    if (expires == null) {
      throw Exception('Backend did not return token expiration.');
    }

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(
      key: _tokenExpiryKey,
      value: expires.toString(),
    );
    await _storage.write(
      key: _providerKey,
      value: provider.headerValue,
    );
    await storeUserData(user);
  }
}
