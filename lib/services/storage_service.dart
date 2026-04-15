import 'dart:io';
import 'package:hive/hive.dart';
import 'package:csv/csv.dart';

class StorageService {
  final box = Hive.box('hr_box');

  void saveHR(int bpm) {
    box.add({
      'bpm': bpm,
      'time': DateTime.now().toIso8601String(),
    });
  }

  Future<String> exportCSV() async {
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

    return path;
  }
}