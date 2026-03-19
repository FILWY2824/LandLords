import 'dart:io';

import 'game_gateway.dart';
import 'socket_game_gateway.dart';
import 'websocket_game_gateway.dart';

const String _configuredWsUrl =
    String.fromEnvironment('LANDLORDS_WS_URL', defaultValue: '');
const String _configuredTcpHost =
    String.fromEnvironment('LANDLORDS_TCP_HOST', defaultValue: '');
const int _configuredTcpPort =
    int.fromEnvironment('LANDLORDS_TCP_PORT', defaultValue: 23001);
const String _fallbackMobileWsUrl =
    String.fromEnvironment('LANDLORDS_MOBILE_WS_URL', defaultValue: '');

GameGateway createPlatformGateway() {
  final wsUrl = _configuredWsUrl.trim();
  if (wsUrl.isNotEmpty) {
    return WebSocketGameGateway(url: wsUrl);
  }
  if (Platform.isAndroid || Platform.isIOS) {
    final mobileWsUrl = _fallbackMobileWsUrl.trim();
    if (mobileWsUrl.isNotEmpty) {
      return WebSocketGameGateway(url: mobileWsUrl);
    }
    return WebSocketGameGateway(url: 'ws://10.0.2.2:23002/ws');
  }
  final tcpHost = _configuredTcpHost.trim();
  if (tcpHost.isNotEmpty) {
    return SocketGameGateway(host: tcpHost, port: _configuredTcpPort);
  }
  return SocketGameGateway();
}
