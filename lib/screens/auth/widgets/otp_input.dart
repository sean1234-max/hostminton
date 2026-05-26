import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';

/// 6-box OTP input with:
/// • Single hidden TextField — keyboard never drops between boxes
/// • Auto-advance visual highlight as digits arrive
/// • Backspace clears last digit
/// • Paste distributes across all boxes
/// • Shake on wrong code (A20)
/// • Success cascade (A21)
///
/// Access via [GlobalKey<OtpInputState>] to call [triggerShake],
/// [triggerSuccess], and [clear].
class OtpInput extends StatefulWidget {
  final void Function(String code) onCompleted;
  final void Function(String code)? onChanged;

  const OtpInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  OtpInputState createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> with TickerProviderStateMixin {
  // Single hidden controller + focus node
  final _hiddenCtrl  = TextEditingController();
  final _hiddenFocus = FocusNode();

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _shakeCtrl;
  late final AnimationController _cascadeCtrl;
  late final List<AnimationController> _popCtrls;

  // ── Visual state ───────────────────────────────────────────────────────────
  bool _isError   = false;
  bool _isSuccess = false;

  String get code => _hiddenCtrl.text;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _cascadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _popCtrls = List.generate(
      6,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 320)),
    );

    _hiddenCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _hiddenCtrl.removeListener(_onTextChanged);
    _hiddenCtrl.dispose();
    _hiddenFocus.dispose();
    _shakeCtrl.dispose();
    _cascadeCtrl.dispose();
    for (final c in _popCtrls) { c.dispose(); }
    super.dispose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  void triggerShake() {
    setState(() => _isError = true);
    _shakeCtrl
      ..reset()
      ..forward().then((_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() => _isError = false);
            clear();
            _hiddenFocus.requestFocus();
          }
        });
      });
  }

  void triggerSuccess() {
    setState(() => _isSuccess = true);
    _cascadeCtrl
      ..reset()
      ..forward();
  }

  void clear() {
    _hiddenCtrl.clear();
    setState(() {});
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  String _prevText = '';

  void _onTextChanged() {
    final raw     = _hiddenCtrl.text;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '').substring(
        0, raw.replaceAll(RegExp(r'[^0-9]'), '').length.clamp(0, 6));

    // If non-digit chars slipped in, correct the field silently
    if (raw != cleaned) {
      _hiddenCtrl.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
      return; // listener fires again with cleaned value
    }

    final prev = _prevText;
    _prevText  = cleaned;

    setState(() {});
    widget.onChanged?.call(cleaned);

    // Pop animation for newly added digit
    if (cleaned.length > prev.length && cleaned.length <= 6) {
      final idx = cleaned.length - 1;
      _popCtrls[idx]
        ..reset()
        ..forward();
    }

    if (cleaned.length == 6) {
      widget.onCompleted(cleaned);
    }
  }

  // ── Animations ─────────────────────────────────────────────────────────────

  double get _shakeX => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -10.0, end: 8.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -6.0, end: 4.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
      ])
          .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut))
          .value;

  double _cascadeY(int i) => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 50),
      ])
          .animate(CurvedAnimation(
            parent: _cascadeCtrl,
            curve: Interval(i / 6 * 0.7, (i / 6 * 0.7 + 0.3).clamp(0, 1),
                curve: Curves.easeInOut),
          ))
          .value;

  double _cascadeScale(int i) => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 50),
      ])
          .animate(CurvedAnimation(
            parent: _cascadeCtrl,
            curve: Interval(i / 6 * 0.7, (i / 6 * 0.7 + 0.3).clamp(0, 1),
                curve: Curves.easeInOut),
          ))
          .value;

  double _popScale(int i) => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0), weight: 60),
      ])
          .animate(CurvedAnimation(
              parent: _popCtrls[i], curve: Curves.elasticOut))
          .value;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final digits = _hiddenCtrl.text.padRight(6).substring(0, 6);

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeCtrl, _cascadeCtrl, ..._popCtrls]),
      builder: (_, __) => Transform.translate(
        offset: Offset(_shakeX, 0),
        child: GestureDetector(
          // Tapping anywhere on the row opens the keyboard
          onTap: () => _hiddenFocus.requestFocus(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Hidden real TextField ──────────────────────────────────────
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: _hiddenCtrl,
                    focusNode: _hiddenFocus,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),

              // ── Visible digit boxes ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final char      = digits[i];
                  final hasDigit  = char.trim().isNotEmpty;
                  final isCurrent = _hiddenCtrl.text.length == i && _hiddenFocus.hasFocus;

                  Color border;
                  Color bg;
                  Color textColor;
                  List<BoxShadow> shadows;

                  if (_isSuccess) {
                    final cp    = _cascadeCtrl.value;
                    final start = i / 6 * 0.7;
                    final end   = (start + 0.3).clamp(0.0, 1.0);
                    final active = cp >= start && cp <= end;
                    border    = AppColors.accent;
                    bg        = active
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.inputBg;
                    textColor = AppColors.accent;
                    shadows   = active
                        ? [BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12, spreadRadius: 2)]
                        : [];
                  } else if (_isError) {
                    border    = AppColors.red;
                    bg        = AppColors.red.withValues(alpha: 0.08);
                    textColor = AppColors.red;
                    shadows   = [];
                  } else if (isCurrent) {
                    border    = AppColors.accent;
                    bg        = AppColors.inputBg;
                    textColor = AppColors.textPrimary;
                    shadows   = [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          blurRadius: 0, spreadRadius: 4),
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          blurRadius: 24),
                    ];
                  } else {
                    border    = hasDigit
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.border;
                    bg        = AppColors.inputBg;
                    textColor = AppColors.textPrimary;
                    shadows   = [];
                  }

                  return Padding(
                    padding: EdgeInsets.only(right: i < 5 ? 10.0 : 0),
                    child: Transform.scale(
                      scale: _isSuccess
                          ? _cascadeScale(i)
                          : _popCtrls[i].isAnimating
                              ? _popScale(i)
                              : 1.0,
                      child: Transform.translate(
                        offset: _isSuccess
                            ? Offset(0, _cascadeY(i))
                            : Offset.zero,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 52,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border, width: 1.5),
                            boxShadow: shadows,
                          ),
                          child: Center(
                            child: hasDigit
                                ? Text(
                                    char,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  )
                                : isCurrent
                                    ? _BlinkingCursor(color: AppColors.accent)
                                    : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Blinking cursor shown on the active empty box ─────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 530))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _ctrl,
        child: Container(
          width: 2,
          height: 24,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );
}
