import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// "OR" divider with glass-style lines used between login form and social buttons.
class LoginOrDivider extends StatelessWidget {
  const LoginOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.4),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context)!.orText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.4),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
