import 'package:flutter/widgets.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/errors/failures.dart';

extension FailureLocalizationExt on Failure {
  String getLocalizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final msg = message.toLowerCase();

    if (this is NetworkFailure) {
      if (msg.contains('socket') ||
          msg.contains('offline') ||
          msg.contains('network')) {
        return l10n.networkError;
      }
      return l10n.serverError;
    }

    if (this is UserBlockedFailure) {
      if (msg.contains('phone')) {
        return l10n.phoneBlacklistedError;
      } else if (msg.contains('email')) {
        return l10n.emailBlacklistedError;
      }
      return l10n.userBlockedError;
    }

    if (this is RegistrationDisabledFailure) {
      return l10n.registrationDisabledMessage;
    }

    if (this is AuthFailure) {
      if (msg.contains('disabled') || msg.contains('suspended') || msg.contains('banned') || msg.contains('blocked')) {
        return l10n.userBlockedError;
      } else if (msg.contains('invalid email or password') ||
          msg.contains('incorrect password') ||
          msg.contains('no account found')) {
        return l10n.invalidCredentials;
      } else if (msg.contains('already exists')) {
        return l10n.emailInUse;
      } else if (msg.contains('too many attempts')) {
        return l10n.tooManyRequests;
      } else if (msg.contains('network error')) {
        return l10n.networkError;
      }
      return l10n.authFailed;
    }

    // Fallback based on generic keywords
    if (msg.contains('network') || msg.contains('connection')) {
      return l10n.networkError;
    }

    return message; // return the original message if we don't have a translation
  }
}
