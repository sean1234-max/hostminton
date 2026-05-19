import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// 14 accent/white particles burst radially from the centre (A25).
/// Wrap around any widget — call [play] to fire the burst once.
class SuccessBurst extends StatefulWidget {
  final Widget child;

  const SuccessBurst({super.key, required this.child});

  @override
  State<SuccessBurst> createState() => SuccessBurstState();
}

class SuccessBurstState extends State<SuccessBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _particles = _buildParticles();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Fire the burst — plays once, 300 ms after called.
  void play() {
    _ctrl.reset();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  static List<_Particle> _buildParticles() {
    final rng = Random(7);
    return List.generate(14, (i) {
      final angle = (2 * pi / 14) * i - pi / 2;
      return _Particle(
        angle: angle,
        dist: 90 + rng.nextDouble() * 40,
        size: 3 + rng.nextDouble() * 2.5,
        color: i < 5 ? Colors.white : AppColors.accent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => CustomPaint(
        painter: _BurstPainter(
          progress: CurvedAnimation(
            parent: _ctrl,
            curve: Curves.easeOutQuart,
          ).value,
          particles: _particles,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _Particle {
  final double angle;
  final double dist;
  final double size;
  final Color color;
  const _Particle(
      {required this.angle,
      required this.dist,
      required this.size,
      required this.color});
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  const _BurstPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final d = p.dist * progress;
      final opacity = (progress < 0.5 ? progress * 2 : (1 - progress) * 2)
          .clamp(0.0, 1.0);
      canvas.drawCircle(
        center + Offset(cos(p.angle) * d, sin(p.angle) * d),
        p.size,
        Paint()..color = p.color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter o) => o.progress != progress;
}
