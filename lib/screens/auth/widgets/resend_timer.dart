import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Circular countdown ring — empties counter-clockwise.
/// Morphs to a "Resend code" tap link when it reaches zero (A22).
class ResendTimer extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onResend;

  const ResendTimer({
    super.key,
    this.totalSeconds = 60,
    required this.onResend,
  });

  @override
  State<ResendTimer> createState() => ResendTimerState();
}

class ResendTimerState extends State<ResendTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Restart the countdown and fire [onResend].
  void restart() {
    _ctrl.reset();
    _ctrl.forward();
    widget.onResend();
  }

  int get _remaining =>
      (widget.totalSeconds * (1 - _ctrl.value)).ceil().clamp(0, widget.totalSeconds);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        if (_ctrl.isCompleted) {
          return GestureDetector(
            onTap: restart,
            child: const Text(
              'Resend code',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final secs = _remaining % 60;
        final mins = _remaining ~/ 60;
        final label = mins > 0
            ? '$mins:${secs.toString().padLeft(2, '0')}'
            : '0:${secs.toString().padLeft(2, '0')}';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(
                painter: _RingPainter(progress: 1 - _ctrl.value),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Resend in $label',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 1.0 = full (just started) → 0.0 = empty

  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = AppColors.border;
    canvas.drawCircle(center, radius, paint);

    // Foreground arc — empties counter-clockwise
    if (progress > 0) {
      paint.color = AppColors.accent;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,              // start at 12-o'clock
        -2 * pi * progress,   // counter-clockwise sweep
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
