import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';

class WebSocketService {
  WebSocketChannel? _notificationsChannel;
  WebSocketChannel? _trackingChannel;
  StreamSubscription? _notificationSub;
  StreamSubscription? _trackingSub;

  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _trackingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;
  Stream<Map<String, dynamic>> get trackingUpdates => _trackingController.stream;

  void connectNotifications(String token) {
    disconnectNotifications();
    final uri = Uri.parse('${AppConfig.wsBaseUrl}/ws/notifications?token=$token');
    _notificationsChannel = WebSocketChannel.connect(uri);
    _notificationSub = _notificationsChannel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        _notificationController.add(decoded);
      },
      onError: (_) {},
    );
  }

  void connectTracking({required int bookingId, required String token}) {
    disconnectTracking();
    final uri = Uri.parse(
      '${AppConfig.wsBaseUrl}/ws/tracking/$bookingId?token=$token',
    );
    _trackingChannel = WebSocketChannel.connect(uri);
    _trackingSub = _trackingChannel!.stream.listen(
      (data) {
        final decoded = jsonDecode(data as String) as Map<String, dynamic>;
        _trackingController.add(decoded);
      },
      onError: (_) {},
    );
  }

  void disconnectNotifications() {
    _notificationSub?.cancel();
    _notificationsChannel?.sink.close();
    _notificationsChannel = null;
  }

  void disconnectTracking() {
    _trackingSub?.cancel();
    _trackingChannel?.sink.close();
    _trackingChannel = null;
  }
}
