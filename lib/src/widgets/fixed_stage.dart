import 'package:flutter/material.dart';

class FixedStageBackdrop extends StatelessWidget {
  const FixedStageBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF7FBFF),
            Color(0xFFE8F4FF),
            Color(0xFFD9ECFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -96,
            left: -32,
            child: _BackdropOrb(
              size: 260,
              color: Color(0x4476C5FF),
            ),
          ),
          const Positioned(
            right: -44,
            bottom: -92,
            child: _BackdropOrb(
              size: 240,
              color: Color(0x335CAFFF),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class FixedStage extends StatelessWidget {
  const FixedStage({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final double width;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Padding(
              padding: padding,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StagePanel extends StatelessWidget {
  const StagePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.radius = 32,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withValues(alpha: 0.90),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x143678A3),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({
    required this.size,
    required this.color,
  });

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
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 120,
              spreadRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
