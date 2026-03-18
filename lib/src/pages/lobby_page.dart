import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/voice_cue_service.dart';
import '../state/app_controller.dart';

final VoiceCueService _lobbyMusicPrimer = VoiceCueService();

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key, required this.controller});

  final AppController controller;

  Future<void> _showBotDifficultySheet(BuildContext context) async {
    final difficulty = await showModalBottomSheet<BotDifficulty>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BotDifficultySheet(
        selected: controller.botDifficulty,
        onSelect: (difficulty) {
          unawaited(_lobbyMusicPrimer.startBackgroundMusic());
          Navigator.of(context).pop(difficulty);
        },
      ),
    );
    if (difficulty == null) {
      return;
    }
    await controller.startMatch(
      MatchMode.vsBot,
      botDifficulty: difficulty,
    );
  }

  VoidCallback _buildOnlineAction() {
    return controller.hasResumeRoom
        ? () {
            unawaited(_lobbyMusicPrimer.startBackgroundMusic());
            controller.resumeRoom();
          }
        : () {
            unawaited(_lobbyMusicPrimer.startBackgroundMusic());
            unawaited(controller.startMatch(MatchMode.online));
          };
  }

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    final botCard = _ModeCard(
      title: '经典人机',
      badge: '推荐',
      accent: const Color(0xFF2B7FFF),
      description:
          '先选简单、标准或困难，再开始一局。三档会分别切到 ${BotDifficulty.easy.modelFamily}、${BotDifficulty.normal.modelFamily}、${BotDifficulty.hard.modelFamily}。',
      buttonLabel: '选择难度',
      enabled: !controller.isBusy && !controller.isMatching,
      onPressed: () => _showBotDifficultySheet(context),
    );
    final onlineCard = _ModeCard(
      title: '真人匹配',
      badge: controller.hasResumeRoom ? '可继续' : '在线',
      accent: const Color(0xFF4FB9FF),
      description: controller.hasResumeRoom
          ? '你有一桌真人对局还在进行中，可以直接回到刚才的牌桌继续。'
          : '在线玩家会自动匹配成桌。匹配时会显示用时，也可以随时退出匹配。',
      buttonLabel: controller.hasResumeRoom ? '继续牌局' : '开始匹配',
      enabled: !controller.isBusy && !controller.isMatching,
      onPressed: _buildOnlineAction(),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FBFF), Color(0xFFE9F5FF), Color(0xFFD8EEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -100,
              right: -20,
              child: _GlowBall(size: 260, color: Color(0x4A74C4FF)),
            ),
            const Positioned(
              left: -40,
              bottom: -90,
              child: _GlowBall(size: 220, color: Color(0x3362ADFF)),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        _TopBar(profile: profile),
                        const SizedBox(height: 18),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 920;
                              final hero = _HeroPanel(
                                controller: controller,
                                profile: profile,
                              );
                              if (stacked) {
                                return SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      hero,
                                      const SizedBox(height: 16),
                                      _MobileModeDeck(
                                        botCard: botCard,
                                        onlineCard: onlineCard,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 7, child: hero),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        Expanded(child: botCard),
                                        const SizedBox(height: 16),
                                        Expanded(child: onlineCard),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (controller.lobbyNotice != null)
              Positioned(
                left: 0,
                right: 0,
                top: 30,
                child: IgnorePointer(
                  child: Center(
                    child: _LobbyNotice(text: controller.lobbyNotice!),
                  ),
                ),
              ),
            if (controller.stage == AppStage.matching)
              _MatchingMask(
                elapsedSeconds: controller.matchingElapsedSeconds,
                timeoutSeconds: controller.matchingTimeoutSeconds,
                onCancel: controller.cancelMatching,
              )
            else if (controller.isBusy)
              _BusyMask(text: controller.busyText ?? '正在处理中...'),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.88),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143678A3),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF89D5FF), Color(0xFF2B7FFF)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              (profile?.username.isNotEmpty ?? false)
                  ? profile!.username.substring(0, 1).toUpperCase()
                  : 'P',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.username ?? '未登录',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF173A59),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '累计欢乐豆 ${profile?.totalScore ?? 0}',
                  style: const TextStyle(
                    color: Color(0xFF5B7B95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFE9F5FF),
            ),
            child: const Text(
              '今日手气正旺',
              style: TextStyle(
                color: Color(0xFF2B7FFF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.controller,
    required this.profile,
  });

  final AppController controller;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF3FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143678A3),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFE4F3FF),
            ),
            child: const Text(
              '轻松开一局',
              style: TextStyle(
                color: Color(0xFF2B7FFF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '欢乐斗地主',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF163A59),
                  height: 1.08,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            '${profile?.username ?? '牌手'} 已经在牌桌等位。先挑一档合适的人机热热手，或者直接去真人场碰一碰手感。',
            style: const TextStyle(
              fontSize: 17,
              height: 1.7,
              color: Color(0xFF587790),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              const _InfoPill(title: '叫分抢地主', value: '真人自由选择'),
              const _InfoPill(title: '语音播报', value: '按牌型自然提示'),
              const _InfoPill(title: '托管功能', value: '25 秒自动接管'),
              _InfoPill(title: '当前人机', value: controller.botDifficulty.label),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5FF), Color(0xFFD7EDFF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前三档模型',
                  style: TextStyle(
                    color: Color(0xFF235D8F),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '简单：${BotDifficulty.easy.modelFamily}，标准：${BotDifficulty.normal.modelFamily}，困难：${BotDifficulty.hard.modelFamily}。',
                  style: const TextStyle(
                    color: Color(0xFF567590),
                    height: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  controller.lobbyNotice ??
                      '当前状态稳定，可以直接开始一局。在线匹配会显示用时，也支持主动退出，不会把调试报错直接展示给玩家。',
                  style: TextStyle(
                    color: controller.lobbyNotice == null
                        ? const Color(0xFF567590)
                        : const Color(0xFFBC5849),
                    height: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (controller.hasResumeRoom) ...[
            const SizedBox(height: 24),
            _ResumeBanner(
              onPressed: () {
                unawaited(_lobbyMusicPrimer.startBackgroundMusic());
                controller.resumeRoom();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.badge,
    required this.accent,
    required this.description,
    required this.buttonLabel,
    required this.enabled,
    required this.onPressed,
  });

  final String title;
  final String badge;
  final Color accent;
  final String description;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 220;
        final veryCompact = constraints.maxHeight < 198;
        return Container(
          padding: EdgeInsets.all(veryCompact ? 16 : compact ? 18 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withValues(alpha: 0.88),
            boxShadow: const [
              BoxShadow(
                color: Color(0x143678A3),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: veryCompact ? 9 : compact ? 10 : 12,
                  vertical: veryCompact ? 5 : compact ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: compact ? 14 : 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: veryCompact ? 22 : compact ? 24 : 30,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF173A59),
                ),
              ),
              SizedBox(height: veryCompact ? 6 : compact ? 8 : 12),
              Expanded(
                child: Text(
                  description,
                  maxLines: veryCompact ? 2 : compact ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: veryCompact ? 13 : compact ? 14 : 16,
                    height: veryCompact ? 1.35 : compact ? 1.5 : 1.7,
                    color: const Color(0xFF587790),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: veryCompact ? 10 : compact ? 14 : 22),
              FilledButton(
                onPressed: enabled ? onPressed : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: veryCompact ? 14 : compact ? 16 : 18,
                    vertical: veryCompact ? 11 : compact ? 14 : 16,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  minimumSize: Size(0, veryCompact ? 40 : 46),
                  visualDensity:
                      veryCompact ? VisualDensity.compact : VisualDensity.standard,
                ),
                child: Text(buttonLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileModeDeck extends StatefulWidget {
  const _MobileModeDeck({
    required this.botCard,
    required this.onlineCard,
  });

  final Widget botCard;
  final Widget onlineCard;

  @override
  State<_MobileModeDeck> createState() => _MobileModeDeckState();
}

class _MobileModeDeckState extends State<_MobileModeDeck> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.96);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView(
            controller: _controller,
            onPageChanged: (value) => setState(() => _currentPage = value),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: widget.botCard,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: widget.onlineCard,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final active = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active
                    ? const Color(0xFF2B7FFF)
                    : const Color(0xFFD3E6F8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BotDifficultySheet extends StatelessWidget {
  const _BotDifficultySheet({
    required this.selected,
    required this.onSelect,
  });

  final BotDifficulty selected;
  final ValueChanged<BotDifficulty> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x143678A3),
              blurRadius: 30,
              offset: Offset(0, 16),
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
                    '选择人机难度',
                    style: TextStyle(
                      color: Color(0xFF173A59),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '三档会切到三套不同的 DouZero baseline。简单更适合练手，标准作为默认档，困难更强调牌权和压制力。',
              style: TextStyle(
                color: Color(0xFF5A7894),
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            for (final difficulty in BotDifficulty.values) ...[
              _DifficultyTile(
                difficulty: difficulty,
                selected: selected == difficulty,
                onTap: () => onSelect(difficulty),
              ),
              if (difficulty != BotDifficulty.values.last)
                const SizedBox(height: 12),
            ],
          ],
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
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF2B7FFF) : const Color(0xFFD7EBFF),
            width: selected ? 2 : 1.2,
          ),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFF5FBFF), Color(0xFFE7F3FF)],
                )
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8FBFF)],
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.hallTitle,
                    style: const TextStyle(
                      color: Color(0xFF173A59),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    difficulty.description,
                    style: const TextStyle(
                      color: Color(0xFF5A7894),
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: selected
                    ? const Color(0xFF2B7FFF)
                    : const Color(0x142B7FFF),
              ),
              child: Text(
                difficulty.modelFamily,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF2B7FFF),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6A8AA5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFEAF6FF),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '你有一局真人对战还在进行，随时可以回到牌桌继续。',
              style: TextStyle(
                color: Color(0xFF245E90),
                fontWeight: FontWeight.w700,
                height: 1.6,
              ),
            ),
          ),
          FilledButton(
            onPressed: onPressed,
            child: const Text('继续牌局'),
          ),
        ],
      ),
    );
  }
}

class _BusyMask extends StatelessWidget {
  const _BusyMask({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x88EFF7FF),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x143678A3),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 14),
              Text(
                text,
                style: const TextStyle(
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

class _MatchingMask extends StatelessWidget {
  const _MatchingMask({
    required this.elapsedSeconds,
    required this.timeoutSeconds,
    required this.onCancel,
  });

  final int elapsedSeconds;
  final int timeoutSeconds;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedSeconds / timeoutSeconds).clamp(0.0, 1.0);
    return ColoredBox(
      color: const Color(0x90EFF7FF),
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x143678A3),
                blurRadius: 26,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '正在为你寻找牌友',
                style: TextStyle(
                  color: Color(0xFF173A59),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '匹配过程中可以随时退出。如果短时间内没有合适对手，会自动返回大厅。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5A7894),
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 86,
                height: 86,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 86,
                      height: 86,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFFDCEEFF),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF2B7FFF)),
                      ),
                    ),
                    Text(
                      '${elapsedSeconds}s',
                      style: const TextStyle(
                        color: Color(0xFF173A59),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '最长等待 ${timeoutSeconds}s',
                style: const TextStyle(
                  color: Color(0xFF5A7894),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
                child: const Text('退出匹配'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyNotice extends StatelessWidget {
  const _LobbyNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0C2BA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143678A3),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFBC5849),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GlowBall extends StatelessWidget {
  const _GlowBall({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
