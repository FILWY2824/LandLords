enum MatchMode { vsBot, online }

enum BotDifficulty { easy, normal, hard }

enum PlayerRole { farmer, landlord }

enum RoomPhase { preparing, waiting, playing, finished }

enum ActionType { play, pass }

enum InvitationFeedbackStatus { accepted, rejected, failed, expired }

enum FriendRequestStatus { pending, accepted, rejected, handled }

extension BotDifficultyPresentation on BotDifficulty {
  String get label => switch (this) {
        BotDifficulty.easy => '简单',
        BotDifficulty.normal => '正常',
        BotDifficulty.hard => '困难',
      };

  String get hallTitle => switch (this) {
        BotDifficulty.easy => '简单模式',
        BotDifficulty.normal => '标准模式',
        BotDifficulty.hard => '困难模式',
      };

  String get description => switch (this) {
        BotDifficulty.easy => '节奏更轻，适合快速上手。',
        BotDifficulty.normal => '强度均衡，适合正式对局。',
        BotDifficulty.hard => '压制更强，适合高强度对抗。',
      };

  String get gameChip => label;

  String get modelFamily => switch (this) {
        BotDifficulty.easy => 'DouZero-ADP',
        BotDifficulty.normal => 'DouZero-SL',
        BotDifficulty.hard => 'DouZero-WP',
      };

  String get modelAttribution => '基于开源$modelFamily模型';

  String get hallSummary => '$hallTitle：$modelAttribution';

  bool get prefersOnnx => true;
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.account,
    required this.nickname,
    required this.coins,
    this.landlordWins = 0,
    this.landlordGames = 0,
    this.farmerWins = 0,
    this.farmerGames = 0,
    this.onlineLandlordWins = 0,
    this.onlineLandlordGames = 0,
    this.onlineFarmerWins = 0,
    this.onlineFarmerGames = 0,
    this.botLandlordWins = 0,
    this.botLandlordGames = 0,
    this.botFarmerWins = 0,
    this.botFarmerGames = 0,
  });

  final String userId;
  final String account;
  final String nickname;
  final int coins;
  final int landlordWins;
  final int landlordGames;
  final int farmerWins;
  final int farmerGames;
  final int onlineLandlordWins;
  final int onlineLandlordGames;
  final int onlineFarmerWins;
  final int onlineFarmerGames;
  final int botLandlordWins;
  final int botLandlordGames;
  final int botFarmerWins;
  final int botFarmerGames;

  String get displayName => nickname.isNotEmpty ? nickname : account;

  String get username => displayName;

  int get totalScore => coins;
  int get totalGames => landlordGames + farmerGames;
  int get totalWins => landlordWins + farmerWins;

  double get landlordWinRate =>
      landlordGames == 0 ? 0 : landlordWins / landlordGames;

  double get farmerWinRate => farmerGames == 0 ? 0 : farmerWins / farmerGames;

  double get overallWinRate => totalGames == 0 ? 0 : totalWins / totalGames;

  int get onlineTotalWins => onlineLandlordWins + onlineFarmerWins;

  int get onlineTotalGames => onlineLandlordGames + onlineFarmerGames;

  double get onlineLandlordWinRate =>
      onlineLandlordGames == 0 ? 0 : onlineLandlordWins / onlineLandlordGames;

  double get onlineFarmerWinRate =>
      onlineFarmerGames == 0 ? 0 : onlineFarmerWins / onlineFarmerGames;

  double get onlineOverallWinRate =>
      onlineTotalGames == 0 ? 0 : onlineTotalWins / onlineTotalGames;

  int get botTotalWins => botLandlordWins + botFarmerWins;

  int get botTotalGames => botLandlordGames + botFarmerGames;

  double get botLandlordWinRate =>
      botLandlordGames == 0 ? 0 : botLandlordWins / botLandlordGames;

  double get botFarmerWinRate =>
      botFarmerGames == 0 ? 0 : botFarmerWins / botFarmerGames;

  double get botOverallWinRate =>
      botTotalGames == 0 ? 0 : botTotalWins / botTotalGames;

  UserProfile copyWith({
    String? userId,
    String? account,
    String? nickname,
    int? coins,
    int? landlordWins,
    int? landlordGames,
    int? farmerWins,
    int? farmerGames,
    int? onlineLandlordWins,
    int? onlineLandlordGames,
    int? onlineFarmerWins,
    int? onlineFarmerGames,
    int? botLandlordWins,
    int? botLandlordGames,
    int? botFarmerWins,
    int? botFarmerGames,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      account: account ?? this.account,
      nickname: nickname ?? this.nickname,
      coins: coins ?? this.coins,
      landlordWins: landlordWins ?? this.landlordWins,
      landlordGames: landlordGames ?? this.landlordGames,
      farmerWins: farmerWins ?? this.farmerWins,
      farmerGames: farmerGames ?? this.farmerGames,
      onlineLandlordWins: onlineLandlordWins ?? this.onlineLandlordWins,
      onlineLandlordGames: onlineLandlordGames ?? this.onlineLandlordGames,
      onlineFarmerWins: onlineFarmerWins ?? this.onlineFarmerWins,
      onlineFarmerGames: onlineFarmerGames ?? this.onlineFarmerGames,
      botLandlordWins: botLandlordWins ?? this.botLandlordWins,
      botLandlordGames: botLandlordGames ?? this.botLandlordGames,
      botFarmerWins: botFarmerWins ?? this.botFarmerWins,
      botFarmerGames: botFarmerGames ?? this.botFarmerGames,
    );
  }
}

class MatchTicket {
  const MatchTicket({
    required this.mode,
    required this.message,
  });

  final MatchMode mode;
  final String message;
}

class OnlineUser {
  const OnlineUser({
    required this.userId,
    required this.account,
    required this.nickname,
    required this.online,
  });

  final String userId;
  final String account;
  final String nickname;
  final bool online;

  String get displayName => nickname.isNotEmpty ? nickname : account;

  String get username => displayName;
}

class FriendRequestEntry {
  const FriendRequestEntry({
    required this.requestId,
    required this.requesterUserId,
    required this.requesterAccount,
    required this.requesterNickname,
    required this.receiverUserId,
    required this.receiverAccount,
    required this.receiverNickname,
    required this.status,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String requestId;
  final String requesterUserId;
  final String requesterAccount;
  final String requesterNickname;
  final String receiverUserId;
  final String receiverAccount;
  final String receiverNickname;
  final FriendRequestStatus status;
  final int createdAtMs;
  final int updatedAtMs;

  String get requesterName =>
      requesterNickname.isNotEmpty ? requesterNickname : requesterAccount;

  String get receiverName =>
      receiverNickname.isNotEmpty ? receiverNickname : receiverAccount;

  bool isIncomingFor(String userId) => receiverUserId == userId;

  bool isOutgoingFor(String userId) => requesterUserId == userId;

  String counterpartNameFor(String userId) =>
      isIncomingFor(userId) ? requesterName : receiverName;

  String counterpartAccountFor(String userId) =>
      isIncomingFor(userId) ? requesterAccount : receiverAccount;
}

class FriendCenterSnapshot {
  const FriendCenterSnapshot({
    required this.friends,
    required this.pendingRequests,
    required this.historyRequests,
    required this.pendingRequestCount,
  });

  const FriendCenterSnapshot.empty()
    : friends = const [],
      pendingRequests = const [],
      historyRequests = const [],
      pendingRequestCount = 0;

  final List<OnlineUser> friends;
  final List<FriendRequestEntry> pendingRequests;
  final List<FriendRequestEntry> historyRequests;
  final int pendingRequestCount;
}

class SupportStats {
  const SupportStats({
    required this.supportLikeCount,
  });

  const SupportStats.empty() : supportLikeCount = 0;

  final int supportLikeCount;
}

class SupportRewardResult {
  const SupportRewardResult({
    required this.profile,
    required this.stats,
    required this.rewardCoins,
  });

  final UserProfile profile;
  final SupportStats stats;
  final int rewardCoins;
}

class SupportRewardOffer {
  const SupportRewardOffer({
    required this.currentCoins,
    required this.rewardCoins,
    required this.supportLikeCount,
  });

  final int currentCoins;
  final int rewardCoins;
  final int supportLikeCount;
}

class RoomInvitation {
  const RoomInvitation({
    required this.invitationId,
    required this.roomId,
    required this.roomCode,
    required this.inviterUserId,
    required this.inviterAccount,
    required this.inviterNickname,
    required this.seatIndex,
  });

  final String invitationId;
  final String roomId;
  final String roomCode;
  final String inviterUserId;
  final String inviterAccount;
  final String inviterNickname;
  final int seatIndex;

  String get inviterName =>
      inviterNickname.isNotEmpty ? inviterNickname : inviterAccount;
}

class InvitationFeedback {
  const InvitationFeedback({
    required this.invitationId,
    required this.status,
    required this.targetUserId,
    required this.targetAccount,
    required this.targetNickname,
    required this.detail,
  });

  final String invitationId;
  final InvitationFeedbackStatus status;
  final String targetUserId;
  final String targetAccount;
  final String targetNickname;
  final String detail;

  String get targetName =>
      targetNickname.isNotEmpty ? targetNickname : targetAccount;
}

class AppDialogNotice {
  const AppDialogNotice({
    required this.title,
    required this.message,
    this.actionLabel = '知道了',
  });

  final String title;
  final String message;
  final String actionLabel;
}
