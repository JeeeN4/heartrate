import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive/hive.dart';

// EXPORT DATA
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

// GRAFIK
import 'package:fl_chart/fl_chart.dart';

// HTTP
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // DATA GRAFIK
  List<FlSpot> bpmData = [];
  double time = 0;

  final Guid serviceUuid = Guid("0000180d-0000-1000-8000-00805f9b34fb");
  final Guid charUuid = Guid("00002a37-0000-1000-8000-00805f9b34fb");

  // 🔥 THROTTLE
  DateTime? lastSent;

  // ================= SEND TO SERVER =================

  Future<void> sendHRToServer(int bpm) async {
    final now = DateTime.now();

    // throttle 1 detik
    if (lastSent != null && now.difference(lastSent!).inMilliseconds < 1000) {
      return;
    }

    lastSent = now;

    final url = Uri.parse(
      'https://webhook.site/bb761321-fe4a-4d99-ab5a-2ca88f17c996',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "memberId": "u1",
          "bpm": bpm,
          "ts": DateTime.now().millisecondsSinceEpoch,
          "deviceId": connectedDevice?.id.toString(),
          "source": "flutter",
        }),
      );

      print("✅ SENT BPM: $bpm");
      print("STATUS: ${response.statusCode}");
    } catch (e) {
      print("❌ ERROR: $e");
    }
  }

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

    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    await Future.delayed(const Duration(seconds: 5));
    setState(() => isScanning = false);
  }

  // ================= CONNECT =================

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    setState(() {
      isConnected = true;
      scanResults.clear();
    });

    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid == serviceUuid) {
        for (var c in service.characteristics) {
          if (c.uuid == charUuid) {
            await c.setNotifyValue(true);

            c.lastValueStream.listen((value) {
              if (value.isNotEmpty && value.length >= 2) {
                int flag = value[0];
                bool is16Bit = flag & 0x01 != 0;

                int bpm;
                if (is16Bit && value.length >= 3) {
                  bpm = value[1] | (value[2] << 8);
                } else {
                  bpm = value[1];
                }

                print("❤️ BPM DETECTED: $bpm");

                setState(() {
                  heartRate = bpm;

                  bpmData.add(FlSpot(time, bpm.toDouble()));
                  time += 1;

                  if (bpmData.length > 20) {
                    bpmData.removeAt(0);
                  }
                });

                saveHeartRate(bpm);

                // 🔥 KIRIM KE WEBHOOK
                sendHRToServer(bpm);
              }
            });
          }
        }
      }
    }
  }

  // ================= DISCONNECT =================

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();

      setState(() {
        isConnected = false;
        connectedDevice = null;
        heartRate = 0;
        bpmData.clear();
        time = 0;
      });
    }
  }

  // ================= SAVE DATA =================

  void saveHeartRate(int bpm) {
    var box = Hive.box('hr_box');
    box.add({'bpm': bpm, 'time': DateTime.now().toIso8601String()});
  }

  // ================= EXPORT DATA =================

  Future<void> exportData() async {
    var box = Hive.box('hr_box');

    List<List<dynamic>> rows = [];
    rows.add(["BPM", "Time"]);

    for (var item in box.values) {
      rows.add([item['bpm'], item['time']]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = Directory('/storage/emulated/0/Download/FitSense');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final path = "${directory.path}/heart_rate_data.csv";

    File file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data berhasil disimpan di:\n$path")),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.favorite, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        "Precision & Pulse",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.notifications_none),
                ],
              ),

              const SizedBox(height: 24),

              // TITLE
              const Text(
                "REAL-TIME READING",
                style: TextStyle(color: Colors.brown, letterSpacing: 1.2),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Cardiac Rhythm",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isConnected ? "● Active" : "● Offline",
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // HEART RATE CARD
              Container(
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
              ),

              const SizedBox(height: 20),

              // 🔥 REAL CHART (pakai data kamu)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: bpmData,
                          isCurved: true,
                          dotData: FlDotData(show: false),
                          color: Colors.red,
                          barWidth: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // STATUS
              Container(
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
                    Expanded(
                      child: Text(
                        isConnected
                            ? "Connected - ${connectedDevice?.platformName ?? 'Device'}"
                            : "Not Connected",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isConnected) const Text("Live"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: startScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isScanning ? "Scanning..." : "Scan Device"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isConnected ? disconnectDevice : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Disconnect"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // DOWNLOAD
              GestureDetector(
                onTap: exportData,
                child: const Center(
                  child: Text(
                    "Download Historical Data",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔥 LIST DEVICE (opsional tapi penting biar connect jalan)
              Expanded(
                child: ListView.builder(
                  itemCount: scanResults.length,
                  itemBuilder: (context, index) {
                    final r = scanResults[index];
                    final device = r.device;

                    return ListTile(
                      title: Text(
                        device.platformName.isNotEmpty
                            ? device.platformName
                            : device.id.toString(),
                      ),
                      subtitle: Text(r.rssi.toString()),
                      onTap: () => connectToDevice(device),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}