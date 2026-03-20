import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../models/game_models.dart';
import '../state/app_controller.dart';

class SeatAssignmentResult {
  const SeatAssignmentResult(this.message);

  final String message;
}

Future<SeatAssignmentResult?> showSeatAssignmentDialog(
  BuildContext context, {
  required AppController controller,
  required RoomSnapshot snapshot,
  required int seatIndex,
}) {
  return showDialog<SeatAssignmentResult>(
    context: context,
    builder: (context) => _SeatAssignmentDialog(
      controller: controller,
      snapshot: snapshot,
      seatIndex: seatIndex,
    ),
  );
}

class _SeatAssignmentDialog extends StatefulWidget {
  const _SeatAssignmentDialog({
    required this.controller,
    required this.snapshot,
    required this.seatIndex,
  });

  final AppController controller;
  final RoomSnapshot snapshot;
  final int seatIndex;

  @override
  State<_SeatAssignmentDialog> createState() => _SeatAssignmentDialogState();
}

class _SeatAssignmentDialogState extends State<_SeatAssignmentDialog> {
  final TextEditingController _friendAccountController =
      TextEditingController();
  final TextEditingController _filterController = TextEditingController();

  List<OnlineUser> _friends = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _friendAccountController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    final friends = await widget.controller.fetchFriends();
    if (!mounted) {
      return;
    }
    friends.sort((left, right) {
      if (left.online != right.online) {
        return left.online ? -1 : 1;
      }
      final accountCompare = left.account.compareTo(right.account);
      if (accountCompare != 0) {
        return accountCompare;
      }
      return left.displayName.compareTo(right.displayName);
    });
    setState(() {
      _friends = friends;
      _loading = false;
    });
  }

  Future<void> _addFriend() async {
    final account = _friendAccountController.text.trim();
    if (account.isEmpty) {
      setState(() => _errorText = '请输入要添加的好友账号。');
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final added = await widget.controller.addFriendByAccount(account);
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (added == null || widget.controller.errorText != null) {
      setState(() {
        _errorText = widget.controller.errorText ?? '添加好友失败。';
      });
      return;
    }
    _friendAccountController.clear();
    await _loadFriends();
    if (!mounted) {
      return;
    }
    setState(() => _errorText = '已添加账号 ${added.account}。');
  }

  Future<void> _inviteFriend(OnlineUser friend) async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    await widget.controller.invitePlayerToRoom(
      account: friend.account,
      seatIndex: widget.seatIndex,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (widget.controller.errorText != null) {
      setState(() => _errorText = widget.controller.errorText);
      return;
    }
    Navigator.of(
      context,
    ).pop(SeatAssignmentResult('已向 ${friend.displayName} 发送入座邀请。'));
  }

  Future<void> _addBot(BotDifficulty difficulty) async {
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    await widget.controller.addBotToRoom(
      seatIndex: widget.seatIndex,
      difficulty: difficulty,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (widget.controller.errorText != null) {
      setState(() => _errorText = widget.controller.errorText);
      return;
    }
    Navigator.of(context).pop(
      SeatAssignmentResult('已为${_seatLabel(widget.seatIndex)}补入 ${difficulty.label} DouZero。'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final occupiedUserIds = widget.snapshot.players
        .where((player) => player.occupied)
        .map((player) => player.playerId)
        .toSet();
    final filter = _filterController.text.trim().toLowerCase();
    final visibleFriends = _friends.where((friend) {
      if (occupiedUserIds.contains(friend.userId)) {
        return false;
      }
      if (filter.isEmpty) {
        return true;
      }
      return friend.account.toLowerCase().contains(filter) ||
          friend.displayName.toLowerCase().contains(filter);
    }).toList(growable: false);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x143678A3),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_seatLabel(widget.seatIndex)}安排',
                      style: const TextStyle(
                        color: Color(0xFF173A59),
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '可以补入 DouZero，也可以按账号邀请在线好友入座。',
                style: TextStyle(
                  color: Color(0xFF587790),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '补入 DouZero',
                style: TextStyle(
                  color: Color(0xFF173A59),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final difficulty in BotDifficulty.values)
                    FilledButton.tonal(
                      onPressed: _submitting ? null : () => _addBot(difficulty),
                      child: Text(difficulty.label),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '添加好友',
                style: TextStyle(
                  color: Color(0xFF173A59),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _friendAccountController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: '输入好友账号',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitting ? null : _addFriend,
                    child: const Text('添加'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '在线好友',
                style: TextStyle(
                  color: Color(0xFF173A59),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _filterController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '按账号或昵称筛选',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      color: _errorText!.startsWith('已')
                          ? const Color(0xFF237A4B)
                          : const Color(0xFFB54A3D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : visibleFriends.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '还没有可邀请的好友，先按账号添加吧。',
                            style: TextStyle(color: Color(0xFF587790)),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: visibleFriends.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final friend = visibleFriends[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              friend.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: Text('账号：${friend.account}'),
                            trailing: friend.online
                                ? FilledButton(
                                    onPressed: _submitting
                                        ? null
                                        : () => _inviteFriend(friend),
                                    child: const Text('邀请'),
                                  )
                                : const Text(
                                    '离线',
                                    style: TextStyle(
                                      color: Color(0xFF587790),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _seatLabel(int seatIndex) => switch (seatIndex) {
      0 => '一号位',
      1 => '二号位',
      _ => '三号位',
    };
