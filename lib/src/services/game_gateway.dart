import '../models/app_models.dart';
import '../models/game_models.dart';

abstract class GameGateway {
  Stream<RoomSnapshot> get roomSnapshots;

  Future<void> register({
    required String username,
    required String password,
  });

  Future<LoginResult> login({
    required String username,
    required String password,
  });

  Future<RoomSnapshot> startMatch({
    required String sessionToken,
    required UserProfile profile,
    required MatchMode mode,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  });

  Future<void> cancelMatch({
    required String sessionToken,
  });

  Future<RoomSnapshot> playCards({
    required String sessionToken,
    required String roomId,
    required List<String> cardIds,
  });

  Future<RoomSnapshot> callScore({
    required String sessionToken,
    required String roomId,
    required int score,
  });

  Future<RoomSnapshot> setManaged({
    required String sessionToken,
    required String roomId,
    required bool managed,
  });

  Future<RoomSnapshot> pass({
    required String sessionToken,
    required String roomId,
  });

  Future<List<String>> requestSuggestion({
    required String sessionToken,
    required String roomId,
  });

  Future<void> acknowledgePresentation({
    required String sessionToken,
    required String roomId,
    required String actionId,
  });

  RoomSnapshot? currentSnapshot(String roomId);
}
