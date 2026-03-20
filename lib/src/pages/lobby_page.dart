import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';
import '../services/voice_cue_service.dart';
import '../state/app_controller.dart';
import '../widgets/fixed_stage.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final _voice = VoiceCueService();

  @override
  void initState() {
    super.initState();
    unawaited(_voice.stopBackgroundMusic(force: true));
  }

  @override
  void dispose() {
    unawaited(_voice.dispose());
    super.dispose();
  }

  Future<void> _selectBotMode() async {
    final difficulty = await showDialog<BotDifficulty>(
      context: context,
      builder: (context) => const _ChoiceDialog<BotDifficulty>(
        title: '选择 AI 对局',
        subtitle: '选择一个难度后，将立即进入牌桌，与两位机器人开始游戏。',
        options: [
          _ChoiceItem(
            value: BotDifficulty.easy,
            title: '简单',
            detail: '节奏更轻，适合快速上手。',
          ),
          _ChoiceItem(
            value: BotDifficulty.normal,
            title: '正常',
            detail: '强度均衡，适合正式对局。',
          ),
          _ChoiceItem(
            value: BotDifficulty.hard,
            title: '困难',
            detail: '压制更强，适合高强度对抗。',
          ),
        ],
      ),
    );
    if (difficulty != null) {
      await widget.controller.startMatch(
        MatchMode.vsBot,
        botDifficulty: difficulty,
      );
    }
  }

  Future<void> _selectOnlineMode() async {
    if (widget.controller.hasResumeRoom) {
      widget.controller.resumeRoom();
      return;
    }
    final action = await showDialog<_OnlineAction>(
      context: context,
      builder: (context) => const _ChoiceDialog<_OnlineAction>(
        title: '真人对局',
        subtitle: '你可以创建房间、进入房间，或者直接自由匹配。',
        options: [
          _ChoiceItem(
            value: _OnlineAction.createRoom,
            title: '创建房间',
            detail: '先创建自己的牌桌，再邀请好友或补入 DouZero。',
          ),
          _ChoiceItem(
            value: _OnlineAction.joinRoom,
            title: '进入房间',
            detail: '输入 6 位房间号即可加入对应牌桌。',
          ),
          _ChoiceItem(
            value: _OnlineAction.freeMatch,
            title: '自由匹配',
            detail: '匹配满 3 人后直接开局，不经过准备阶段。',
          ),
        ],
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == _OnlineAction.createRoom) {
      await widget.controller.createRoom();
      return;
    }
    if (action == _OnlineAction.joinRoom) {
      final roomCode = await showDialog<String>(
        context: context,
        builder: (context) => const _JoinRoomDialog(),
      );
      if (roomCode != null && roomCode.isNotEmpty) {
        await widget.controller.joinRoom(roomCode);
      }
      return;
    }
    await widget.controller.startMatch(MatchMode.online);
  }

  Future<void> _showWinRate() async {
    final profile = widget.controller.profile;
    if (profile == null) {
      return;
    }
    if (mounted) {
      await _showWinRatePanel(profile);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('个人胜率'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('地主胜率：${_formatRate(profile.landlordWinRate)}'),
            Text('农民胜率：${_formatRate(profile.farmerWinRate)}'),
            Text('总体胜率：${_formatRate(profile.overallWinRate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWinRatePanel(UserProfile profile) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x33173A59),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: StagePanel(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
            radius: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '个人战绩',
                            style: TextStyle(
                              color: Color(0xFF173A59),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${profile.displayName} 的地主、农民与总体胜率一览',
                            style: const TextStyle(
                              color: Color(0xFF587790),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2F8FF), Color(0xFFE3F1FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFD7EBFF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF84D2FF), Color(0xFF2B7FFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _formatRate(profile.overallWinRate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '总体表现',
                              style: TextStyle(
                                color: Color(0xFF173A59),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '共 ${profile.totalGames} 局，胜 ${profile.totalWins} 局',
                              style: const TextStyle(
                                color: Color(0xFF587790),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.totalGames == 0
                                  ? '当前还没有历史对局数据'
                                  : '继续对局后会实时更新本面板数据',
                              style: const TextStyle(
                                color: Color(0xFF587790),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _WinRateStatCard(
                      title: '地主胜率',
                      rate: _formatRate(profile.landlordWinRate),
                      record: _formatRecord(
                        wins: profile.landlordWins,
                        games: profile.landlordGames,
                      ),
                      accent: const Color(0xFF2B7FFF),
                    ),
                    _WinRateStatCard(
                      title: '农民胜率',
                      rate: _formatRate(profile.farmerWinRate),
                      record: _formatRecord(
                        wins: profile.farmerWins,
                        games: profile.farmerGames,
                      ),
                      accent: const Color(0xFF3BB58F),
                    ),
                    _WinRateStatCard(
                      title: '总体胜率',
                      rate: _formatRate(profile.overallWinRate),
                      record: _formatRecord(
                        wins: profile.totalWins,
                        games: profile.totalGames,
                      ),
                      accent: const Color(0xFF4F7BFF),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出当前账号'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.controller.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final profile = controller.profile;
    final displayName = profile?.displayName ?? '牌友';

    return Scaffold(
      body: FixedStageBackdrop(
        child: FixedStage(
          width: 1320,
          height: 760,
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              StagePanel(
                padding: const EdgeInsets.all(24),
                radius: 34,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: const Color(0xFFEAF5FF),
                          ),
                          child: const Text(
                            '欢乐斗地主',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFD7EBFF)),
                          ),
                          child: Text(
                            '${profile?.displayName ?? '玩家'}  账号：${profile?.account ?? '-'}  金币：${profile?.coins ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.tonal(
                          onPressed: _showWinRate,
                          child: const Text('胜率'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _logout,
                          child: const Text('退出'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: StagePanel(
                              padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
                              radius: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: const Color(0xFFE6F3FF),
                                    ),
                                    child: const Text(
                                      '大厅',
                                      style: TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  const Text(
                                    '立即对局',
                                    style: TextStyle(
                                      color: Color(0xFF173A59),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 66,
                                      height: 0.98,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    '$displayName，选择模式后即可开始正式对局。',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF587790),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: const [
                                      _Chip('AI策略'),
                                      _Chip('实时分析'),
                                      _Chip('真人对局'),
                                      _Chip('断线可续'),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF2F8FF),
                                          Color(0xFFE3F1FF),
                                        ],
                                      ),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '简单模式：DouZero-ADP',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          '标准模式：DouZero-SL',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          '困难模式：DouZero-WP',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    controller.lobbyNotice ?? '状态正常，随时可以开始对局。',
                                    style: TextStyle(
                                      color: controller.lobbyNotice == null
                                          ? const Color(0xFF587790)
                                          : const Color(0xFFB95645),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (controller.hasResumeRoom) ...[
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: controller.resumeRoom,
                                      child: const Text('恢复牌桌'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 398,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _ActionCard(
                                    title: 'AI 对局',
                                    subtitle:
                                        '选择难度后立即进入牌桌，与两位 DouZero 直接开始游戏。',
                                    accent: const Color(0xFF2B7FFF),
                                    buttonLabel: '选择模式',
                                    onPressed: controller.isBusy ||
                                            controller.isMatching
                                        ? null
                                        : _selectBotMode,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  child: _ActionCard(
                                    title:
                                        controller.hasResumeRoom ? '恢复牌桌' : '真人匹配',
                                    subtitle: controller.hasResumeRoom
                                        ? '返回上一桌，继续当前已经开局的真人对局。'
                                        : '支持创建房间、进入房间与自由匹配。',
                                    accent: const Color(0xFF4FB9FF),
                                    buttonLabel:
                                        controller.hasResumeRoom ? '恢复牌桌' : '选择方式',
                                    onPressed: controller.isBusy ||
                                            controller.isMatching
                                        ? null
                                        : _selectOnlineMode,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.stage == AppStage.matching)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.5),
                    child: Center(
                      child: StagePanel(
                        padding: const EdgeInsets.all(24),
                        radius: 30,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              '正在匹配玩家 ${controller.matchingElapsedSeconds}/${controller.matchingTimeoutSeconds}',
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () =>
                                  controller.cancelMatching(timedOut: false),
                              child: const Text('取消匹配'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (controller.isBusy)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.25),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OnlineAction { createRoom, joinRoom, freeMatch }

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return StagePanel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF587790),
              height: 1.45,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _WinRateStatCard extends StatelessWidget {
  const _WinRateStatCard({
    required this.title,
    required this.rate,
    required this.record,
    required this.accent,
  });

  final String title;
  final String rate;
  final String record;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 161,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFF9FCFF),
          border: Border.all(color: const Color(0xFFD7EBFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F3678A3),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: accent.withValues(alpha: 0.12),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              rate,
              style: const TextStyle(
                color: Color(0xFF173A59),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              record,
              style: const TextStyle(
                color: Color(0xFF587790),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinRoomDialog extends StatefulWidget {
  const _JoinRoomDialog();

  @override
  State<_JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<_JoinRoomDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _controller.text.trim().length == 6;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
                  const Expanded(
                    child: Text(
                      '进入房间',
                      style: TextStyle(
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
                '输入 6 位房间号即可加入对应牌桌。',
                style: TextStyle(
                  color: Color(0xFF587790),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  hintText: '请输入 6 位房间号',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: canSubmit
                          ? () => Navigator.of(context).pop(_controller.text.trim())
                          : null,
                      child: const Text('确认进入'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceItem<T> {
  const _ChoiceItem({
    required this.value,
    required this.title,
    required this.detail,
  });

  final T value;
  final String title;
  final String detail;
}

class _ChoiceDialog<T> extends StatelessWidget {
  const _ChoiceDialog({
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final String title;
  final String subtitle;
  final List<_ChoiceItem<T>> options;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF587790)),
              ),
              const SizedBox(height: 12),
              for (final option in options) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    option.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(option.detail),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
                if (option != options.last) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatRate(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _formatRecord({
  required int wins,
  required int games,
}) {
  if (games == 0) {
    return '0 胜 / 0 局';
  }
  return '$wins 胜 / $games 局';
}
