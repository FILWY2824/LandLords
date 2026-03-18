import 'dart:async';
import 'dart:math';

import '../models/app_models.dart';
import '../models/game_models.dart';
import 'game_gateway.dart';

class LocalDemoGateway implements GameGateway {
  LocalDemoGateway() {
    final demo = _LocalUser(
      profile: const UserProfile(
        userId: 'demo-user',
        username: 'player1',
        totalScore: 1888,
      ),
      password: 'player1',
    );
    _usersByName[demo.profile.username] = demo;
  }

  final Map<String, _LocalUser> _usersByName = {};
  final Map<String, _DemoRoom> _roomsById = {};
  final Map<String, String> _sessionToUserId = {};
  final StreamController<RoomSnapshot> _snapshotController =
      StreamController<RoomSnapshot>.broadcast();
  final Random _random = Random();

  @override
  Stream<RoomSnapshot> get roomSnapshots => _snapshotController.stream;

  @override
  Future<void> register({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (username.trim().isEmpty || password.isEmpty) {
      throw Exception('用户名和密码不能为空');
    }
    if (_usersByName.containsKey(username)) {
      throw Exception('用户名已存在');
    }
    _usersByName[username] = _LocalUser(
      profile: UserProfile(
        userId: _id('user'),
        username: username,
        totalScore: 0,
      ),
      password: password,
    );
  }

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final user = _usersByName[username];
    if (user == null || user.password != password) {
      throw Exception('用户名或密码错误');
    }
    final session = _id('session');
    _sessionToUserId[session] = user.profile.userId;
    return LoginResult(profile: user.profile, sessionToken: session);
  }

  @override
  Future<RoomSnapshot> startMatch({
    required String sessionToken,
    required UserProfile profile,
    required MatchMode mode,
    BotDifficulty botDifficulty = BotDifficulty.normal,
  }) async {
    await Future<void>.delayed(Duration(milliseconds: mode == MatchMode.online ? 1300 : 520));
    final room = _DemoRoom.create(
      roomId: _id('room'),
      random: _random,
      owner: profile,
      mode: mode,
    );
    _roomsById[room.roomId] = room;
    room.driveBotsIfNeeded();
    final snapshot = room.snapshotFor(profile.userId);
    _snapshotController.add(snapshot);
    return snapshot;
  }

  @override
  Future<void> cancelMatch({
    required String sessionToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<RoomSnapshot> playCards({
    required String sessionToken,
    required String roomId,
    required List<String> cardIds,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final userId = _requireUserId(sessionToken);
    final room = _requireRoom(roomId);
    room.play(userId, cardIds);
    room.driveBotsIfNeeded();
    _persistRoundScoreIfNeeded(room, userId);
    final snapshot = room.snapshotFor(userId);
    _snapshotController.add(snapshot);
    return snapshot;
  }

  @override
  Future<RoomSnapshot> callScore({
    required String sessionToken,
    required String roomId,
    required int score,
  }) {
    return playCards(
      sessionToken: sessionToken,
      roomId: roomId,
      cardIds: ['bid:$score'],
    );
  }

  @override
  Future<RoomSnapshot> setManaged({
    required String sessionToken,
    required String roomId,
    required bool managed,
  }) async {
    final userId = _requireUserId(sessionToken);
    final room = _requireRoom(roomId);
    room.statusText = managed ? '已开启托管' : '已取消托管';
    final snapshot = room.snapshotFor(userId);
    _snapshotController.add(snapshot);
    return snapshot;
  }

  @override
  Future<RoomSnapshot> pass({
    required String sessionToken,
    required String roomId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final userId = _requireUserId(sessionToken);
    final room = _requireRoom(roomId);
    room.pass(userId);
    room.driveBotsIfNeeded();
    _persistRoundScoreIfNeeded(room, userId);
    final snapshot = room.snapshotFor(userId);
    _snapshotController.add(snapshot);
    return snapshot;
  }

  @override
  Future<List<String>> requestSuggestion({
    required String sessionToken,
    required String roomId,
  }) async {
    final userId = _requireUserId(sessionToken);
    final room = _requireRoom(roomId);
    return room.suggest(userId);
  }

  @override
  Future<void> acknowledgePresentation({
    required String sessionToken,
    required String roomId,
    required String actionId,
  }) async {}

  @override
  RoomSnapshot? currentSnapshot(String roomId) => _roomsById[roomId]?.snapshotFor(
        _roomsById[roomId]!.ownerId,
      );

  void _persistRoundScoreIfNeeded(_DemoRoom room, String userId) {
    if (room.phase != RoomPhase.finished) {
      return;
    }
    final player = room.players.firstWhere((item) => item.playerId == userId);
    final user = _usersByName.values.firstWhere((item) => item.profile.userId == userId);
    user.profile = UserProfile(
      userId: user.profile.userId,
      username: user.profile.username,
      totalScore: user.profile.totalScore + player.roundScore,
    );
  }

  _DemoRoom _requireRoom(String roomId) {
    final room = _roomsById[roomId];
    if (room == null) {
      throw Exception('牌桌不存在');
    }
    return room;
  }

  String _requireUserId(String sessionToken) {
    final userId = _sessionToUserId[sessionToken];
    if (userId == null) {
      throw Exception('请先登录');
    }
    return userId;
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(99999)}';
}

class _LocalUser {
  _LocalUser({
    required this.profile,
    required this.password,
  });

  UserProfile profile;
  final String password;
}

class _DemoRoom {
  _DemoRoom({
    required this.roomId,
    required this.mode,
    required this.players,
    required this.ownerId,
    required this.landlordCards,
    required this.phase,
    required this.currentTurnPlayerId,
    required this.statusText,
  });

  factory _DemoRoom.create({
    required String roomId,
    required Random random,
    required UserProfile owner,
    required MatchMode mode,
  }) {
    final players = <_MutablePlayer>[
      _MutablePlayer(playerId: owner.userId, displayName: owner.username),
      _MutablePlayer(
        playerId: 'left-seat',
        displayName: mode == MatchMode.vsBot ? '老杨' : '牌友甲',
        isBot: mode == MatchMode.vsBot,
      ),
      _MutablePlayer(
        playerId: 'right-seat',
        displayName: mode == MatchMode.vsBot ? '秋秋' : '牌友乙',
        isBot: mode == MatchMode.vsBot,
      ),
    ];

    final deck = _buildDeck()..shuffle(random);
    for (var i = 0; i < 51; i++) {
      players[i % 3].hand.add(deck[i]);
    }
    final landlordCards = deck.sublist(51);
    final landlordIndex = random.nextInt(3);
    players[landlordIndex].isLandlord = true;
    players[landlordIndex].hand.addAll(landlordCards);
    for (final player in players) {
      player.hand.sort(_compareCards);
    }

    return _DemoRoom(
      roomId: roomId,
      mode: mode,
      players: players,
      ownerId: owner.userId,
      landlordCards: landlordCards,
      phase: RoomPhase.playing,
      currentTurnPlayerId: players[landlordIndex].playerId,
      statusText: '${players[landlordIndex].displayName} 成为地主',
    );
  }

  final String roomId;
  final MatchMode mode;
  final List<_MutablePlayer> players;
  final String ownerId;
  final List<PlayingCard> landlordCards;
  final List<TableAction> actions = <TableAction>[];

  RoomPhase phase;
  String currentTurnPlayerId;
  String statusText;
  CardPattern? lastPattern;
  String? lastActionPlayerId;
  int passCount = 0;
  int baseScore = 1;
  int multiplier = 1;
  int turnSerial = 1;
  bool springTriggered = false;
  int landlordPlayCount = 0;
  int farmerPlayCount = 0;

  RoomSnapshot snapshotFor(String selfId) {
    final me = players.firstWhere((item) => item.playerId == selfId);
    final counter = <String, int>{};
    for (final card in _buildDeck()) {
      counter.update(card.rank, (value) => value + 1, ifAbsent: () => 1);
    }
    for (final card in me.hand) {
      counter.update(card.rank, (value) => value - 1);
    }
    for (final action in actions) {
      for (final card in action.cards) {
        counter.update(card.rank, (value) => value - 1);
      }
    }

    return RoomSnapshot(
      roomId: roomId,
      mode: mode,
      phase: phase,
      players: players
          .map(
            (player) => RoomPlayer(
              playerId: player.playerId,
              displayName: player.displayName,
              isBot: player.isBot,
              role: player.isLandlord ? PlayerRole.landlord : PlayerRole.farmer,
              cardsLeft: player.hand.length,
              roundScore: player.roundScore,
            ),
          )
          .toList(),
      selfCards: List<PlayingCard>.from(me.hand),
      landlordCards: List<PlayingCard>.from(landlordCards),
      recentActions: List<TableAction>.from(actions),
      currentTurnPlayerId: currentTurnPlayerId,
      statusText: statusText,
      cardCounter: counter.entries
          .map((entry) => CardCounterEntry(rank: entry.key, remaining: entry.value))
          .toList()
        ..sort((a, b) => b.remaining.compareTo(a.remaining)),
      baseScore: baseScore,
      multiplier: multiplier,
      currentRoundScore: baseScore * multiplier,
      springTriggered: springTriggered,
      turnSerial: turnSerial,
    );
  }

  void play(String playerId, List<String> cardIds) {
    if (phase != RoomPhase.playing) {
      throw Exception('本局已经结束');
    }
    if (currentTurnPlayerId != playerId) {
      throw Exception('还没轮到你');
    }

    final player = players.firstWhere((item) => item.playerId == playerId);
    final selected = player.hand.where((card) => cardIds.contains(card.id)).toList()
      ..sort(_compareCards);
    if (selected.length != cardIds.length) {
      throw Exception('选中的牌无效');
    }

    final pattern = _evaluatePattern(selected);
    if (pattern.type == PatternType.invalid) {
      throw Exception('当前牌型不合法');
    }
    if (!_canBeat(pattern)) {
      throw Exception('压不过当前牌型');
    }

    player.hand.removeWhere((card) => cardIds.contains(card.id));
    lastPattern = pattern;
    lastActionPlayerId = playerId;
    passCount = 0;
    if (player.isLandlord) {
      landlordPlayCount++;
    } else {
      farmerPlayCount++;
    }
    if (pattern.type == PatternType.bomb || pattern.type == PatternType.rocket) {
      multiplier *= 2;
    }
    actions.add(
      TableAction(
        actionId: _makeActionId(),
        playerId: playerId,
        playerName: player.displayName,
        type: ActionType.play,
        patternLabel: pattern.label,
        cards: selected,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    statusText = '${player.displayName} 打出 ${pattern.label}';

    if (player.hand.isEmpty) {
      phase = RoomPhase.finished;
      springTriggered = (player.isLandlord && farmerPlayCount == 0) ||
          (!player.isLandlord && landlordPlayCount <= 1);
      if (springTriggered) {
        multiplier *= 2;
      }
      _applyScore(player);
      statusText = '${player.displayName} 获胜';
      return;
    }

    _advanceTurn();
  }

  void pass(String playerId) {
    if (phase != RoomPhase.playing) {
      throw Exception('本局已经结束');
    }
    if (currentTurnPlayerId != playerId) {
      throw Exception('还没轮到你');
    }
    if (lastPattern == null || lastActionPlayerId == playerId) {
      throw Exception('本轮先手不能不出');
    }

    final player = players.firstWhere((item) => item.playerId == playerId);
    actions.add(
      TableAction(
        actionId: _makeActionId(),
        playerId: playerId,
        playerName: player.displayName,
        type: ActionType.pass,
        patternLabel: '不出',
        cards: const [],
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    passCount++;
    if (passCount >= 2 && lastActionPlayerId != null) {
      currentTurnPlayerId = lastActionPlayerId!;
      lastActionPlayerId = null;
      lastPattern = null;
      passCount = 0;
      statusText = '新的一轮开始';
      turnSerial++;
      return;
    }

    statusText = '${player.displayName} 选择不出';
    _advanceTurn();
  }

  void driveBotsIfNeeded() {
    if (mode != MatchMode.vsBot || phase != RoomPhase.playing) {
      return;
    }
    while (phase == RoomPhase.playing) {
      final current = players.firstWhere((item) => item.playerId == currentTurnPlayerId);
      if (!current.isBot) {
        break;
      }
      final suggestion = _findBotMove(current);
      if (suggestion == null) {
        pass(current.playerId);
      } else {
        play(current.playerId, suggestion.cards.map((card) => card.id).toList());
      }
    }
  }

  List<String> suggest(String playerId) {
    if (phase != RoomPhase.playing || currentTurnPlayerId != playerId) {
      return const [];
    }
    final player = players.firstWhere((item) => item.playerId == playerId);
    final suggestion = _findBotMove(player);
    if (suggestion == null) {
      return const [];
    }
    return suggestion.cards.map((card) => card.id).toList();
  }

  CardPattern? _findBotMove(_MutablePlayer player) {
    final candidates = _buildCandidates(player.hand);
    final lastPlayer = lastActionPlayerId == null
        ? null
        : players.firstWhere((item) => item.playerId == lastActionPlayerId);

    if (lastPattern != null &&
        lastPlayer != null &&
        lastPlayer.playerId != player.playerId &&
        lastPlayer.isLandlord == player.isLandlord) {
      if (lastPlayer.hand.length > 1) {
        return null;
      }
    }

    final valid = candidates.where(_canBeat).toList();
    if (valid.isEmpty) {
      return null;
    }

    valid.sort((a, b) {
      final scoreCompare = _candidateScore(player, a).compareTo(_candidateScore(player, b));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.weight.compareTo(b.weight);
    });

    final opponentAlmostOut = players
        .where((item) => item.isLandlord != player.isLandlord)
        .any((item) => item.hand.length <= 2);

    if (!opponentAlmostOut) {
      final noBomb = valid.where((item) => item.type != PatternType.bomb && item.type != PatternType.rocket).toList();
      if (noBomb.isNotEmpty) {
        return noBomb.first;
      }
    }
    return valid.first;
  }

  int _candidateScore(_MutablePlayer player, CardPattern candidate) {
    final isLead = lastPattern == null;
    final typeWeight = switch (candidate.type) {
      PatternType.straight => 6,
      PatternType.straightPair => 5,
      PatternType.airplane => 4,
      PatternType.airplaneWithSingle || PatternType.airplaneWithPair => 5,
      PatternType.tripleWithPair || PatternType.tripleWithSingle => 7,
      PatternType.triple => 8,
      PatternType.pair => 10,
      PatternType.single => 12,
      PatternType.bomb => 40,
      PatternType.rocket => 50,
      PatternType.invalid => 99,
    };
    final endgameBonus = player.hand.length <= 5 ? -candidate.length : 0;
    return (isLead ? typeWeight - candidate.length : typeWeight + candidate.weight) + endgameBonus;
  }

  bool _canBeat(CardPattern pattern) {
    if (pattern.type == PatternType.invalid) {
      return false;
    }
    if (lastPattern == null) {
      return true;
    }
    if (pattern.type == PatternType.rocket) {
      return true;
    }
    if (lastPattern!.type == PatternType.rocket) {
      return false;
    }
    if (pattern.type == PatternType.bomb && lastPattern!.type != PatternType.bomb) {
      return true;
    }
    if (pattern.type != lastPattern!.type) {
      return false;
    }
    if (pattern.length != lastPattern!.length &&
        pattern.type != PatternType.single &&
        pattern.type != PatternType.pair &&
        pattern.type != PatternType.triple &&
        pattern.type != PatternType.bomb) {
      return false;
    }
    return pattern.weight > lastPattern!.weight;
  }

  void _advanceTurn() {
    final currentIndex = players.indexWhere((item) => item.playerId == currentTurnPlayerId);
    currentTurnPlayerId = players[(currentIndex + 1) % players.length].playerId;
    turnSerial++;
  }

  void _applyScore(_MutablePlayer winner) {
    for (final player in players) {
      if (winner.isLandlord) {
        player.roundScore =
            player.isLandlord ? 2 * baseScore * multiplier : -baseScore * multiplier;
      } else {
        player.roundScore =
            player.isLandlord ? -2 * baseScore * multiplier : baseScore * multiplier;
      }
    }
  }

  String _makeActionId() => 'action-${DateTime.now().microsecondsSinceEpoch}-${actions.length}';
}

class _MutablePlayer {
  _MutablePlayer({
    required this.playerId,
    required this.displayName,
    this.isBot = false,
  });

  final String playerId;
  final String displayName;
  final bool isBot;
  bool isLandlord = false;
  int roundScore = 0;
  final List<PlayingCard> hand = <PlayingCard>[];
}

enum PatternType {
  invalid,
  single,
  pair,
  triple,
  tripleWithSingle,
  tripleWithPair,
  straight,
  straightPair,
  airplane,
  airplaneWithSingle,
  airplaneWithPair,
  bomb,
  rocket,
}

class CardPattern {
  const CardPattern({
    required this.type,
    required this.cards,
    required this.weight,
    required this.length,
    required this.label,
  });

  final PatternType type;
  final List<PlayingCard> cards;
  final int weight;
  final int length;
  final String label;
}

List<PlayingCard> _buildDeck() {
  const suits = ['S', 'H', 'C', 'D'];
  const ranks = ['3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A', '2'];
  final deck = <PlayingCard>[];
  var index = 0;
  for (final rank in ranks) {
    for (final suit in suits) {
      deck.add(
        PlayingCard(
          id: 'card_${index++}',
          rank: rank,
          suit: suit,
          value: _rankValue(rank),
        ),
      );
    }
  }
  deck.add(const PlayingCard(id: 'joker_small', rank: 'SJ', suit: '', value: 16));
  deck.add(const PlayingCard(id: 'joker_big', rank: 'BJ', suit: '', value: 17));
  return deck;
}

int _rankValue(String rank) {
  const values = {
    '3': 3,
    '4': 4,
    '5': 5,
    '6': 6,
    '7': 7,
    '8': 8,
    '9': 9,
    '10': 10,
    'J': 11,
    'Q': 12,
    'K': 13,
    'A': 14,
    '2': 15,
    'SJ': 16,
    'BJ': 17,
  };
  return values[rank]!;
}

int _compareCards(PlayingCard left, PlayingCard right) {
  final byValue = left.value.compareTo(right.value);
  if (byValue != 0) {
    return byValue;
  }
  return left.suit.compareTo(right.suit);
}

CardPattern _evaluatePattern(List<PlayingCard> cards) {
  if (cards.isEmpty) {
    return const CardPattern(
      type: PatternType.invalid,
      cards: [],
      weight: 0,
      length: 0,
      label: '无效牌',
    );
  }

  final sorted = [...cards]..sort(_compareCards);
  final groups = <int, List<PlayingCard>>{};
  for (final card in sorted) {
    groups.putIfAbsent(card.value, () => []).add(card);
  }
  final values = groups.keys.toList()..sort();
  final counts = groups.values.map((value) => value.length).toList()..sort();

  if (sorted.length == 1) {
    return CardPattern(
      type: PatternType.single,
      cards: sorted,
      weight: sorted.first.value,
      length: 1,
      label: '单牌 ${sorted.first.label}',
    );
  }

  if (sorted.length == 2) {
    if (sorted.first.value == 16 && sorted.last.value == 17) {
      return CardPattern(
        type: PatternType.rocket,
        cards: sorted,
        weight: 100,
        length: 2,
        label: '王炸',
      );
    }
    if (groups.length == 1) {
      return CardPattern(
        type: PatternType.pair,
        cards: sorted,
        weight: sorted.first.value,
        length: 2,
        label: '对子 ${sorted.first.rank}',
      );
    }
  }

  if (sorted.length == 3 && groups.length == 1) {
    return CardPattern(
      type: PatternType.triple,
      cards: sorted,
      weight: sorted.first.value,
      length: 3,
      label: '三张 ${sorted.first.rank}',
    );
  }

  if (sorted.length == 4) {
    if (groups.length == 1) {
      return CardPattern(
        type: PatternType.bomb,
        cards: sorted,
        weight: sorted.first.value,
        length: 4,
        label: '炸弹 ${sorted.first.rank}',
      );
    }
    if (counts.join(',') == '1,3') {
      final triple = groups.entries.firstWhere((entry) => entry.value.length == 3).key;
      return CardPattern(
        type: PatternType.tripleWithSingle,
        cards: sorted,
        weight: triple,
        length: 4,
        label: '三带一',
      );
    }
  }

  if (sorted.length == 5 && counts.join(',') == '2,3') {
    final triple = groups.entries.firstWhere((entry) => entry.value.length == 3).key;
    return CardPattern(
      type: PatternType.tripleWithPair,
      cards: sorted,
      weight: triple,
      length: 5,
      label: '三带二',
    );
  }

  final isStraight = groups.values.every((group) => group.length == 1) &&
      values.length >= 5 &&
      values.last < 15 &&
      List<int>.generate(values.length, (index) => values.first + index).every(values.contains);
  if (isStraight) {
    return CardPattern(
      type: PatternType.straight,
      cards: sorted,
      weight: values.last,
      length: sorted.length,
      label: '顺子',
    );
  }

  final isStraightPair = groups.values.every((group) => group.length == 2) &&
      values.length >= 3 &&
      values.last < 15 &&
      List<int>.generate(values.length, (index) => values.first + index).every(values.contains);
  if (isStraightPair) {
    return CardPattern(
      type: PatternType.straightPair,
      cards: sorted,
      weight: values.last,
      length: sorted.length,
      label: '连对',
    );
  }

  final tripleValues = groups.entries
      .where((entry) => entry.value.length >= 3 && entry.key < 15)
      .map((entry) => entry.key)
      .toList()
    ..sort();
  if (tripleValues.length >= 2) {
    final planeLength = _longestRun(tripleValues);
    if (planeLength != null) {
      final run = planeLength;
      final main = tripleValues.sublist(run.$1, run.$2 + 1);
      final triples = main.length;
      if (sorted.length == triples * 3) {
        return CardPattern(
          type: PatternType.airplane,
          cards: sorted,
          weight: main.last,
          length: sorted.length,
          label: '飞机',
        );
      }
      if (sorted.length == triples * 4) {
        return CardPattern(
          type: PatternType.airplaneWithSingle,
          cards: sorted,
          weight: main.last,
          length: sorted.length,
          label: '飞机带单',
        );
      }
      if (sorted.length == triples * 5) {
        return CardPattern(
          type: PatternType.airplaneWithPair,
          cards: sorted,
          weight: main.last,
          length: sorted.length,
          label: '飞机带对',
        );
      }
    }
  }

  return CardPattern(
    type: PatternType.invalid,
    cards: sorted,
    weight: 0,
    length: sorted.length,
    label: '无效牌',
  );
}

List<CardPattern> _buildCandidates(List<PlayingCard> hand) {
  final sorted = [...hand]..sort(_compareCards);
  final groups = <int, List<PlayingCard>>{};
  for (final card in sorted) {
    groups.putIfAbsent(card.value, () => []).add(card);
  }

  final result = <CardPattern>[];
  for (final entry in groups.entries) {
    result.add(_evaluatePattern([entry.value.first]));
    if (entry.value.length >= 2) {
      result.add(_evaluatePattern(entry.value.take(2).toList()));
    }
    if (entry.value.length >= 3) {
      final triple = entry.value.take(3).toList();
      result.add(_evaluatePattern(triple));
      for (final single in sorted.where((card) => card.value != entry.key)) {
        result.add(_evaluatePattern([...triple, single]));
      }
      final pairEntries = groups.entries.where((item) => item.key != entry.key && item.value.length >= 2);
      for (final pair in pairEntries) {
        result.add(_evaluatePattern([...triple, ...pair.value.take(2)]));
      }
    }
    if (entry.value.length == 4) {
      result.add(_evaluatePattern(entry.value));
    }
  }

  if (groups.containsKey(16) && groups.containsKey(17)) {
    result.add(_evaluatePattern([groups[16]!.first, groups[17]!.first]));
  }

  final singles = groups.keys.where((value) => value < 15).toList()..sort();
  _collectRuns(singles, 5, (values) {
    result.add(_evaluatePattern(values.map((value) => groups[value]!.first).toList()));
  });

  final pairs = groups.entries.where((entry) => entry.value.length >= 2 && entry.key < 15).map((entry) => entry.key).toList()
    ..sort();
  _collectRuns(pairs, 3, (values) {
    result.add(_evaluatePattern([
      for (final value in values) ...groups[value]!.take(2),
    ]));
  });

  final triples = groups.entries.where((entry) => entry.value.length >= 3 && entry.key < 15).map((entry) => entry.key).toList()
    ..sort();
  _collectRuns(triples, 2, (values) {
    final plane = [
      for (final value in values) ...groups[value]!.take(3),
    ];
    result.add(_evaluatePattern(plane));
    final singlesOutside = sorted.where((card) => !values.contains(card.value)).toList();
    if (singlesOutside.length >= values.length) {
      result.add(_evaluatePattern([...plane, ...singlesOutside.take(values.length)]));
    }
    final pairsOutside = groups.entries.where((entry) => !values.contains(entry.key) && entry.value.length >= 2).toList();
    if (pairsOutside.length >= values.length) {
      result.add(_evaluatePattern([
        ...plane,
        for (final pair in pairsOutside.take(values.length)) ...pair.value.take(2),
      ]));
    }
  });

  final valid = result.where((pattern) => pattern.type != PatternType.invalid).toSet().toList();
  valid.sort((a, b) {
    final typeCompare = a.type.index.compareTo(b.type.index);
    if (typeCompare != 0) {
      return typeCompare;
    }
    final lengthCompare = a.length.compareTo(b.length);
    if (lengthCompare != 0) {
      return lengthCompare;
    }
    return a.weight.compareTo(b.weight);
  });
  return valid;
}

void _collectRuns(List<int> values, int minLength, void Function(List<int>) onRun) {
  for (var start = 0; start < values.length;) {
    var end = start;
    while (end + 1 < values.length && values[end + 1] == values[end] + 1) {
      end++;
    }
    final runLength = end - start + 1;
    if (runLength >= minLength) {
      for (var length = minLength; length <= runLength; length++) {
        for (var offset = start; offset + length - 1 <= end; offset++) {
          onRun(values.sublist(offset, offset + length));
        }
      }
    }
    start = end + 1;
  }
}

(int, int)? _longestRun(List<int> values) {
  if (values.length < 2) {
    return null;
  }
  for (var start = 0; start < values.length;) {
    var end = start;
    while (end + 1 < values.length && values[end + 1] == values[end] + 1) {
      end++;
    }
    if (end - start + 1 >= 2) {
      return (start, end);
    }
    start = end + 1;
  }
  return null;
}
