import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

// ─── Ripple data ──────────────────────────────────────────────────────────

class _RippleEntry {
  final Offset position;
  final AnimationController ctrl;
  _RippleEntry({required this.position, required this.ctrl});
}

// ─── Check mark painter (A11) ─────────────────────────────────────────────

class _CheckPainter extends CustomPainter {
  final double progress; // 0 → 1
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = AppColors.dark
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.50)
      ..lineTo(size.width * 0.44, size.height * 0.72)
      ..lineTo(size.width * 0.78, size.height * 0.30);

    final metric = path.computeMetrics().first;
    canvas.drawPath(
        metric.extractPath(0, metric.length * progress), paint);
  }

  @override
  bool shouldRepaint(_CheckPainter o) => o.progress != progress;
}

// ─── Button widget ────────────────────────────────────────────────────────

enum _BtnState { idle, loading, success }

class AnimatedPrimaryButton extends StatefulWidget {
  final String label;

  /// Null → disabled appearance.
  /// Return normally for success, throw for error (button resets to idle).
  final Future<void> Function()? onPressed;

  const AnimatedPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton>
    with TickerProviderStateMixin {
  _BtnState _state = _BtnState.idle;
  bool _pressed = false;

  // Loading dots (A10): single controller, Interval-staggered
  late final AnimationController _dotsCtrl;

  // Check pop + draw (A11 / A12)
  late final AnimationController _popCtrl;
  late final AnimationController _checkCtrl;

  // Ripple (A9)
  final List<_RippleEntry> _ripples = [];

  @override
  void initState() {
    super.initState();

    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();

    _popCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _dotsCtrl.dispose();
    _popCtrl.dispose();
    _checkCtrl.dispose();
    for (final r in _ripples) { r.ctrl.dispose(); }
    super.dispose();
  }

  // ── Ripple ────────────────────────────────────────────────────────────

  void _spawnRipple(Offset localPos) {
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();
    final entry = _RippleEntry(position: localPos, ctrl: ctrl);
    setState(() => _ripples.add(entry));
    ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() {
          _ripples.remove(entry);
          ctrl.dispose();
        });
      }
    });
  }

  // ── Tap handling ──────────────────────────────────────────────────────

  Future<void> _handleTap(Offset localPos) async {
    if (widget.onPressed == null || _state != _BtnState.idle) return;
    _spawnRipple(localPos);
    setState(() => _state = _BtnState.loading);
    try {
      await widget.onPressed!();
      if (!mounted) return;
      setState(() => _state = _BtnState.success);
      // A12: pop
      await _popCtrl.forward();
      // A11: draw check 120 ms later
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) _checkCtrl.forward();
    } catch (_) {
      if (mounted) setState(() => _state = _BtnState.idle);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final bgColor = disabled
        ? AppColors.accent.withValues(alpha: 0.3)
        : _state == _BtnState.success
            ? AppColors.accent
            : AppColors.accent;

    return GestureDetector(
      onTapDown: (d) {
        if (disabled || _state != _BtnState.idle) return;
        setState(() => _pressed = true);
        _handleTap(d.localPosition);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: Listenable.merge([_popCtrl, _checkCtrl]),
          builder: (_, __) {
            // A12: TweenSequence pop
            final popScale = _state == _BtnState.success
                ? TweenSequence<double>([
                    TweenSequenceItem(
                        tween: Tween(begin: 1.0, end: 1.18),
                        weight: 40),
                    TweenSequenceItem(
                        tween: Tween(begin: 1.18, end: 1.0),
                        weight: 60),
                  ]).animate(CurvedAnimation(
                        parent: _popCtrl, curve: Curves.elasticOut))
                    .value
                : 1.0;

            return Transform.scale(
              scale: popScale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // Button body
                    Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: disabled
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.20),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(child: _buildContent()),
                    ),
                    // Ripples on top
                    ..._ripples.map((r) => AnimatedBuilder(
                          animation: r.ctrl,
                          builder: (_, __) => CustomPaint(
                            painter: _RipplePainter(
                                r.position,
                                CurvedAnimation(
                                    parent: r.ctrl,
                                    curve: Curves.easeOut)
                                    .value),
                            size: const Size.fromHeight(54),
                          ),
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _BtnState.loading:
        return _LoadingDots(ctrl: _dotsCtrl);
      case _BtnState.success:
        return AnimatedBuilder(
          animation: _checkCtrl,
          builder: (_, __) => SizedBox(
            width: 28,
            height: 28,
            child: CustomPaint(
              painter: _CheckPainter(_checkCtrl.value),
            ),
          ),
        );
      case _BtnState.idle:
        return Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.dark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        );
    }
  }
}

// ─── Loading dots (A10) ───────────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  final AnimationController ctrl;
  const _LoadingDots({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final interval = Interval(
              i * 0.166,
              0.5 + i * 0.166,
              curve: Curves.easeInOut,
            );
            final scale = Tween<double>(begin: 0.5, end: 1.0)
                .animate(CurvedAnimation(parent: ctrl, curve: interval))
                .value;
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 5.0 : 0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.dark,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Ripple painter (A9) ──────────────────────────────────────────────────

class _RipplePainter extends CustomPainter {
  final Offset center;
  final double progress; // 0 → 1

  _RipplePainter(this.center, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = 8 + (240 - 8) * progress;
    final opacity = 0.30 * (1 - progress);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RipplePainter o) =>
      o.progress != progress || o.center != center;
}
