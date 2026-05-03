// ============================================
// API Service — HTTP Client for Backend
// ============================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/services/auth_service.dart';

class ApiService {
  static String get baseUrl {
    // Android emulator uses 10.0.2.2 to reach host localhost
    if (Platform.isAndroid) return AppConfig.apiBaseUrl;
    return AppConfig.iosApiBaseUrl;
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 30));
    return _handle(res);
  }

  // POST
  static Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 30));
    return _handle(res);
  }

  // PUT
  static Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 30));
    return _handle(res);
  }

  // DELETE
  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 30));
    return _handle(res);
  }

  static Map<String, dynamic> _handle(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException(data['message'] ?? 'Something went wrong', res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
