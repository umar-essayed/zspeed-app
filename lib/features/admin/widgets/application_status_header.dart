import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Color-coded status banner for application detail/list views.
class ApplicationStatusHeader extends StatelessWidget {
  final ReviewStatus status;
  final String? rejectionReason;

  const ApplicationStatusHeader({
    super.key,
    required this.status,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _fgColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    color: _fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (rejectionReason != null &&
                    rejectionReason!.isNotEmpty &&
                    status == ReviewStatus.rejected) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.rejectionReasonPrefix(rejectionReason!),
                    style: TextStyle(
                      color: _fgColor.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (status) {
      case ReviewStatus.pending:
        return const Color(0xFFFFF3E0);
      case ReviewStatus.underReview:
        return const Color(0xFFE3F2FD);
      case ReviewStatus.approved:
        return const Color(0xFFE8F5E9);
      case ReviewStatus.rejected:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get _borderColor {
    switch (status) {
      case ReviewStatus.pending:
        return const Color(0xFFFFCC80);
      case ReviewStatus.underReview:
        return const Color(0xFF90CAF9);
      case ReviewStatus.approved:
        return const Color(0xFFA5D6A7);
      case ReviewStatus.rejected:
        return const Color(0xFFEF9A9A);
    }
  }

  Color get _fgColor {
    switch (status) {
      case ReviewStatus.pending:
        return const Color(0xFFE65100);
      case ReviewStatus.underReview:
        return const Color(0xFF1565C0);
      case ReviewStatus.approved:
        return const Color(0xFF2E7D32);
      case ReviewStatus.rejected:
        return const Color(0xFFC62828);
    }
  }

  IconData get _icon {
    switch (status) {
      case ReviewStatus.pending:
        return Icons.hourglass_empty;
      case ReviewStatus.underReview:
        return Icons.visibility;
      case ReviewStatus.approved:
        return Icons.check_circle;
      case ReviewStatus.rejected:
        return Icons.cancel;
    }
  }
}
