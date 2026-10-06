import 'package:flutter/material.dart';

/// Glassmorphism text field for login/signup.
class LoginGlassField extends StatelessWidget {
  const LoginGlassField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: .5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        cursorColor: const Color(0xFFFF9800),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFFFB74D),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              prefixIcon,
              color: Colors.white.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: false,
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFFF9800),
              width: 1.5,
            ),
          ),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorStyle: const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
