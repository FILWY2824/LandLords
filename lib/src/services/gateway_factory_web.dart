import 'game_gateway.dart';
import 'websocket_game_gateway.dart';

GameGateway createPlatformGateway() => WebSocketGameGateway();
