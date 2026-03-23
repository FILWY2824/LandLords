import 'game_gateway.dart';
import 'socket_game_gateway.dart';
import 'websocket_game_gateway.dart';

const String _configuredWsUrl =
    String.fromEnvironment('LANDLORDS_WS_URL', defaultValue: '');

GameGateway createPlatformGateway() {
  final wsUrl = _configuredWsUrl.trim();
  if (wsUrl.isNotEmpty) {
    return WebSocketGameGateway(url: wsUrl);
  }
  return SocketGameGateway();
}
