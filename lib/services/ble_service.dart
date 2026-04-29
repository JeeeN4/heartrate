import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final Guid serviceUuid = Guid("0000180d-0000-1000-8000-00805f9b34fb");
  final Guid charUuid = Guid("00002a37-0000-1000-8000-00805f9b34fb");
  final Guid batteryServiceUuid = Guid("0000180f-0000-1000-8000-00805f9b34fb");
  final Guid batteryCharUuid = Guid("00002a19-0000-1000-8000-00805f9b34fb");

  // ================= SCAN =================

  Stream<List<ScanResult>> scanDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    return FlutterBluePlus.scanResults.map((results) {
      return results.where((r) {
        return r.advertisementData.serviceUuids.any(
          (uuid) => uuid.toString().toLowerCase().contains("180d"),
        );
      }).toList();
    });
  }

  // ================= CONNECT =================

  Future<void> connectToDevice(
    BluetoothDevice device,
    Function(int bpm) onData,
    Function() onDisconnect, {
    Function(int battery)? onBattery,
  }) async {
    await device.connect();

    // listen disconnect
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        print("❌ DEVICE DISCONNECTED"); // 🔥 TARUH DI SINI
        onDisconnect();
      }
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

                onData(bpm); // 🔥 kirim ke UI
              }
            });
          }
        }
      }

      // 🔋 BATTERY SERVICE
      if (service.uuid == batteryServiceUuid) {
        for (var c in service.characteristics) {
          if (c.uuid == batteryCharUuid) {
            var value = await c.read();

            if (value.isNotEmpty) {
              int batteryLevel = value[0];

              print("🔋 Battery: $batteryLevel%");

              onBattery?.call(batteryLevel);
            }
          }
        }
      }
    }
  }

  // ================= DISCONNECT =================

  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }

  // ================= CHECK BT =================

  Future<bool> isBluetoothOn() async {
    var state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }
}
