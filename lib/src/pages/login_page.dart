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
  final _usernameController = TextEditingController(text: 'player1');
  final _passwordController = TextEditingController(text: 'player1');
  final _voice = VoiceCueService();
  bool _registerMode = false;

  @override
  void initState() {
    super.initState();
    appLog(AppLogLevel.info, 'login_page', 'initState');
    unawaited(_voice.stopBackgroundMusic());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    unawaited(_voice.dispose());
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (_registerMode) {
      await widget.controller.register(username, password);
    }
    if (!mounted) {
      return;
    }
    await widget.controller.login(username, password);
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
                  width: 438,
                  child: _AuthCard(
                    registerMode: _registerMode,
                    controller: widget.controller,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    onToggleMode: () {
                      setState(() => _registerMode = !_registerMode);
                    },
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
              '轻松开局',
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
              '登录后直接进大厅，选模式就能开局。',
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
              _HeroChip(label: '抢分'),
              _HeroChip(label: '人机'),
              _HeroChip(label: '匹配'),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _FeatureLine(
                          title: '开局快',
                          detail: '账号填好就能直接玩。',
                        ),
                        SizedBox(height: 14),
                        _FeatureLine(
                          title: '节奏清爽',
                          detail: '人机、真人、托管一套走通。',
                        ),
                        SizedBox(height: 14),
                        _FeatureLine(
                          title: '三端统一',
                          detail: '手机、网页、桌面都同一套页面。',
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
    required this.usernameController,
    required this.passwordController,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final bool registerMode;
  final AppController controller;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onToggleMode;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return StagePanel(
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 26),
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  registerMode ? '创建账号' : '进入大厅',
                  style: const TextStyle(
                    color: Color(0xFF173A59),
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                  ),
                ),
              ),
              TextButton(
                onPressed: controller.isBusy ? null : onToggleMode,
                child: Text(registerMode ? '去登录' : '去注册'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            registerMode ? '两项填好，马上开局。' : '账号密码填好就进大厅。',
            style: const TextStyle(
              color: Color(0xFF587790),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 24),
          const _InputLabel(label: '账号'),
          const SizedBox(height: 10),
          _InputField(
            controller: usernameController,
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
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: controller.errorText == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(controller.errorText),
                    width: double.infinity,
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
          const Spacer(),
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
              child: Text(registerMode ? '注册并进入' : '进入大厅'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '默认账号：player1 / player1',
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
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
