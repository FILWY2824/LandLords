import 'dart:async';

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
  static const _refreshInterval = Duration(seconds: 4);

  final _addFriendController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  late FriendCenterSnapshot _snapshot;
  Timer? _refreshTimer;
  bool _loading = true;
  bool _submitting = false;
  bool _historyExpanded = false;
  String? _noticeText;
  bool _noticeSuccess = false;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.controller.friendCenterSnapshot;
    _loading =
        _snapshot.friends.isEmpty &&
        _snapshot.pendingRequests.isEmpty &&
        _snapshot.historyRequests.isEmpty;
    _searchController.addListener(_rebuild);
    _loadFriendCenter(showSpinner: _loading, silent: true);
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (!_submitting && mounted) {
        _loadFriendCenter(showSpinner: false, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _addFriendController.dispose();
    _searchController
      ..removeListener(_rebuild)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
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

  String get _query => _searchController.text.trim().toLowerCase();

  String get _selfUserId => widget.controller.profile?.userId ?? '';

  List<OnlineUser> get _friends {
    return _snapshot.friends.where((friend) {
      final text = '${friend.displayName} ${friend.account}'.toLowerCase();
      final matches = _query.isEmpty || text.contains(_query);
      if (!matches) {
        return false;
      }
      return !widget.inviteMode || !_occupiedUserIds.contains(friend.userId);
    }).toList(growable: false);
  }

  List<FriendRequestEntry> get _pendingRequests {
    if (widget.inviteMode) {
      return const [];
    }
    return _snapshot.pendingRequests.where((request) {
      final text =
          '${request.requesterName} ${request.requesterAccount}'.toLowerCase();
      return _query.isEmpty || text.contains(_query);
    }).toList(growable: false);
  }

  List<FriendRequestEntry> get _historyRequests {
    if (widget.inviteMode) {
      return const [];
    }
    return _snapshot.historyRequests.where((request) {
      final text =
          '${request.requesterName} ${request.requesterAccount} ${request.receiverName} ${request.receiverAccount}'
              .toLowerCase();
      return _query.isEmpty || text.contains(_query);
    }).toList(growable: false);
  }

  Future<void> _loadFriendCenter({
    bool showSpinner = false,
    bool silent = false,
  }) async {
    if (showSpinner && mounted) {
      setState(() => _loading = true);
    }
    final snapshot = await widget.controller.refreshFriendCenter(silent: silent);
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  void _setNotice(String text, {required bool success}) {
    setState(() {
      _noticeText = text;
      _noticeSuccess = success;
    });
  }

  Future<void> _sendFriendRequest() async {
    FocusScope.of(context).unfocus();
    final account = _addFriendController.text.trim();
    if (account.isEmpty) {
      _setNotice('请输入要添加的好友账号。', success: false);
      return;
    }
    setState(() => _submitting = true);
    final snapshot = await widget.controller.sendFriendRequestByAccount(account);
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final error = widget.controller.errorText;
    if (snapshot == null || error != null) {
      _setNotice(
        _friendlyMessage(error ?? 'friend request failed'),
        success: false,
      );
      widget.controller.clearError();
      return;
    }
    _addFriendController.clear();
    setState(() => _snapshot = snapshot);
    _setNotice('好友申请已发送，等待对方处理。', success: true);
  }

  Future<void> _handleRequest(FriendRequestEntry request, bool accept) async {
    setState(() => _submitting = true);
    final snapshot = await widget.controller.respondFriendRequest(
      requestId: request.requestId,
      accept: accept,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final error = widget.controller.errorText;
    if (snapshot == null || error != null) {
      _setNotice(_friendlyMessage(error ?? 'request failed'), success: false);
      widget.controller.clearError();
      return;
    }
    setState(() => _snapshot = snapshot);
    _setNotice(accept ? '已同意好友申请。' : '已拒绝好友申请。', success: true);
  }

  Future<void> _deleteFriend(OnlineUser friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确认要删除好友 ${friend.displayName} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _submitting = true);
    final snapshot = await widget.controller.deleteFriend(friend.userId);
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final error = widget.controller.errorText;
    if (snapshot == null || error != null) {
      _setNotice(_friendlyMessage(error ?? 'delete failed'), success: false);
      widget.controller.clearError();
      return;
    }
    setState(() => _snapshot = snapshot);
    _setNotice('已删除好友 ${friend.displayName}。', success: true);
  }

  Future<void> _inviteFriend(OnlineUser friend) async {
    final seatIndex = widget.seatIndex;
    if (seatIndex == null) {
      return;
    }
    setState(() => _submitting = true);
    await widget.controller.invitePlayerToRoom(
      account: friend.account,
      displayName: friend.displayName,
      seatIndex: seatIndex,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final error = widget.controller.errorText;
    if (error != null) {
      _setNotice(_friendlyMessage(error), success: false);
      widget.controller.clearError();
      return;
    }
    Navigator.of(context).pop(const FriendDialogResult('已发送邀请。'));
  }

  Future<void> _addBot(BotDifficulty difficulty) async {
    final seatIndex = widget.seatIndex;
    if (seatIndex == null) {
      return;
    }
    setState(() => _submitting = true);
    await widget.controller.addBotToRoom(
      seatIndex: seatIndex,
      difficulty: difficulty,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final error = widget.controller.errorText;
    if (error != null) {
      _setNotice(_friendlyMessage(error), success: false);
      widget.controller.clearError();
      return;
    }
    Navigator.of(
      context,
    ).pop(FriendDialogResult('已补入 ${difficulty.hallTitle}。'));
  }

  @override
  Widget build(BuildContext context) {
    final friends = _friends;
    final pendingRequests = _pendingRequests;
    final historyRequests = _historyRequests;
    final onlineCount =
        _snapshot.friends.where((friend) => friend.online).length;

    return StageRelativeDialogPanel(
      stageWidth: widget.stageWidth,
      stageHeight: widget.stageHeight,
      stageScale: widget.stageScale ?? 1,
      widthRatio: 0.45,
      heightRatio: 0.75,
      scrollable: false,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: LayoutBuilder(
        builder: (context, constraints) => Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(right: 4),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          _Header(
            title: widget.inviteMode ? '安排座位' : '好友中心',
            subtitle: widget.inviteMode
                ? '优先邀请在线好友入座，也可以直接补入 DouZero。'
                : '这里会展示待处理好友请求、历史记录和实时在线状态，并每 4 秒自动刷新一次。',
            refreshLabel: widget.inviteMode ? '邀请视图' : '实时刷新',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatCard(
                label: '好友总数',
                value: '${_snapshot.friends.length}',
                icon: Icons.groups_rounded,
                tint: const Color(0xFF2B7FFF),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: '在线好友',
                value: '$onlineCount',
                icon: Icons.bolt_rounded,
                tint: const Color(0xFF22A06B),
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: '待处理',
                value: '${_snapshot.pendingRequestCount}',
                icon: Icons.mark_email_unread_rounded,
                tint: const Color(0xFFEF8C24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: _inputDecoration(
              hint: widget.inviteMode ? '搜索可邀请好友' : '搜索好友、请求与历史记录',
              icon: Icons.search_rounded,
            ),
          ),
          if (_noticeText != null) ...[
            const SizedBox(height: 12),
            _NoticeBar(text: _noticeText!, success: _noticeSuccess),
          ],
          const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 96),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    if (widget.inviteMode) ...[
                      _buildBotSection(),
                      const SizedBox(height: 12),
                    ],
                    if (!widget.inviteMode) ...[
                      _buildPendingSection(pendingRequests),
                      const SizedBox(height: 12),
                      _buildAddFriendSection(),
                      const SizedBox(height: 12),
                    ],
                    _buildFriendSection(friends),
                    if (!widget.inviteMode) ...[
                      const SizedBox(height: 12),
                      _buildHistorySection(historyRequests),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingSection(List<FriendRequestEntry> pendingRequests) {
    return _SectionCard(
      title: '好友请求消息',
      subtitle: '这里显示等待你同意或拒绝的好友申请。',
      icon: Icons.mark_email_unread_rounded,
      badgeText: '${pendingRequests.length}',
      child: pendingRequests.isEmpty
          ? const _EmptyPanel('暂时没有待处理的好友请求。')
          : Column(
              children: [
                for (final request in pendingRequests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RequestTile(
                      request: request,
                      timeLabel: _formatTime(request.createdAtMs),
                      onAccept: _submitting
                          ? null
                          : () => _handleRequest(request, true),
                      onReject: _submitting
                          ? null
                          : () => _handleRequest(request, false),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildAddFriendSection() {
    return _SectionCard(
      title: '添加好友',
      subtitle: '发送好友申请后，需要对方同意，才会出现在双方好友列表中。',
      icon: Icons.person_add_alt_1_rounded,
      child: Column(
        children: [
          TextField(
            controller: _addFriendController,
            onSubmitted: (_) {
              if (!_submitting) {
                unawaited(_sendFriendRequest());
              }
            },
            decoration: _inputDecoration(
              hint: '输入好友账号',
              icon: Icons.alternate_email_rounded,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _sendFriendRequest,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('发送好友申请'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendSection(List<OnlineUser> friends) {
    return _SectionCard(
      title: widget.inviteMode ? '可邀请好友' : '好友列表',
      subtitle: widget.inviteMode
          ? '只有在线且还没占座的好友可以直接邀请。'
          : '在线状态会自动刷新，你也可以在这里管理和删除好友。',
      icon: widget.inviteMode
          ? Icons.event_seat_rounded
          : Icons.groups_2_rounded,
      badgeText: '${friends.length}',
      child: friends.isEmpty
          ? _EmptyPanel(
              widget.inviteMode ? '当前没有可邀请的好友。' : '当前没有符合条件的好友。',
            )
          : Column(
              children: [
                for (final friend in friends)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FriendTile(
                      friend: friend,
                      inviteMode: widget.inviteMode,
                      enabled: !_submitting,
                      onInvite: widget.inviteMode
                          ? () => _inviteFriend(friend)
                          : null,
                      onDelete: widget.inviteMode
                          ? null
                          : () => _deleteFriend(friend),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildHistorySection(List<FriendRequestEntry> historyRequests) {
    return _SectionCard(
      title: '历史请求消息',
      subtitle: '保留你发出的申请和已经处理过的好友请求，按最新时间排序。',
      icon: Icons.history_rounded,
      badgeText: '${historyRequests.length}',
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              _historyExpanded = !_historyExpanded;
            }),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFFF5FAFF),
                border: Border.all(color: const Color(0xFFD7EBFF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF2B7FFF),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _historyExpanded ? '收起历史请求' : '展开历史请求',
                      style: const TextStyle(
                        color: Color(0xFF173A59),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    text: '${historyRequests.length}',
                    tint: const Color(0xFF2B7FFF),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _historyExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF5D7B94),
                  ),
                ],
              ),
            ),
          ),
          if (_historyExpanded) ...[
            const SizedBox(height: 10),
            if (historyRequests.isEmpty)
              const _EmptyPanel('还没有历史好友请求记录。')
            else
              Column(
                children: [
                  for (final request in historyRequests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryTile(
                        request: request,
                        selfUserId: _selfUserId,
                        timeLabel: _formatTime(request.updatedAtMs),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotSection() {
    return _SectionCard(
      title: '补入 DouZero',
      subtitle: '如果好友不在线，可以直接补入机器人，快速完成开局准备。',
      icon: Icons.smart_toy_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final difficulty in BotDifficulty.values)
            OutlinedButton.icon(
              onPressed: _submitting ? null : () => _addBot(difficulty),
              icon: const Icon(Icons.smart_toy_outlined, size: 16),
              label: Text(difficulty.hallTitle),
            ),
        ],
      ),
    );
  }

  String _formatTime(int millisecondsSinceEpoch) {
    final time = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7FBFF),
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
        borderSide: const BorderSide(color: Color(0xFF6BB6FF), width: 1.4),
      ),
    );
  }

  String _friendlyMessage(String raw) {
    final text = raw.replaceFirst('Exception: ', '');
    if (text.contains('account not found')) {
      return '没有找到这个账号，请检查后重试。';
    }
    if (text.contains('cannot add yourself')) {
      return '不能把自己添加为好友。';
    }
    if (text.contains('friend already exists')) {
      return '这个账号已经在你的好友列表里了。';
    }
    if (text.contains('already sent')) {
      return '你已经发送过好友申请了。';
    }
    if (text.contains('target already sent you a request')) {
      return '对方已经向你发送好友申请，请在请求区处理。';
    }
    if (text.contains('friend request already handled')) {
      return '这条好友请求已经处理过了。';
    }
    if (text.contains('player is offline')) {
      return '这位好友当前离线，暂时无法邀请。';
    }
    if (text.contains('room is full')) {
      return '当前房间已经满员。';
    }
    return text;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.refreshLabel,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final String refreshLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF4FAFF), Color(0xFFE9F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD4E9FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF74C3FF), Color(0xFF2B7FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x262B7FFF),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF173A59),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Badge(
                      text: refreshLabel,
                      tint: const Color(0xFF2B7FFF),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF5D7B94),
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF7FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFD7EBFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: tint.withValues(alpha: 0.14),
                  ),
                  child: Icon(icon, color: tint, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF5D7B94),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF173A59),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeBar extends StatelessWidget {
  const _NoticeBar({required this.text, required this.success});

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF1E9A62) : const Color(0xFFE05A4F);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.badgeText,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badgeText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x142B7FFF),
                ),
                child: Icon(icon, color: const Color(0xFF2B7FFF), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF173A59),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (badgeText != null)
                _Badge(text: badgeText!, tint: const Color(0xFF2B7FFF)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF5D7B94),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.tint});

  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tint.withValues(alpha: 0.12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tint,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF6FAFE),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B879D),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.timeLabel,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequestEntry request;
  final String timeLabel;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${request.requesterName} 向你发送了好友申请',
                  style: const TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const _Badge(text: '待处理', tint: Color(0xFFEF8C24)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '账号 ${request.requesterAccount} · $timeLabel',
            style: const TextStyle(
              color: Color(0xFF5D7B94),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('拒绝'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  child: const Text('同意'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.inviteMode,
    required this.enabled,
    this.onInvite,
    this.onDelete,
  });

  final OnlineUser friend;
  final bool inviteMode;
  final bool enabled;
  final VoidCallback? onInvite;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = friend.online
        ? const Color(0xFF22A06B)
        : const Color(0xFF859AB0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: friend.online
                    ? const [Color(0xFF74C3FF), Color(0xFF2B7FFF)]
                    : const [Color(0xFFC2D2E2), Color(0xFF93A8BE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              friend.displayName.isEmpty ? '?' : friend.displayName.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
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
                        friend.displayName,
                        style: const TextStyle(
                          color: Color(0xFF173A59),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Badge(
                      text: friend.online ? '在线' : '离线',
                      tint: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '账号 ${friend.account}',
                  style: const TextStyle(
                    color: Color(0xFF5D7B94),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (inviteMode)
            FilledButton.tonal(
              onPressed: enabled && friend.online ? onInvite : null,
              child: const Text('邀请入座'),
            )
          else
            IconButton.filledTonal(
              onPressed: enabled ? onDelete : null,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.request,
    required this.selfUserId,
    required this.timeLabel,
  });

  final FriendRequestEntry request;
  final String selfUserId;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final incoming = request.isIncomingFor(selfUserId);
    final (statusLabel, tint) = switch (request.status) {
      FriendRequestStatus.accepted => ('已同意', const Color(0xFF22A06B)),
      FriendRequestStatus.rejected => ('已拒绝', const Color(0xFFE05A4F)),
      FriendRequestStatus.handled => ('已处理', const Color(0xFF6C7F92)),
      FriendRequestStatus.pending => ('处理中', const Color(0xFFEF8C24)),
    };
    final summary = incoming
        ? '${request.requesterName} 向你发送了好友申请'
        : '你向 ${request.receiverName} 发送了好友申请';
    final detail = incoming
        ? '来自 ${request.requesterAccount}'
        : '发送至 ${request.receiverAccount}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  style: const TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Badge(text: statusLabel, tint: tint),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$detail · $timeLabel',
            style: const TextStyle(
              color: Color(0xFF5D7B94),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
