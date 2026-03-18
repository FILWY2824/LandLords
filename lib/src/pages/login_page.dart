import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../utils/app_log.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController(text: 'player1');
  final _passwordController = TextEditingController(text: 'player1');
  bool _registerMode = false;

  @override
  void initState() {
    super.initState();
    appLog(AppLogLevel.info, 'login_page', 'initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final renderObject = context.findRenderObject();
      final size = renderObject is RenderBox ? renderObject.size : null;
      appLog(
        AppLogLevel.info,
        'login_page',
        'post-frame mounted=$mounted size=${size?.width ?? -1}x${size?.height ?? -1}',
      );
    });
  }

  @override
  void dispose() {
    appLog(AppLogLevel.info, 'login_page', 'dispose');
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    appLog(
      AppLogLevel.info,
      'login_page',
      'build busy=${widget.controller.isBusy} register=$_registerMode error=${widget.controller.errorText ?? '-'}',
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5FBFF), Color(0xFFE6F4FF), Color(0xFFD7EEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: -80, left: -30, child: _BlurOrb(size: 260, color: Color(0x5567C2FF))),
            const Positioned(bottom: -60, right: -20, child: _BlurOrb(size: 220, color: Color(0x5579E3FF))),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 880;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            color: Colors.white.withValues(alpha: 0.84),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x143678A3),
                                blurRadius: 36,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: wide
                              ? Row(
                                  children: [
                                    const Expanded(flex: 6, child: _HeroPanel()),
                                    Expanded(
                                      flex: 5,
                                      child: _LoginCard(
                                        registerMode: _registerMode,
                                        controller: widget.controller,
                                        usernameController: _usernameController,
                                        passwordController: _passwordController,
                                        onToggleMode: () => setState(() {
                                          _registerMode = !_registerMode;
                                        }),
                                      ),
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    children: [
                                      const _HeroPanel(compact: true),
                                      const SizedBox(height: 20),
                                      _LoginCard(
                                        registerMode: _registerMode,
                                        controller: widget.controller,
                                        usernameController: _usernameController,
                                        passwordController: _passwordController,
                                        onToggleMode: () => setState(() {
                                          _registerMode = !_registerMode;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (widget.controller.isBusy)
              _LoadingMask(text: widget.controller.busyText ?? '正在加载...'),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF19466E),
          height: 1.05,
        );
    return Padding(
      padding: EdgeInsets.all(compact ? 20 : 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
          Text('欢乐斗地主', style: titleStyle),
          const SizedBox(height: 16),
          const Text(
            '清爽蓝色牌桌，叫分抢地主、人机热身、真人匹配和托管一套打通。进入大厅后就能直接开局。',
            style: TextStyle(
              fontSize: 17,
              height: 1.7,
              color: Color(0xFF50708E),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _FeatureChip(label: '浅蓝牌桌'),
              _FeatureChip(label: '叫分抢地主'),
              _FeatureChip(label: '真人匹配'),
              _FeatureChip(label: '断线可续'),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFEDF7FF), Color(0xFFDDF1FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '上桌节奏',
                        style: TextStyle(
                          color: Color(0xFF245E90),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '先登录，再选人机热身或真人匹配，系统会自动接入当前房间。',
                        style: TextStyle(
                          color: Color(0xFF4F6F8B),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: compact ? 90 : 126,
                  height: compact ? 90 : 126,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF72C7FF), Color(0xFF2B7FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.style_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.registerMode,
    required this.controller,
    required this.usernameController,
    required this.passwordController,
    required this.onToggleMode,
  });

  final bool registerMode;
  final AppController controller;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final title = registerMode ? '创建账号' : '进入大厅';
    final buttonLabel = registerMode ? '注册并进入' : '进入大厅';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A446D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            registerMode ? '创建一个昵称，马上开始第一局。' : '登录后就能回到大厅，继续开局。',
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Color(0xFF5A7894),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          _InputField(
            controller: usernameController,
            icon: Icons.person_outline_rounded,
            hintText: '昵称',
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: passwordController,
            icon: Icons.lock_outline_rounded,
            hintText: '密码',
            obscureText: true,
          ),
          const SizedBox(height: 18),
          if (controller.errorText != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFFFFF0EE),
              ),
              child: Text(
                controller.errorText!,
                style: const TextStyle(
                  color: Color(0xFFB74A3D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.isBusy
                  ? null
                  : () async {
                      if (registerMode) {
                        await controller.register(
                          usernameController.text.trim(),
                          passwordController.text,
                        );
                      }
                      if (context.mounted) {
                        await controller.login(
                          usernameController.text.trim(),
                          passwordController.text,
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color(0xFF2B7FFF),
              ),
              child: Text(buttonLabel),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: controller.isBusy ? null : onToggleMode,
              child: Text(registerMode ? '已有账号，去登录' : '还没有账号，先注册'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF4FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: const Color(0xFFD6EBFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF245E90),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.size, required this.color});

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
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class _LoadingMask extends StatelessWidget {
  const _LoadingMask({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.white.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x143678A3),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF245E90),
                    fontWeight: FontWeight.w700,
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
