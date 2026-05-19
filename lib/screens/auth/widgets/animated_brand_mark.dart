import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AnimatedBrandMark extends StatefulWidget {
  const AnimatedBrandMark({super.key});

  @override
  State<AnimatedBrandMark> createState() => _AnimatedBrandMarkState();
}

class _AnimatedBrandMarkState extends State<AnimatedBrandMark>
    with TickerProviderStateMixin {
  // A4 — entrance: scale + slide, 900 ms, elasticOut, plays once
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceScale;
  late final Animation<Offset> _entranceSlide;

  // A5 — halo pulse: 3200 ms, repeat(reverse: true)
  late final AnimationController _haloCtrl;
  late final Animation<double> _haloOpacity;
  late final Animation<double> _haloScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _entranceScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.elasticOut));
    _entranceSlide = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutQuint));

    _haloCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _haloOpacity = Tween<double>(begin: 0.4, end: 0.9)
        .animate(CurvedAnimation(parent: _haloCtrl, curve: Curves.easeInOut));
    _haloScale = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _haloCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _haloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceCtrl, _haloCtrl]),
      builder: (_, __) {
        return SlideTransition(
          position: _entranceSlide,
          child: ScaleTransition(
            scale: _entranceScale,
            child: Column(
              children: [
                // Logo + halo
                RepaintBoundary(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer halo
                        Transform.scale(
                          scale: _haloScale.value,
                          child: Opacity(
                            opacity: _haloOpacity.value * 0.5,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withValues(alpha: _haloOpacity.value * 0.35),
                                    blurRadius: 32,
                                    spreadRadius: 8,
                                  ),
                                ],
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.accent
                                        .withValues(alpha: _haloOpacity.value * 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Logo
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cardBg,
                            border: Border.all(
                              color: AppColors.accent
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Wordmark
                const Text(
                  'HOSTMINTON',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Tagline
                const Text(
                  'HOST · PLAY · RECORD',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
