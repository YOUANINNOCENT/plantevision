import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService._privateConstructor() {
    configure();
  }

  static final ApiService instance = ApiService._privateConstructor();

  /// URL de base du backend. Valeur par défaut adaptée à la plateforme.
  late String baseUrl;

  int? _currentUserId;
  String? _authToken;

  int? get currentUserId => _currentUserId;

  /// Charge les préférences (si disponibles). Non bloquant.
  Future<void> loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      _authToken = prefs.getString('auth_token');
    } catch (_) {}
  }

  String _determineDefaultBaseUrl() {
    // Development-friendly defaults
    try {
      if (kIsWeb) return 'http://192.168.0.102:8000';
      if (Platform.isAndroid) return 'http://10.0.2.2:8000'; // Android emulator
      if (Platform.isIOS) return 'http://localhost:8000'; // iOS simulator
    } catch (_) {}
    return 'http://192.168.0.102:8000';
  }

  /// Configure le service (appelé automatiquement au premier accès).
  void configure({String? overrideBaseUrl}) {
    if (overrideBaseUrl != null && overrideBaseUrl.isNotEmpty) {
      baseUrl = overrideBaseUrl;
    } else {
      baseUrl = _determineDefaultBaseUrl();
    }
    // Kick off loading prefs asynchronously
    loadPrefs();
  }

  /// Remplace l'URL de base à chaud.
  void setBaseUrl(String url) {
    if (url.isNotEmpty) baseUrl = url;
  }

  /// Se déconnecte localement
  Future<void> logout() async {
    _currentUserId = null;
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('auth_token');
    } catch (_) {}
  }

  Map<String, String> _defaultHeaders() {
    final h = <String, String>{'Accept': 'application/json'};
    if (_authToken != null && _authToken!.isNotEmpty) {
      h['Authorization'] = 'Bearer ${_authToken!}';
    }
    return h;
  }

  Uri _buildUri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = _buildUri(path);
    final resp = await http.get(uri, headers: _defaultHeaders());
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> postJson(String path, Object body) async {
    final uri = _buildUri(path);
    final resp = await http.post(
      uri,
      headers: {..._defaultHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(resp);
  }

  Future<Map<String, dynamic>> patchJson(String path, Object body) async {
    final uri = _buildUri(path);
    final resp = await http.patch(
      uri,
      headers: {..._defaultHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(resp);
  }

  Map<String, dynamic> _handleResponse(http.Response resp) {
    final code = resp.statusCode;
    if (code >= 200 && code < 300) {
      try {
        final parsed = jsonDecode(resp.body);
        if (parsed is Map<String, dynamic>) return parsed;
        // If the server returned a list or other JSON, wrap it
        return {'result': parsed};
      } catch (e) {
        return {};
      }
    }

    String msg = resp.reasonPhrase ?? 'HTTP $code';
    try {
      final parsed = jsonDecode(resp.body);
      if (parsed is Map && parsed['detail'] != null) {
        msg = parsed['detail'].toString();
      } else if (parsed is Map && parsed['message'] != null) {
        msg = parsed['message'].toString();
      }
    } catch (_) {}
    throw ApiException(code, msg);
  }

  /// Récupère des informations enrichies sur une plante via le backend.
  /// Si l'endpoint n'existe pas, renvoie une map vide.
  Future<Map<String, dynamic>> getPlantInfo(String name) async {
    try {
      // Essaye un endpoint explicite si présent côté backend
      final resp = await postJson('/plant_info', {'name': name});
      return resp;
    } catch (_) {
      // Fallback vers /ask (si backend propose une route d'IA) ou retourne vide
      try {
        final r2 = await postJson('/ask', {
          'message': 'Info plant: $name',
          'user_id': _currentUserId ?? 0,
        });
        return r2;
      } catch (_) {
        return <String, dynamic>{};
      }
    }
  }

  /// Setter/getter for the full current user object (optional).
  Map<String, dynamic>? _currentUser;

  set currentUser(Map<String, dynamic>? u) {
    _currentUser = u;
    try {
      if (u == null) {
        _currentUserId = null;
        SharedPreferences.getInstance().then((p) => p.remove('user_id'));
      } else {
        final id = (u['id'] is int)
            ? u['id'] as int
            : int.tryParse(u['id'].toString());
        _currentUserId = id;
        SharedPreferences.getInstance().then(
          (p) => p.setInt('user_id', _currentUserId ?? 0),
        );
      }
    } catch (_) {}
  }

  Map<String, dynamic>? get currentUser => _currentUser;

  /// HTTP PUT helper
  Future<Map<String, dynamic>> putJson(String path, Object body) async {
    final uri = _buildUri(path);
    final resp = await http.put(
      uri,
      headers: {..._defaultHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(resp);
  }

  /// HTTP DELETE helper
  Future<void> delete(String path) async {
    final uri = _buildUri(path);
    final resp = await http.delete(uri, headers: _defaultHeaders());
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String msg = resp.reasonPhrase ?? 'HTTP ${resp.statusCode}';
      try {
        final parsed = jsonDecode(resp.body);
        if (parsed is Map && parsed['detail'] != null) {
          msg = parsed['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(resp.statusCode, msg);
    }
  }

  /// Auth: login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    try {
      final user = resp['user'];
      if (user is Map<String, dynamic>) {
        currentUser = Map<String, dynamic>.from(user);
      }
    } catch (_) {}
    return resp;
  }

  /// Auth: register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final body = {'email': email, 'password': password};
    if (fullName != null) {
      body['full_name'] = fullName;
    }
    final resp = await postJson('/auth/register', body);
    try {
      final user = resp['user'];
      if (user is Map<String, dynamic>) {
        // do not auto-login, just store nothing
      }
    } catch (_) {}
    return resp;
  }

  /// Change password for the current user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uid = _currentUserId;
    if (uid == null) throw ApiException(401, 'Utilisateur non connecté');
    await postJson('/users/$uid/change_password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  /// Reset password (from email flow)
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await postJson('/auth/reset_password', {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  /// Groq/chat completion helper — calls backend /ask endpoint and returns the JSON.
  Future<Map<String, dynamic>> groqChatCompletion(
    String message, {
    Duration? timeout,
    int? conversationId,
  }) async {
    final body = {
      'message': message,
      'conversation_id': conversationId,
      'user_id': _currentUserId ?? 0,
    };
    final future = postJson('/ask', body);
    if (timeout != null) {
      final resp = await future.timeout(timeout);
      return resp;
    }
    return await future;
  }
}
