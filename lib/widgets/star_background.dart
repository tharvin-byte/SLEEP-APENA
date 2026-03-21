import 'dart:math';

import 'package:flutter/material.dart';

class StarBackground extends StatelessWidget {
  const StarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarPainter(),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Random _rand = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final bgGlow = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x332563EB),
          Color(0x00000000),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.25, size.height * 0.15),
          radius: size.shortestSide * 0.9,
        ),
      );
    canvas.drawRect(Offset.zero & size, bgGlow);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final brightStarPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);

    final int starCount = max(80, (size.width * size.height / 9000).round());
    for (int i = 0; i < starCount; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      final r = 0.6 + _rand.nextDouble() * 1.4;
      canvas.drawCircle(Offset(dx, dy), r, i % 7 == 0 ? brightStarPaint : starPaint);
    }

    final hazePaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.35),
      size.shortestSide * 0.35,
      hazePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

