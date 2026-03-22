import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';
import '../services/voice_cue_service.dart';
import '../state/app_controller.dart';
import '../widgets/friend_center_dialog.dart';
import '../widgets/fixed_stage.dart';
import '../widgets/responsive_modal.dart';

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
      builder: (context) => const _ResponsiveChoiceDialog<BotDifficulty>(
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
    final action = await _pickOnlineActionV2();
    if (!mounted || action == null) {
      return;
    }
    if (action == _OnlineAction.createRoom) {
      await widget.controller.createRoom();
      return;
    }
    if (action == _OnlineAction.joinRoom) {
      final roomCode = await _promptRoomCode();
      if (roomCode != null && roomCode.isNotEmpty) {
        await widget.controller.joinRoom(roomCode);
      }
      return;
    }
    await widget.controller.startMatch(MatchMode.online);
    return;
    /* legacy desktop path retained during refactor
    final legacyAction = await showDialog<_OnlineAction>(
      context: context,
      builder: (context) => const _ResponsiveChoiceDialog<_OnlineAction>(
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
    if (!mounted || legacyAction == null) {
      return;
    }
    if (legacyAction == _OnlineAction.createRoom) {
      await widget.controller.createRoom();
      return;
    }
    if (legacyAction == _OnlineAction.joinRoom) {
      final legacyRoomCode = await showDialog<String>(
        context: context,
        builder: (context) => const _ResponsiveJoinRoomDialog(),
      );
      if (legacyRoomCode != null && legacyRoomCode.isNotEmpty) {
        await widget.controller.joinRoom(legacyRoomCode);
      }
      return;
    }
    await widget.controller.startMatch(MatchMode.online);
    */
  }

  Future<_OnlineAction?> _pickOnlineActionV2() async {
    return showDialog<_OnlineAction>(
      context: context,
      builder: (context) => const _ResponsiveChoiceDialog<_OnlineAction>(
        title: '真人对局',
        subtitle: '你可以创建房间、进入房间，或者直接自由匹配。',
        options: [
          _ChoiceItem(
            value: _OnlineAction.createRoom,
            title: '创建房间',
            detail: '先创建自己的牌桌，再邀请好友或补入机器人。',
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
  }

  Future<_OnlineAction?> pickOnlineActionLegacy() async {
    return showDialog<_OnlineAction>(
      context: context,
      builder: (context) => const _ResponsiveChoiceDialog<_OnlineAction>(
        title: '鐪熶汉瀵瑰眬',
        subtitle: '浣犲彲浠ュ垱寤烘埧闂淬€佽繘鍏ユ埧闂达紝鎴栬€呯洿鎺ヨ嚜鐢卞尮閰嶃€?',
        options: [
          _ChoiceItem(
            value: _OnlineAction.createRoom,
            title: '鍒涘缓鎴块棿',
            detail: '鍏堝垱寤鸿嚜宸辩殑鐗屾锛屽啀閭€璇峰ソ鍙嬫垨琛ュ叆 DouZero銆?',
          ),
          _ChoiceItem(
            value: _OnlineAction.joinRoom,
            title: '杩涘叆鎴块棿',
            detail: '杈撳叆 6 浣嶆埧闂村彿鍗冲彲鍔犲叆瀵瑰簲鐗屾銆?',
          ),
          _ChoiceItem(
            value: _OnlineAction.freeMatch,
            title: '鑷敱鍖归厤',
            detail: '鍖归厤婊?3 浜哄悗鐩存帴寮€灞€锛屼笉缁忚繃鍑嗗闃舵銆?',
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRoomCode() async {
    return showDialog<String>(
      context: context,
      builder: (context) => const _ResponsiveJoinRoomDialog(),
    );
  }

  Future<void> _showFriendCenter() async {
    final media = MediaQuery.sizeOf(context);
    const designWidth = 1320.0;
    const designHeight = 760.0;
    final stageScale = math.min(
      media.width / designWidth,
      media.height / designHeight,
    );
    await showFriendCenterDialog(
      context,
      controller: widget.controller,
      stageScale: stageScale,
      stageWidth: designWidth,
      stageHeight: designHeight,
    );
  }

  Future<void> _showWinRate() async {
    final profile = widget.controller.profile;
    if (profile == null) {
      return;
    }
    if (mounted) {
      await _showResponsiveWinRateDialog(profile);
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

  // ignore: unused_element
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
                      progress: profile.landlordWinRate,
                      record: _formatBattleRecord(
                        wins: profile.landlordWins,
                        games: profile.landlordGames,
                      ),
                      accent: const Color(0xFF2B7FFF),
                    ),
                    _WinRateStatCard(
                      title: '农民胜率',
                      rate: _formatRate(profile.farmerWinRate),
                      progress: profile.farmerWinRate,
                      record: _formatBattleRecord(
                        wins: profile.farmerWins,
                        games: profile.farmerGames,
                      ),
                      accent: const Color(0xFF3BB58F),
                    ),
                    _WinRateStatCard(
                      title: '总体胜率',
                      rate: _formatRate(profile.overallWinRate),
                      progress: profile.overallWinRate,
                      record: _formatBattleRecord(
                        wins: profile.totalWins,
                        games: profile.totalGames,
                      ),
                      accent: const Color(0xFF4F7BFF),
                    ),
                  ],
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

  double _stageScale() {
    final media = MediaQuery.sizeOf(context);
    const designWidth = 1320.0;
    const designHeight = 760.0;
    return math.min(
      media.width / designWidth,
      media.height / designHeight,
    );
  }

  Future<void> _showProfileDialog() async {
    final profile = widget.controller.profile;
    if (profile == null) {
      return;
    }
    final stageScale = _stageScale();
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x33173A59),
      builder: (context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final currentProfile = widget.controller.profile;
          if (currentProfile == null) {
            return const SizedBox.shrink();
          }
          final displayName = currentProfile.displayName;
          final avatarLabel =
              (displayName.isEmpty ? 'P' : displayName.substring(0, 1))
                  .toUpperCase();
          final messenger = ScaffoldMessenger.of(context);

          void showProfileMessage(String successMessage) {
            final errorText = widget.controller.errorText;
            if (errorText != null && errorText.isNotEmpty) {
              messenger.showSnackBar(SnackBar(content: Text(errorText)));
              widget.controller.clearError();
              return;
            }
            messenger.showSnackBar(SnackBar(content: Text(successMessage)));
          }
          Future<void> handleNicknameEdit() async {
            final nickname = await showDialog<String>(
              context: context,
              barrierColor: const Color(0x33173A59),
              builder: (context) => _EditNicknameDialog(
                initialValue: currentProfile.nickname,
                stageScale: stageScale,
              ),
            );
            if (!mounted) {
              return;
            }
            if (nickname != null) {
              if (nickname == currentProfile.nickname) {
                return;
              }
              await widget.controller.updateNickname(nickname);
              if (!mounted) {
                return;
              }
              if (widget.controller.errorText != null) {
                showProfileMessage('');
                return;
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('昵称已经更新。')),
              );
            }
          }

          Future<void> handlePasswordEdit() async {
            final messenger = ScaffoldMessenger.of(context);
            final passwordChange = await showDialog<_PasswordChangeResult>(
              context: context,
              barrierColor: const Color(0x33173A59),
              builder: (context) => _ChangePasswordDialog(
                account: currentProfile.account,
                stageScale: stageScale,
              ),
            );
            if (!mounted) {
              return;
            }
            if (passwordChange != null) {
              await widget.controller.changePassword(
                passwordChange.currentPassword,
                passwordChange.newPassword,
              );
              if (!mounted) {
                return;
              }
              if (widget.controller.errorText != null) {
                showProfileMessage('');
                return;
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('密码修改请求已提交。')),
              );
            }
          }

          return _ProfileDialogSurface(
            profile: currentProfile,
            avatarLabel: avatarLabel,
            stageScale: stageScale,
            onClose: () => Navigator.of(context).pop(),
            onEditNickname: handleNicknameEdit,
            onEditPassword: handlePasswordEdit,
          );
          /*
          return ResponsiveDialogPanel(
            maxWidth: 560,
            maxHeight: math.min(720.0, media.height * 0.88),
            widthFactor: 0.86,
            heightFactor: 0.86,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            radius: 28,
            stageScale: stageScale,
            scrollable: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF2B7FFF),
                      child: Text(
                        avatarLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Color(0xFF173A59),
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '账号：${currentProfile.account}',
                            style: const TextStyle(
                              color: Color(0xFF587790),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileFieldCard(
                        label: '昵称',
                        value:
                            currentProfile.nickname.isEmpty ? '未设置' : currentProfile.nickname,
                        icon: Icons.badge_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfileFieldCard(
                        label: '金币',
                        value: '${currentProfile.coins}',
                        icon: Icons.paid_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nickname = await showDialog<String>(
                            context: context,
                            barrierColor: const Color(0x33173A59),
                            builder: (context) => _EditNicknameDialog(
                              initialValue: currentProfile.nickname,
                              stageScale: stageScale,
                            ),
                          );
                          if (!mounted) {
                            return;
                          }
                          if (nickname != null) {
                            widget.controller.updateNicknameLocal(nickname);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('昵称已更新')),
                            );
                          }
                        },
                        child: const Text('修改昵称'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final password = await showDialog<String>(
                            context: context,
                            barrierColor: const Color(0x33173A59),
                            builder: (context) => _ChangePasswordDialog(
                              account: currentProfile.account,
                              stageScale: stageScale,
                            ),
                          );
                          if (!mounted) {
                            return;
                          }
                          if (password != null) {
                            await widget.controller
                                .resetPassword(currentProfile.account, password);
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              const SnackBar(content: Text('密码已提交更新')),
                            );
                          }
                        },
                        child: const Text('修改密码'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          */
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final profile = controller.profile;
    final displayName = profile?.displayName ?? '牌友';
    final avatarLabel = (displayName.isEmpty ? 'P' : displayName.substring(0, 1))
        .toUpperCase();
    final coins = profile?.coins ?? 0;

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
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFD7EBFF)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: _showProfileDialog,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF2B7FFF),
                                      child: Text(
                                        avatarLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            color: Color(0xFF173A59),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          profile?.account ?? '-',
                                          style: const TextStyle(
                                            color: Color(0xFF587790),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: Color(0xFF587790),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF3CC), Color(0xFFFFE6A4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: const Color(0xFFFFD773)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.paid_rounded,
                                size: 18,
                                color: Color(0xFF8A5A00),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$coins',
                                style: const TextStyle(
                                  color: Color(0xFF8A5A00),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _showFriendCenter,
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.groups_rounded, size: 18),
                              if (widget.controller.pendingFriendRequestCount > 0)
                                const Positioned(
                                  right: -2,
                                  top: -2,
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Color(0xFFE5534B),
                                  ),
                                ),
                            ],
                          ),
                          label: const Text('好友'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: _showWinRate,
                          icon: const Icon(Icons.emoji_events_rounded, size: 18),
                          label: const Text('胜率'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('退出'),
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
                                    controller.hasResumeRoom
                                        ? '你有一局正在进行的牌局，可直接恢复对局。'
                                        : '状态正常，随时可以开始对局。',
                                    style: TextStyle(
                                      color: !controller.hasResumeRoom
                                          ? const Color(0xFF587790)
                                          : const Color(0xFF2B7FFF),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (controller.hasResumeRoom) ...[
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: controller.resumeRoom,
                                      child: const Text('恢复对局'),
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
                                        controller.hasResumeRoom ? '恢复对局' : '真人匹配',
                                    subtitle: controller.hasResumeRoom
                                        ? '返回当前仍在进行中的牌局，继续完成这桌对局。'
                                        : '支持创建房间、进入房间与自由匹配。',
                                    accent: const Color(0xFF4FB9FF),
                                    buttonLabel:
                                        controller.hasResumeRoom ? '恢复对局' : '选择方式',
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
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                minimumSize: const Size.fromHeight(58),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
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

class _ProfileDialogSurface extends StatelessWidget {
  const _ProfileDialogSurface({
    required this.profile,
    required this.avatarLabel,
    required this.stageScale,
    required this.onClose,
    required this.onEditNickname,
    required this.onEditPassword,
  });

  final UserProfile profile;
  final String avatarLabel;
  final double stageScale;
  final VoidCallback onClose;
  final Future<void> Function() onEditNickname;
  final Future<void> Function() onEditPassword;

  @override
  Widget build(BuildContext context) {
    return StageRelativeDialogPanel(
      stageWidth: 1320,
      stageHeight: 760,
      stageScale: stageScale,
      widthRatio: 0.45,
      heightRatio: 0.75,
      padding: EdgeInsets.zero,
      radius: 34,
      fillHeight: true,
      scrollable: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final compactLayout = width < 560 || height < 620;
          final stackedActions = width < 640;
          final gap = compactLayout ? 10.0 : 12.0;

          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: compactLayout
                      ? const EdgeInsets.fromLTRB(18, 18, 18, 16)
                      : const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileHeroCard(
                        avatarLabel: avatarLabel,
                        displayName: profile.displayName,
                        account: profile.account,
                        compact: compactLayout,
                        onClose: onClose,
                        metrics: [
                          _ProfileHeroMetric(
                            label: '金币',
                            value: '${profile.coins}',
                            icon: Icons.paid_rounded,
                          ),
                          _ProfileHeroMetric(
                            label: '总场次',
                            value: '${profile.totalGames}',
                            icon: Icons.sports_esports_rounded,
                          ),
                          _ProfileHeroMetric(
                            label: '总胜率',
                            value: _formatRate(profile.overallWinRate),
                            icon: Icons.auto_graph_rounded,
                          ),
                        ],
                      ),
                      SizedBox(height: gap),
                      _FixedTwoColumnGrid(
                        gap: gap,
                        children: [
                          _ProfileFieldCard(
                            label: '昵称',
                            value: profile.nickname.isEmpty ? '未设置' : profile.nickname,
                            icon: Icons.badge_rounded,
                            accent: const Color(0xFF2B7FFF),
                            subtitle: '当前大厅展示名称',
                          ),
                          _ProfileFieldCard(
                            label: '账号',
                            value: profile.account,
                            icon: Icons.alternate_email_rounded,
                            accent: const Color(0xFF4F7BFF),
                            subtitle: '登录与好友搜索使用',
                          ),
                          _ProfileFieldCard(
                            label: '总胜局',
                            value: '${profile.totalWins}',
                            icon: Icons.emoji_events_rounded,
                            accent: const Color(0xFFF0A11A),
                            subtitle: '所有角色累计胜场',
                          ),
                          _ProfileFieldCard(
                            label: '地主胜率',
                            value: _formatRate(profile.landlordWinRate),
                            icon: Icons.workspace_premium_rounded,
                            accent: const Color(0xFF2B7FFF),
                            subtitle:
                                '${profile.landlordWins} 胜 / ${profile.landlordGames} 局',
                          ),
                          _ProfileFieldCard(
                            label: '农民胜率',
                            value: _formatRate(profile.farmerWinRate),
                            icon: Icons.agriculture_rounded,
                            accent: const Color(0xFF2FA772),
                            subtitle: '${profile.farmerWins} 胜 / ${profile.farmerGames} 局',
                          ),
                          _ProfileFieldCard(
                            label: '玩家编号',
                            value: profile.userId,
                            icon: Icons.fingerprint_rounded,
                            accent: const Color(0xFF7A8CA7),
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: profile.userId),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制玩家编号')),
                              );
                            },
                            subtitle: '点击卡片可复制，用于服务端唯一识别',
                          ),
                        ],
                      ),
                      SizedBox(height: gap),
                      _ProfileSectionCard(
                        icon: Icons.tune_rounded,
                        title: '快捷操作',
                        subtitle: '昵称会立即同步到当前大厅展示，密码修改会提交到账户系统。',
                        compact: compactLayout,
                        child: stackedActions
                            ? Column(
                                children: [
                                  _ProfileActionCard(
                                    title: '修改昵称',
                                    detail: '调整大厅展示名称与好友列表显示效果。',
                                    icon: Icons.edit_rounded,
                                    accent: const Color(0xFF2B7FFF),
                                    onTap: onEditNickname,
                                  ),
                                  SizedBox(height: gap),
                                  _ProfileActionCard(
                                    title: '修改密码',
                                    detail: '更新当前账号的登录密码，提升账户安全。',
                                    icon: Icons.lock_reset_rounded,
                                    accent: const Color(0xFF1C8F74),
                                    onTap: onEditPassword,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _ProfileActionCard(
                                      title: '修改昵称',
                                      detail: '调整大厅展示名称与好友列表显示效果。',
                                      icon: Icons.edit_rounded,
                                      accent: const Color(0xFF2B7FFF),
                                      onTap: onEditNickname,
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Expanded(
                                    child: _ProfileActionCard(
                                      title: '修改密码',
                                      detail: '更新当前账号的登录密码，提升账户安全。',
                                      icon: Icons.lock_reset_rounded,
                                      accent: const Color(0xFF1C8F74),
                                      onTap: onEditPassword,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      SizedBox(height: gap),
                      _ProfileSectionCard(
                        icon: Icons.insights_rounded,
                        title: '资料摘要',
                        subtitle: '继续对局后，胜率和对局数据会自动刷新到这里。',
                        compact: compactLayout,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ProfileInfoBadge(
                              icon: Icons.trending_up_rounded,
                              text: profile.landlordWinRate >= profile.farmerWinRate
                                  ? '当前地主表现更好'
                                  : '当前农民表现更好',
                            ),
                            _ProfileInfoBadge(
                              icon: Icons.local_fire_department_rounded,
                              text: '总胜场 ${profile.totalWins}',
                            ),
                            _ProfileInfoBadge(
                              icon: Icons.schedule_rounded,
                              text: '累计对局 ${profile.totalGames}',
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

class _ProfileHeroMetric {
  const _ProfileHeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.avatarLabel,
    required this.displayName,
    required this.account,
    required this.compact,
    required this.onClose,
    required this.metrics,
  });

  final String avatarLabel;
  final String displayName;
  final String account;
  final bool compact;
  final VoidCallback onClose;
  final List<_ProfileHeroMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
          : const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 26 : 30),
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FCFF), Color(0xFFE9F4FF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD7EBFF)),
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
                width: compact ? 58 : 64,
                height: compact ? 58 : 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF82D5FF), Color(0xFF2B7FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 24 : 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: const Color(0xFF173A59),
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 23 : 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.88),
                        border: Border.all(color: const Color(0xFFD7EBFF)),
                      ),
                      child: Text(
                        '账号 $account',
                        style: const TextStyle(
                          color: Color(0xFF587790),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
              for (final metric in metrics)
                _ProfileInfoBadge(
                  icon: metric.icon,
                  text: '${metric.label} ${metric.value}',
                  emphasized: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FixedTwoColumnGrid extends StatelessWidget {
  const _FixedTwoColumnGrid({
    required this.children,
    this.gap = 12,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rowCount = (children.length / 2).ceil();

    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[rowIndex * 2]),
                SizedBox(width: gap),
                Expanded(
                  child: rowIndex * 2 + 1 < children.length
                      ? children[rowIndex * 2 + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (rowIndex != rowCount - 1) SizedBox(height: gap),
        ],
      ],
    );
  }
}

class _ProfileFieldCard extends StatelessWidget {
  const _ProfileFieldCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? subtitle;
  final FutureOr<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: const Color(0xFFF9FCFF),
      border: Border.all(color: const Color(0xFFD7EBFF)),
    );

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF587790),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B8399),
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 10),
            const Icon(
              Icons.content_copy_rounded,
              color: Color(0xFF6B8399),
              size: 18,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: body);
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            final result = onTap!.call();
            if (result is Future<void>) {
              unawaited(result);
            }
          },
          child: body,
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
          : const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
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
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => onTap(),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF173A59),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFF587790),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoBadge extends StatelessWidget {
  const _ProfileInfoBadge({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  final IconData icon;
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: emphasized
            ? const Color(0xFFEAF5FF)
            : const Color(0xFFF3F7FB),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: emphasized
                ? const Color(0xFF2B7FFF)
                : const Color(0xFF587790),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: emphasized
                  ? const Color(0xFF245E90)
                  : const Color(0xFF587790),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditNicknameDialog extends StatefulWidget {
  const _EditNicknameDialog({
    required this.initialValue,
    required this.stageScale,
  });

  final String initialValue;
  final double stageScale;

  @override
  State<_EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<_EditNicknameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final nickname = _controller.text.trim();
    if (nickname.isEmpty) {
      setState(() => _errorText = '请输入昵称');
      return;
    }
    if (nickname.length > 10) {
      setState(() => _errorText = '昵称过长，请控制在 10 个字以内');
      return;
    }
    Navigator.of(context).pop(nickname);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogPanel(
      maxWidth: 440,
      maxHeight: 420,
      widthFactor: 0.86,
      heightFactor: 0.72,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      radius: 26,
      stageScale: widget.stageScale,
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '修改昵称',
                  style: TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '昵称将用于大厅与对局展示。',
            style: TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.badge_rounded),
              hintText: '请输入昵称',
              filled: true,
              fillColor: const Color(0xFFF3F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFFFF1EE),
              ),
              child: Text(
                _errorText!,
                style: const TextStyle(
                  color: Color(0xFFB54A3D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text('保存昵称'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordChangeResult {
  const _PasswordChangeResult({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({
    required this.account,
    required this.stageScale,
  });

  final String account;
  final double stageScale;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final currentPassword = _currentPasswordController.text;
    final password = _newPasswordController.text;
    final confirm = _confirmController.text;
    if (currentPassword.isEmpty) {
      setState(() => _errorText = '请输入当前密码');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorText = '请输入新密码');
      return;
    }
    if (password == currentPassword) {
      setState(() => _errorText = '新密码需要和当前密码不同');
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = '两次输入的新密码不一致');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorText = '请输入新密码');
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = '两次输入的密码不一致');
      return;
    }
    Navigator.of(context).pop(
      _PasswordChangeResult(
        currentPassword: currentPassword,
        newPassword: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialogPanel(
      maxWidth: 480,
      maxHeight: 520,
      widthFactor: 0.86,
      heightFactor: 0.78,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      radius: 26,
      stageScale: widget.stageScale,
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '修改密码',
                  style: TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '账号：${widget.account}',
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_clock_outlined),
              hintText: '请输入当前密码',
              filled: true,
              fillColor: const Color(0xFFF3F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              hintText: '请输入新密码',
              filled: true,
              fillColor: const Color(0xFFF3F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmController,
            obscureText: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.verified_user_outlined),
              hintText: '请再次输入新密码',
              filled: true,
              fillColor: const Color(0xFFF3F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFFFF1EE),
              ),
              child: Text(
                _errorText!,
                style: const TextStyle(
                  color: Color(0xFFB54A3D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text('确认修改'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WinRateStatCard extends StatelessWidget {
  const _WinRateStatCard({
    required this.title,
    required this.rate,
    required this.progress,
    required this.record,
    required this.accent,
    this.compact = false,
  });

  final String title;
  final String rate;
  final double progress;
  final String record;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 12, 12, 10)
          : const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
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
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 5 : 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: accent.withValues(alpha: 0.12),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: accent,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rate,
              style: TextStyle(
                color: const Color(0xFF173A59),
                fontSize: compact ? 22 : 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: compact ? 7 : 8,
              backgroundColor: accent.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            record,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF587790),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            progress == 0
                ? '继续完成对局后，这里会形成更稳定的统计。'
                : '当前数据会在每局结束后自动更新。',
            style: TextStyle(
              color: const Color(0xFF7A8CA7),
              fontSize: compact ? 11 : 11.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _JoinRoomDialog extends StatefulWidget {
  const _JoinRoomDialog();

  @override
  State<_JoinRoomDialog> createState() => _JoinRoomDialogState();
}

// ignore: unused_element
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

// ignore: unused_element
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

extension on _LobbyPageState {
  Future<void> _showResponsiveWinRateDialog(UserProfile profile) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x33173A59),
      builder: (context) {
        final media = MediaQuery.sizeOf(context);
        const designWidth = 1320.0;
        const designHeight = 760.0;
        final stageScale = math.min(
          media.width / designWidth,
          media.height / designHeight,
        );
        final compactLayout = media.height < 560 || media.width < 720;
        return _WinRateDialogSurface(
          profile: profile,
          stageScale: stageScale,
          compactLayout: compactLayout,
        );
        /*
        final padding = compactLayout
            ? const EdgeInsets.fromLTRB(18, 18, 18, 16)
            : const EdgeInsets.fromLTRB(24, 24, 24, 22);
        final radius = compactLayout ? 30.0 : 34.0;
        return StageRelativeDialogPanel(
          stageWidth: designWidth,
          stageHeight: designHeight,
          stageScale: stageScale,
          widthRatio: 1 / 3,
          heightRatio: 0.65,
          fillHeight: true,
          padding: padding,
          radius: radius,
          scrollable: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final compactSummary = width < 420;
              final compactHeader =
                  compactLayout || width < 420 || constraints.maxHeight < 520;
              final titleSize = compactHeader ? 22.0 : 24.0;
              final subtitleSize = compactHeader ? 13.0 : 14.0;
              final headerGap = compactHeader ? 4.0 : 6.0;
              final sectionGap = compactHeader ? 8.0 : 12.0;
              final gridGap = compactHeader ? 10.0 : 12.0;
              final columns = width >= 520
                  ? 3
                  : width >= 360
                      ? 2
                      : 1;
              final tileWidth =
                  (width - (columns - 1) * gridGap) / columns.toDouble();
              final tileHeight = compactHeader ? 118.0 : 132.0;
              final childAspectRatio = tileWidth / tileHeight;
              return SizedBox(
                height: constraints.maxHeight,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                            Text(
                              '个人战绩',
                              style: TextStyle(
                                color: const Color(0xFF173A59),
                                fontSize: titleSize,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: headerGap),
                            Text(
                              '${profile.displayName} 的地主、农民与总体胜率',
                              style: TextStyle(
                                color: const Color(0xFF587790),
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  Container(
                    width: double.infinity,
                    padding: compactHeader
                        ? const EdgeInsets.fromLTRB(12, 12, 12, 10)
                        : const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(compactHeader ? 20 : 22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF2F8FF), Color(0xFFE3F1FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0xFFD7EBFF)),
                    ),
                    child: compactSummary
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OverallRateBadge(
                                rate: _formatRate(profile.overallWinRate),
                              ),
                              const SizedBox(height: 12),
                              _OverallRateSummary(profile: profile),
                            ],
                          )
                        : Row(
                            children: [
                              _OverallRateBadge(
                                rate: _formatRate(profile.overallWinRate),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _OverallRateSummary(profile: profile),
                              ),
                            ],
                          ),
                  ),
                  SizedBox(height: sectionGap),
                  GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: gridGap,
                    mainAxisSpacing: gridGap,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _WinRateStatCard(
                        title: '地主胜率',
                        rate: _formatRate(profile.landlordWinRate),
                        record: _formatBattleRecord(
                          wins: profile.landlordWins,
                          games: profile.landlordGames,
                        ),
                        accent: const Color(0xFF2B7FFF),
                        compact: compactHeader,
                      ),
                      _WinRateStatCard(
                        title: '农民胜率',
                        rate: _formatRate(profile.farmerWinRate),
                        record: _formatBattleRecord(
                          wins: profile.farmerWins,
                          games: profile.farmerGames,
                        ),
                        accent: const Color(0xFF3BB58F),
                        compact: compactHeader,
                      ),
                      _WinRateStatCard(
                        title: '总体胜率',
                        rate: _formatRate(profile.overallWinRate),
                        record: _formatBattleRecord(
                          wins: profile.totalWins,
                          games: profile.totalGames,
                        ),
                        accent: const Color(0xFF4F7BFF),
                        compact: compactHeader,
                      ),
                    ],
                  ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
        */
      },
    );
  }
}

class _WinRateDialogSurface extends StatelessWidget {
  const _WinRateDialogSurface({
    required this.profile,
    required this.stageScale,
    required this.compactLayout,
  });

  final UserProfile profile;
  final double stageScale;
  final bool compactLayout;

  @override
  Widget build(BuildContext context) {
    return StageRelativeDialogPanel(
      stageWidth: 1320,
      stageHeight: 760,
      stageScale: stageScale,
      widthRatio: 0.45,
      heightRatio: 0.75,
      fillHeight: true,
      padding: EdgeInsets.zero,
      radius: compactLayout ? 30 : 34,
      scrollable: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final compactHeader = compactLayout || width < 520 || height < 580;
          final gap = compactHeader ? 10.0 : 12.0;

          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: compactHeader
                      ? const EdgeInsets.fromLTRB(18, 18, 18, 16)
                      : const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileSectionCard(
                        icon: Icons.query_stats_rounded,
                        title: '个人战绩',
                        subtitle: '${profile.displayName} 的地主与农民胜率概览。',
                        compact: compactHeader,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _ProfileInfoBadge(
                                    icon: Icons.emoji_events_rounded,
                                    text: '总胜场 ${profile.totalWins}',
                                    emphasized: true,
                                  ),
                                  _ProfileInfoBadge(
                                    icon: Icons.sports_esports_rounded,
                                    text: '总对局 ${profile.totalGames}',
                                  ),
                                  _ProfileInfoBadge(
                                    icon: Icons.analytics_rounded,
                                    text: _buildWinRateFocus(profile),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: gap),
                      _WinRateOverviewCard(
                        profile: profile,
                        compact: compactHeader,
                      ),
                      SizedBox(height: gap),
                      _FixedTwoColumnGrid(
                        gap: gap,
                        children: [
                          _WinRateStatCard(
                            title: '地主胜率',
                            rate: _formatRate(profile.landlordWinRate),
                            progress: profile.landlordWinRate,
                            record: _formatBattleRecord(
                              wins: profile.landlordWins,
                              games: profile.landlordGames,
                            ),
                            accent: const Color(0xFF2B7FFF),
                            compact: compactHeader,
                          ),
                          _WinRateStatCard(
                            title: '农民胜率',
                            rate: _formatRate(profile.farmerWinRate),
                            progress: profile.farmerWinRate,
                            record: _formatBattleRecord(
                              wins: profile.farmerWins,
                              games: profile.farmerGames,
                            ),
                            accent: const Color(0xFF2FA772),
                            compact: compactHeader,
                          ),
                        ],
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

class _WinRateOverviewCard extends StatelessWidget {
  const _WinRateOverviewCard({
    required this.profile,
    required this.compact,
  });

  final UserProfile profile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 16, 16, 14)
          : const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 24 : 28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF2F8FF), Color(0xFFE5F2FF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OverallRateSummaryPanel(
            profile: profile,
            compact: compact,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileInfoBadge(
                icon: Icons.workspace_premium_rounded,
                text: '地主 ${_formatRate(profile.landlordWinRate)}',
                emphasized: true,
              ),
              _ProfileInfoBadge(
                icon: Icons.agriculture_rounded,
                text: '农民 ${_formatRate(profile.farmerWinRate)}',
              ),
              _ProfileInfoBadge(
                icon: Icons.flag_rounded,
                text: profile.totalGames == 0 ? '还没有战绩记录' : _buildWinRateFocus(profile),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverallRateSummaryPanel extends StatelessWidget {
  const _OverallRateSummaryPanel({
    required this.profile,
    this.compact = false,
  });

  final UserProfile profile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '战绩概览',
          style: TextStyle(
            color: const Color(0xFF173A59),
            fontSize: compact ? 17 : 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '共 ${profile.totalGames} 局，胜 ${profile.totalWins} 局',
          style: TextStyle(
            color: const Color(0xFF587790),
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.totalGames == 0
              ? '当前还没有历史对局数据。'
              : '继续对局后，这里的统计会自动刷新并保持最新。',
          style: TextStyle(
            color: const Color(0xFF587790),
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ResponsiveDialogFrame extends StatelessWidget {
  const _ResponsiveDialogFrame({
    required this.maxWidth,
    required this.padding,
    required this.radius,
    required this.child,
  });

  final double maxWidth;
  final EdgeInsets padding;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    const designWidth = 1320.0;
    const designHeight = 760.0;
    final stageScale = math.min(
      media.width / designWidth,
      media.height / designHeight,
    );
    return ResponsiveDialogPanel(
      maxWidth: maxWidth,
      padding: padding,
      radius: radius,
      stageScale: stageScale,
      child: child,
    );
  }
}

// ignore: unused_element
class _OverallRateSummary extends StatelessWidget {
  const _OverallRateSummary({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
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
              : '后续对局后会自动更新这里的统计',
          style: const TextStyle(
            color: Color(0xFF587790),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ResponsiveChoiceDialog<T> extends StatelessWidget {
  const _ResponsiveChoiceDialog({
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final String title;
  final String subtitle;
  final List<_ChoiceItem<T>> options;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    const designWidth = 1320.0;
    const designHeight = 760.0;
    final stageScale = math.min(
      media.width / designWidth,
      media.height / designHeight,
    );
    final compactLayout = media.height < 560 || media.width < 420;
    final titleSize = compactLayout ? 22.0 : 24.0;
    final subtitleSize = compactLayout ? 13.0 : 14.0;
    return StageRelativeDialogPanel(
      stageWidth: designWidth,
      stageHeight: designHeight,
      stageScale: stageScale,
      widthRatio: 0.45,
      heightRatio: 0.75,
      fillHeight: true,
      padding: compactLayout
          ? const EdgeInsets.fromLTRB(18, 18, 18, 16)
          : const EdgeInsets.fromLTRB(24, 22, 24, 20),
      radius: compactLayout ? 30 : 34,
      scrollable: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: constraints.maxHeight,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF173A59),
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: compactLayout ? 4 : 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFF587790),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: compactLayout ? 14 : 18),
                  for (var index = 0; index < options.length; index++) ...[
                    _ChoiceCard<T>(item: options[index]),
                    if (index != options.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard<T> extends StatelessWidget {
  const _ChoiceCard({required this.item});

  final _ChoiceItem<T> item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).pop(item.value),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FCFF), Color(0xFFF0F8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFD7EBFF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFF173A59),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.detail,
                    style: const TextStyle(
                      color: Color(0xFF587790),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0x142B7FFF),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF2B7FFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveJoinRoomDialog extends StatefulWidget {
  const _ResponsiveJoinRoomDialog();

  @override
  State<_ResponsiveJoinRoomDialog> createState() =>
      _ResponsiveJoinRoomDialogState();
}

class _ResponsiveJoinRoomDialogState extends State<_ResponsiveJoinRoomDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _controller.text.trim().length == 6;
    return _ResponsiveDialogFrame(
      maxWidth: 430,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      radius: 28,
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
                    fontSize: 26,
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
          const SizedBox(height: 6),
          const Text(
            '输入 6 位房间号即可进入对应牌桌。',
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
            decoration: InputDecoration(
              hintText: '请输入 6 位房间号',
              filled: true,
              fillColor: const Color(0xFFF8FCFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
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
                borderSide: const BorderSide(
                  color: Color(0xFF2B7FFF),
                  width: 1.4,
                ),
              ),
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
    );
  }
}

// ignore: unused_element
class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final compactLayout = media.height < 560 || media.width < 720;
    const designWidth = 1320.0;
    const designHeight = 760.0;
    final stageScale = math.min(
      media.width / designWidth,
      media.height / designHeight,
    );
    return ResponsiveBottomSheetPanel(
      maxWidth: compactLayout ? 560 : 780,
      maxHeight: compactLayout ? 520 : 620,
      widthFactor: compactLayout ? 0.88 : 0.94,
      heightFactor: compactLayout ? 0.76 : 0.82,
      padding: compactLayout
          ? const EdgeInsets.fromLTRB(14, 14, 14, 14)
          : const EdgeInsets.fromLTRB(18, 18, 18, 18),
      radius: compactLayout ? 22 : 28,
      stageScale: stageScale,
      child: child,
    );
  }
}

// ignore: unused_element
class _OnlineActionSheet extends StatelessWidget {
  const _OnlineActionSheet();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final compactLayout = media.height < 560 || media.width < 720;
    final titleSize = compactLayout ? 20.0 : 22.0;
    final subtitleSize = compactLayout ? 12.0 : 13.0;
    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '真人对局',
            style: TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          SizedBox(height: compactLayout ? 4 : 6),
          Text(
            '选择创建房间、进入房间或自由匹配，手机 Web 会优先使用更紧凑的弹出面板。',
            style: TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: subtitleSize,
              height: 1.45,
            ),
          ),
          SizedBox(height: compactLayout ? 10 : 14),
          const _ChoiceCard<_OnlineAction>(
            item: _ChoiceItem(
              value: _OnlineAction.createRoom,
              title: '创建房间',
              detail: '先创建自己的牌桌，再邀请好友或补入机器人。',
            ),
          ),
          const SizedBox(height: 10),
          const _ChoiceCard<_OnlineAction>(
            item: _ChoiceItem(
              value: _OnlineAction.joinRoom,
              title: '进入房间',
              detail: '输入 6 位房间号即可加入对应牌桌。',
            ),
          ),
          const SizedBox(height: 10),
          const _ChoiceCard<_OnlineAction>(
            item: _ChoiceItem(
              value: _OnlineAction.freeMatch,
              title: '自由匹配',
              detail: '匹配满 3 人后直接开局，不经过准备阶段。',
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _JoinRoomSheet extends StatefulWidget {
  const _JoinRoomSheet();

  @override
  State<_JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends State<_JoinRoomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final compactLayout = media.height < 560 || media.width < 720;
    final titleSize = compactLayout ? 20.0 : 22.0;
    final subtitleSize = compactLayout ? 12.0 : 13.0;
    final canSubmit = _controller.text.trim().length == 6;
    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '进入房间',
                  style: TextStyle(
                    color: const Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                    fontSize: titleSize,
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
          SizedBox(height: compactLayout ? 4 : 6),
          Text(
            '输入 6 位房间号后即可加入对应牌桌。',
            style: TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: subtitleSize,
              height: 1.45,
            ),
          ),
          SizedBox(height: compactLayout ? 10 : 14),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              hintText: '请输入 6 位房间号',
              filled: true,
              fillColor: const Color(0xFFF8FCFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
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
                borderSide: const BorderSide(
                  color: Color(0xFF2B7FFF),
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSubmit
                  ? () => Navigator.of(context).pop(_controller.text.trim())
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text('确认进入'),
            ),
          ),
        ],
      ),
    );
  }
}

String _buildWinRateFocus(UserProfile profile) {
  if (profile.totalGames == 0) {
    return '还没有形成有效偏好';
  }
  if (profile.landlordWinRate == profile.farmerWinRate) {
    return '当前两种身份表现均衡';
  }
  return profile.landlordWinRate > profile.farmerWinRate
      ? '当前更擅长地主节奏'
      : '当前更擅长农民配合';
}

String _formatRate(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _formatBattleRecord({
  required int wins,
  required int games,
}) {
  if (games == 0) {
    return '0 胜 / 0 局';
  }
  return '$wins 胜 / $games 局';
}

// ignore: unused_element
String _formatRecord({
  required int wins,
  required int games,
}) {
  if (games == 0) {
    return '0 胜 / 0 局';
  }
  return '$wins 胜 / $games 局';
}
