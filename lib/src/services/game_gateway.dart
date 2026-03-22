import '../models/app_models.dart';
import '../models/game_models.dart';

sealed class GatewayNotification {
  const GatewayNotification();
}

class RoomInvitationNotification extends GatewayNotification {
  const RoomInvitationNotification(this.invitation);

  final RoomInvitation invitation;
}

class InvitationFeedbackNotification extends GatewayNotification {
  const InvitationFeedbackNotification(this.feedback);

  final InvitationFeedback feedback;
}

class FriendCenterNotification extends GatewayNotification {
  const FriendCenterNotification(this.snapshot);

  final FriendCenterSnapshot snapshot;
}

class SessionExpiredNotification extends GatewayNotification {
  const SessionExpiredNotification(this.message);

  final String message;
}

abstract class GameGateway {
  Stream<RoomSnapshot> get roomSnapshots;
  Stream<GatewayNotification> get notifications;

  Future<void> register({
    required String account,
    required String nickname,
    required String password,
  });

  Future<LoginResult> login({
    required String account,
    required String password,
  });

  Future<void> resetPassword({
    required String account,
    required String newPassword,
  });

  Future<void> changePassword({
    required String sessionToken,
    required String currentPassword,
    required String newPassword,
  });

  Future<UserProfile> updateNickname({
    required String sessionToken,
    required String nickname,
  });

  Future<RoomSnapshot> startMatch({
    required String sessionToken,
    required UserProfile profile,
    required MatchMode mode,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  });

  Future<RoomSnapshot> createRoom({
    required String sessionToken,
  });

  Future<RoomSnapshot> joinRoom({
    required String sessionToken,
    required String roomCode,
  });

  Future<void> leaveRoom({
    required String sessionToken,
    required String roomId,
  });

  Future<RoomSnapshot> setRoomReady({
    required String sessionToken,
    required String roomId,
    required bool ready,
  });

  Future<RoomSnapshot> addBot({
    required String sessionToken,
    required String roomId,
    required int seatIndex,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  });

  Future<RoomSnapshot> removePlayer({
    required String sessionToken,
    required String roomId,
    required String playerId,
  });

  Future<FriendCenterSnapshot> fetchFriendCenter({
    required String sessionToken,
  });

  Future<FriendCenterSnapshot> sendFriendRequest({
    required String sessionToken,
    required String account,
  });

  Future<FriendCenterSnapshot> respondFriendRequest({
    required String sessionToken,
    required String requestId,
    required bool accept,
  });

  Future<FriendCenterSnapshot> deleteFriend({
    required String sessionToken,
    required String friendUserId,
  });

  Future<void> invitePlayer({
    required String sessionToken,
    required String roomId,
    required String targetAccount,
    required int seatIndex,
  });

  Future<RoomSnapshot?> respondInvitation({
    required String sessionToken,
    required String invitationId,
    required bool accept,
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

  Future<void> recoverConnection();

  Future<RoomSnapshot?> refreshCurrentRoom();

  RoomSnapshot? currentSnapshot(String roomId);

  void clearCurrentRoomCache();

  void forgetSession();

  Future<void> close();
}
