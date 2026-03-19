enum MatchMode { vsBot, online }

enum BotDifficulty { easy, normal, hard }

enum PlayerRole { farmer, landlord }

enum RoomPhase { waiting, playing, finished }

enum ActionType { play, pass }

extension BotDifficultyPresentation on BotDifficulty {
  String get label => switch (this) {
        BotDifficulty.easy => '\u7b80\u5355',
        BotDifficulty.normal => '\u6807\u51c6',
        BotDifficulty.hard => '\u56f0\u96be',
      };

  String get hallTitle => switch (this) {
        BotDifficulty.easy => '\u7b80\u5355\u4eba\u673a',
        BotDifficulty.normal => '\u6807\u51c6\u4eba\u673a',
        BotDifficulty.hard => '\u56f0\u96be\u4eba\u673a',
      };

  String get description => switch (this) {
        BotDifficulty.easy => '\u8282\u594f\u66f4\u8f7b\uff0c\u9002\u5408\u70ed\u8eab\u3002',
        BotDifficulty.normal => '\u5f3a\u5ea6\u5747\u8861\uff0c\u9002\u5408\u9ed8\u8ba4\u5f00\u5c40\u3002',
        BotDifficulty.hard => '\u538b\u5236\u66f4\u5f3a\uff0c\u9002\u5408\u6311\u6218\u3002',
      };

  String get gameChip => switch (this) {
        BotDifficulty.easy => '\u7b80\u5355\u4eba\u673a',
        BotDifficulty.normal => '\u6807\u51c6\u4eba\u673a',
        BotDifficulty.hard => '\u56f0\u96be\u4eba\u673a',
      };

  String get modelFamily => switch (this) {
        BotDifficulty.easy => 'DouZero-ADP',
        BotDifficulty.normal => 'SL',
        BotDifficulty.hard => 'DouZero-WP',
      };

  bool get prefersOnnx => true;
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.username,
    required this.totalScore,
  });

  final String userId;
  final String username;
  final int totalScore;
}

class MatchTicket {
  const MatchTicket({
    required this.mode,
    required this.message,
  });

  final MatchMode mode;
  final String message;
}
