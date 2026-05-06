import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_style.dart';
import '../../services/auth/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;

  void onRegister() async {
    setState(() => isLoading = true);

    final result = await authService.register(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
    );

    setState(() => isLoading = false);

    if (result != null) {
      print("REGISTER SUCCESS");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register berhasil")));

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register gagal")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Create Account", style: AppTextStyle.title),

            AppSpacing.h24,

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            AppSpacing.h12,

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
                onPressed: isLoading ? null : onRegister,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
