import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'package:http/http.dart' as http;

/// Simple API client service
/// Usage:
///   ApiService.instance.baseUrl = 'https://api.example.com/';
///   ApiService.instance.setToken('xxx');
///   final data = await ApiService.instance.getJson('/path');
class ApiService {
  static final ApiService instance = ApiService._internal();

  /// Base URL must include scheme and optional trailing slash
  String baseUrl = 'https://api.example.com';
  ApiService._internal() {
    // When running as web app, prefer the current origin to avoid mixed-content issues.
    if (kIsWeb) {
      try {
        final ub = Uri.base;
        // If the frontend is served over plain HTTP during development, prefer calling local backend directly.
        if (ub.scheme == 'http') {
          baseUrl = 'http://127.0.0.1:8000';
        } else {
          baseUrl = ub.origin;
        }
      } catch (_) {
        baseUrl = 'http://127.0.0.1:8000';
      }
    } else {
      // Default for local development on desktop/mobile.
      // When running the Android emulator, the host machine is reachable
      // at 10.0.2.2 instead of 127.0.0.1.
      if (defaultTargetPlatform == TargetPlatform.android) {
        baseUrl = 'http://10.0.2.2:8000';
      } else {
        baseUrl = 'http://127.0.0.1:8000';
      }
    }
  }
  String? _token;
  final Duration _timeout = const Duration(seconds: 20);

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _defaultHeaders {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? params]) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$cleanBase$path');
    if (params == null || params.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: params);
  }

  void _handleStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    String message = 'Erreur HTTP ${res.statusCode}';
    try {
      final body = json.decode(res.body);
      if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      }
    } catch (_) {}
    throw ApiException(res.statusCode, message);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? params,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, params);
    try {
      final res = await http
          .get(uri, headers: {..._defaultHeaders, ...?headers})
          .timeout(_timeout);
      _handleStatus(res);
      return json.decode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw ApiException(504, 'Le serveur ne répond pas');
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    try {
      final res = await http
          .post(
            uri,
            headers: {..._defaultHeaders, ...?headers},
            body: json.encode(body),
          )
          .timeout(_timeout);
      _handleStatus(res);
      return json.decode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw ApiException(504, 'Le serveur ne répond pas');
    }
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    try {
      final res = await http
          .put(
            uri,
            headers: {..._defaultHeaders, ...?headers},
            body: json.encode(body),
          )
          .timeout(_timeout);
      _handleStatus(res);
      return json.decode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw ApiException(504, 'Le serveur ne répond pas');
    }
  }

  Future<void> delete(String path, {Map<String, String>? headers}) async {
    final uri = _buildUri(path);
    try {
      final res = await http
          .delete(uri, headers: {..._defaultHeaders, ...?headers})
          .timeout(_timeout);
      _handleStatus(res);
    } on TimeoutException {
      throw ApiException(504, 'Le serveur ne répond pas');
    }
  }

  /// Upload a single file with multipart/form-data
  /// Returns decoded JSON response if server returns JSON
  /// Upload a single file as bytes (works on Web and native).
  Future<Map<String, dynamic>> uploadFileBytes(
    String path,
    Uint8List bytes, {
    String fieldName = 'file',
    String? filename,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({..._defaultHeaders, ...?headers});
    // Remove content-type so MultipartRequest can set boundary
    request.headers.remove('content-type');
    if (fields != null) {
      request.fields.addAll(fields);
    }
    final multipartFile = http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename ?? 'upload.jpg',
    );
    request.files.add(multipartFile);
    try {
      final streamed = await request.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed).timeout(_timeout);
      _handleStatus(res);
      return json.decode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw ApiException(504, 'Le serveur ne répond pas');
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
