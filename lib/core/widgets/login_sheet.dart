import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class LoginSheet extends StatelessWidget {
  const LoginSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(25),
          topEnd: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.welcomeBack,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            AppLocalizations.of(context)!.loginToYourAccount,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.emailOrUsername,
              prefixIcon:
                  const Icon(Icons.person_outline, color: Color(0xFF666666)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF35535)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              prefixIcon:
                  const Icon(Icons.lock_outline, color: Color(0xFF666666)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF35535)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF35535),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                AppLocalizations.of(context)!.signIn,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: Text(
              AppLocalizations.of(context)!.forgotPassword,
              style: const TextStyle(
                color: Color(0xFFF35535),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${AppLocalizations.of(context)!.dontHaveAnAccount} ',
                style: const TextStyle(color: Colors.grey),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  AppLocalizations.of(context)!.signUp,
                  style: const TextStyle(
                    color: Color(0xFFF35535),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
