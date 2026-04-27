import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io(
      'http://10.221.135.214:3001', // 🔥 ganti IP kamu
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("✅ Socket Connected");
    });

    socket.onDisconnect((_) {
      print("❌ Socket Disconnected");
    });
  }

  void listenHR(Function(dynamic data) onData) {
    socket.on("hr", (data) {
      print("🔥 REALTIME DATA: $data");
      onData(data);
    });
  }

  void dispose() {
    socket.dispose();
  }
}
