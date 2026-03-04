import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive/hive.dart';

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  int heartRate = 0;
  bool isScanning = false;
  bool isConnected = false;

  final Guid serviceUuid = Guid("0000180d-0000-1000-8000-00805f9b34fb");
  final Guid charUuid = Guid("00002a37-0000-1000-8000-00805f9b34fb");

  // ================= BLUETOOTH CHECK =================

  Future<bool> isBluetoothOn() async {
    var state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  void showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bluetooth Off"),
        content: const Text(
          "Bluetooth belum aktif. Silakan nyalakan Bluetooth terlebih dahulu.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ================= SCAN =================

  Future<void> startScan() async {
    bool btOn = await isBluetoothOn();

    if (!btOn) {
      showBluetoothDialog();
      return;
    }

    print("🔍 Start Scan");

    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    await Future.delayed(const Duration(seconds: 5));
    setState(() => isScanning = false);

    print("🛑 Scan Finished");
  }

  // ================= CONNECT =================

  Future<void> connectToDevice(BluetoothDevice device) async {
    print("🔗 Connecting to ${device.id}");

    await device.connect();
    connectedDevice = device;

    setState(() => isConnected = true);

    print("✅ Connected");

    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      print("🧩 Service: ${service.uuid}");

      if (service.uuid == serviceUuid) {
        print("❤️ Heart Rate Service Found");

        for (var c in service.characteristics) {
          print("   ↳ Char: ${c.uuid}");

          if (c.uuid == charUuid) {
            print("🎯 Heart Rate Characteristic Found");

            await c.setNotifyValue(true);

            c.lastValueStream.listen((value) {
              print("📥 Raw: $value");

              if (value.isNotEmpty && value.length >= 2) {
                int flag = value[0];
                bool is16Bit = flag & 0x01 != 0;

                int bpm;
                if (is16Bit && value.length >= 3) {
                  bpm = value[1] | (value[2] << 8);
                } else {
                  bpm = value[1];
                }

                print("💓 BPM: $bpm");

                setState(() => heartRate = bpm);
                saveHeartRate(bpm);
              }
            });
          }
        }
      }
    }
  }

  void saveHeartRate(int bpm) {
    var box = Hive.box('hr_box');
    box.add({'bpm': bpm, 'time': DateTime.now().toIso8601String()});

    print("💾 Saved: $bpm");
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent,
        title: const Text(
          "Heart Rate Monitor",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ================= HEART RATE CARD =================
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.redAccent, Colors.pinkAccent],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Current Heart Rate",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  "$heartRate BPM",
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ================= STATUS =================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green[100]
                  : isScanning
                  ? Colors.orange[100]
                  : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isConnected
                    ? "🟢 Connected"
                    : isScanning
                    ? "🟡 Scanning..."
                    : "🔴 Disconnected",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isConnected
                      ? Colors.green
                      : isScanning
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ================= SCAN BUTTON =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: startScan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  "Scan BLE Devices",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= DEVICE LIST =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      result.device.name.isNotEmpty
                          ? result.device.name
                          : "Unknown Device",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(result.device.id.toString()),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => connectToDevice(result.device),
                      child: const Text("Connect"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
