import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

// ─── Particle data (fixed, seeded) ────────────────────────────────────────
class _ParticleData {
  final double baseX;     // 0-1 fraction of width
  final double phase;     // 0-1 offset within cycle
  final double riseDur;   // seconds to rise full height (16-30)
  final double swayAmt;   // px amplitude
  final double swayFreq;  // cycles per full rise
  final double size;      // radius px
  final double opacity;

  const _ParticleData({
    required this.baseX,
    required this.phase,
    required this.riseDur,
    required this.swayAmt,
    required this.swayFreq,
    required this.size,
    required this.opacity,
  });
}

const _particles = [
  _ParticleData(baseX:.12, phase:.00, riseDur:22, swayAmt:18, swayFreq:1.4, size:2.5, opacity:.35),
  _ParticleData(baseX:.28, phase:.18, riseDur:17, swayAmt:12, swayFreq:1.8, size:2.0, opacity:.25),
  _ParticleData(baseX:.44, phase:.37, riseDur:25, swayAmt:22, swayFreq:1.2, size:3.5, opacity:.40),
  _ParticleData(baseX:.60, phase:.54, riseDur:19, swayAmt:14, swayFreq:2.0, size:2.0, opacity:.28),
  _ParticleData(baseX:.75, phase:.07, riseDur:28, swayAmt:10, swayFreq:1.6, size:3.0, opacity:.32),
  _ParticleData(baseX:.88, phase:.42, riseDur:16, swayAmt:20, swayFreq:1.3, size:2.5, opacity:.38),
  _ParticleData(baseX:.20, phase:.70, riseDur:23, swayAmt:16, swayFreq:1.9, size:1.8, opacity:.22),
  _ParticleData(baseX:.52, phase:.85, riseDur:20, swayAmt:24, swayFreq:1.1, size:3.2, opacity:.42),
  _ParticleData(baseX:.68, phase:.28, riseDur:26, swayAmt:12, swayFreq:1.7, size:2.2, opacity:.30),
];

// ─── Painters ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 40.0;
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (double x = 0; x <= size.width; x += step) {
      final frac = (x - cx).abs() / cx;
      final alpha = ((1 - frac) * 0.18).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = AppColors.border.withValues(alpha: alpha)
          ..strokeWidth = 0.5,
      );
    }
    for (double y = 0; y <= size.height; y += step) {
      final frac = (y - cy).abs() / cy;
      final alpha = ((1 - frac) * 0.18).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = AppColors.border.withValues(alpha: alpha)
          ..strokeWidth = 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => false;
}

class _ParticlePainter extends CustomPainter {
  final double t; // 0-1 repeating

  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      // progress within this particle's own cycle
      final prog = (t + p.phase) % 1.0;
      final y = size.height * (1.02 - prog * 1.04); // rise bottom→top+a bit
      final x = size.width * p.baseX +
          math.sin(prog * math.pi * 2 * p.swayFreq) * p.swayAmt;

      // fade in at bottom, fade out at top
      final fade = prog < 0.1
          ? prog / 0.1
          : prog > 0.85
              ? (1 - (prog - 0.85) / 0.15)
              : 1.0;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: p.opacity * fade),
            AppColors.accent40.withValues(alpha: p.opacity * fade * 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: p.size * 2.5));

      canvas.drawCircle(Offset(x, y), p.size * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter o) => o.t != t;
}

// ─── Main widget ──────────────────────────────────────────────────────────

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _blob1;
  late final AnimationController _blob2;
  late final AnimationController _ptCtrl; // particles

  late final Animation<Offset> _blobOffset1;
  late final Animation<Offset> _blobOffset2;

  @override
  void initState() {
    super.initState();

    _blob1 = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat(reverse: true);
    _blob2 = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat(reverse: true);
    _ptCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))
      ..repeat();

    _blobOffset1 = Tween<Offset>(
      begin: const Offset(-60, -80),
      end: const Offset(60, 40),
    ).animate(CurvedAnimation(parent: _blob1, curve: Curves.easeInOut));

    _blobOffset2 = Tween<Offset>(
      begin: const Offset(40, 20),
      end: const Offset(-50, -60),
    ).animate(CurvedAnimation(parent: _blob2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _blob1.dispose();
    _blob2.dispose();
    _ptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return RepaintBoundary(
      child: Stack(
        children: [
          // Pure black base
          const ColoredBox(color: AppColors.background, child: SizedBox.expand()),

          // Grid
          CustomPaint(painter: _GridPainter(), size: size),

          // Blob 1 — top-left quadrant
          AnimatedBuilder(
            animation: _blobOffset1,
            builder: (_, __) => Positioned(
              left: size.width * 0.05 + _blobOffset1.value.dx,
              top: size.height * 0.05 + _blobOffset1.value.dy,
              child: Container(
                width: size.width * 0.85,
                height: size.width * 0.85,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.accent12, Colors.transparent],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Blob 2 — bottom-right quadrant
          AnimatedBuilder(
            animation: _blobOffset2,
            builder: (_, __) => Positioned(
              right: size.width * 0.0 + _blobOffset2.value.dx,
              bottom: size.height * 0.1 + _blobOffset2.value.dy,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Particles
          AnimatedBuilder(
            animation: _ptCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_ptCtrl.value),
              size: size,
            ),
          ),
        ],
      ),
    );
  }
}
