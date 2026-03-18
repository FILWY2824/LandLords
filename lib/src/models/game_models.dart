import 'app_models.dart';

class PlayingCard {
  const PlayingCard({
    required this.id,
    required this.rank,
    required this.suit,
    required this.value,
  });

  final String id;
  final String rank;
  final String suit;
  final int value;

  bool get isRed => suit == 'H' || suit == 'D';

  bool get isJoker => rank == 'SJ' || rank == 'BJ';

  String get suitSymbol => switch (suit) {
        'S' => '\u2660',
        'H' => '\u2665',
        'C' => '\u2663',
        'D' => '\u2666',
        _ => '',
      };

  String get rankLabel => switch (rank) {
        'SJ' => '\u5c0f\u738b',
        'BJ' => '\u5927\u738b',
        _ => rank,
      };

  String get label => isJoker ? rankLabel : '$suitSymbol$rank';

  String get voiceLabel => switch (rank) {
        'SJ' => '\u5c0f\u738b',
        'BJ' => '\u5927\u738b',
        'A' => 'A',
        'K' => 'K',
        'Q' => 'Q',
        'J' => 'J',
        _ => rank,
      };
}

class RoomPlayer {
  const RoomPlayer({
    required this.playerId,
    required this.displayName,
    required this.isBot,
    required this.role,
    required this.cardsLeft,
    required this.roundScore,
  });

  final String playerId;
  final String displayName;
  final bool isBot;
  final PlayerRole role;
  final int cardsLeft;
  final int roundScore;

  bool get isLandlord => role == PlayerRole.landlord;
}

class TableAction {
  const TableAction({
    required this.actionId,
    required this.playerId,
    required this.playerName,
    required this.type,
    required this.patternLabel,
    required this.cards,
    required this.timestampMs,
  });

  final String actionId;
  final String playerId;
  final String playerName;
  final ActionType type;
  final String patternLabel;
  final List<PlayingCard> cards;
  final int timestampMs;
}

class CardCounterEntry {
  const CardCounterEntry({
    required this.rank,
    required this.remaining,
  });

  final String rank;
  final int remaining;
}

class RoomSnapshot {
  const RoomSnapshot({
    required this.roomId,
    required this.mode,
    required this.phase,
    required this.players,
    required this.selfCards,
    required this.landlordCards,
    required this.recentActions,
    required this.currentTurnPlayerId,
    required this.statusText,
    required this.cardCounter,
    required this.baseScore,
    required this.multiplier,
    required this.currentRoundScore,
    required this.springTriggered,
    required this.turnSerial,
  });

  final String roomId;
  final MatchMode mode;
  final RoomPhase phase;
  final List<RoomPlayer> players;
  final List<PlayingCard> selfCards;
  final List<PlayingCard> landlordCards;
  final List<TableAction> recentActions;
  final String currentTurnPlayerId;
  final String statusText;
  final List<CardCounterEntry> cardCounter;
  final int baseScore;
  final int multiplier;
  final int currentRoundScore;
  final bool springTriggered;
  final int turnSerial;

  TableAction? get latestAction => recentActions.isEmpty ? null : recentActions.last;
}

class LoginResult {
  const LoginResult({
    required this.profile,
    required this.sessionToken,
  });

  final UserProfile profile;
  final String sessionToken;
}
