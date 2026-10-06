import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Row toggling between "Login" and "Sign Up" modes.
class LoginToggleRow extends StatelessWidget {
  const LoginToggleRow({
    super.key,
    required this.isSignUp,
    required this.onToggle,
  });

  final bool isSignUp;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isSignUp
              ? AppLocalizations.of(context)!.alreadyHaveAnAccount
              : AppLocalizations.of(context)!.dontHaveAnAccount,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onToggle,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            isSignUp
                ? AppLocalizations.of(context)!.logIn
                : AppLocalizations.of(context)!.signUp,
            style: const TextStyle(
              color: Color(0xFFFF9800),
              fontWeight: FontWeight.bold,
              fontSize: 15,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 6,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
