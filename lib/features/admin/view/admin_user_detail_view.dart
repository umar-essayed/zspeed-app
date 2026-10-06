import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_application_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/view/admin_application_detail_view.dart';

/// Full-detail view of a user's profile for the admin dashboard.
///
/// Shows:
/// - User info card (name, email, phone, type, status)
/// - Per-field review with approve / reject + reason per field
/// - Linked applications (driver/restaurant) with navigation to detail
/// - User documents (profile image, uploaded docs)
///
/// The admin can approve or reject individual data fields, and the user
/// will see the rejection reason for each field on their profile.
class AdminUserDetailView extends StatefulWidget {
  final AppUser user;

  const AdminUserDetailView({super.key, required this.user});

  @override
  State<AdminUserDetailView> createState() => _AdminUserDetailViewState();
}

class _AdminUserDetailViewState extends State<AdminUserDetailView> {
  late AppUser _user;
  bool _isLoading = false;

  // Field-level review state: field → {status: 'approved'|'rejected', reason: '...'}
  Map<String, Map<String, String>> _fieldReviews = const {};
  List<Application> _userApplications = const [];
  bool _loadingApplications = true;
  DriverProfile? _driverProfile;
  StreamSubscription? _driverProfileSub;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadFieldReviews();
    _loadUserApplications();
    if (_user.type == UserType.driver) {
      _listenToDriverProfile();
    }
  }

  @override
  void dispose() {
    _driverProfileSub?.cancel();
    super.dispose();
  }

  Future<void> _loadFieldReviews() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.id)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final reviews = data?['fieldReviews'] as Map<String, dynamic>?;
        if (reviews != null) {
          setState(() {
            _fieldReviews = reviews.map(
              (key, value) =>
                  MapEntry(key, Map<String, String>.from(value as Map)),
            );
          });
        }
      }
    } catch (_) {
      // Silently fail — field reviews are optional
    }
  }

  Future<void> _loadUserApplications() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: _user.id)
          .orderBy('submittedAt', descending: true)
          .get();
      setState(() {
        _userApplications = snapshot.docs
            .map((doc) => Application.fromMap(doc.data(), doc.id))
            .toList();
        _loadingApplications = false;
      });
    } catch (_) {
      setState(() => _loadingApplications = false);
    }
  }

  void _listenToDriverProfile() {
    _driverProfileSub?.cancel();
    _driverProfileSub = FirebaseFirestore.instance
        .collection('driverProfiles')
        .doc(_user.id)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            setState(() {
              _driverProfile = DriverProfile.fromMap(doc.data()!, doc.id);
            });
          } else {
            // Self-heal: create the document if it doesn't exist
            FirebaseFirestore.instance
                .collection('driverProfiles')
                .doc(_user.id)
                .set({
                  'userId': _user.id,
                  'name': _user.name,
                  'status': 'offline',
                  'rating': 5.0,
                  'ratingCount': 0,
                  'totalTrips': 0,
                  'totalEarnings': 0.0,
                  'walletBalance': 0.0,
                  'earningsLimit': 0.0,
                  'isLimitLocked': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
          }
        });
  }

  Future<void> _showEditLimitDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _driverProfile?.earningsLimit == 0.0
          ? ''
          : _driverProfile?.earningsLimit.toString(),
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Custom Earnings Limit'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Earnings Limit (EGP)',
              hintText: 'Enter 0 or leave empty to use global limit',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = controller.text.trim();
                final val = double.tryParse(input) ?? 0.0;
                await FirebaseFirestore.instance
                    .collection('driverProfiles')
                    .doc(_user.id)
                    .update({'earningsLimit': val});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom earnings limit updated'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryOrange,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmResetLimit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Earnings Limit & Unlock Driver'),
          content: const Text(
            'Are you sure you want to reset the driver earnings limit state and unlock this driver? This will clear total earnings and wallet balance for the current limit check.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Confirm Settle',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final settledAmount = _driverProfile?.walletBalance ?? 0.0;
        await FirebaseFirestore.instance
            .collection('driverProfiles')
            .doc(_user.id)
            .update({
              'walletBalance': 0.0,
              'totalEarnings': 0.0,
              'isLimitLocked': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        final txId = const Uuid().v4();
        await FirebaseFirestore.instance
            .collection('driverWalletTransactions')
            .doc(txId)
            .set({
              'driverId': _user.id,
              'orderId': '',
              'type': 'debit',
              'amount': settledAmount,
              'paymentMethod': 'admin_reset',
              'evidenceUrl': null,
              'confirmedByDriver': true,
              'confirmedAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Driver balance settled and account unlocked successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Failed to reset: $e')));
      }
    }
  }

  Future<void> _updateFieldReview(
    String fieldName,
    String status,
    String? reason,
  ) async {
    setState(() => _isLoading = true);
    try {
      final review = <String, String>{
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        'reviewedAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.id)
          .update({
            'fieldReviews.$fieldName': review,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _fieldReviews[fieldName] = review;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$fieldName ${status == 'approved' ? 'approved' : 'rejected'}',
            ),
            backgroundColor: status == 'approved'
                ? AdminTheme.successGreen
                : AdminTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToUpdate(e.toString()),
            ),
            backgroundColor: AdminTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AdminTheme.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AdminTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _user.name,
          style: TextStyle(
            color: AdminTheme.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          // Overall status badge
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(child: _buildUserStatusBadge(_user.status)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AdminTheme.primaryOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  _buildProfileHeader(),
                  const SizedBox(height: 24),

                  // User info fields with per-field review
                  _buildSectionTitle(
                    AppLocalizations.of(context)!.profileInformationSection,
                  ),
                  const SizedBox(height: 12),
                  _buildReviewableField(
                    'name',
                    AppLocalizations.of(context)!.fullNameLabel,
                    _user.name,
                    icon: Icons.person,
                  ),
                  _buildReviewableField(
                    'email',
                    AppLocalizations.of(context)!.emailLabel2,
                    _user.email,
                    icon: Icons.email,
                  ),
                  _buildReviewableField(
                    'phone',
                    AppLocalizations.of(context)!.phoneLabel,
                    _user.phone ?? '—',
                    icon: Icons.phone,
                  ),
                  _buildReviewableField(
                    'address',
                    AppLocalizations.of(context)!.addressLabel2,
                    _user.address ?? '—',
                    icon: Icons.location_on,
                  ),
                  _buildReviewableField(
                    'type',
                    AppLocalizations.of(context)!.accountTypeLabel,
                    _user.type.name.toUpperCase(),
                    icon: Icons.badge,
                  ),

                  const SizedBox(height: 24),

                  // Profile Image
                  if (_user.profileImage != null &&
                      _user.profileImage!.isNotEmpty) ...[
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.profileImage,
                    ),
                    const SizedBox(height: 12),
                    _buildReviewableDocument(
                      'profileImage',
                      'Profile Photo',
                      _user.profileImage!,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Account Dates
                  _buildSectionTitle(
                    AppLocalizations.of(context)!.accountDetailsSection,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.joinedLabel,
                    _formatDateTime(_user.createdAt),
                  ),
                  if (_user.updatedAt != null)
                    _buildInfoRow(
                      AppLocalizations.of(context)!.lastUpdatedLabel,
                      _formatDateTime(_user.updatedAt!),
                    ),
                  if (_user.appliedAt != null)
                    _buildInfoRow(
                      AppLocalizations.of(context)!.appliedLabel,
                      _formatDateTime(_user.appliedAt!),
                    ),
                  if (_user.approvedAt != null)
                    _buildInfoRow(
                      AppLocalizations.of(context)!.approvedLabel2,
                      _formatDateTime(_user.approvedAt!),
                    ),
                  if (_user.applicationStatus != null)
                    _buildInfoRow(
                      AppLocalizations.of(context)!.applicationStatusLabel,
                      _user.applicationStatus!.name.toUpperCase(),
                    ),
                  if (_user.rejectionReason != null &&
                      _user.rejectionReason!.isNotEmpty)
                    _buildInfoRow(
                      AppLocalizations.of(context)!.globalRejectionReasonLabel,
                      _user.rejectionReason!,
                      isError: true,
                    ),

                  const SizedBox(height: 24),

                  // Driver Capabilities
                  if (_user.type == UserType.driver) ...[
                    _buildSectionTitle('Driver Capabilities'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            activeThumbColor: AdminTheme.primaryOrange,
                            title: Text(
                              'Transport Eligible',
                              style: TextStyle(
                                color: AdminTheme.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Allow this driver to receive passenger transport requests.',
                              style: TextStyle(
                                color: AdminTheme.textLight,
                                fontSize: 12,
                              ),
                            ),
                            value: _user.canTransport,
                            onChanged: (val) async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                if (val) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_user.id)
                                      .update({
                                        'canTransport': true,
                                        'canDeliver': false,
                                      });
                                  if (!mounted) return;
                                  setState(() {
                                    _user = _user.copyWith(
                                      canTransport: true,
                                      canDeliver: false,
                                    );
                                  });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_user.id)
                                      .update({'canTransport': false});
                                  if (!mounted) return;
                                  setState(() {
                                    _user = _user.copyWith(canTransport: false);
                                  });
                                }
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Transport eligibility updated',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Error updating eligibility'),
                                  ),
                                );
                              }
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            activeThumbColor: AdminTheme.primaryOrange,
                            title: Text(
                              'Delivery Eligible',
                              style: TextStyle(
                                color: AdminTheme.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Allow this driver to receive food/package delivery requests.',
                              style: TextStyle(
                                color: AdminTheme.textLight,
                                fontSize: 12,
                              ),
                            ),
                            value: _user.canDeliver,
                            onChanged: (val) async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                if (val) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_user.id)
                                      .update({
                                        'canDeliver': true,
                                        'canTransport': false,
                                      });
                                  if (!mounted) return;
                                  setState(() {
                                    _user = _user.copyWith(
                                      canDeliver: true,
                                      canTransport: false,
                                    );
                                  });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_user.id)
                                      .update({'canDeliver': false});
                                  if (!mounted) return;
                                  setState(() {
                                    _user = _user.copyWith(canDeliver: false);
                                  });
                                }
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Delivery eligibility updated',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Error updating eligibility'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Earnings Limit & Lock Status'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_driverProfile == null)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            // Balance & Status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Wallet Balance',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'EGP ${_driverProfile!.walletBalance.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AdminTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _driverProfile!.isLimitLocked
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : Colors.green.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _driverProfile!.isLimitLocked
                                            ? 'LOCKED'
                                            : 'ACTIVE',
                                        style: TextStyle(
                                          color: _driverProfile!.isLimitLocked
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Earnings',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'EGP ${_driverProfile!.totalEarnings.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AdminTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Current Limit Display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Custom Earnings Limit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _driverProfile!.earningsLimit > 0.0
                                          ? 'EGP ${_driverProfile!.earningsLimit.toStringAsFixed(2)}'
                                          : 'No Custom Limit (using global default)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AdminTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                // Edit Limit button for Superadmin
                                if (context
                                        .read<AuthCubit>()
                                        .state
                                        .user
                                        ?.type ==
                                    UserType.superAdmin)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showEditLimitDialog(context),
                                  ),
                              ],
                            ),

                            // Reset & Unlock Button (for Admin & Superadmin)
                            if (_driverProfile!.isLimitLocked ||
                                _driverProfile!.totalEarnings > 0) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _confirmResetLimit(context),
                                  icon: const Icon(
                                    Icons.lock_open_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Settle Balance & Unlock',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Linked Applications
                  _buildSectionTitle(
                    AppLocalizations.of(context)!.linkedApplicationsSection,
                  ),
                  const SizedBox(height: 12),
                  if (_loadingApplications)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: AdminTheme.primaryOrange,
                        ),
                      ),
                    )
                  else if (_userApplications.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AdminTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.borderColor),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.noApplicationsFound,
                          style: TextStyle(
                            color: AdminTheme.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._userApplications.map(
                      (app) => _buildApplicationCard(app),
                    ),
                ],
              ),
            ),
    );
  }

  // ── Profile Header ──────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    final initials =
        (_user.name.length >= 2 ? _user.name.substring(0, 2) : _user.name)
            .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AdminTheme.primaryOrange, AdminTheme.accentOrange],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _user.profileImage != null && _user.profileImage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _user.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _user.type.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  // ── Reviewable Field ────────────────────────────────────────────────

  Widget _buildReviewableField(
    String fieldKey,
    String label,
    String value, {
    IconData? icon,
  }) {
    final review = _fieldReviews[fieldKey];
    final fieldStatus = review?['status'];
    final reason = review?['reason'];

    Color borderColor = AdminTheme.borderColor;
    Widget? statusIndicator;

    if (fieldStatus == 'approved') {
      borderColor = AdminTheme.successGreen.withValues(alpha: 0.4);
      statusIndicator = Icon(
        Icons.check_circle,
        color: AdminTheme.successGreen,
        size: 20,
      );
    } else if (fieldStatus == 'rejected') {
      borderColor = AdminTheme.errorRed.withValues(alpha: 0.4);
      statusIndicator = Icon(
        Icons.cancel,
        color: AdminTheme.errorRed,
        size: 20,
      );
    }

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AdminTheme.textLight),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: AdminTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: AdminTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (statusIndicator != null) ...[
                statusIndicator,
                const SizedBox(width: 8),
              ],
              // Approve button
              _buildSmallActionButton(
                icon: Icons.check,
                color: AdminTheme.successGreen,
                tooltip: AppLocalizations.of(context)!.approve,
                isActive: fieldStatus == 'approved',
                onPressed: () => _updateFieldReview(fieldKey, 'approved', null),
              ),
              const SizedBox(width: 4),
              // Reject button
              _buildSmallActionButton(
                icon: Icons.close,
                color: AdminTheme.errorRed,
                tooltip: AppLocalizations.of(context)!.reject,
                isActive: fieldStatus == 'rejected',
                onPressed: () => _showRejectFieldDialog(fieldKey),
              ),
            ],
          ),
          // Show rejection reason if rejected
          if (fieldStatus == 'rejected' && reason != null && reason.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminTheme.errorRed.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AdminTheme.errorRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AdminTheme.errorRed,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.rejectionReasonValue(reason.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : AdminTheme.borderColor,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive ? color : AdminTheme.textLight,
          ),
        ),
      ),
    );
  }

  // ── Reviewable Document ─────────────────────────────────────────────

  Widget _buildReviewableDocument(String fieldKey, String label, String url) {
    final review = _fieldReviews[fieldKey];
    final fieldStatus = review?['status'];
    final reason = review?['reason'];

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fieldStatus == 'approved'
              ? AdminTheme.successGreen.withValues(alpha: 0.4)
              : fieldStatus == 'rejected'
              ? AdminTheme.errorRed.withValues(alpha: 0.4)
              : AdminTheme.borderColor,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 16, color: AdminTheme.textLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AdminTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildSmallActionButton(
                icon: Icons.check,
                color: AdminTheme.successGreen,
                tooltip: AppLocalizations.of(context)!.approve,
                isActive: fieldStatus == 'approved',
                onPressed: () => _updateFieldReview(fieldKey, 'approved', null),
              ),
              const SizedBox(width: 4),
              _buildSmallActionButton(
                icon: Icons.close,
                color: AdminTheme.errorRed,
                tooltip: AppLocalizations.of(context)!.reject,
                isActive: fieldStatus == 'rejected',
                onPressed: () => _showRejectFieldDialog(fieldKey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Document preview/link
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AdminTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 32,
                        color: AdminTheme.textLight,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.couldNotLoadImage,
                        style: TextStyle(
                          fontSize: 11,
                          color: AdminTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (fieldStatus == 'rejected' && reason != null && reason.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdminTheme.errorRed.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AdminTheme.errorRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AdminTheme.errorRed,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.rejectionReasonValue(reason.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Reject Dialog ───────────────────────────────────────────────────

  Future<void> _showRejectFieldDialog(String fieldKey) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.rejectItem(fieldKey.toString()),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.provideRejectionReason,
              style: TextStyle(fontSize: 13, color: AdminTheme.textMedium),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.rejectFieldHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorRed,
              foregroundColor: AdminTheme.white,
            ),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      await _updateFieldReview(fieldKey, 'rejected', reason);
    }
  }

  // ── Application Card ────────────────────────────────────────────────

  Widget _buildApplicationCard(Application app) {
    final isDriver = app.applicationType == ApplicationType.driver;
    final name = isDriver
        ? (app.formData['personalInfo']?['name'] as String? ?? 'Driver App')
        : (app.formData['businessInfo']?['restaurantName'] as String? ??
              'Restaurant App');

    Color statusColor;
    String statusLabel;
    switch (app.status) {
      case ReviewStatus.pending:
      case ReviewStatus.underReview:
        statusColor = AdminTheme.warningAmber;
        statusLabel = AppLocalizations.of(context)!.pending;
      case ReviewStatus.approved:
        statusColor = AdminTheme.successGreen;
        statusLabel = AppLocalizations.of(context)!.approvedLabel;
      case ReviewStatus.rejected:
        statusColor = AdminTheme.errorRed;
        statusLabel = AppLocalizations.of(context)!.rejectedLabel;
    }

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: ListTile(
        leading: Icon(
          isDriver ? Icons.directions_car : Icons.store,
          color: isDriver ? const Color(0xFF1976D2) : AdminTheme.primaryOrange,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${isDriver ? AppLocalizations.of(context)!.driverLabel2 : AppLocalizations.of(context)!.restaurantLabel2} ${AppLocalizations.of(context)!.applicationLabel} • ${AppLocalizations.of(context)!.submittedLabel} ${_formatDate(app.submittedAt)}',
          style: TextStyle(fontSize: 12, color: AdminTheme.textLight),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AdminTheme.textLight,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AdminApplicationCubit>(),
                child: AdminApplicationDetailView(applicationId: app.id),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AdminTheme.textDark,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AdminTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isError ? AdminTheme.errorRed : AdminTheme.textDark,
                fontWeight: isError ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusBadge(UserStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case UserStatus.active:
        bgColor = AdminTheme.successGreen.withValues(alpha: 0.1);
        textColor = AdminTheme.successGreen;
        label = AppLocalizations.of(context)!.active;
      case UserStatus.inactive:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        label = AppLocalizations.of(context)!.inactive;
      case UserStatus.suspended:
        bgColor = AdminTheme.warningAmber.withValues(alpha: 0.1);
        textColor = AdminTheme.warningAmber;
        label = AppLocalizations.of(context)!.suspended;
      case UserStatus.pendingVerification:
        bgColor = AdminTheme.infoBlue.withValues(alpha: 0.1);
        textColor = AdminTheme.infoBlue;
        label = AppLocalizations.of(context)!.pending;
      case UserStatus.banned:
        bgColor = AdminTheme.errorRed.withValues(alpha: 0.1);
        textColor = AdminTheme.errorRed;
        label = AppLocalizations.of(context)!.banned;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
