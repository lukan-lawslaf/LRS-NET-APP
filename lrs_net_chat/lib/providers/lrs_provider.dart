import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../models/gps_data.dart';

class LrsProvider extends ChangeNotifier {
  static const String _wsUrl = 'ws://192.168.4.1/ws';
  static const Duration _reconnectDelay = Duration(seconds: 3);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  GpsData? _gpsData;
  GpsData? get gpsData => _gpsData;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  LrsProvider() {
    _connect();
  }

  void _connect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      debugPrint('[LRS] Connecting to $_wsUrl ...');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Mark connected after successful stream setup
      _isConnected = true;
      notifyListeners();
      debugPrint('[LRS] Connected');
    } catch (e) {
      debugPrint('[LRS] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final Map<String, dynamic> json = jsonDecode(raw as String);
      final type = json['type'] as String?;

      if (type == 'gps') {
        _gpsData = GpsData.fromJson(json);
        notifyListeners();
      } else if (type == 'chat') {
        final from = json['from']?.toString() ?? 'hiker';
        final text = json['text']?.toString() ?? '';
        _messages.add(ChatMessage(
          sender: from == 'hiker' ? Sender.hiker : Sender.base,
          text: text,
        ));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[LRS] Parse error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[LRS] WebSocket error: $error');
    _setDisconnected();
  }

  void _onDone() {
    debugPrint('[LRS] WebSocket closed');
    _setDisconnected();
  }

  void _setDisconnected() {
    _isConnected = false;
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    debugPrint('[LRS] Reconnecting in ${_reconnectDelay.inSeconds}s...');
    _reconnectTimer = Timer(_reconnectDelay, _connect);
  }

  void sendChat(String text) {
    if (text.trim().isEmpty) return;
    final payload = jsonEncode({'type': 'chat', 'text': text.trim()});
    try {
      _channel?.sink.add(payload);
      // Add own message to the list as "base" (we are base camp operator)
      _messages.add(ChatMessage(
        sender: Sender.base,
        text: text.trim(),
      ));
      notifyListeners();
    } catch (e) {
      debugPrint('[LRS] Send error: $e');
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
