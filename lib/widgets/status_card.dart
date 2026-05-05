import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class StatusCard extends StatelessWidget {
  final bool isConnected;
  final BluetoothDevice? device;
  final int batteryLevel;

  const StatusCard({
    super.key,
    required this.isConnected,
    required this.device,
    required this.batteryLevel,
  });

  @override
  Widget build(BuildContext context) {
    String deviceName = device?.platformName ?? "Device";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isConnected ? Colors.green : Colors.grey,
            child: const Icon(Icons.bluetooth, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // 🔥 STATUS TEXT
          Expanded(
            child: Text(
              isConnected ? "Connected - $deviceName" : "Not Connected",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // 🔋 BATTERY
          if (isConnected)
            Text(
              "$batteryLevel%",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
        ],
      ),
    );
  }
}
