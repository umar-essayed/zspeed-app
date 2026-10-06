import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

import 'package:url_launcher/url_launcher_string.dart';

import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/cubit/admin_application_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_application_state.dart';
import 'package:z_speed/features/admin/widgets/application_status_header.dart';
import 'package:z_speed/features/admin/widgets/application_action_buttons.dart';

/// Full-detail view for a single driver or vendor application.
///
/// Shows: status header → applicant info card → form-data sections
/// (expandable) → document links → approve/reject actions.
class AdminApplicationDetailView extends StatefulWidget {
  final String applicationId;

  const AdminApplicationDetailView({
    super.key,
    required this.applicationId,
  });

  @override
  State<AdminApplicationDetailView> createState() =>
      _AdminApplicationDetailViewState();
}

class _AdminApplicationDetailViewState
    extends State<AdminApplicationDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<AdminApplicationCubit>()
          .loadApplicationDetail(widget.applicationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminApplicationCubit, AdminApplicationState>(
      builder: (context, state) {
        final app = state.selectedApplication;

        return Scaffold(
          appBar: AppBar(
            title: Text(app != null
                ? _titleFor(context, app)
                : AppLocalizations.of(context)!.applicationDetailTitle),
            elevation: 0,
          ),
          body: _buildContent(state, context, app),
        );
      },
    );
  }

  // ── Content Switch ────────────────────────────────────────────────────

  Widget _buildContent(
      AdminApplicationState state, BuildContext context, Application? app) {
    if (state.isBusy || app == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.failure != null) {
      return Center(
        child: Text(
          state.failure!.message,
          style: const TextStyle(color: Color(0xFF757575)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status Banner ────────────────────────────────────────────
          ApplicationStatusHeader(
            status: app.status,
            rejectionReason: app.rejectionReason,
          ),

          const SizedBox(height: 16),

          // ── Applicant Summary Card ──────────────────────────────────
          _ApplicantSummaryCard(application: app),

          const SizedBox(height: 8),

          // ── Form-Data Sections ──────────────────────────────────────
          ..._buildFormDataSections(context, app),

          const SizedBox(height: 8),

          // ── Documents Section ───────────────────────────────────────
          _DocumentsSection(application: app),

          const SizedBox(height: 16),

          // ── Action Buttons ──────────────────────────────────────────
          if (app.status == ReviewStatus.pending ||
              app.status == ReviewStatus.underReview)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ApplicationActionButtons(
                isActionable: app.isPending,
                isActioning: state.isActioning,
                onApprove: () => _handleApprove(context, app),
                onReject: () => _handleReject(context, app),
              ),
            ),
        ],
      ),
    );
  }

  // ── Handlers ────────────────────────────────────────────────────────────

  Future<void> _handleApprove(BuildContext context, Application app) async {
    final cubit = context.read<AdminApplicationCubit>();
    await cubit.approveApplication(app.id, 'admin-system');
    if (!context.mounted) return;
    if (cubit.state.failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.applicationApproved),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context, Application app) async {
    final reason = await ApplicationActionButtons.showRejectDialog(context);
    if (reason == null) return;
    if (!context.mounted) return;

    final cubit = context.read<AdminApplicationCubit>();
    await cubit.rejectApplication(app.id, 'admin-system', reason);
    if (!context.mounted) return;
    if (cubit.state.failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.applicationRejected),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Section-Level Handlers ─────────────────────────────────────────────────

  Future<void> _handleApproveSection(
      BuildContext context, Application app, String sectionKey) async {
    final cubit = context.read<AdminApplicationCubit>();
    final l10n = AppLocalizations.of(context)!;
    final sectionLabel = _sectionLabel(context, sectionKey);
    final messenger = ScaffoldMessenger.of(context);

    final success =
        await cubit.approveSection(app.id, sectionKey, 'admin-system');
    if (!mounted) return;

    if (success) {
      // If auto-approved (all sections passed), show different message
      if (cubit.state.selectedApplication?.isApproved == true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.allSectionsApprovedApplication),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.sectionApprovedMsg(sectionLabel)),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectSection(
      BuildContext context, Application app, String sectionKey) async {
    final l10n = AppLocalizations.of(context)!;
    final sectionLabel = _sectionLabel(context, sectionKey);
    final messenger = ScaffoldMessenger.of(context);

    final reason = await _showSectionRejectDialog(sectionKey);
    if (reason == null) return;
    if (!context.mounted) return;

    final cubit = context.read<AdminApplicationCubit>();
    final success =
        await cubit.rejectSection(app.id, sectionKey, 'admin-system', reason);
    if (!context.mounted) return;
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.sectionRejectedMsg(sectionLabel)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showSectionRejectDialog(String sectionKey) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!
            .rejectSection(_sectionLabel(context, sectionKey).toString())),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.pleaseProvideAReason),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.rejectionReasonHint,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              if (text.isNotEmpty) Navigator.of(ctx).pop(text);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828)),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
  }

  String _sectionLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'businessInfo':
        return l10n.businessInformation;
      case 'locationInfo':
        return l10n.locationAndHours;
      case 'contactInfo':
        return l10n.contactInformation;
      case 'bankInfo':
        return l10n.bankInformation;
      default:
        return key;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _titleFor(BuildContext context, Application app) {
    if (app.applicationType == ApplicationType.driver) {
      return app.formData['personalInfo']?['name'] as String? ??
          AppLocalizations.of(context)!.driverApplication;
    }
    return app.formData['businessInfo']?['restaurantName'] as String? ??
        AppLocalizations.of(context)!.restaurantApplication;
  }

  List<Widget> _buildFormDataSections(BuildContext context, Application app) {
    if (app.applicationType == ApplicationType.driver) {
      return [
        _FormDataSection(
          title: AppLocalizations.of(context)!.personalInformation,
          icon: Icons.person,
          data: app.formData['personalInfo'] as Map<String, dynamic>? ?? {},
        ),
        _FormDataSection(
          title: AppLocalizations.of(context)!.vehicleInformation,
          icon: Icons.directions_car,
          data: app.formData['vehicleInfo'] as Map<String, dynamic>? ?? {},
        ),
      ];
    }

    // Vendor
    return [
      _FormDataSection(
        title: AppLocalizations.of(context)!.businessInformation,
        icon: Icons.store,
        data: app.formData['businessInfo'] as Map<String, dynamic>? ?? {},
        sectionKey: 'businessInfo',
        application: app,
        onApproveSection: app.isPending
            ? () => _handleApproveSection(context, app, 'businessInfo')
            : null,
        onRejectSection: app.isPending
            ? () => _handleRejectSection(context, app, 'businessInfo')
            : null,
      ),
      _FormDataSection(
        title: AppLocalizations.of(context)!.locationAndHours,
        icon: Icons.location_on,
        data: app.formData['locationInfo'] as Map<String, dynamic>? ?? {},
        sectionKey: 'locationInfo',
        application: app,
        onApproveSection: app.isPending
            ? () => _handleApproveSection(context, app, 'locationInfo')
            : null,
        onRejectSection: app.isPending
            ? () => _handleRejectSection(context, app, 'locationInfo')
            : null,
      ),
      _FormDataSection(
        title: AppLocalizations.of(context)!.contactInformation,
        icon: Icons.phone,
        data: app.formData['contactInfo'] as Map<String, dynamic>? ?? {},
        sectionKey: 'contactInfo',
        application: app,
        onApproveSection: app.isPending
            ? () => _handleApproveSection(context, app, 'contactInfo')
            : null,
        onRejectSection: app.isPending
            ? () => _handleRejectSection(context, app, 'contactInfo')
            : null,
      ),
      _FormDataSection(
        title: AppLocalizations.of(context)!.bankInformation,
        icon: Icons.account_balance,
        data: app.formData['bankInfo'] as Map<String, dynamic>? ?? {},
        sectionKey: 'bankInfo',
        application: app,
        onApproveSection: app.isPending
            ? () => _handleApproveSection(context, app, 'bankInfo')
            : null,
        onRejectSection: app.isPending
            ? () => _handleRejectSection(context, app, 'bankInfo')
            : null,
      ),
    ];
  }
}

// ── Applicant Summary Card ──────────────────────────────────────────────────

class _ApplicantSummaryCard extends StatelessWidget {
  final Application application;

  const _ApplicantSummaryCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final isDriver = application.applicationType == ApplicationType.driver;
    final name = isDriver
        ? (application.formData['personalInfo']?['name'] as String? ?? '—')
        : (application.formData['businessInfo']?['restaurantName'] as String? ??
            '—');
    final email = isDriver
        ? (application.formData['personalInfo']?['email'] as String? ?? '—')
        : (application.formData['contactInfo']?['ownerEmail'] as String? ??
            '—');
    final phone = isDriver
        ? (application.formData['personalInfo']?['phone'] as String? ?? '—')
        : (application.formData['contactInfo']?['ownerPhone'] as String? ??
            '—');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  isDriver ? const Color(0xFF1976D2) : const Color(0xFFE65100),
              child: Icon(
                isDriver ? Icons.directions_car : Icons.store,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(icon: Icons.email_outlined, text: email),
                  const SizedBox(height: 2),
                  _InfoRow(icon: Icons.phone_outlined, text: phone),
                  const SizedBox(height: 2),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: AppLocalizations.of(context)!
                        .submittedDate(_formatDate(application.submittedAt)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF757575)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Expandable Form-Data Section ────────────────────────────────────────────

class _FormDataSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, dynamic> data;
  final String? sectionKey;
  final Application? application;
  final VoidCallback? onApproveSection;
  final VoidCallback? onRejectSection;

  const _FormDataSection({
    required this.title,
    required this.icon,
    required this.data,
    this.sectionKey,
    this.application,
    this.onApproveSection,
    this.onRejectSection,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sectionStatus = (sectionKey != null && application != null)
        ? application!.sectionStatus(sectionKey!)
        : SectionReviewStatus.pending;

    final rejectionReason = (sectionKey != null && application != null)
        ? application!.sectionReasons[sectionKey!]
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(icon, size: 22, color: const Color(0xFF546E7A)),
        title: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            if (sectionKey != null) _buildSectionBadge(sectionStatus),
          ],
        ),
        initiallyExpanded: false,
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      _formatKey(entry.key),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatValue(context, entry.key, entry.value),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Show rejection reason if section was rejected
          if (sectionStatus == SectionReviewStatus.rejected &&
              rejectionReason != null) ...[
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFC62828)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!
                          .rejectedReason(rejectionReason),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFFC62828)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Section-level approve/reject buttons
          if (onApproveSection != null || onRejectSection != null) ...[
            const SizedBox(height: 8),
            _buildSectionActions(context, sectionStatus),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionBadge(SectionReviewStatus status) {
    switch (status) {
      case SectionReviewStatus.approved:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case SectionReviewStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red, size: 20);
      case SectionReviewStatus.pending:
        return const Icon(Icons.hourglass_empty,
            color: Color(0xFFFFA000), size: 20);
    }
  }

  Widget _buildSectionActions(
      BuildContext context, SectionReviewStatus status) {
    // Already reviewed sections only show status (can be re-reviewed)
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Row(
        children: [
          if (onRejectSection != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: status == SectionReviewStatus.rejected
                    ? null
                    : onRejectSection,
                icon: const Icon(Icons.close, size: 16),
                label: Text(status == SectionReviewStatus.rejected
                    ? AppLocalizations.of(context)!.rejectedLabel
                    : AppLocalizations.of(context)!.reject),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC62828),
                  side: const BorderSide(color: Color(0xFFEF9A9A)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (onApproveSection != null)
            Expanded(
              child: FilledButton.icon(
                onPressed: status == SectionReviewStatus.approved
                    ? null
                    : onApproveSection,
                icon: const Icon(Icons.check, size: 16),
                label: Text(status == SectionReviewStatus.approved
                    ? AppLocalizations.of(context)!.approvedLabel
                    : AppLocalizations.of(context)!.approve),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Converts camelCase keys to Title Case labels.
  String _formatKey(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  String _formatValue(BuildContext context, String key, dynamic value) {
    if (value == null) return '—';
    if (key == 'operatingHours' && value is Map) {
      return _formatOperatingHours(context, value);
    }
    if (value is List) return value.join(', ');
    if (value is Map) {
      return value.entries
          .map((e) => '${_formatKey(e.key.toString())}: ${e.value}')
          .join('\n');
    }
    return value.toString();
  }

  String _formatOperatingHours(
      BuildContext context, Map<dynamic, dynamic> hours) {
    final List<String> lines = [];
    const days = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];

    for (final day in days) {
      if (hours.containsKey(day)) {
        final dayData = hours[day];
        if (dayData is Map) {
          final isClosed = dayData['closed'] == true;
          if (isClosed) {
            lines.add(
                '${_formatKey(day)}: ${AppLocalizations.of(context)!.closedLabel}');
          } else {
            final open = dayData['open'] ?? '--:--';
            final close = dayData['close'] ?? '--:--';
            lines.add('${_formatKey(day)}: $open - $close');
          }
        }
      }
    }

    if (lines.isEmpty) return AppLocalizations.of(context)!.noHoursProvided;
    return lines.join('\n');
  }
}

// ── Documents Section ───────────────────────────────────────────────────────

class _DocumentsSection extends StatelessWidget {
  final Application application;

  const _DocumentsSection({required this.application});

  static const _docLabels = [
    'Commercial Registration',
    'Business License',
    'Health Certificate',
    'Tax Registration',
  ];

  static const _docIcons = [
    Icons.business_outlined,
    Icons.verified_outlined,
    Icons.health_and_safety_outlined,
    Icons.receipt_long_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    var docs = application.formData['documents'] as Map<String, dynamic>? ?? {};

    // Fallback: If map is empty but the List exists, artificially create a map
    // so the expanding UI renderer can pick it up natively
    if (docs.isEmpty && application.documentUrls.isNotEmpty) {
      final List<String> labels;
      if (application.applicationType == ApplicationType.driver) {
        labels = [
          AppLocalizations.of(context)!.nationalId,
          AppLocalizations.of(context)!.driversLicense,
          AppLocalizations.of(context)!.vehicleRegistration,
          AppLocalizations.of(context)!.vehicleInsurance,
          AppLocalizations.of(context)!.policeClearance,
          AppLocalizations.of(context)!.facePhoto,
          AppLocalizations.of(context)!.vehiclePhoto,
        ];
      } else if (application.applicationType == ApplicationType.restaurant ||
          application.applicationType == ApplicationType.vendor) {
        labels = _docLabels;
      } else {
        labels = const [];
      }

      docs = {
        for (var i = 0; i < application.documentUrls.length; i++)
          i < labels.length
                  ? labels[i]
                  : AppLocalizations.of(context)!.documentNumber(i + 1):
              application.documentUrls[i]
      };
    }

    if (docs.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ExpansionTile(
          leading: const Icon(Icons.description_outlined,
              size: 22, color: Color(0xFF546E7A)),
          title: Text(AppLocalizations.of(context)!.documents,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          initiallyExpanded: true,
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 20, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'No documents uploaded',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final docEntries = docs.entries.toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.description_outlined,
            size: 22, color: Color(0xFF546E7A)),
        title: Text(AppLocalizations.of(context)!.documents,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        initiallyExpanded: true,
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (var i = 0; i < docEntries.length; i++)
            _buildDocItem(
                context,
                docEntries[i].key,
                docEntries[i].value?.toString() ?? '',
                i,
                application.applicationType),
        ],
      ),
    );
  }

  Widget _buildDocItem(BuildContext context, String key, String url, int index,
      ApplicationType type) {
    if (url.isEmpty) return const SizedBox.shrink();

    IconData icon = Icons.insert_drive_file_outlined;
    if ((type == ApplicationType.restaurant ||
            type == ApplicationType.vendor) &&
        index < _docIcons.length) {
      icon = _docIcons[index];
    } else if (type == ApplicationType.driver) {
      icon = Icons.badge_outlined; // generic driver doc icon
    }

    final label = _formatDocKey(key);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDocumentViewer(context, url, label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1976D2)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              Icon(Icons.check_circle, size: 18, color: Colors.green[400]),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentViewer(BuildContext context, String url, String label) {
    final isPdf = url.toLowerCase().contains('.pdf') ||
        url.toLowerCase().contains('%2F') && url.toLowerCase().contains('pdf');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.description_outlined,
                    size: 20,
                    color: isPdf
                        ? const Color(0xFFC62828)
                        : const Color(0xFF2D3748),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Content
            if (isPdf)
              // PDF — show open button directly
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf,
                        size: 64, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        launchUrlString(url,
                            mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Image — display inline with zoom support
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                      minHeight: 200,
                    ),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (context, url) => const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!
                                      .failedToLoadDocument,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Icon(Icons.pinch_outlined,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Pinch to zoom',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            launchUrlString(url,
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('Open'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1976D2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDocKey(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
