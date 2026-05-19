import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Auth-specific text field with:
///  - A7: focus glow (AnimatedContainer, 250 ms)
///  - A6: staggered entrance slide-in (550 ms, delay = 300 + index*70 ms)
class AuthInputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int entranceIndex; // 0, 1, 2 …
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const AuthInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.controller,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.entranceIndex = 0,
    this.onChanged,
    this.errorText,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _opacity = CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.easeOutQuint);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutQuint));

    // Staggered delay: 300 + index × 70 ms
    Future.delayed(
        Duration(milliseconds: 300 + widget.entranceIndex * 70),
        () { if (mounted) _entranceCtrl.forward(); });

    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            // A7 — focus glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focused ? AppColors.accent : AppColors.border,
                  width: 1,
                ),
                color: AppColors.inputBg,
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          blurRadius: 24,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                onChanged: widget.onChanged,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: Icon(widget.prefixIcon,
                      color: _focused
                          ? AppColors.accent
                          : AppColors.textMuted,
                      size: 18),
                  suffixIcon: widget.suffixIcon,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 15),
                  isDense: true,
                  filled: false,
                ),
              ),
            ),
            if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                widget.errorText!,
                style: const TextStyle(
                    color: AppColors.red, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
