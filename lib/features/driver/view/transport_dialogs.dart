import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Centralized transport dialog helpers.
///
/// Each public static method produces a specific dialog variant while
/// delegating the common shell (rounded Dialog, colored header, action
/// button row) to [_showDialog].
class TransportDialogs {
  TransportDialogs._(); // prevent instantiation

  // ─── Shared dialog shell ───────────────────────────────────────────

  static Future<void> _showDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color headerBgColor,
    required Color iconColor,
    required Widget content,
    required String cancelText,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: headerBgColor,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(16),
                    topEnd: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Content + buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    content,
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(cancelText),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              onConfirm();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: confirmColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(confirmText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Public dialog variants ────────────────────────────────────────

  /// Generic confirmation dialog (used by _bookRide, etc.).
  static void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    _showDialog(
      context: context,
      title: title,
      icon: Icons.info_outline,
      headerBgColor: Colors.orange.shade50,
      iconColor: Colors.orange.shade700,
      content: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        textAlign: TextAlign.center,
      ),
      cancelText: AppLocalizations.of(context)!.cancel,
      confirmText: AppLocalizations.of(context)!.confirm,
      confirmColor: Colors.orange.shade600,
      onConfirm: onConfirm,
    );
  }

  /// Call driver dialog — shows phone number, then triggers [onCall].
  static void showCallDialog(
    BuildContext context, {
    required String phoneNumber,
    required VoidCallback onCall,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showDialog(
      context: context,
      title: l10n.callDriver,
      icon: Icons.phone,
      headerBgColor: Colors.orange.shade50,
      iconColor: Colors.orange.shade700,
      content: Column(
        children: [
          Text(
            l10n.callingDriver2,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            phoneNumber,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
      cancelText: l10n.cancel,
      confirmText: l10n.callLabel,
      confirmColor: Colors.orange.shade600,
      onConfirm: onCall,
    );
  }

  /// Message driver dialog — includes a text field for composing a message.
  static void showChatDialog(
    BuildContext context, {
    required VoidCallback onSend,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showDialog(
      context: context,
      title: l10n.messageDriver,
      icon: Icons.message,
      headerBgColor: Colors.orange.shade50,
      iconColor: Colors.orange.shade700,
      content: Column(
        children: [
          Text(
            l10n.sendMessageToDriver,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: l10n.typeMessageHere,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
          ),
        ],
      ),
      cancelText: l10n.cancel,
      confirmText: l10n.send,
      confirmColor: Colors.orange.shade600,
      onConfirm: onSend,
    );
  }

  /// Driver location dialog — map placeholder with "Open Maps" action.
  static void showLocationDialog(
    BuildContext context, {
    required VoidCallback onOpenMaps,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showDialog(
      context: context,
      title: l10n.driverLocation,
      icon: Icons.location_on,
      headerBgColor: Colors.orange.shade50,
      iconColor: Colors.orange.shade700,
      content: Column(
        children: [
          const Icon(Icons.map, size: 60, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            l10n.openingDriverLocation,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      cancelText: l10n.close,
      confirmText: l10n.openMaps,
      confirmColor: Colors.orange.shade600,
      onConfirm: onOpenMaps,
    );
  }

  /// Complete ride confirmation dialog — green theme.
  static void showCompleteRideDialog(
    BuildContext context, {
    required VoidCallback onComplete,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showDialog(
      context: context,
      title: l10n.completeRide,
      icon: Icons.check_circle,
      headerBgColor: Colors.green.shade50,
      iconColor: Colors.green.shade700,
      content: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            l10n.hasRideBeenCompleted,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      cancelText: l10n.noButton,
      confirmText: l10n.yesComplete,
      confirmColor: Colors.green,
      onConfirm: onComplete,
    );
  }

  /// Cancel ride confirmation dialog — red theme with warning.
  static void showCancelRideDialog(
    BuildContext context, {
    required VoidCallback onCancel,
  }) {
    final l10n = AppLocalizations.of(context)!;
    _showDialog(
      context: context,
      title: l10n.cancelRide,
      icon: Icons.cancel,
      headerBgColor: Colors.red.shade50,
      iconColor: Colors.red.shade700,
      content: Column(
        children: [
          const Icon(Icons.warning_amber_outlined, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            l10n.areYouSureCancelRide,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.cannotBeUndone,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
      cancelText: l10n.noButton,
      confirmText: l10n.yesCancel,
      confirmColor: Colors.red,
      onConfirm: onCancel,
    );
  }
}
