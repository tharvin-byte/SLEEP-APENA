import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({
    super.key,
    required this.assetPath,
    this.size = 120,
  });

  final String assetPath;
  final double size;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringSize = widget.size * 1.55;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2 * pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: t,
                child: _OrbitRing(
                  size: ringSize,
                  strokeWidth: 1.6,
                  opacity: 0.30,
                ),
              ),
              Transform.rotate(
                angle: -t * 0.75,
                child: _OrbitRing(
                  size: ringSize * 0.88,
                  strokeWidth: 1.2,
                  opacity: 0.20,
                ),
              ),
              Transform.rotate(
                angle: t * 0.45,
                child: _OrbitRing(
                  size: ringSize * 0.74,
                  strokeWidth: 1.0,
                  opacity: 0.14,
                ),
              ),
              Container(
                width: widget.size + 18,
                height: widget.size + 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              ClipOval(
                child: Image.asset(
                  widget.assetPath,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitRing extends StatelessWidget {
  const _OrbitRing({
    required this.size,
    required this.strokeWidth,
    required this.opacity,
  });

  final double size;
  final double strokeWidth;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OrbitRingPainter(
        strokeWidth: strokeWidth,
        opacity: opacity,
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({
    required this.strokeWidth,
    required this.opacity,
  });

  final double strokeWidth;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: [
          const Color(0x002563EB),
          const Color(0xFF60A5FA).withValues(alpha: opacity),
          const Color(0xFF2563EB).withValues(alpha: opacity),
          const Color(0x002563EB),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final center = rect.center;
    final radius = size.shortestSide * 0.45;
    canvas.drawCircle(center, radius, ringPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: opacity + 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(center.dx + radius, center.dy), 2.4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

