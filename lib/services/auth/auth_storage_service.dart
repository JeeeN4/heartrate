import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const String tokenKey = "auth_token";

  // 🔥 SAVE TOKEN
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(tokenKey, token);
  }

  // 🔥 GET TOKEN
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(tokenKey);
  }

  // 🔥 LOGOUT
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(tokenKey);
  }
}
