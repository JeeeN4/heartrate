import 'package:flutter/material.dart';

import '../../services/auth/auth_storage_service.dart';
import '../auth/login_screen.dart';
import '../ble_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final authStorage = AuthStorageService();

  @override
  void initState() {
    super.initState();

    checkLogin();
  }

  void checkLogin() async {
    final token = await authStorage.getToken();

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (token != null) {
      print("AUTO LOGIN");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BleScreen()),
      );
    } else {
      print("NO TOKEN");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
