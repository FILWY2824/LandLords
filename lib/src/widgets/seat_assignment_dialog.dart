import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../state/app_controller.dart';
import 'friend_center_dialog.dart';

class SeatAssignmentResult {
  const SeatAssignmentResult(this.message);

  final String message;
}

Future<SeatAssignmentResult?> showSeatAssignmentDialog(
  BuildContext context, {
  required AppController controller,
  required RoomSnapshot snapshot,
  required int seatIndex,
  double? stageScale,
  double stageWidth = 1320,
  double stageHeight = 760,
}) async {
  final result = await showSeatInviteDialog(
    context,
    controller: controller,
    snapshot: snapshot,
    seatIndex: seatIndex,
    stageScale: stageScale,
    stageWidth: stageWidth,
    stageHeight: stageHeight,
  );
  if (result == null) {
    return null;
  }
  return SeatAssignmentResult(result.message);
}
