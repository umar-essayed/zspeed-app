import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_users_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_users_state.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/admin/view/admin_user_detail_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin view displaying directory of active drivers.
///
/// Contains capabilities switches, wallet balance adjustment, search, and details navigation.
class AdminDriversView extends StatefulWidget {
  const AdminDriversView({super.key});

  @override
  State<AdminDriversView> createState() => _AdminDriversViewState();
}

class _AdminDriversViewState extends State<AdminDriversView> {
  String _driverSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AdminUsersCubit, AdminUsersState>(
      builder: (context, state) {
        if (state.isBusy) {
          return Center(
            child: CircularProgressIndicator(color: AdminTheme.primaryOrange),
          );
        }

        if (state.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AdminTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  l10n.noAvailableDrivers, // or generic failure message
                  style: TextStyle(color: AdminTheme.textDark),
                ),
              ],
            ),
          );
        }

        final query = _driverSearchQuery.toLowerCase();
        final drivers = state.users.where((u) {
          if (u.applicationStatus != ApplicationStatus.approved) {
            return false;
          }
          return u.name.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query) ||
              (u.phone ?? '').toLowerCase().contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.activeDrivers,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.read<AdminUsersCubit>().loadUsers();
                  },
                  icon: Icon(Icons.refresh, color: AdminTheme.textMedium),
                  tooltip: l10n.refreshTooltip,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActiveDriversSearchBar(l10n),
            const SizedBox(height: 16),
            if (drivers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    l10n.noAvailableDrivers,
                    style: TextStyle(color: AdminTheme.textMedium),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  return _buildActiveDriverCard(context, drivers[index], l10n);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildActiveDriversSearchBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _driverSearchQuery = val),
        decoration: InputDecoration(
          hintText: l10n.activeDriversSearchPlaceholder,
          prefixIcon: Icon(Icons.search, color: AdminTheme.textLight, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: AdminTheme.textLight, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildActiveDriverCard(BuildContext context, AppUser driver, AppLocalizations l10n) {
    final initials = (driver.name.length >= 2
            ? driver.name.substring(0, 2)
            : driver.name)
        .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AdminTheme.borderColor, width: 1),
      ),
      color: AdminTheme.cardWhite,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminUserDetailView(user: driver),
            ),
          );
        },
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('driverProfiles')
              .doc(driver.id)
              .snapshots(),
          builder: (context, snapshot) {
            final profileData = snapshot.data?.data() as Map<String, dynamic>?;
            final statusStr = profileData?['status'] as String? ?? 'offline';
            final make = profileData?['vehicleMake'] as String? ?? '—';
            final model = profileData?['vehicleModel'] as String? ?? '—';
            final plate = profileData?['licensePlate'] as String? ?? '—';
            final type = profileData?['vehicleType'] as String? ?? '—';
            final balance =
                (profileData?['walletBalance'] as num?)?.toDouble() ?? 0.0;
            final profileImage = profileData?['profileImage'] as String? ??
                profileData?['profilePicture'] as String? ??
                driver.profileImage;

            Color statusColor;
            switch (statusStr) {
              case 'online':
                statusColor = AdminTheme.successGreen;
              case 'busy':
                statusColor = AdminTheme.warningAmber;
              case 'offline':
              default:
                statusColor = Colors.grey.shade400;
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: profileImage == null || profileImage.isEmpty
                                  ? const LinearGradient(
                                      colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              image: profileImage != null && profileImage.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(profileImage),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profileImage == null || profileImage.isEmpty
                                ? Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AdminTheme.cardWhite,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Core Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AdminTheme.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.email_outlined,
                                    size: 13, color: AdminTheme.textLight),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    driver.email,
                                    style: TextStyle(
                                        color: AdminTheme.textLight, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.phone_outlined,
                                        size: 13, color: AdminTheme.textLight),
                                    const SizedBox(width: 5),
                                    Text(
                                      driver.phone ?? '—',
                                      style: TextStyle(
                                          color: AdminTheme.textLight, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 12, color: AdminTheme.textLight),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${driver.createdAt.day}/${driver.createdAt.month}/${driver.createdAt.year}',
                                      style: TextStyle(
                                          color: AdminTheme.textLight, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AdminTheme.textLight),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Wallet Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminTheme.contentBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminTheme.borderColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 20, color: AdminTheme.primaryOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.walletBalanceLabel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AdminTheme.textLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${balance.toStringAsFixed(2)} EGP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: balance >= 0
                                      ? AdminTheme.successGreen
                                      : AdminTheme.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showWalletAdjustmentDialog(
                              context, driver.id, driver.name, l10n),
                          icon: const Icon(Icons.edit_outlined, size: 13),
                          label: Text(l10n.adjustBalance,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Vehicle details & switches
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AdminTheme.borderColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getVehicleIcon(type),
                                size: 20,
                                color: AdminTheme.textMedium,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.vehicleClassification.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AdminTheme.textLight,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$make $model',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AdminTheme.textDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Plate: $plate ($type)',
                                    style: TextStyle(
                                        fontSize: 11, color: AdminTheme.textLight),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Toggles
                      Expanded(
                        flex: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Transport',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AdminTheme.textMedium),
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  height: 28,
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: Switch(
                                      value: driver.canTransport,
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: AdminTheme.primaryOrange,
                                      inactiveThumbColor: Colors.grey.shade400,
                                      inactiveTrackColor: Colors.grey.shade200,
                                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                      onChanged: (val) {
                                        context
                                            .read<AdminUsersCubit>()
                                            .updateDriverCapabilities(driver.id,
                                                canTransport: val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Column(
                              children: [
                                Text(
                                  'Delivery',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AdminTheme.textMedium),
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  height: 28,
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: Switch(
                                      value: driver.canDeliver,
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: AdminTheme.primaryOrange,
                                      inactiveThumbColor: Colors.grey.shade400,
                                      inactiveTrackColor: Colors.grey.shade200,
                                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                      onChanged: (val) {
                                        context
                                            .read<AdminUsersCubit>()
                                            .updateDriverCapabilities(driver.id,
                                                canDeliver: val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWalletAdjustmentDialog(
      BuildContext context, String driverId, String driverName, AppLocalizations l10n) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Adjust Wallet: $driverName'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (EGP)',
                  hintText: 'e.g. 50 or -50',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  if (double.tryParse(val.trim()) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description / Reason',
                  hintText: 'e.g. Manual cash ride commission settlement',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountCtrl.text.trim());
                final desc = descCtrl.text.trim();

                final usersCubit = context.read<AdminUsersCubit>();
                Navigator.pop(dialogCtx);

                await usersCubit.adjustDriverWallet(driverId, amount, desc);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Wallet adjusted successfully by $amount EGP'),
                      backgroundColor: AdminTheme.successGreen,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('car') || t.contains('auto') || t.contains('taxi')) {
      return Icons.directions_car_outlined;
    } else if (t.contains('bike') || t.contains('cycle') || t.contains('motor')) {
      return Icons.motorcycle_outlined;
    } else if (t.contains('truck') || t.contains('van') || t.contains('delivery')) {
      return Icons.local_shipping_outlined;
    }
    return Icons.directions_run_outlined;
  }
}
