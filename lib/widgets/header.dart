import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_style.dart';

class Header extends StatelessWidget {
  const Header({super.key});

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
        const Icon(Icons.notifications_none),
      ],
    );
  }
}
