import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  DateTime? lastSent;

  final String baseUrl = "http://10.221.135.214:3001";

  Future<void> sendHR({
    required int bpm,
    required String memberId,
    String? deviceId,
  }) async {
    final now = DateTime.now();

    // throttle 1 detik
    if (lastSent != null && now.difference(lastSent!).inMilliseconds < 1000) {
      return;
    }

    lastSent = now;

    final url = Uri.parse("$baseUrl/api/mobile/hr");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "memberId": memberId,
          "bpm": bpm,
          "ts": DateTime.now().millisecondsSinceEpoch,
          "deviceId": deviceId,
          "source": "flutter",
        }),
      );

      print("✅ SENT BPM: $bpm");
      print("STATUS: ${response.statusCode}");
    } catch (e) {
      print("❌ ERROR: $e");
    }
  }

  Future<void> sendConnect(String memberId) async {
    final url = Uri.parse("$baseUrl/api/mobile/connect");

    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"memberId": memberId}),
      );

      print("🟢 SENT CONNECT");
    } catch (e) {
      print("ERROR CONNECT: $e");
    }
  }

  Future<void> sendDisconnect(String memberId) async {
    final url = Uri.parse("$baseUrl/api/mobile/disconnect");

    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"memberId": memberId}),
      );

      print("❌ SENT DISCONNECT");
    } catch (e) {
      print("ERROR DISCONNECT: $e");
    }
  }
}
