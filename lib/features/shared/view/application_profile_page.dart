import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:z_speed/core/core.dart';
import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:z_speed/features/admin/repository/application_repository.dart';
import 'package:z_speed/features/admin/repository/application_repository_impl.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/core/utils/image_utils.dart';

/// Page where driver/restaurant applicants can view and edit their
/// submitted application data. Editing an approved section shows a
/// warning dialog and resets that section to pending.
class ApplicationProfilePage extends StatefulWidget {
  const ApplicationProfilePage({super.key});

  @override
  State<ApplicationProfilePage> createState() => _ApplicationProfilePageState();
}

class _ApplicationProfilePageState extends State<ApplicationProfilePage> {
  final ApplicationRepository _repo = ApplicationRepositoryImpl();
  Application? _application;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _repo.getApplicationsByUserId(user.id);
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _application = data.isNotEmpty ? data.first : null;
          _loading = false;
        });
      case Err(:final failure):
        setState(() {
          _error = failure.getLocalizedMessage(context);
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myApplication),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadApplication,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }
    if (_application == null) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noApplicationFound),
      );
    }

    final app = _application!;
    final formData = app.formData;
    final isRestaurant = app.applicationType == ApplicationType.restaurant ||
        app.applicationType == ApplicationType.vendor;

    // Build section list based on application type
    final sections = isRestaurant
        ? _buildRestaurantSections(formData, app)
        : _buildDriverSections(formData, app);

    return RefreshIndicator(
      onRefresh: _loadApplication,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall status card
          _StatusCard(application: app),
          const SizedBox(height: 16),
          ...sections,
        ],
      ),
    );
  }

  List<Widget> _buildRestaurantSections(
      Map<String, dynamic> formData, Application app) {
    // Extract locationInfo but format operatingHours separately
    final locationData = formData['locationInfo'] as Map?;
    final locationFields =
        _extractFields(locationData, skipKeys: {'operatingHours'});
    final operatingHours = locationData?['operatingHours'];
    if (operatingHours is Map) {
      locationFields['operatingHours'] =
          _formatOperatingHoursFromMap(operatingHours);
    }

    return [
      _SectionCard(
        sectionKey: 'businessInfo',
        title: AppLocalizations.of(context)!.businessInformation,
        icon: Icons.restaurant_outlined,
        application: app,
        fields: _extractFields(formData['businessInfo']),
        onSave: (data) => _saveSection('businessInfo', data),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        sectionKey: 'locationInfo',
        title: AppLocalizations.of(context)!.locationAndHours,
        icon: Icons.location_on_outlined,
        application: app,
        fields: locationFields,
        onSave: (data) => _saveSection('locationInfo', data),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        sectionKey: 'contactInfo',
        title: AppLocalizations.of(context)!.contactInformation,
        icon: Icons.contact_phone_outlined,
        application: app,
        fields: _extractFields(formData['contactInfo']),
        onSave: (data) => _saveSection('contactInfo', data),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        sectionKey: 'bankInfo',
        title: AppLocalizations.of(context)!.bankInformation,
        icon: Icons.account_balance_outlined,
        application: app,
        fields: _extractFields(formData['bankInfo']),
        onSave: (data) => _saveSection('bankInfo', data),
      ),
      const SizedBox(height: 12),
      // Documents
      _DocumentsCard(
        application: app,
        documentUrls: app.documentUrls,
        onSave: _saveDocuments,
      ),
    ];
  }

  List<Widget> _buildDriverSections(
      Map<String, dynamic> formData, Application app) {
    return [
      _SectionCard(
        sectionKey: 'personalInfo',
        title: AppLocalizations.of(context)!.personalInformation,
        icon: Icons.person_outline,
        application: app,
        fields: _extractFields(formData['personalInfo']),
        onSave: (data) => _saveSection('personalInfo', data),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        sectionKey: 'vehicleInfo',
        title: AppLocalizations.of(context)!.vehicleInformation,
        icon: Icons.directions_car_outlined,
        application: app,
        fields: _extractFields(formData['vehicleInfo']),
        onSave: (data) => _saveSection('vehicleInfo', data),
      ),
      const SizedBox(height: 12),
      // Documents
      _DocumentsCard(
        application: app,
        documentUrls: app.documentUrls,
        onSave: _saveDocuments,
      ),
    ];
  }

  Map<String, String> _extractFields(dynamic data,
      {Set<String> skipKeys = const {}}) {
    if (data is! Map) return {};
    final result = <String, String>{};
    for (final entry in data.entries) {
      final key = entry.key.toString();
      if (skipKeys.contains(key)) continue;
      final value = entry.value;
      if (value is String) {
        result[key] = value;
      } else if (value is List) {
        result[key] = value.join(', ');
      } else if (value is Map) {
        result[key] =
            value.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      } else {
        result[key] = value.toString();
      }
    }
    return result;
  }

  /// Format operating hours from the Firestore serialized map.
  /// Input: {'Saturday': {'closed': false, 'open': '9:00', 'close': '22:00'}, ...}
  String _formatOperatingHoursFromMap(Map hours) {
    final dayOrder = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];
    final lines = <String>[];
    for (final day in dayOrder) {
      final data = hours[day];
      if (data is Map) {
        final isClosed = data['closed'] == true;
        if (isClosed) {
          lines.add('$day: Closed');
        } else {
          final open = data['open'] ?? '';
          final close = data['close'] ?? '';
          lines.add('$day: $open - $close');
        }
      }
    }
    return lines.join('\n');
  }

  Future<void> _saveSection(
      String sectionKey, Map<String, dynamic> data) async {
    if (_application == null) return;

    final isApproved =
        _application!.sectionStatus(sectionKey) == SectionReviewStatus.approved;

    if (isApproved) {
      final confirm = await _showEditWarningDialog();
      if (confirm != true) return;
    }

    setState(() => _loading = true);

    final result = await _repo.updateApplicationSection(
      applicationId: _application!.id,
      sectionKey: sectionKey,
      sectionData: data,
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sectionUpdatedSentBack),
            backgroundColor: const Color(0xFF388E3C),
          ),
        );
        // Refresh the auth viewmodel so the PendingAccountOverlay reacts
        context.read<AuthCubit>().checkAuthStatus();
        await _loadApplication();
      case Err(:final failure):
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToSave(
                  failure.getLocalizedMessage(context).toString())),
              backgroundColor: const Color(0xFFD32F2F),
            ),
          );
        }
    }
  }

  Future<void> _saveDocuments(List<String> documentUrls) async {
    if (_application == null) return;

    final isApproved = _application!.status == ReviewStatus.approved;

    if (isApproved) {
      final confirm = await _showEditWarningDialog();
      if (confirm != true) return;
    }

    setState(() => _loading = true);

    final result = await _repo.updateApplicationDocuments(
      applicationId: _application!.id,
      documentUrls: documentUrls,
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sectionUpdatedSentBack),
            backgroundColor: const Color(0xFF388E3C),
          ),
        );
        context.read<AuthCubit>().checkAuthStatus();
        await _loadApplication();
      case Err(:final failure):
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToSave(
                  failure.getLocalizedMessage(context).toString())),
              backgroundColor: const Color(0xFFD32F2F),
            ),
          );
        }
    }
  }

  Future<bool?> _showEditWarningDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFFF9800),
          size: 48,
        ),
        title: Text(AppLocalizations.of(context)!.editApprovedSection),
        content: Text(
          AppLocalizations.of(context)!.editApprovedSectionDesc,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
            ),
            child: Text(AppLocalizations.of(context)!.editAnyway),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final Application application;

  const _StatusCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final status = application.status;
    final Color color;
    final IconData icon;
    final String label;

    switch (status) {
      case ReviewStatus.approved:
        color = const Color(0xFF388E3C);
        icon = Icons.check_circle;
        label = AppLocalizations.of(context)!.statusApprovedLabel;
      case ReviewStatus.rejected:
        color = const Color(0xFFD32F2F);
        icon = Icons.cancel;
        label = AppLocalizations.of(context)!.statusRejectedLabel;
      case ReviewStatus.underReview:
        color = const Color(0xFF1976D2);
        icon = Icons.visibility;
        label = AppLocalizations.of(context)!.statusUnderReviewLabel;
      case ReviewStatus.pending:
        color = const Color(0xFFFF9800);
        icon = Icons.hourglass_top;
        label = AppLocalizations.of(context)!.statusPendingLabel;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.applicationStatusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              application.typeDisplayName,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  final String sectionKey;
  final String title;
  final IconData icon;
  final Application application;
  final Map<String, String> fields;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _SectionCard({
    required this.sectionKey,
    required this.title,
    required this.icon,
    required this.application,
    required this.fields,
    required this.onSave,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _editing = false;
  late Map<String, TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final entry in widget.fields.entries)
        entry.key: TextEditingController(text: entry.value),
    };
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  SectionReviewStatus get _sectionStatus =>
      widget.application.sectionStatus(widget.sectionKey);

  Color get _statusColor {
    switch (_sectionStatus) {
      case SectionReviewStatus.approved:
        return const Color(0xFF388E3C);
      case SectionReviewStatus.rejected:
        return const Color(0xFFD32F2F);
      case SectionReviewStatus.pending:
        return const Color(0xFFFF9800);
    }
  }

  String _statusLabelFor(BuildContext context) {
    switch (_sectionStatus) {
      case SectionReviewStatus.approved:
        return AppLocalizations.of(context)!.statusApprovedLabel;
      case SectionReviewStatus.rejected:
        return AppLocalizations.of(context)!.statusRejectedLabel;
      case SectionReviewStatus.pending:
        return AppLocalizations.of(context)!.statusPendingLabel;
    }
  }

  String _formatKey(String key) {
    // camelCase → Title Case
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceFirst(key[0], key[0].toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final rejectionReason =
        widget.application.sectionReasons[widget.sectionKey];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: const Color(0xFF2D3748)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Section status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabelFor(context),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit toggle
                IconButton(
                  icon: Icon(
                    _editing ? Icons.close : Icons.edit_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _editing = !_editing),
                  tooltip: _editing
                      ? AppLocalizations.of(context)!.cancelTooltip
                      : AppLocalizations.of(context)!.editTooltip,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Rejection reason
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rejectionReason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in _controllers.entries) ...[
                  if (_editing)
                    TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: _formatKey(entry.key),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      maxLines: entry.value.text.contains('\n') ? 4 : 1,
                    )
                  else
                    _ReadOnlyField(
                      label: _formatKey(entry.key),
                      value: entry.value.text,
                    ),
                  const SizedBox(height: 12),
                ],

                // Save button
                if (_editing)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _onSave,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(_saving
                          ? AppLocalizations.of(context)!.savingChanges
                          : AppLocalizations.of(context)!.saveChanges),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF35535),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);
    final data = <String, dynamic>{
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
    await widget.onSave(data);
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '—',
          style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
        ),
      ],
    );
  }
}

class _DocumentsCard extends StatefulWidget {
  final Application application;
  final List<String> documentUrls;
  final Future<void> Function(List<String> documentUrls) onSave;

  const _DocumentsCard({
    required this.application,
    required this.documentUrls,
    required this.onSave,
  });

  @override
  State<_DocumentsCard> createState() => _DocumentsCardState();
}

class _DocumentsCardState extends State<_DocumentsCard> {
  List<String> _getDocLabels(BuildContext context) {
    if (widget.application.applicationType == ApplicationType.driver) {
      return [
        AppLocalizations.of(context)!.nationalId,
        AppLocalizations.of(context)!.driversLicense,
        AppLocalizations.of(context)!.vehicleRegistration,
        AppLocalizations.of(context)!.vehicleInsurance,
        AppLocalizations.of(context)!.policeClearance,
        AppLocalizations.of(context)!.facePhoto,
        AppLocalizations.of(context)!.vehiclePhoto,
      ];
    }
    return [
      AppLocalizations.of(context)!.commercialRegistration,
      AppLocalizations.of(context)!.businessLicenseDoc,
      AppLocalizations.of(context)!.healthCertificate,
      AppLocalizations.of(context)!.taxRegistrationDoc,
    ];
  }

  List<IconData> _getDocIcons() {
    if (widget.application.applicationType == ApplicationType.driver) {
      return const [
        Icons.badge_outlined,
        Icons.card_membership_outlined,
        Icons.description_outlined,
        Icons.security_outlined,
        Icons.policy_outlined,
        Icons.face_outlined,
        Icons.directions_car_outlined,
      ];
    }
    return const [
      Icons.business_outlined,
      Icons.verified_outlined,
      Icons.health_and_safety_outlined,
      Icons.receipt_long_outlined,
    ];
  }

  bool _editing = false;
  bool _saving = false;
  int? _uploadingIndex;
  late List<String> _currentUrls;

  @override
  void initState() {
    super.initState();
    _currentUrls = List.from(widget.documentUrls);
  }

  @override
  void didUpdateWidget(covariant _DocumentsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _currentUrls = List.from(widget.documentUrls);
    }
  }

  Color get _statusColor {
    switch (widget.application.status) {
      case ReviewStatus.approved:
        return const Color(0xFF388E3C);
      case ReviewStatus.rejected:
        return const Color(0xFFD32F2F);
      case ReviewStatus.pending:
      case ReviewStatus.underReview:
        return const Color(0xFFFF9800);
    }
  }

  String _statusLabelFor(BuildContext context) {
    switch (widget.application.status) {
      case ReviewStatus.approved:
        return AppLocalizations.of(context)!.statusApprovedLabel;
      case ReviewStatus.rejected:
        return AppLocalizations.of(context)!.statusRejectedLabel;
      case ReviewStatus.pending:
        return AppLocalizations.of(context)!.statusPendingLabel;
      case ReviewStatus.underReview:
        return AppLocalizations.of(context)!.statusUnderReviewLabel;
    }
  }

  Future<void> _pickAndUploadDocument(int index) async {
    final pickedFile = await ImageUtils.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    final sizeBytes = await pickedFile.length();
    if (!mounted) return;
    if (sizeBytes > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fileExceedsThe10mb),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _uploadingIndex = index);

    try {
      final uploadService = MediaUploadService();
      final isDriver = widget.application.applicationType == ApplicationType.driver;
      final folder = isDriver
          ? 'drivers/${widget.application.userId}/documents'
          : 'restaurants/${widget.application.userId}/documents';
      final result = await uploadService.uploadXFile(pickedFile, folder);

      if (mounted) {
        setState(() {
          _currentUrls[index] = result.url;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .failedToUploadDocument(e.toString())),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingIndex = null);
      }
    }
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);
    await widget.onSave(_currentUrls);
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 20, color: Color(0xFF2D3748)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.uploadedDocuments,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Section status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabelFor(context),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit toggle
                IconButton(
                  icon: Icon(
                    _editing ? Icons.close : Icons.edit_outlined,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_editing) {
                        _currentUrls = List.from(widget.documentUrls);
                      }
                      _editing = !_editing;
                    });
                  },
                  tooltip: _editing
                      ? AppLocalizations.of(context)!.cancelTooltip
                      : AppLocalizations.of(context)!.editTooltip,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (_currentUrls.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(context)!.noDocumentsUploaded),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < _currentUrls.length; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (_editing) {
                            if (_uploadingIndex == null) {
                              _pickAndUploadDocument(i);
                            }
                          } else {
                            _showDocumentViewer(
                              context,
                              _currentUrls[i],
                              i < _getDocLabels(context).length
                                  ? _getDocLabels(context)[i]
                                  : AppLocalizations.of(context)!
                                      .documentWithIndex((i + 1).toString()),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _editing
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFFFE0B2),
                              width: _editing ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_uploadingIndex == i)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(
                                  i < _getDocIcons().length
                                      ? _getDocIcons()[i]
                                      : Icons.insert_drive_file_outlined,
                                  size: 20,
                                  color: const Color(0xFFFF9800),
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  i < _getDocLabels(context).length
                                      ? _getDocLabels(context)[i]
                                      : AppLocalizations.of(context)!
                                          .documentWithIndex(
                                              (i + 1).toString()),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                              if (_currentUrls[i].isNotEmpty &&
                                  _uploadingIndex != i)
                                Icon(Icons.check_circle,
                                    size: 18, color: Colors.green[400]),
                              const SizedBox(width: 8),
                              if (_editing && _uploadingIndex != i)
                                const Icon(Icons.upload_file,
                                    size: 16, color: Color(0xFFFF9800))
                              else if (!_editing)
                                Icon(Icons.open_in_new,
                                    size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Save button
                  if (_editing)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _saving || _uploadingIndex != null ? null : _onSave,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_saving
                            ? AppLocalizations.of(context)!.savingChanges
                            : AppLocalizations.of(context)!.saveChanges),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF35535),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDocumentViewer(BuildContext context, String url, String label) {
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
                  const Icon(Icons.description_outlined,
                      size: 20, color: Color(0xFF2D3748)),
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
            // Image
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
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
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
