import 'package:flutter/material.dart';
import 'api.dart';

class AuthService extends ChangeNotifier {
  bool _loggedIn = false;
  Map<String, dynamic>? user;
  String? token;

  bool get isLoggedIn => _loggedIn;

  Future<void> login(String email, String password) async {
    final resp = await API.post('/auth/login', {'email': email, 'password': password});
    if (resp['accessToken'] != null) {
      token = resp['accessToken'];
      await setToken(token!);
      user = resp['user'];
      _loggedIn = true;
      notifyListeners();
    } else {
      throw Exception('Invalid login response: $resp');
    }
  }

  Future<void> logout() async {
    user = null;
    token = null;
    _loggedIn = false;
    await clearToken();
    notifyListeners();
  }

  Future<void> loadFromStorage() async {
    token = await getToken();
    _loggedIn = token != null;
    if (_loggedIn) {
      try {
        final me = await API.get('/auth/me');
        user = me['user'];
      } catch (e) {
        // token invalid
        await logout();
      }
    }
    notifyListeners();
  }
}
