import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isScanning;
  final bool isConnected;
  final VoidCallback onScan;
  final VoidCallback onDisconnect;
  final VoidCallback onDownload;

  const ActionButtons({
    super.key,
    required this.isScanning,
    required this.isConnected,
    required this.onScan,
    required this.onDisconnect,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔥 SCAN + DISCONNECT
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onScan,
                icon: Image.asset(
                  "assets/icons/scan.png",
                  width: 20,
                  height: 20,
                ),
                label: Text(isScanning ? "Scanning..." : "Scan Device"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isConnected ? onDisconnect : null,
                icon: Image.asset(
                  "assets/icons/disconnect.png",
                  width: 20,
                  height: 20,
                  color: isConnected ? Colors.white : Colors.grey,
                ),
                label: const Text("Disconnect"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 🔥 DOWNLOAD BUTTON
        GestureDetector(
          onTap: onDownload,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/icons/download.png",
                    width: 20,
                    height: 20,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Download Historical Data",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}