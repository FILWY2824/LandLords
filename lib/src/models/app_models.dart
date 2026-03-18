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
        BotDifficulty.easy => '\u7b80\u5355\u6a21\u5f0f',
        BotDifficulty.normal => '\u6807\u51c6\u6a21\u5f0f',
        BotDifficulty.hard => '\u56f0\u96be\u6a21\u5f0f',
      };

  String get description => switch (this) {
        BotDifficulty.easy =>
          '\u4f7f\u7528 DouZero-ADP \u6a21\u578b\uff0c\u6574\u4f53\u66f4\u7a33\uff0c\u538b\u5236\u611f\u8f83\u8f7b\uff0c\u9002\u5408\u5148\u719f\u6089\u8282\u594f\u3002',
        BotDifficulty.normal =>
          '\u4f7f\u7528 SL \u6a21\u578b\uff0c\u5728\u5f53\u524d ONNX \u5b9e\u6d4b\u4e2d\u6574\u4f53\u5f3a\u4e8e ADP\uff0c\u9002\u5408\u4f5c\u4e3a\u9ed8\u8ba4\u6863\u3002',
        BotDifficulty.hard =>
          '\u4f7f\u7528 DouZero-WP \u6a21\u578b\uff0c\u66f4\u5f3a\u8c03\u80dc\u7387\u3001\u724c\u6743\u548c\u538b\u5236\u611f\uff0c\u6574\u4f53\u66f4\u96be\u7f20\u3002',
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
