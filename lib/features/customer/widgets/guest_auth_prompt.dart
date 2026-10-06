import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/auth/cubit/auth_state.dart';
import 'package:z_speed/features/auth/view/login_screen.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class GuestAuthPrompt {
  static Future<void> show(
    BuildContext context, {
    required String actionLabel,
    VoidCallback? onAuthenticated,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocListener<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state.isAuthenticated) {
              Navigator.of(sheetContext).pop();
              onAuthenticated?.call();
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.signInRequired,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.signInToAction} $actionLabel',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.signIn),
                    ),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(AppLocalizations.of(context)!.continueAsGuest),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
