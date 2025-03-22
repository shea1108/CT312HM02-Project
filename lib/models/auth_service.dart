import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final PocketBase pb = PocketBase('http://10.0.2.2:8090');
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AuthService() {
    _loadLoginStatus();
  }
  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getString('authToken') != null;
    notifyListeners();
  }

  // Đăng ký
  Future<bool> signUp(String email, String password) async {
    try {
      await pb.collection('users').create(body: {
        "email": email,
        "password": password,
        "passwordConfirm": password
      });
      return await login(email, password);
    } catch (e) {
      print("$e");
      return false;
    }
  }

  // Đăng nhập
  Future<bool> login(String email, String password) async {
    try {
      final authData = await pb.collection('users').authWithPassword(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', authData.token);
      await prefs.setString('userId', authData.record.id);

      _isLoggedIn = true;
      notifyListeners(); 
      return true;
    } catch (e) {
      print("$e");
      return false;
    }
  }

}
