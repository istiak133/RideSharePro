// ============================================
// Auth Provider — Login State Management
// ============================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rideshare_app/services/api_service.dart';
import 'package:rideshare_app/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;
  String? _role;
  String? _token;
  String? _devOTP; // For development testing

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String? get role => _role;
  String? get token => _token;
  String? get devOTP => _devOTP;
  bool get isLoggedIn => _token != null;

  // Request OTP
  Future<bool> requestOTP(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post('/auth/request-otp', body: {'phone': phone});
      _devOTP = res['data']?['devOTP']; // Auto-fill in dev mode
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP & Login
  Future<bool> verifyOTP(String phone, String otp, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post('/auth/verify-otp', body: {
        'phone': phone,
        'otp': otp,
        'role': role,
      });

      _token = res['data']['token'];
      _user = res['data']['user'];
      _role = role;

      // Save to local storage
      await AuthService.saveToken(_token!);
      await AuthService.saveRole(role);
      await AuthService.saveUserData(jsonEncode(_user));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('OTP Verification Error: $e'); // Added detailed log
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Auto-login from saved token
  Future<bool> tryAutoLogin() async {
    final token = await AuthService.getToken();
    final role = await AuthService.getRole();
    final userData = await AuthService.getUserData();

    if (token == null || role == null) return false;

    try {
      _token = token;
      _role = role;
      if (userData != null) _user = jsonDecode(userData);

      // Verify token is still valid
      final res = await ApiService.get('/auth/me');
      _user = res['data'];
      await AuthService.saveUserData(jsonEncode(_user));
      notifyListeners();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    _role = null;
    await AuthService.logout();
    notifyListeners();
  }
}
