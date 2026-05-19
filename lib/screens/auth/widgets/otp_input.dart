import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';

/// 6-box OTP input with:
/// • Auto-advance on digit entry (A19 pop)
/// • Backspace moves to previous box
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
  // Controllers & focus
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  final List<String> _digits = List.filled(6, '');
  bool _updating = false;

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _shakeCtrl;    // A20 — horizontal shake
  late final AnimationController _cascadeCtrl;  // A21 — success cascade
  late final List<AnimationController> _popCtrls; // A19 — per-digit pop

  // ── Visual state ───────────────────────────────────────────────────────────
  bool _isError = false;
  bool _isSuccess = false;

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

    for (int i = 0; i < 6; i++) {
      final idx = i;
      _nodes[i].onKeyEvent = (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_digits[idx].isEmpty && idx > 0) {
            _setDigit(idx - 1, '');
            _nodes[idx - 1].requestFocus();
          } else {
            _setDigit(idx, '');
          }
          _notifyChanged();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    _shakeCtrl.dispose();
    _cascadeCtrl.dispose();
    for (final c in _popCtrls) { c.dispose(); }
    super.dispose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  String get code => _digits.join();

  /// Shake all boxes red, then auto-clear and refocus box 0 after 700 ms.
  void triggerShake() {
    setState(() => _isError = true);
    _shakeCtrl
      ..reset()
      ..forward().then((_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            setState(() => _isError = false);
            clear();
            _nodes[0].requestFocus();
          }
        });
      });
  }

  /// Green cascade across all 6 boxes.
  void triggerSuccess() {
    setState(() => _isSuccess = true);
    _cascadeCtrl
      ..reset()
      ..forward();
  }

  /// Clear all digits.
  void clear() {
    for (int i = 0; i < 6; i++) {
      _setDigit(i, '');
    }
    setState(() {});
    _notifyChanged();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _setDigit(int i, String d) {
    _digits[i] = d;
    if (_updating) return;
    _updating = true;
    _ctrls[i].text = d;
    if (d.isNotEmpty) {
      _ctrls[i].selection =
          TextSelection.collapsed(offset: d.length);
    }
    _updating = false;
  }

  void _notifyChanged() => widget.onChanged?.call(code);

  void _handleChange(int index, String value) {
    if (_updating) return;
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) {
      _setDigit(index, '');
      _notifyChanged();
      return;
    }

    if (cleaned.length > 1) {
      // ── Paste: distribute from this index ──────────────────────────────
      for (int i = 0; i < 6 && i < cleaned.length; i++) {
        _setDigit(i, cleaned[i]);
      }
      setState(() {});
      _notifyChanged();
      final last = (cleaned.length - 1).clamp(0, 5);
      _nodes[last].requestFocus();
      if (code.length == 6) widget.onCompleted(code);
      return;
    }

    // ── Single digit ───────────────────────────────────────────────────────
    _setDigit(index, cleaned);
    setState(() {});

    // Pop animation (A19)
    _popCtrls[index]
      ..reset()
      ..forward();

    _notifyChanged();

    if (index < 5) {
      _nodes[index + 1].requestFocus();
    } else {
      _nodes[index].unfocus();
      if (code.length == 6) widget.onCompleted(code);
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
          .animate(CurvedAnimation(
              parent: _shakeCtrl, curve: Curves.easeInOut))
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
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeCtrl, _cascadeCtrl, ..._popCtrls]),
      builder: (_, __) => Transform.translate(
        offset: Offset(_shakeX, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final isFocused = _nodes[i].hasFocus;
            final hasDigit = _digits[i].isNotEmpty;

            // Determine styling
            Color border;
            Color bg;
            Color textColor;
            List<BoxShadow> shadows;

            if (_isSuccess) {
              final cp = _cascadeCtrl.value;
              final start = i / 6 * 0.7;
              final end = (start + 0.3).clamp(0.0, 1.0);
              final active = cp >= start && cp <= end;
              border = AppColors.accent;
              bg = active
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.inputBg;
              textColor = AppColors.accent;
              shadows = active
                  ? [
                      BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2)
                    ]
                  : [];
            } else if (_isError) {
              border = AppColors.red;
              bg = AppColors.red.withValues(alpha: 0.08);
              textColor = AppColors.red;
              shadows = [];
            } else if (isFocused) {
              border = AppColors.accent;
              bg = AppColors.inputBg;
              textColor = AppColors.textPrimary;
              shadows = [
                BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    blurRadius: 0,
                    spreadRadius: 4),
                BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    blurRadius: 24),
              ];
            } else {
              border = hasDigit
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : AppColors.border;
              bg = AppColors.inputBg;
              textColor = AppColors.textPrimary;
              shadows = [];
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
                  offset: _isSuccess ? Offset(0, _cascadeY(i)) : Offset.zero,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border, width: 1.5),
                      boxShadow: shadows,
                    ),
                    child: Center(
                      child: TextField(
                        controller: _ctrls[i],
                        focusNode: _nodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (v) => _handleChange(i, v),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
