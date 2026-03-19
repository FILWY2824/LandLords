import 'dart:async';

import 'package:flutter/material.dart';

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
    unawaited(_voice.stopBackgroundMusic());
  }

  @override
  void dispose() {
    unawaited(_voice.dispose());
    super.dispose();
  }

  Future<void> _showBotDifficultyDialog(BuildContext context) async {
    final difficulty = await showDialog<BotDifficulty>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: _BotDifficultyDialog(selected: widget.controller.botDifficulty),
      ),
    );
    if (difficulty == null) {
      return;
    }
    await widget.controller.startMatch(
      MatchMode.vsBot,
      botDifficulty: difficulty,
    );
  }

  VoidCallback _onlineAction() {
    return widget.controller.hasResumeRoom
        ? widget.controller.resumeRoom
        : () => unawaited(widget.controller.startMatch(MatchMode.online));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final profile = controller.profile;
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
                    _LobbyHeader(profile: profile),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: _LobbyHero(
                              username: profile?.username ?? 'player1',
                              notice: controller.lobbyNotice,
                              hasResumeRoom: controller.hasResumeRoom,
                              onResume: controller.hasResumeRoom
                                  ? controller.resumeRoom
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 398,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _LobbyActionCard(
                                    badge: '推荐',
                                    title: '人机练习',
                                    subtitle: '先选难度，再开一局。',
                                    accent: const Color(0xFF2B7FFF),
                                    buttonLabel: '选难度',
                                    enabled:
                                        !controller.isBusy && !controller.isMatching,
                                    onPressed: () =>
                                        _showBotDifficultyDialog(context),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  child: _LobbyActionCard(
                                    badge: controller.hasResumeRoom ? '继续' : '在线',
                                    title: controller.hasResumeRoom
                                        ? '继续牌局'
                                        : '真人匹配',
                                    subtitle: controller.hasResumeRoom
                                        ? '回到上一桌继续玩。'
                                        : '在线匹配，随时可退出。',
                                    accent: const Color(0xFF4FB9FF),
                                    buttonLabel: controller.hasResumeRoom
                                        ? '回到牌桌'
                                        : '开始匹配',
                                    enabled:
                                        !controller.isBusy && !controller.isMatching,
                                    onPressed: _onlineAction(),
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
                _MatchingMask(
                  elapsedSeconds: controller.matchingElapsedSeconds,
                  timeoutSeconds: controller.matchingTimeoutSeconds,
                  onCancel: controller.cancelMatching,
                )
              else if (controller.isBusy)
                const _BusyMask(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFFEAF5FF),
          ),
          child: const Text(
            '欢乐斗地主',
            style: TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(color: const Color(0xFFD7EBFF)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2B7FFF),
                child: Text(
                  (profile?.username.isNotEmpty ?? false)
                      ? profile!.username.substring(0, 1).toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.username ?? 'player1',
                    style: const TextStyle(
                      color: Color(0xFF173A59),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '总分：${profile?.totalScore ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFF5A7894),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LobbyHero extends StatelessWidget {
  const _LobbyHero({
    required this.username,
    required this.notice,
    required this.hasResumeRoom,
    required this.onResume,
  });

  final String username;
  final String? notice;
  final bool hasResumeRoom;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StagePanel(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
            radius: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFE6F3FF),
                  ),
                  child: const Text(
                    '大厅',
                    style: TextStyle(
                      color: Color(0xFF2B7FFF),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '继续开局',
                  style: TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                    fontSize: 66,
                    height: 0.98,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '$username，选一个模式就能直接开局。',
                  style: const TextStyle(
                    color: Color(0xFF587790),
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _LobbyChip(label: '人机热身'),
                    _LobbyChip(label: '真人匹配'),
                    _LobbyChip(label: '托管续局'),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2F8FF), Color(0xFFE3F1FF)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HallFact(title: '简单人机', value: 'DouZero-ADP模型'),
                            SizedBox(height: 10),
                            _HallFact(title: '标准人机', value: 'DouZero-SL模型'),
                            SizedBox(height: 10),
                            _HallFact(title: '困难人机', value: 'DouZero-WP模型'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF83D2FF), Color(0xFF2B7FFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.style_rounded,
                          color: Colors.white,
                          size: 62,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 118,
          child: StagePanel(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            radius: 26,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    notice ?? '状态正常，随时可以开始。',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: notice == null
                          ? const Color(0xFF587790)
                          : const Color(0xFFB95645),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 1.45,
                    ),
                  ),
                ),
                if (hasResumeRoom && onResume != null) ...[
                  const SizedBox(width: 14),
                  FilledButton(
                    onPressed: onResume,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 54),
                    ),
                    child: const Text('继续牌局'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LobbyActionCard extends StatelessWidget {
  const _LobbyActionCard({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.buttonLabel,
    required this.enabled,
    required this.onPressed,
  });

  final String badge;
  final String title;
  final String subtitle;
  final Color accent;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return StagePanel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: accent.withValues(alpha: 0.14),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: 17,
              height: 1.45,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                minimumSize: const Size.fromHeight(58),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotDifficultyDialog extends StatelessWidget {
  const _BotDifficultyDialog({required this.selected});

  final BotDifficulty selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: StagePanel(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '选择难度',
                      style: TextStyle(
                        color: Color(0xFF173A59),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '选一档就能开局。',
                style: TextStyle(
                  color: Color(0xFF587790),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              for (final difficulty in BotDifficulty.values) ...[
                _DifficultyTile(
                  difficulty: difficulty,
                  selected: selected == difficulty,
                  onTap: () => Navigator.of(context).pop(difficulty),
                ),
                if (difficulty != BotDifficulty.values.last)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final BotDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (difficulty) {
      BotDifficulty.easy => const Color(0xFF4FB9FF),
      BotDifficulty.normal => const Color(0xFF2B7FFF),
      BotDifficulty.hard => const Color(0xFF0F5BD6),
    };
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? accent.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.86),
          border: Border.all(
            color: selected ? accent : const Color(0xFFD7EBFF),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.label,
                    style: const TextStyle(
                      color: Color(0xFF173A59),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: accent,
              size: selected ? 24 : 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchingMask extends StatelessWidget {
  const _MatchingMask({
    required this.elapsedSeconds,
    required this.timeoutSeconds,
    required this.onCancel,
  });

  final int elapsedSeconds;
  final int timeoutSeconds;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x66F4FAFF),
      child: Center(
        child: StagePanel(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
          radius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.8),
              ),
              const SizedBox(height: 16),
              const Text(
                '匹配中',
                style: TextStyle(
                  color: Color(0xFF173A59),
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$elapsedSeconds / $timeoutSeconds 秒',
                style: const TextStyle(
                  color: Color(0xFF587790),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onCancel,
                child: const Text('退出匹配'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusyMask extends StatelessWidget {
  const _BusyMask();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x55F4FAFF),
      child: const Center(
        child: StagePanel(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          radius: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 12),
              Text(
                '请稍候',
                style: TextStyle(
                  color: Color(0xFF173A59),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HallFact extends StatelessWidget {
  const _HallFact({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            '$title：',
            style: const TextStyle(
              color: Color(0xFF245E90),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }
}

class _LobbyChip extends StatelessWidget {
  const _LobbyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF245E90),
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}
