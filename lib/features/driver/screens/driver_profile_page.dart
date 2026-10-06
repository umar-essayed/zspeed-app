import 'package:z_speed/core/localization/language_selector_widget.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/privacy/widgets/privacy_data_dialogs.dart';

import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';
import 'package:z_speed/features/admin/model/application_model.dart';
import 'package:z_speed/features/admin/repository/application_repository_impl.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';

/// Driver profile page that fetches application data from the `applications`
/// collection (same source as admin) and displays 3 expandable sections:
/// Personal Information, Vehicle Information, and Documents.
///
/// Also keeps the Performance Summary and Earnings sections from
/// the driver dashboard viewmodel.
class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  Application? _application;
  bool _isLoadingApplication = true;
  String? _applicationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthCubit>().state.user;
      if (user != null) {
        context.read<DriverDashboardCubit>().init(user.id);
        _loadApplication(user.id);
      }
    });
  }

  Future<void> _loadApplication(String userId) async {
    final repo = ApplicationRepositoryImpl();
    final result = await repo.getApplicationsByUserId(userId);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        // Find the driver application (most recent)
        final driverApps = data
            .where((a) => a.applicationType == ApplicationType.driver)
            .toList();
        setState(() {
          _application = driverApps.isNotEmpty ? driverApps.first : null;
          _isLoadingApplication = false;
        });
      case Err(:final failure):
        setState(() {
          _applicationError = failure.getLocalizedMessage(context);
          _isLoadingApplication = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final driverState = context.watch<DriverDashboardCubit>().state;
    final profile = driverState.driverProfile;

    const Color brandOrange = Color(0xFFF35535);
    const Color brandYellow = Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myProfile,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandOrange, brandYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: user == null || driverState.isBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 16),
                  const Card(child: LanguageSelectorTile()),
                  const SizedBox(height: 24),

                  // ── Application Data Sections ─────────────────────────
                  if (_isLoadingApplication)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_applicationError != null)
                    _buildErrorCard(_applicationError!)
                  else if (_application != null) ...[
                    _buildFormDataSection(
                      title: AppLocalizations.of(context)!.personalInformation,
                      icon: Icons.person,
                      data:
                          _application!.formData['personalInfo']
                              as Map<String, dynamic>? ??
                          {},
                    ),
                    const SizedBox(height: 8),
                    _buildFormDataSection(
                      title: AppLocalizations.of(context)!.vehicleInformation,
                      icon: Icons.directions_car,
                      data:
                          _application!.formData['vehicleInfo']
                              as Map<String, dynamic>? ??
                          {},
                    ),
                    const SizedBox(height: 8),
                    _buildDocumentsSection(),
                  ] else
                    _buildErrorCard(
                      AppLocalizations.of(context)!.noApplicationData,
                    ),

                  const SizedBox(height: 24),

                  // ── Performance Summary (from dashboard VM) ────────────
                  _buildSectionTitle(
                    AppLocalizations.of(context)!.performanceSummary,
                  ),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.star,
                      AppLocalizations.of(context)!.rating,
                      '${profile?.rating.toStringAsFixed(1) ?? "0.0"} (${AppLocalizations.of(context)!.reviewsCount(profile?.ratingCount ?? 0)})',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.check_circle,
                      AppLocalizations.of(context)!.acceptanceRate,
                      '${((profile?.acceptanceRate ?? 1.0) * 100).toStringAsFixed(0)}%',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.delivery_dining,
                      AppLocalizations.of(context)!.totalDeliveries,
                      AppLocalizations.of(
                        context,
                      )!.completedCount(profile?.totalTrips ?? 0),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Earnings & Payout (from dashboard VM) ──────────────
                  _buildSectionTitle(
                    AppLocalizations.of(context)!.earningsAndPayout,
                  ),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.account_balance_wallet,
                      AppLocalizations.of(context)!.walletBalance,
                      AppLocalizations.of(context)!.egpAmount(
                        (profile?.walletBalance ?? 0).toStringAsFixed(2),
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.payments,
                      AppLocalizations.of(context)!.totalEarnings,
                      AppLocalizations.of(context)!.egpAmount(
                        (profile?.totalEarnings ?? 0).toStringAsFixed(2),
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.event_repeat,
                      AppLocalizations.of(context)!.payoutFrequency,
                      profile?.payoutFrequency.toUpperCase() ?? 'WEEKLY',
                    ),
                  ]),
                  const SizedBox(height: 32),

                  // ── Delete Account ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          PrivacyDataDialogs.showDeleteAccount(context),
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: Text(
                        AppLocalizations.of(context)!.deleteAccount,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── Profile Header ──────────────────────────────────────────────────────

  Widget _buildProfileHeader(AppUser user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.teal.shade100,
          backgroundImage: user.profileImage != null
              ? NetworkImage(user.profileImage!)
              : null,
          child: user.profileImage == null
              ? const Icon(Icons.person, size: 50, color: Colors.teal)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        if (user.phone != null) ...[
          const SizedBox(height: 4),
          Text(
            user.phone!,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  // ── Expandable Form Data Section ────────────────────────────────────────

  Widget _buildFormDataSection({
    required String title,
    required IconData icon,
    required Map<String, dynamic> data,
  }) {
    if (data.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF546E7A)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.noDataAvailable,
            style: const TextStyle(color: Color(0xFF9E9E9E)),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, size: 22, color: const Color(0xFF546E7A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: data.entries.map((entry) {
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
                    _formatValue(entry.value),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Documents Section ──────────────────────────────────────────────────

  Widget _buildDocumentsSection() {
    if (_application == null) return const SizedBox.shrink();

    var docs =
        _application!.formData['documents'] as Map<String, dynamic>? ?? {};

    // Fallback: use documentUrls list with labeled names
    if (docs.isEmpty && _application!.documentUrls.isNotEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final labels = [
        l10n.nationalId,
        l10n.driversLicense,
        l10n.vehicleRegistration,
        l10n.vehicleInsurance,
      ];
      docs = {
        for (var i = 0; i < _application!.documentUrls.length; i++)
          i < labels.length ? labels[i] : l10n.documentNumber(i + 1):
              _application!.documentUrls[i],
      };
    }

    if (docs.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(
          Icons.description_outlined,
          size: 22,
          color: Color(0xFF546E7A),
        ),
        title: Text(
          AppLocalizations.of(context)!.documents,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: docs.entries.map((entry) {
          final url = entry.value?.toString() ?? '';
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: url.isNotEmpty
                ? () => _previewDocument(context, _formatKey(entry.key), url)
                : null,
            leading: Icon(
              url.isNotEmpty ? Icons.check_circle : Icons.cancel,
              color: url.isNotEmpty ? Colors.green : Colors.red,
              size: 20,
            ),
            title: Text(
              _formatKey(entry.key),
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: url.isNotEmpty
                ? Text(
                    AppLocalizations.of(context)!.preview,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF90A4AE),
                    ),
                  )
                : null,
            trailing: url.isNotEmpty
                ? const Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: Color(0xFF1976D2),
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  // ── Formatting Helpers ────────────────────────────────────────────────

  /// Converts camelCase keys to Title Case labels.
  String _formatKey(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  String _formatValue(dynamic value) {
    if (value == null) return '—';
    if (value is List) return value.join(', ');
    if (value is Map) {
      return value.entries
          .map((e) => '${_formatKey(e.key.toString())}: ${e.value}')
          .join('\n');
    }
    final str = value.toString().trim();
    return str.isEmpty ? '—' : str;
  }

  void _previewDocument(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 120,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
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
