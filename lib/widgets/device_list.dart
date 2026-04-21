import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceList extends StatelessWidget {
  final List<ScanResult> scanResults;
  final Function(BluetoothDevice) onTap;

  const DeviceList({
    super.key,
    required this.scanResults,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: scanResults.length,
      itemBuilder: (context, index) {
        final r = scanResults[index];
        final device = r.device;

        return Card(
          child: ListTile(
            title: Text(
              device.platformName.isNotEmpty
                  ? device.platformName
                  : "Unknown Device",
            ),
            subtitle: Text("ID: ${device.id}\nRSSI: ${r.rssi}"),
            onTap: () => onTap(device),
          ),
        );
      },
    );
  }
}