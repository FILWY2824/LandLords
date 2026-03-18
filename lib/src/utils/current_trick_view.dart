import '../models/app_models.dart';
import '../models/game_models.dart';

enum TrickActionEmphasis { primary, secondary }

class TrickDisplayAction {
  const TrickDisplayAction({
    required this.action,
    required this.emphasis,
  });

  final TableAction action;
  final TrickActionEmphasis emphasis;

  String get patternLabel => action.patternLabel;
  ActionType get type => action.type;
  List<PlayingCard> get cards => action.cards;
  String get playerId => action.playerId;
}

class CurrentTrickView {
  const CurrentTrickView({
    required this.actionsByPlayer,
    required this.leadingPlayerId,
    required this.latestPlayerId,
  });

  final Map<String, TrickDisplayAction> actionsByPlayer;
  final String? leadingPlayerId;
  final String? latestPlayerId;
}

CurrentTrickView buildCurrentTrickView(List<TableAction> actions) {
  final currentSegment = <TableAction>[];
  String? leadingPlayerId;
  var trailingPasses = 0;

  for (final action in actions) {
    if (_isSystemAction(action)) {
      continue;
    }

    final isPlayableAction =
        action.type == ActionType.play && action.cards.isNotEmpty;
    if (isPlayableAction) {
      currentSegment.add(action);
      leadingPlayerId = action.playerId;
      trailingPasses = 0;
      continue;
    }

    if (action.type != ActionType.pass || leadingPlayerId == null) {
      continue;
    }

    currentSegment.add(action);
    trailingPasses += 1;
    if (trailingPasses >= 2) {
      currentSegment.clear();
      leadingPlayerId = null;
      trailingPasses = 0;
    }
  }

  if (currentSegment.isEmpty) {
    return const CurrentTrickView(
      actionsByPlayer: <String, TrickDisplayAction>{},
      leadingPlayerId: null,
      latestPlayerId: null,
    );
  }

  final latestAction = currentSegment.last;
  final previousAction = _resolvePreviousVisibleAction(currentSegment);
  final display = <String, TrickDisplayAction>{};

  if (previousAction != null && previousAction.playerId != latestAction.playerId) {
    display[previousAction.playerId] = TrickDisplayAction(
      action: previousAction,
      emphasis: TrickActionEmphasis.secondary,
    );
  }

  display[latestAction.playerId] = TrickDisplayAction(
    action: latestAction,
    emphasis: TrickActionEmphasis.primary,
  );

  return CurrentTrickView(
    actionsByPlayer: Map<String, TrickDisplayAction>.unmodifiable(display),
    leadingPlayerId: _resolveLeadingPlayerId(currentSegment, previousAction, latestAction),
    latestPlayerId: latestAction.playerId,
  );
}

TableAction? _resolvePreviousVisibleAction(List<TableAction> currentSegment) {
  if (currentSegment.length < 2) {
    return null;
  }

  final latestAction = currentSegment.last;
  if (latestAction.type == ActionType.pass) {
    return currentSegment[currentSegment.length - 2];
  }

  for (var index = currentSegment.length - 2; index >= 0; index--) {
    final candidate = currentSegment[index];
    if (candidate.playerId != latestAction.playerId) {
      return candidate;
    }
  }
  return null;
}

String? _resolveLeadingPlayerId(
  List<TableAction> currentSegment,
  TableAction? previousAction,
  TableAction latestAction,
) {
  if (latestAction.type == ActionType.play && latestAction.cards.isNotEmpty) {
    return latestAction.playerId;
  }
  if (previousAction != null &&
      previousAction.type == ActionType.play &&
      previousAction.cards.isNotEmpty) {
    return previousAction.playerId;
  }
  for (var index = currentSegment.length - 1; index >= 0; index--) {
    final candidate = currentSegment[index];
    if (candidate.type == ActionType.play && candidate.cards.isNotEmpty) {
      return candidate.playerId;
    }
  }
  return null;
}

bool _isSystemAction(TableAction action) {
  return action.patternLabel == 'managed_on' ||
      action.patternLabel == 'managed_off' ||
      action.patternLabel == 'bid_pass' ||
      action.patternLabel.startsWith('bid_');
}
