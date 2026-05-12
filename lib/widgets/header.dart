import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_style.dart';

class Header extends StatelessWidget {
  final VoidCallback onLogout;

  const Header({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.favorite, color: Colors.red),
            AppSpacing.w8,
            Text("Precision & Pulse", style: AppTextStyle.subtitle),
          ],
        ),
        IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
      ],
    );
  }
}
