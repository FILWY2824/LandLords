import 'game_gateway.dart';
import 'gateway_factory_stub.dart'
    if (dart.library.io) 'gateway_factory_io.dart'
    if (dart.library.js_interop) 'gateway_factory_web.dart';

GameGateway createGateway() => createPlatformGateway();
