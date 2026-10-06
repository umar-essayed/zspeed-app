import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Approve / Reject action buttons for the application detail view.
class ApplicationActionButtons extends StatelessWidget {
  final bool isActionable;
  final bool isActioning;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ApplicationActionButtons({
    super.key,
    required this.isActionable,
    this.isActioning = false,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActionable) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Reject
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isActioning ? null : onReject,
              icon: isActioning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close, size: 18),
              label: Text(AppLocalizations.of(context)!.reject),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFEF9A9A)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Approve
          Expanded(
            child: FilledButton.icon(
              onPressed: isActioning ? null : onApprove,
              icon: isActioning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(AppLocalizations.of(context)!.approve),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a dialog to collect rejection reason.
  static Future<String?> showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.rejectApplication),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.rejectionReasonBodyHint,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.rejectionReasonInputHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop(text);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
  }
}
