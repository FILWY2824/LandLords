import 'package:flutter_test/flutter_test.dart';

import 'package:landlords/src/models/app_models.dart';
import 'package:landlords/src/models/game_models.dart';
import 'package:landlords/src/utils/current_trick_view.dart';

void main() {
  test('keeps every visible play in the unresolved trick', () {
    final actions = <TableAction>[
      _play('a1', 'player_a', 'single', ['3']),
      _play('a2', 'player_b', 'single', ['4']),
    ];

    final trick = buildCurrentTrickView(actions);

    expect(trick.leadingPlayerId, 'player_b');
    expect(trick.actionsByPlayer.keys, ['player_a', 'player_b']);
    expect(trick.actionsByPlayer['player_a']?.patternLabel, 'single');
    expect(trick.actionsByPlayer['player_b']?.patternLabel, 'single');
    expect(
      trick.actionsByPlayer['player_a']?.emphasis,
      TrickActionEmphasis.secondary,
    );
    expect(
      trick.actionsByPlayer['player_b']?.emphasis,
      TrickActionEmphasis.primary,
    );
  });

  test('clears the table after two passes end the trick', () {
    final actions = <TableAction>[
      _play('a1', 'player_a', 'single', ['8']),
      _pass('a2', 'player_b'),
      _pass('a3', 'player_c'),
    ];

    final trick = buildCurrentTrickView(actions);

    expect(trick.leadingPlayerId, isNull);
    expect(trick.actionsByPlayer, isEmpty);
  });

  test('keeps visible passes and plays for the latest unresolved trick', () {
    final actions = <TableAction>[
      _play('a1', 'player_a', 'pair', ['Q', 'Q']),
      _pass('a2', 'player_b'),
      _play('a3', 'player_c', 'pair', ['K', 'K']),
    ];

    final trick = buildCurrentTrickView(actions);

    expect(trick.leadingPlayerId, 'player_c');
    expect(trick.actionsByPlayer.keys, ['player_b', 'player_c']);
    expect(trick.actionsByPlayer['player_b']?.type, ActionType.pass);
    expect(trick.actionsByPlayer['player_c']?.patternLabel, 'pair');
  });
}

TableAction _play(
  String actionId,
  String playerId,
  String patternLabel,
  List<String> ranks,
) {
  return TableAction(
    actionId: actionId,
    playerId: playerId,
    playerName: playerId,
    type: ActionType.play,
    patternLabel: patternLabel,
    cards: [
      for (var index = 0; index < ranks.length; index++)
        PlayingCard(
          id: '$actionId-$index',
          rank: ranks[index],
          suit: 'S',
          value: index + 3,
        ),
    ],
    timestampMs: 1,
  );
}

TableAction _pass(String actionId, String playerId) {
  return TableAction(
    actionId: actionId,
    playerId: playerId,
    playerName: playerId,
    type: ActionType.pass,
    patternLabel: 'pass',
    cards: const [],
    timestampMs: 1,
  );
}
