import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onebus/constants/app_constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _expiryKey = 'token_expiry';

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    return _retry(() async {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        await _storeSession(
          token: data['token'],
          email: data['email'],
          fullName: data['fullName'],
          role: data['role'],
          companyId: data['companyId'],
          expiry: data['expiresAt'],
        );

        return {'success': true, 'data': data};
      } else {
        final error = response.body;
        return {'success': false, 'error': error};
      }
    });
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        await _storeSession(
          token: data['token'],
          email: data['email'],
          fullName: data['fullName'],
          role: data['role'],
          companyId: data['companyId'],
          expiry: data['expiresAt'],
        );

        return {'success': true, 'data': data};
      } else {
        final error = response.body;
        return {'success': false, 'error': error};
      }
    } catch (e) {
      print('[AuthService] Registration failed. Error: $e');
      return {'success': false, 'error': 'Connection timeout or error. Please check if you can login or try again later.'};
    }
  }

  // Store session data
  Future<void> _storeSession({
    required String token,
    required String email,
    required String fullName,
    required String role,
    String? companyId,
    required String expiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_expiryKey, expiry);
    
    final userData = {
      'email': email,
      'fullName': fullName,
      'role': role,
      'companyId': companyId,
    };
    
    await prefs.setString(_userDataKey, jsonEncode(userData));
    print('[AuthService] Session stored successfully');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiryString = prefs.getString(_expiryKey);

    if (token == null || expiryString == null) {
      return false;
    }

    // Check if token is expired
    try {
      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry)) {
        print('[AuthService] Token expired, logging out');
        await logout();
        return false;
      }
      return true;
    } catch (e) {
      print('[AuthService] Error parsing expiry: $e');
      return false;
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString == null) {
      return null;
    }

    try {
      return jsonDecode(userDataString);
    } catch (e) {
      print('[AuthService] Error parsing user data: $e');
      return null;
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_expiryKey);
    print('[AuthService] User logged out successfully');
  }

  /// Helper method to retry a network call with backoff
  Future<T> _retry<T>(Future<T> Function() call, {int maxAttempts = 2}) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await call();
      } catch (e) {
        if (attempts >= maxAttempts) {
          print('[AuthService] Max retry attempts reached ($maxAttempts). Error: $e');
          if (T == Map<String, dynamic>) {
            return {'success': false, 'error': 'Connection timeout. Please try again.'} as T;
          }
          rethrow;
        }
        print('[AuthService] Network attempt $attempts failed, retrying... Error: $e');
        await Future.delayed(Duration(seconds: attempts));
      }
    }
  }
}
