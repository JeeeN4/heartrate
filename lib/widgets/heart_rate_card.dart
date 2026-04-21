import 'package:flutter/material.dart';

class HeartRateCard extends StatelessWidget {
  final int heartRate;
  final bool isConnected;

  const HeartRateCard({
    super.key,
    required this.heartRate,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$heartRate",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const TextSpan(
                  text: " BPM",
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConnected
                ? "Resting Rate • Monitoring"
                : "Device not connected",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}