import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// A13 — fade + slide page transition used between auth screens.
PageRouteBuilder authFadeSlide(Widget page) => PageRouteBuilder(
      pageBuilder: (_, a, __) => page,
      transitionsBuilder: (_, a, __, child) {
        final curved =
            CurvedAnimation(parent: a, curve: Curves.easeOutQuint);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );

/// Horizontal divider with centred text label.
class AuthDivider extends StatelessWidget {
  final String label;
  const AuthDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: AppColors.border)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
      ),
      const Expanded(child: Divider(color: AppColors.border)),
    ]);
  }
}

/// "Already have one? [Sign in]" style link row.
class AuthSwitchLink extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;

  const AuthSwitchLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
          children: [
            TextSpan(text: prefix),
            TextSpan(
              text: action,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
