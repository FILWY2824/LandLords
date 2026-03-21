import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../models/game_models.dart';
import '../state/app_controller.dart';
import 'responsive_modal.dart';

class FriendDialogResult {
  const FriendDialogResult(this.message);

  final String message;
}

Future<FriendDialogResult?> showFriendCenterDialog(
  BuildContext context, {
  required AppController controller,
  double? stageScale,
  double stageWidth = 1320,
  double stageHeight = 760,
}) {
  return showDialog<FriendDialogResult>(
    context: context,
    builder: (context) => _FriendCenterDialog(
      controller: controller,
      mode: _FriendDialogMode.center,
      stageScale: stageScale,
      stageWidth: stageWidth,
      stageHeight: stageHeight,
    ),
  );
}

Future<FriendDialogResult?> showSeatInviteDialog(
  BuildContext context, {
  required AppController controller,
  required RoomSnapshot snapshot,
  required int seatIndex,
  double? stageScale,
  double stageWidth = 1320,
  double stageHeight = 760,
}) {
  return showDialog<FriendDialogResult>(
    context: context,
    builder: (context) => _FriendCenterDialog(
      controller: controller,
      mode: _FriendDialogMode.seatInvite,
      snapshot: snapshot,
      seatIndex: seatIndex,
      stageScale: stageScale,
      stageWidth: stageWidth,
      stageHeight: stageHeight,
    ),
  );
}

enum _FriendDialogMode { center, seatInvite }

class _FriendCenterDialog extends StatefulWidget {
  const _FriendCenterDialog({
    required this.controller,
    required this.mode,
    required this.stageWidth,
    required this.stageHeight,
    this.snapshot,
    this.seatIndex,
    this.stageScale,
  });

  final AppController controller;
  final _FriendDialogMode mode;
  final RoomSnapshot? snapshot;
  final int? seatIndex;
  final double? stageScale;
  final double stageWidth;
  final double stageHeight;

  bool get inviteMode => mode == _FriendDialogMode.seatInvite;

  @override
  State<_FriendCenterDialog> createState() => _FriendCenterDialogState();
}

class _FriendCenterDialogState extends State<_FriendCenterDialog> {
  final TextEditingController _addFriendController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _panelScrollController = ScrollController();
  final ScrollController _friendListScrollController = ScrollController();

  List<OnlineUser> _friends = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _noticeText;
  bool _noticeSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _addFriendController.dispose();
    _searchController.dispose();
    _panelScrollController.dispose();
    _friendListScrollController.dispose();
    super.dispose();
  }

  Set<String> get _occupiedUserIds {
    final snapshot = widget.snapshot;
    if (snapshot == null) {
      return const <String>{};
    }
    return snapshot.players
        .where((player) => player.occupied)
        .map((player) => player.playerId)
        .toSet();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _loading = true;
      _noticeText = null;
      _noticeSuccess = false;
    });
    final friends = await widget.controller.fetchFriends();
    if (!mounted) {
      return;
    }
    friends.sort((left, right) {
      if (left.online != right.online) {
        return left.online ? -1 : 1;
      }
      final byName = left.displayName.compareTo(right.displayName);
      if (byName != 0) {
        return byName;
      }
      return left.account.compareTo(right.account);
    });
    setState(() {
      _friends = friends;
      _loading = false;
    });
  }

  void _setNotice(String text, {required bool success}) {
    setState(() {
      _noticeText = text;
      _noticeSuccess = success;
    });
  }

  Future<void> _addFriend() async {
    final account = _addFriendController.text.trim();
    if (account.isEmpty) {
      _setNotice('请输入要添加的好友账号。', success: false);
      return;
    }
    setState(() {
      _submitting = true;
      _noticeText = null;
    });
    final added = await widget.controller.addFriendByAccount(account);
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final rawError = widget.controller.errorText;
    if (added == null || rawError != null) {
      _setNotice(
        _friendlyFriendMessage(rawError ?? 'add friend failed'),
        success: false,
      );
      widget.controller.clearError();
      return;
    }
    _addFriendController.clear();
    await _loadFriends();
    if (!mounted) {
      return;
    }
    _setNotice('已添加好友 ${added.displayName}。', success: true);
  }

  Future<void> _inviteFriend(OnlineUser friend) async {
    final seatIndex = widget.seatIndex;
    if (seatIndex == null) {
      return;
    }
    setState(() {
      _submitting = true;
      _noticeText = null;
    });
    await widget.controller.invitePlayerToRoom(
      account: friend.account,
      displayName: friend.displayName,
      seatIndex: seatIndex,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final rawError = widget.controller.errorText;
    if (rawError != null) {
      _setNotice(_friendlyFriendMessage(rawError), success: false);
      widget.controller.clearError();
      return;
    }
    Navigator.of(
      context,
    ).pop(FriendDialogResult('已向 ${friend.displayName} 发送入座邀请，请等待对方确认。'));
  }

  Future<void> _addBot(BotDifficulty difficulty) async {
    final snapshot = widget.snapshot;
    final seatIndex = widget.seatIndex;
    if (snapshot == null || seatIndex == null) {
      return;
    }
    setState(() {
      _submitting = true;
      _noticeText = null;
    });
    await widget.controller.addBotToRoom(
      seatIndex: seatIndex,
      difficulty: difficulty,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final rawError = widget.controller.errorText;
    if (rawError != null) {
      _setNotice(_friendlyFriendMessage(rawError), success: false);
      widget.controller.clearError();
      return;
    }
    Navigator.of(
      context,
    ).pop(FriendDialogResult('已为${_seatLabel(seatIndex)}补入${difficulty.label}机器人。'));
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: const Color(0xFF5A7894)),
      filled: true,
      fillColor: const Color(0xFFF8FCFF),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD7EBFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD7EBFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2B7FFF), width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final stageScale =
        widget.stageScale ??
        math.min(media.width / widget.stageWidth, media.height / widget.stageHeight);
    final search = _searchController.text.trim().toLowerCase();
    final visibleFriends = _friends.where((friend) {
      if (widget.inviteMode && _occupiedUserIds.contains(friend.userId)) {
        return false;
      }
      if (search.isEmpty) {
        return true;
      }
      return friend.account.toLowerCase().contains(search) ||
          friend.displayName.toLowerCase().contains(search);
    }).toList(growable: false);
    final onlineCount = _friends.where((friend) => friend.online).length;
    final inviteableOnlineCount =
        visibleFriends.where((friend) => friend.online).length;
    final title = widget.inviteMode ? '安排座位' : '好友中心';
    final subtitle = widget.inviteMode
        ? '${_seatLabel(widget.seatIndex ?? 0)}可邀请在线好友入座，也可以直接补入不同难度的机器人。'
        : '在这里统一管理好友关系、查看在线状态，并快速发起邀请。';
    final insetPadding = EdgeInsets.symmetric(
      horizontal: math.max(12.0, media.width * 0.024),
      vertical: math.max(10.0, media.height * 0.014),
    );

    return StageRelativeDialogPanel(
      stageWidth: widget.stageWidth,
      stageHeight: widget.stageHeight,
      stageScale: stageScale,
      widthRatio: 0.45,
      heightRatio: 0.75,
      padding: EdgeInsets.zero,
      radius: 34,
      fillHeight: true,
      scrollable: false,
      insetPadding: insetPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final compactLayout = width < 540 || height < 620;
          final stackControls = width < 640;
          final contentPadding = compactLayout
              ? const EdgeInsets.fromLTRB(18, 18, 18, 16)
              : const EdgeInsets.fromLTRB(24, 24, 24, 20);
          final sectionGap = compactLayout ? 10.0 : 14.0;
          final listViewportHeight = math.max(
            compactLayout ? 220.0 : 250.0,
            math.min(
              height * (widget.inviteMode ? 0.34 : 0.38),
              compactLayout ? 300.0 : 360.0,
            ),
          );
          final scrollBehavior = const MaterialScrollBehavior().copyWith(
            scrollbars: false,
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.unknown,
            },
          );

          final addFriendField = TextField(
            controller: _addFriendController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitting ? null : _addFriend(),
            decoration: _inputDecoration(hintText: '输入好友账号'),
          );
          final searchField = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(
              hintText: '按昵称或账号搜索',
              icon: Icons.search_rounded,
            ),
          );

          return ScrollConfiguration(
            behavior: scrollBehavior,
            child: Scrollbar(
              controller: _panelScrollController,
              interactive: true,
              thumbVisibility: compactLayout,
              child: SingleChildScrollView(
                controller: _panelScrollController,
                child: Padding(
                  padding: contentPadding,
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FriendHeroCard(
                  title: title,
                  subtitle: subtitle,
                  compact: compactLayout,
                  icon: widget.inviteMode
                      ? Icons.event_seat_rounded
                      : Icons.groups_rounded,
                  onClose: () => Navigator.of(context).pop(),
                  stats: [
                    _FriendStatData(
                      label: '好友总数',
                      value: '${_friends.length}',
                      icon: Icons.people_alt_rounded,
                    ),
                    _FriendStatData(
                      label: '当前在线',
                      value: '$onlineCount',
                      icon: Icons.wifi_tethering_rounded,
                    ),
                    if (widget.inviteMode)
                      _FriendStatData(
                        label: '可邀请',
                        value: '$inviteableOnlineCount',
                        icon: Icons.mail_outline_rounded,
                      ),
                  ],
                ),
                SizedBox(height: sectionGap),
                if (widget.inviteMode) ...[
                  _FriendSectionCard(
                    icon: Icons.smart_toy_rounded,
                    title: '快速补位',
                    subtitle: '房主可以直接为当前空位补入不同难度的 AI，快速继续对局。',
                    compact: compactLayout,
                    trailing: _SoftCountBadge(
                      text: '${BotDifficulty.values.length} 档可选',
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final difficulty in BotDifficulty.values)
                          FilledButton.tonalIcon(
                            onPressed: _submitting ? null : () => _addBot(difficulty),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(Icons.smart_toy_rounded, size: 18),
                            label: Text(difficulty.label),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),
                ],
                _FriendSectionCard(
                  icon: Icons.person_add_alt_1_rounded,
                  title: '添加好友',
                  subtitle: '输入对方账号即可加入列表，后续邀请和在线状态都会在这里同步。',
                  compact: compactLayout,
                  child: stackControls
                      ? Column(
                          children: [
                            addFriendField,
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _submitting ? null : _addFriend,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: const Text('添加好友'),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: addFriendField),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: _submitting ? null : _addFriend,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(118, 52),
                              ),
                              child: const Text('添加好友'),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: sectionGap),
                _FriendSectionCard(
                    icon: widget.inviteMode
                        ? Icons.mark_email_unread_rounded
                        : Icons.people_alt_outlined,
                    title: widget.inviteMode ? '可邀请好友' : '好友列表',
                    subtitle: widget.inviteMode
                        ? '在线好友可直接发送入座邀请，离线好友会继续保留在列表里。'
                        : '支持按昵称或账号搜索，在线状态会实时反映在这里。',
                    compact: compactLayout,
                    trailing: _SoftCountBadge(text: '共 ${visibleFriends.length} 位'),
                    child: Column(
                      children: [
                        if (stackControls)
                          Column(
                            children: [
                              searchField,
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _submitting || _loading ? null : _loadFriends,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('刷新列表'),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(child: searchField),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: _submitting || _loading ? null : _loadFriends,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(116, 52),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('刷新'),
                              ),
                            ],
                          ),
                        if (_noticeText != null) ...[
                          const SizedBox(height: 12),
                          _NoticePill(
                            text: _noticeText!,
                            success: _noticeSuccess,
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          height: listViewportHeight,
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : visibleFriends.isEmpty
                              ? _EmptyState(
                                  text: widget.inviteMode
                                      ? '当前没有可邀请的好友，先添加一些好友吧。'
                                      : '当前还没有好友，先通过账号添加几位牌友吧。',
                                )
                              : Scrollbar(
                                  controller: _friendListScrollController,
                                  interactive: true,
                                  thumbVisibility:
                                      visibleFriends.length >
                                      (compactLayout ? 4 : 5),
                                  child: ListView.separated(
                                    controller: _friendListScrollController,
                                    primary: false,
                                    padding: EdgeInsets.zero,
                                    itemCount: visibleFriends.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final friend = visibleFriends[index];
                                      return _FriendTile(
                                        friend: friend,
                                        inviteMode: widget.inviteMode,
                                        busy: _submitting,
                                        compact: compactLayout,
                                        onInvite: widget.inviteMode && friend.online
                                            ? () => _inviteFriend(friend)
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
              ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FriendStatData {
  const _FriendStatData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _FriendHeroCard extends StatelessWidget {
  const _FriendHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClose,
    required this.stats,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onClose;
  final List<_FriendStatData> stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
          : const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 26 : 30),
        gradient: const LinearGradient(
          colors: [Color(0xFFF6FBFF), Color(0xFFEAF4FF), Color(0xFFF5FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD8EAFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x123678A3),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 52 : 58,
                height: compact ? 52 : 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7FD1FF), Color(0xFF2B7FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: compact ? 26 : 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF173A59),
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 23 : 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF587790),
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12.5 : 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final stat in stats)
                _FriendStatChip(
                  label: stat.label,
                  value: stat.value,
                  icon: stat.icon,
                  compact: compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendStatChip extends StatelessWidget {
  const _FriendStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.compact,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 11,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 28 : 30,
            height: compact ? 28 : 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFEAF5FF),
            ),
            child: Icon(icon, color: const Color(0xFF2B7FFF), size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF587790),
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 11.5 : 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF173A59),
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 16 : 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendSectionCard extends StatelessWidget {
  const _FriendSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.compact,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
          : const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 24 : 26),
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFEFF), Color(0xFFF5FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFEAF5FF),
                ),
                child: Icon(icon, color: const Color(0xFF2B7FFF), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFF173A59),
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 17 : 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF587790),
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 12 : 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SoftCountBadge extends StatelessWidget {
  const _SoftCountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFEAF5FF),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF245E90),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.inviteMode,
    required this.busy,
    required this.compact,
    required this.onInvite,
  });

  final OnlineUser friend;
  final bool inviteMode;
  final bool busy;
  final bool compact;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final displayName = friend.displayName;
    final online = friend.online;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 14,
        compact ? 12 : 14,
        compact ? 12 : 14,
        compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: online
              ? [
                  Colors.white.withValues(alpha: 0.96),
                  const Color(0xFFF1FAF5),
                ]
              : [
                  Colors.white.withValues(alpha: 0.96),
                  const Color(0xFFF7FAFD),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: online ? const Color(0xFFCEE9D7) : const Color(0xFFD7EBFF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 48 : 54,
            height: compact ? 48 : 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF80D0FF), Color(0xFF2B7FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 18 : 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF173A59),
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 15.5 : 17,
                        ),
                      ),
                    ),
                    if (!inviteMode) ...[
                      const SizedBox(width: 8),
                      _OnlineBadge(online: online),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FriendMetaChip(
                      icon: Icons.person_outline_rounded,
                      text: friend.account,
                    ),
                    if (inviteMode)
                      _FriendMetaChip(
                        icon: online
                            ? Icons.wifi_tethering_rounded
                            : Icons.cloud_off_rounded,
                        text: online ? '在线可邀请' : '当前离线',
                        active: online,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (inviteMode)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _OnlineBadge(online: online),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: online && !busy ? onInvite : null,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(compact ? 96 : 118, 44),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(online ? '邀请入座' : '暂不可邀'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FriendMetaChip extends StatelessWidget {
  const _FriendMetaChip({
    required this.icon,
    required this.text,
    this.active = false,
  });

  final IconData icon;
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background =
        active ? const Color(0xFFEAF8EE) : const Color(0xFFF1F6FB);
    final color = active ? const Color(0xFF237A4B) : const Color(0xFF587790);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF22A064) : const Color(0xFF7B90A8);
    final background =
        online ? const Color(0xFFE9F8EF) : const Color(0xFFF0F4F8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: background,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            online ? '在线' : '离线',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticePill extends StatelessWidget {
  const _NoticePill({
    required this.text,
    required this.success,
  });

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final background =
        success ? const Color(0xFFEAF8EE) : const Color(0xFFFFF1EC);
    final color = success ? const Color(0xFF237A4B) : const Color(0xFFB54A3D);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: background,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF8FCFF),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAF5FF),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Color(0xFF2B7FFF),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

String _seatLabel(int seatIndex) => switch (seatIndex) {
      0 => '一号位',
      1 => '二号位',
      _ => '三号位',
    };

String _friendlyFriendMessage(String raw) {
  final text = raw.replaceFirst('Exception: ', '');
  final lowerText = text.toLowerCase();
  switch (text) {
    case 'account is required':
      return '请输入要添加的好友账号。';
    case 'account not found':
    case 'player not found':
      return '没有找到这个账号，请检查后再试。';
    case 'cannot add yourself':
      return '不能把自己添加为好友。';
    case 'friend already exists':
      return '这个账号已经在你的好友列表里了。';
    case 'login required':
      return '登录状态已失效，请重新登录后再试。';
    case 'operation in progress':
      return '当前还有操作正在处理中，请稍候再试。';
    case 'room not found':
      return '当前房间不存在或已经关闭。';
    case 'room is full':
      return '房间已经满员，暂时不能继续邀请。';
    case 'only host can invite players':
      return '只有房主可以邀请玩家入座。';
    case 'invalid invite target':
      return '请选择一个有效的邀请对象。';
    case 'seat is occupied':
      return '这个座位已经有人了，请换一个空位。';
    case 'player is offline':
      return '对方当前不在线。';
    case 'player is not available':
      return '对方现在暂时不能加入房间。';
    case 'player already in room':
      return '这位好友已经在房间里了。';
    case 'player is handling another invitation':
      return '对方正在处理另一条邀请，请稍后再试。';
    default:
      if (lowerText.contains('timeout') ||
          lowerText.contains('timed out') ||
          lowerText.contains('socketexception') ||
          lowerText.contains('websocket') ||
          lowerText.contains('connection') ||
          lowerText.contains('service unavailable') ||
          text.contains('连接') ||
          text.contains('超时')) {
        return '当前连接不稳定，已尝试自动重连，请稍后再试一次。';
      }
      return text;
  }
}
