import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/social_auth_provider.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class BackendApiService {
  static const String _category = 'BackendApiService';
  final String _baseUrl;
  final http.Client _client;

  BackendApiService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = _normalizeBaseUrl(
            baseUrl ?? dotenv.env['POLY_PRODUCTION_BACKEND_URL'] ?? ''),
        _client = client ?? http.Client() {
    if (_baseUrl.isEmpty) {
      throw ArgumentError('POLY_PRODUCTION_BACKEND_URL is not configured.');
    }
  }

  Uri _buildUri(String path) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return Uri.parse('$_baseUrl$path');
  }

  Future<UserModel> loginWithProvider({
    required SocialAuthProvider provider,
    required String token,
    required Map<String, dynamic> user,
    Map<String, dynamic>? account,
  }) async {
    final requestBody = <String, dynamic>{
      'provider': provider.headerValue,
      'token': token,
      'user': user,
      if (account != null) 'account': account,
    };

    Logger.info('Logging in with provider ${provider.headerValue}', data: {
      'category': _category,
      'userEmail': user['email'],
    });

    final response = await _client.post(
      _buildUri('/api/login'),
      headers: {
        'Content-Type': 'application/json',
        'X-Auth-Provider': provider.headerValue,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      Logger.error('Backend login failed', data: {
        'category': _category,
        'status': response.statusCode,
        'body': response.body,
      });
      throw Exception('Backend login failed: ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return UserModel.fromJson(payload);
  }

  Future<UserModel> getUserDetails({
    required String appToken,
    required SocialAuthProvider provider,
  }) async {
    final response = await _client.get(
      _buildUri('/api/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $appToken',
        'X-Auth-Provider': provider.headerValue,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user details: ${response.statusCode}');
    }

    return UserModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> refreshAppToken({
    required String userId,
  }) async {
    final response = await _client.post(
      _buildUri('/api/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh token: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> logout({
    required String appToken,
    required SocialAuthProvider provider,
  }) async {
    final response = await _client.post(
      _buildUri('/api/logout'),
      headers: {
        'Authorization': 'Bearer $appToken',
        'X-Auth-Provider': provider.headerValue,
      },
    );

    if (response.statusCode != 200) {
      Logger.info('Logout returned non-200 status but continuing', data: {
        'category': _category,
        'status': response.statusCode,
        'body': response.body,
      });
    }
  }

  Future<http.Response> authenticatedRequest({
    required String path,
    required String method,
    required String appToken,
    required SocialAuthProvider provider,
    Map<String, dynamic>? body,
  }) {
    final headers = <String, String>{
      'Authorization': 'Bearer $appToken',
      'X-Auth-Provider': provider.headerValue,
      'Content-Type': 'application/json',
    };

    final uri = _buildUri(path);
    switch (method.toUpperCase()) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri,
            headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'PUT':
        return _client.put(uri,
            headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'DELETE':
        return _client.delete(uri,
            headers: headers, body: body != null ? jsonEncode(body) : null);
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }
  }
}

String _normalizeBaseUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
