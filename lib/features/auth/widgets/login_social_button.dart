import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphism-styled social-login button (Google, Phone, etc.).
///
/// Wider pill shape instead of cramped circle for better tap targets
/// and cleaner visual hierarchy.
class LoginSocialButton extends StatelessWidget {
  const LoginSocialButton({
    super.key,
    required this.label,
    this.icon,
    this.imagePath,
    required this.color,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final String? imagePath;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.white.withValues(alpha: 0.13),
          child: InkWell(
            onTap: onPressed,
            splashColor: color.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imagePath != null)
                    Image.asset(imagePath!, width: 24, height: 24)
                  else if (icon != null)
                    Icon(icon, color: color, size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
