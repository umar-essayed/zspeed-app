import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class FlexibleUpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String updateUrl;
  final VoidCallback onLaterPressed;

  const FlexibleUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.updateUrl,
    required this.onLaterPressed,
  });

  Future<void> _launchUpdateUrl(BuildContext context) async {
    if (updateUrl.isEmpty) {
      debugPrint('No update URL provided.');
      return;
    }
    final Uri url = Uri.parse(updateUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch update URL: $updateUrl');
      }
    } catch (e) {
      debugPrint('Error launching update URL: $e');
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    const primaryColor = Color(0xFFF35535);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom premium update icon/badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.system_update_alt_rounded,
                color: primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n?.flexibleUpdateTitle ?? 'New Update Available!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : const Color(0xFF2D3748),
              ),
            ),
            if (latestVersion.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'v$latestVersion',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Description
            Text(
              l10n?.flexibleUpdateMessage ??
                  'A new version of Z Speed is available with improvements and new features. Would you like to update now?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 28),

            // Actions
            Row(
              children: [
                // "Later" Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      onLaterPressed();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n?.updateLater ?? 'Later',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // "Update Now" Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _launchUpdateUrl(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n?.updateNow ?? 'Update Now',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
