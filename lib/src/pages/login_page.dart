import 'dart:async';

import 'package:flutter/material.dart';

import '../services/voice_cue_service.dart';
import '../state/app_controller.dart';
import '../utils/app_log.dart';
import '../widgets/fixed_stage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nicknameController = TextEditingController(text: '玩家1');
  final _accountController = TextEditingController(text: 'player1');
  final _passwordController = TextEditingController(text: 'player1');
  final _voice = VoiceCueService();
  bool _registerMode = false;

  @override
  void initState() {
    super.initState();
    appLog(AppLogLevel.info, 'login_page', 'initState');
    unawaited(_voice.stopBackgroundMusic(force: true));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    unawaited(_voice.dispose());
    super.dispose();
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    final account = _accountController.text.trim();
    final password = _passwordController.text;
    if (_registerMode) {
      if (nickname.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入昵称')),
        );
        return;
      }
      if (nickname.runes.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称请控制在 5 个字以内')),
        );
        return;
      }
      await widget.controller.register(account, nickname, password);
      if (!mounted || widget.controller.errorText != null) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    await widget.controller.login(account, password);
  }

  Future<void> _showResetPasswordDialog() async {
    final result = await showDialog<_PasswordResetResult>(
      context: context,
      builder: (context) => const _PasswordResetDialog(),
    );
    if (result == null || !mounted) {
      return;
    }
    await widget.controller.resetPassword(result.account, result.newPassword);
    if (!mounted || widget.controller.errorText != null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('密码已更新，请使用新密码登录')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FixedStageBackdrop(
        child: FixedStage(
          width: 1320,
          height: 760,
          padding: const EdgeInsets.all(14),
          child: StagePanel(
            padding: const EdgeInsets.all(24),
            radius: 34,
            child: Row(
              children: [
                const Expanded(
                  flex: 7,
                  child: _LoginHero(),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 470,
                  child: _AuthCard(
                    registerMode: _registerMode,
                    controller: widget.controller,
                    nicknameController: _nicknameController,
                    accountController: _accountController,
                    passwordController: _passwordController,
                    onToggleMode: () {
                      setState(() => _registerMode = !_registerMode);
                    },
                    onForgotPassword: _showResetPasswordDialog,
                    onSubmit: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
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
              '三端同步牌局',
              style: TextStyle(
                color: Color(0xFF2B7FFF),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '欢乐斗地主',
            style: TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: 72,
              height: 0.98,
            ),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            width: 560,
            child: Text(
              '登录后直接进入大厅，选择模式即可开始对局。',
              style: TextStyle(
                color: Color(0xFF587790),
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroChip(label: 'AI策略'),
              _HeroChip(label: '实时分析'),
              _HeroChip(label: '真人对局'),
              _HeroChip(label: '断线可续'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2F8FF), Color(0xFFE3F1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FeatureLine(
                          title: '快捷登录',
                          detail: '快速注册账号即可登录。',
                        ),
                        SizedBox(height: 14),
                        _FeatureLine(
                          title: '对局顺畅',
                          detail: 'AI策略、真人对局与实时提示一体衔接。',
                        ),
                        SizedBox(height: 14),
                        _FeatureLine(
                          title: '三端同步',
                          detail: '手机、网页、桌面所有信息同步。',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Container(
                    width: 164,
                    height: 164,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(38),
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
                      size: 68,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.registerMode,
    required this.controller,
    required this.nicknameController,
    required this.accountController,
    required this.passwordController,
    required this.onToggleMode,
    required this.onForgotPassword,
    required this.onSubmit,
  });

  final bool registerMode;
  final AppController controller;
  final TextEditingController nicknameController;
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final VoidCallback onToggleMode;
  final Future<void> Function() onForgotPassword;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return StagePanel(
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 26),
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthModeTabs(
            registerMode: registerMode,
            loginEnabled: !controller.isBusy && registerMode,
            registerEnabled: !controller.isBusy && !registerMode,
            onSelectLogin: onToggleMode,
            onSelectRegister: onToggleMode,
          ),
          const SizedBox(height: 22),
          Text(
            registerMode ? '创建账号' : '账号登录',
            style: const TextStyle(
              color: Color(0xFF173A59),
              fontWeight: FontWeight.w900,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            registerMode
                ? '注册时请填写昵称、账号与密码。账号不可重复，昵称请控制在 5 个字以内。'
                : '输入账号密码后即可进入大厅。',
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: 17,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (registerMode) ...[
                    const _InputLabel(label: '昵称'),
                    const SizedBox(height: 10),
                    _InputField(
                      controller: nicknameController,
                      hintText: '请输入昵称（5 个字以内）',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 18),
                  ],
                  const _InputLabel(label: '账号'),
                  const SizedBox(height: 10),
                  _InputField(
                    controller: accountController,
                    hintText: '请输入账号',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 18),
                  const _InputLabel(label: '密码'),
                  const SizedBox(height: 10),
                  _InputField(
                    controller: passwordController,
                    hintText: '请输入密码',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  if (!registerMode) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: controller.isBusy ? null : onForgotPassword,
                        icon: const Icon(Icons.key_rounded, size: 18),
                        label: const Text('忘记密码 / 修改密码'),
                      ),
                    ),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: controller.errorText == null
                        ? const SizedBox.shrink()
                        : Container(
                            key: ValueKey(controller.errorText),
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: const Color(0xFFFFF1EE),
                            ),
                            child: Text(
                              controller.errorText!,
                              style: const TextStyle(
                                color: Color(0xFFB54A3D),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.isBusy ? null : onSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(66),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              child: Text(registerMode ? '注册并登录' : '登录进入大厅'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              registerMode
                  ? '注册成功后会自动使用新账号登录'
                  : '默认测试账号：player1 / player1',
              style: TextStyle(
                color: const Color(0xFF6E88A1).withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (controller.isBusy)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Center(child: _InlineBusy()),
            ),
        ],
      ),
    );
  }
}

class _AuthModeTabs extends StatelessWidget {
  const _AuthModeTabs({
    required this.registerMode,
    required this.loginEnabled,
    required this.registerEnabled,
    required this.onSelectLogin,
    required this.onSelectRegister,
  });

  final bool registerMode;
  final bool loginEnabled;
  final bool registerEnabled;
  final VoidCallback onSelectLogin;
  final VoidCallback onSelectRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFEAF5FF),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthModeTabButton(
              label: '登录',
              selected: !registerMode,
              onPressed: loginEnabled ? onSelectLogin : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AuthModeTabButton(
              label: '注册',
              selected: registerMode,
              onPressed: registerEnabled ? onSelectRegister : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeTabButton extends StatelessWidget {
  const _AuthModeTabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF2B7FFF) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF245E90),
        disabledBackgroundColor:
            selected ? const Color(0xFF2B7FFF) : Colors.white,
        disabledForegroundColor:
            selected ? Colors.white : const Color(0xFF245E90),
        elevation: 0,
        minimumSize: const Size.fromHeight(58),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? const Color(0xFF2B7FFF)
                : const Color(0xFFD7EBFF),
          ),
        ),
      ),
      child: Text(label),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF245E90),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          style: const TextStyle(
            color: Color(0xFF587790),
            fontWeight: FontWeight.w700,
            fontSize: 17,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF245E90),
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: Color(0xFF173A59),
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF5A7894).withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        prefixIcon: Icon(icon, size: 24),
        filled: true,
        fillColor: const Color(0xFFF4FAFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

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

class _InlineBusy extends StatelessWidget {
  const _InlineBusy();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        SizedBox(width: 10),
        Text(
          '请稍候',
          style: TextStyle(
            color: Color(0xFF173A59),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PasswordResetResult {
  const _PasswordResetResult({
    required this.account,
    required this.newPassword,
  });

  final String account;
  final String newPassword;
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog();

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final account = _accountController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (account.isEmpty) {
      setState(() => _errorText = '请输入账号');
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
      _PasswordResetResult(account: account, newPassword: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: StagePanel(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          radius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '忘记密码 / 修改密码',
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
                '输入账号与新密码后即可更新密码。',
                style: TextStyle(
                  color: Color(0xFF587790),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              const _InputLabel(label: '账号'),
              const SizedBox(height: 8),
              _InputField(
                controller: _accountController,
                hintText: '请输入账号',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              const _InputLabel(label: '新密码'),
              const SizedBox(height: 8),
              _InputField(
                controller: _passwordController,
                hintText: '请输入新密码',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 14),
              const _InputLabel(label: '确认密码'),
              const SizedBox(height: 8),
              _InputField(
                controller: _confirmController,
                hintText: '请再次输入新密码',
                icon: Icons.verified_user_outlined,
                obscureText: true,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 14),
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('更新密码'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
