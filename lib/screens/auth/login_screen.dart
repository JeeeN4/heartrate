import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';
import 'register_screen.dart';
import '../../services/auth/auth_service.dart';
import '../ble_screen.dart';
import '../../services/auth/auth_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();
  final authStorage = AuthStorageService();

  bool isLoading = false;

  void onLogin() async {
    setState(() => isLoading = true);

    final result = await authService.login(
      email: emailController.text,
      password: passwordController.text,
    );

    setState(() => isLoading = false);

    if (result != null) {
      print("LOGIN SUCCESS");

      final token = result['token'];

      print("TOKEN: $token");

      await authStorage.saveToken(token);

      print("TOKEN SAVED");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BleScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login gagal")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome Back", style: AppTextStyle.title),

            AppSpacing.h8,

            const Text("Login to continue", style: AppTextStyle.caption),

            AppSpacing.h24,

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            AppSpacing.h12,

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            AppSpacing.h20,

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Login"),
              ),
            ),

            AppSpacing.h16,

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text(
                "Don't have an account? Register",
                style: AppTextStyle.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
