enum MatchMode { vsBot, online }

enum BotDifficulty { easy, normal, hard }

enum PlayerRole { farmer, landlord }

enum RoomPhase { preparing, waiting, playing, finished }

enum ActionType { play, pass }

enum InvitationFeedbackStatus { accepted, rejected, failed, expired }

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
  });

  final String userId;
  final String account;
  final String nickname;
  final int coins;
  final int landlordWins;
  final int landlordGames;
  final int farmerWins;
  final int farmerGames;

  String get displayName => nickname.isNotEmpty ? nickname : account;

  String get username => displayName;

  int get totalScore => coins;
  int get totalGames => landlordGames + farmerGames;
  int get totalWins => landlordWins + farmerWins;

  double get landlordWinRate =>
      landlordGames == 0 ? 0 : landlordWins / landlordGames;

  double get farmerWinRate => farmerGames == 0 ? 0 : farmerWins / farmerGames;

  double get overallWinRate => totalGames == 0 ? 0 : totalWins / totalGames;

  UserProfile copyWith({
    String? userId,
    String? account,
    String? nickname,
    int? coins,
    int? landlordWins,
    int? landlordGames,
    int? farmerWins,
    int? farmerGames,
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
