import 'game_gateway.dart';
import 'socket_game_gateway.dart';

GameGateway createPlatformGateway() => SocketGameGateway();
