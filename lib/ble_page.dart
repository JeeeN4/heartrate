import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive/hive.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/ble_service.dart';
import '../services/socket_service.dart';

// WIDGETS
import '../widgets/heart_rate_card.dart';
import '../widgets/bpm_chart.dart';
import '../widgets/action_buttons.dart';
import '../widgets/device_bottom_sheet.dart';

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

  // ================= SOCKET.IO =================
  final socketService = SocketService();
  @override
  void initState() {
    super.initState();

    socketService.connect();

    socketService.listenHR((data) {
      print("REALTIME FROM SERVER: $data");
    });
  }

  @override
  void dispose() {
    socketService.dispose(); // 🔥 taruh di sini
    super.dispose();
  }

  // ================= SEND TO SERVER =================
  final apiService = ApiService();

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

  // ================= Device List =================
  void showDeviceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DeviceBottomSheet(
          scanResults: scanResults,
          isScanning: isScanning,
          onConnect: connectToDevice,
        );
      },
    );
  }

  // ================= SCAN =================
  final bleService = BleService();

  Future<bool> startScan() async {
    bool btOn = await bleService.isBluetoothOn();

    if (!btOn) {
      showBluetoothDialog();
      return false; // 🔥 tambahin ini
    }

    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    bleService.scanDevices().listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    await Future.delayed(const Duration(seconds: 5));

    setState(() => isScanning = false);

    print("SCAN STARTED");

    FlutterBluePlus.scanResults.listen((results) {
      print("RESULT COUNT: ${results.length}");
    });

    return true; // 🔥 tambahin ini
  }

  // ================= CONNECT =================
  Future<void> connectToDevice(BluetoothDevice device) async {
    connectedDevice = device;

    setState(() {
      isConnected = true;
      scanResults.clear();
    });

    await bleService.connectToDevice(
      device,
      (bpm) {
        print("❤️ BPM DETECTED: $bpm");

        setState(() {
          heartRate = bpm;

          bpmData.add(FlSpot(time, bpm.toDouble()));
          time += 1;

          if (bpmData.length > 20) {
            bpmData.removeAt(0);
          }
        });

        storageService.saveHR(bpm);

        apiService.sendHR(
          bpm: bpm,
          memberId: "u1",
          deviceId: connectedDevice?.id.toString(),
        );
      },
      () {
        setState(() {
          isConnected = false;
          connectedDevice = null;
          heartRate = 0;
          bpmData.clear();
          time = 0;
        });
      },
    );
    await apiService.sendConnect("u1");
  }

  // ================= DISCONNECT =================
  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await bleService.disconnect(connectedDevice!);
      await apiService.sendDisconnect("u1");

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
  final storageService = StorageService();
  void saveHeartRate(int bpm) {
    var box = Hive.box('hr_box');
    box.add({'bpm': bpm, 'time': DateTime.now().toIso8601String()});
  }

  // ================= EXPORT DATA =================

  Future<void> exportData() async {
    final path = await storageService.exportCSV();

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
              HeartRateCard(heartRate: heartRate, isConnected: isConnected),

              const SizedBox(height: 20),

              // 🔥 REAL CHART (pakai data kamu)
              BpmChart(bpmData: bpmData),

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
              ActionButtons(
                isScanning: isScanning,
                isConnected: isConnected,
                onScan: () async {
                  bool success = await startScan();

                  if (success) {
                    showDeviceBottomSheet();
                  }
                },
                onDisconnect: disconnectDevice,
                onDownload: exportData,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
