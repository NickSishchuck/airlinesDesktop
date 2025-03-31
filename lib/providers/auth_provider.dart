import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool get isAuthenticated => _user != null;
  User? get user => _user;

  Future<bool> checkAuthentication() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        _user = null;
        return false;
      }

      // Only check with API if we don't already have a user
      if (_user == null) {
        _user = await _apiService.getCurrentUser();

        // Only allow admin or staff roles
        if (_user != null && (_user!.role == 'admin' || _user!.role == 'worker')) {
          notifyListeners();
          return true;
        } else {
          // If user is not admin or staff, logout
          await logout();
          return false;
        }
      }

      return _user != null;
    } catch (e) {
      await logout();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _user = await _apiService.login(email, password);

      // Only allow admin or staff roles
      if (_user != null && (_user!.role == 'admin' || _user!.role == 'worker')) {
        notifyListeners();
        return true;
      } else {
        // If user is not admin or staff, logout
        await logout();
        throw Exception('Only admin and staff can access this application');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    notifyListeners();
  }
}