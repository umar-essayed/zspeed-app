import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_vendors_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_vendors_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/widgets/admin_dialogs.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';
import 'package:z_speed/core/permissions/permission_service.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/admin/view/admin_vendor_detail_view.dart';
import 'package:z_speed/features/admin/widgets/admin_add_vendor_sheet.dart';

/// Vendor-management view for the admin panel.
///
/// Theme colors are sourced directly from [AdminTheme].
class AdminVendorsView extends StatelessWidget {
  const AdminVendorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminVendorsCubit, AdminVendorsState>(
      builder: (context, state) {
        // Loading state
        if (state.isBusy) {
          return Center(
            child: CircularProgressIndicator(
              color: AdminTheme.primaryOrange,
            ),
          );
        }

        // Error state
        if (state.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AdminTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  state.failure?.getLocalizedMessage(context) ??
                      'An error occurred',
                  style: TextStyle(color: AdminTheme.textDark, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<AdminVendorsCubit>().loadVendors(),
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryOrange,
                    foregroundColor: AdminTheme.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Success state
        final currentUserType =
            context.read<AuthCubit>().state.user?.type ?? UserType.admin;

        return _VendorsContent(
          vendors: state.filteredVendors,
          allVendors: state.vendors,
          currentUserType: currentUserType,
          onUpdateStatus: context.read<AdminVendorsCubit>().updateStatus,
          onDeleteVendor: context.read<AdminVendorsCubit>().deleteVendor,
          onUpdateVendorType:
              context.read<AdminVendorsCubit>().updateVendorType,
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: () =>
              context.read<AdminVendorsCubit>().loadVendors(isLoadMore: true),
          vendorTypeFilter: state.vendorTypeFilter,
          onVendorTypeFilter:
              context.read<AdminVendorsCubit>().setVendorTypeFilter,
        );
      },
    );
  }
}

/// Internal widget to render vendor list when data is loaded.
class _VendorsContent extends StatelessWidget {
  const _VendorsContent({
    required this.vendors,
    required this.allVendors,
    required this.currentUserType,
    required this.onUpdateStatus,
    required this.onDeleteVendor,
    required this.onUpdateVendorType,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.vendorTypeFilter,
    required this.onVendorTypeFilter,
  });

  final List<AdminVendor> vendors;
  final List<Restaurant> allVendors;
  final UserType currentUserType;
  final Future<void> Function(String vendorId, RestaurantStatus status)
      onUpdateStatus;
  final Future<void> Function(String vendorId) onDeleteVendor;
  final Future<void> Function(String vendorId, VendorType vendorType)
      onUpdateVendorType;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VendorType? vendorTypeFilter;
  final void Function(VendorType?) onVendorTypeFilter;

  Color _vendorStatusColor(RestaurantStatus status) {
    switch (status) {
      case RestaurantStatus.active:
        return AdminTheme.successGreen;
      case RestaurantStatus.pending:
        return AdminTheme.warningAmber;
      case RestaurantStatus.suspended:
        return AdminTheme.errorRed;
    }
  }

  IconData _resolveVendorIcon(VendorType type) {
    switch (type) {
      case VendorType.restaurant:
        return Icons.restaurant;
      case VendorType.supermarket:
        return Icons.local_grocery_store;
      case VendorType.pharmacy:
        return Icons.local_pharmacy;
      case VendorType.bookstore:
        return Icons.menu_book;
      case VendorType.homeFurnishing:
        return Icons.chair;
      case VendorType.meatAndProteins:
        return Icons.restaurant_menu;
      case VendorType.clothes:
        return Icons.checkroom;
      case VendorType.buyAndSell:
        return Icons.swap_horiz;
      case VendorType.electronics:
        return Icons.devices;
    }
  }

  String _buildDeliveryFeeDescription(BuildContext context, Restaurant restaurant) {
    final l10n = AppLocalizations.of(context)!;
    if (restaurant.deliveryFeeMode == DeliveryFeeMode.fixed) {
      return l10n.deliveryFeeFixed(restaurant.deliveryFee.toStringAsFixed(0));
    } else {
      if (restaurant.deliveryFeeSubMode == DeliveryFeeSubMode.formula) {
        final formula = restaurant.deliveryFeeFormula ?? {};
        final base = (formula['baseFee'] ?? 15.0).toStringAsFixed(0);
        final perKm = (formula['perKmFee'] ?? 5.0).toStringAsFixed(0);
        return l10n.deliveryFeeFormula(base, perKm);
      } else {
        final tiers = restaurant.deliveryFeeTiers ?? [];
        return l10n.deliveryFeeTiers(tiers.length.toString());
      }
    }
  }

  String _getLocalizedStatus(BuildContext context, RestaurantStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case RestaurantStatus.active:
        return l10n.active;
      case RestaurantStatus.pending:
        return l10n.pendingVerification;
      case RestaurantStatus.suspended:
        return l10n.suspended;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.vendorManagement,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (PermissionService.canEditVendor(currentUserType))
              ElevatedButton.icon(
                onPressed: () => showAddVendorSheet(context),
                icon: const Icon(Icons.store, size: 16),
                label: Text(AppLocalizations.of(context)!.addVendor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryOrange,
                  foregroundColor: AdminTheme.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Vendor type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _VendorFilterChip(
                label: AppLocalizations.of(context)!.allFilter,
                selected: vendorTypeFilter == null,
                onTap: () => onVendorTypeFilter(null),
              ),
              const SizedBox(width: 8),
              for (final type in VendorType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _VendorFilterChip(
                    label: type.getLocalizedLabel(AppLocalizations.of(context)!),
                    selected: vendorTypeFilter == type,
                    onTap: () => onVendorTypeFilter(type),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            children: [
              if (vendors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.store_outlined,
                            size: 48, color: AdminTheme.textLight),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.noVendorsFound,
                            style: TextStyle(color: AdminTheme.textMedium)),
                      ],
                    ),
                  ),
                ),
              ...vendors.map((vendor) {
                final statusColor = _vendorStatusColor(vendor.status);
                final statusText = vendor.status.toString().split('.').last;
                final restaurant =
                    allVendors.firstWhere((r) => r.id == vendor.id);

                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AdminVendorsCubit>(),
                          child: AdminVendorDetailView(restaurant: restaurant),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    key: ValueKey(vendor.id),
                    margin: const EdgeInsetsDirectional.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AdminTheme.borderColor, width: 1),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 768;
                        if (isMobile) {
                          return _buildMobileVendorCard(
                              vendor, restaurant, statusColor, statusText, context);
                        }
                        return _buildDesktopVendorRow(
                            vendor, restaurant, statusColor, statusText, context);
                      },
                    ),
                  ),
                );
              }),
              if (hasMore && vendors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: isLoadingMore
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: onLoadMore,
                          style: TextButton.styleFrom(
                            foregroundColor: AdminTheme.primaryOrange,
                          ),
                          child: Text(AppLocalizations.of(context)!.loadMore),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile card layout ─────────────────────────────────────────────

  Widget _buildMobileVendorCard(AdminVendor vendor, Restaurant restaurant, Color statusColor,
      String statusText, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Header (Avatar, Name, Category) & Wallet Balance
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AdminTheme.primaryOrange, AdminTheme.accentOrange],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  _resolveVendorIcon(restaurant.vendorType),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vendor.vendorType.getLocalizedLabel(AppLocalizations.of(context)!)} • ${vendor.category}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AdminTheme.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Wallet Balance Stacked on the Right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${restaurant.walletBalance.toStringAsFixed(0)} EGP',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: restaurant.walletBalance >= 0
                        ? AdminTheme.successGreen
                        : AdminTheme.errorRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.walletBalanceLabel,
                  style: TextStyle(fontSize: 10, color: AdminTheme.textLight),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Badges (Status, Rating, Delivery)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Status Badge
            InkWell(
              onTap: PermissionService.canEditVendor(currentUserType)
                  ? () async {
                      final newStatus = await AdminDialogs.pickVendorStatus(
                          context,
                          currentStatus: vendor.status);
                      if (newStatus != null && context.mounted) {
                        await onUpdateStatus(vendor.id, newStatus);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getLocalizedStatus(context, vendor.status).toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Rating Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminTheme.warningAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: AdminTheme.warningAmber, size: 10),
                  const SizedBox(width: 3),
                  Text(
                    vendor.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: AdminTheme.warningAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Delivery Fee Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminTheme.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _buildDeliveryFeeDescription(context, restaurant),
                style: TextStyle(
                  fontSize: 10,
                  color: AdminTheme.infoBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5E5)),
        const SizedBox(height: 8),

        // Row 3: Action Buttons (Adjust Wallet & Edit/Delete)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Adjust Balance Button (Outline/Clean Style)
            OutlinedButton.icon(
              onPressed: () => _showVendorWalletAdjustmentDialog(context, restaurant),
              icon: Icon(Icons.account_balance_wallet_outlined, size: 12, color: AdminTheme.primaryOrange),
              label: Text(
                AppLocalizations.of(context)!.adjustBalance,
                style: TextStyle(fontSize: 11, color: AdminTheme.primaryOrange, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AdminTheme.primaryOrange.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // Icons on the right
            Row(
              children: [
                IconButton(
                  tooltip: 'Set Priority (${restaurant.priority})',
                  icon: const Icon(Icons.star_rate_rounded,
                      color: Color(0xFFFFB800), size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showPriorityDialog(context, restaurant),
                ),
                const SizedBox(width: 14),
                IconButton(
                  tooltip: 'Change category',
                  icon: Icon(Icons.category_outlined,
                      color: AdminTheme.textMedium, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showChangeTypeDialog(context, vendor),
                ),
                const SizedBox(width: 14),
                if (PermissionService.canEditVendor(currentUserType))
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: AdminTheme.textMedium, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<AdminVendorsCubit>(),
                            child: AdminVendorDetailView(restaurant: restaurant),
                          ),
                        ),
                      );
                    },
                  ),
                if (PermissionService.canEditVendor(currentUserType))
                  const SizedBox(width: 14),
                if (PermissionService.canDeleteVendor(currentUserType))
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AdminTheme.errorRed, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDeleteVendor(context, vendor),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Desktop row layout ─────────────────────────────────────────────

  Widget _buildDesktopVendorRow(AdminVendor vendor, Restaurant restaurant, Color statusColor,
      String statusText, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [AdminTheme.primaryOrange, AdminTheme.accentOrange],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              _resolveVendorIcon(restaurant.vendorType),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textDark,
                ),
              ),
              Text(
                '${vendor.vendorType.getLocalizedLabel(AppLocalizations.of(context)!)} • ${vendor.category}',
                style: TextStyle(
                  fontSize: 12,
                  color: AdminTheme.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Chip(
                    label: Text(
                      '⭐ ${vendor.rating}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AdminTheme.warningAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor:
                        AdminTheme.warningAmber.withValues(alpha: 0.1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  const SizedBox(width: 6),
                  Chip(
                    label: Text(
                      '🎯 Priority: ${restaurant.priority}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AdminTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor:
                        AdminTheme.primaryOrange.withValues(alpha: 0.1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _buildDeliveryFeeDescription(context, restaurant),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.textDark,
                ),
              ),
              const Text(
                'Delivery Settings',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${restaurant.walletBalance.toStringAsFixed(2)} EGP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: restaurant.walletBalance >= 0
                      ? AdminTheme.successGreen
                      : AdminTheme.errorRed,
                ),
              ),
              const Text(
                'Wallet Balance',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: PermissionService.canEditVendor(currentUserType)
                      ? () async {
                          final newStatus = await AdminDialogs.pickVendorStatus(
                              context,
                              currentStatus: vendor.status);
                          if (newStatus != null && context.mounted) {
                            await onUpdateStatus(vendor.id, newStatus);
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Adjust Wallet',
                  icon: Icon(Icons.account_balance_wallet_outlined,
                      color: AdminTheme.successGreen, size: 16),
                  onPressed: () => _showVendorWalletAdjustmentDialog(context, restaurant),
                ),
                IconButton(
                  tooltip: 'Set Priority (${restaurant.priority})',
                  icon: const Icon(Icons.star_rate_rounded,
                      color: Color(0xFFFFB800), size: 16),
                  onPressed: () => _showPriorityDialog(context, restaurant),
                ),
                IconButton(
                  tooltip: 'Change type (${vendor.vendorType.label})',
                  icon: Icon(Icons.category_outlined,
                      color: AdminTheme.infoBlue, size: 16),
                  onPressed: () => _showChangeTypeDialog(context, vendor),
                ),
                if (PermissionService.canEditVendor(currentUserType))
                  IconButton(
                    icon: Icon(Icons.edit,
                        color: AdminTheme.primaryOrange, size: 16),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<AdminVendorsCubit>(),
                            child:
                                AdminVendorDetailView(restaurant: restaurant),
                          ),
                        ),
                      );
                    },
                  ),
                if (PermissionService.canDeleteVendor(currentUserType))
                  IconButton(
                    icon: Icon(Icons.delete,
                        color: AdminTheme.errorRed, size: 16),
                    onPressed: () => _confirmDeleteVendor(context, vendor),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showChangeTypeDialog(BuildContext context, AdminVendor vendor) async {
    final picked = await showDialog<VendorType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.changeVendorType),
        children: VendorType.values.map((type) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(type),
            child: Row(
              children: [
                if (type == vendor.vendorType)
                  const Icon(Icons.check, size: 16, color: Colors.green)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(type.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (picked != null && picked != vendor.vendorType && context.mounted) {
      await onUpdateVendorType(vendor.id, picked);
    }
  }

  void _showPriorityDialog(BuildContext context, Restaurant restaurant) {
    final priorityCtrl = TextEditingController(text: restaurant.priority.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Set Vendor Priority: ${restaurant.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Higher priority scores show up first in recommended products feeds (e.g. 100 > 10 > 0).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priorityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Priority Score',
                  hintText: 'e.g. 100',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter priority';
                  if (int.tryParse(val.trim()) == null) return 'Enter a valid integer';
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
              if (formKey.currentState?.validate() ?? false) {
                final newPriority = int.parse(priorityCtrl.text.trim());
                Navigator.pop(dialogCtx);
                await context.read<AdminVendorsCubit>().updateVendorPriority(restaurant.id, newPriority);
              }
            },
            child: const Text('Save Priority'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVendor(BuildContext context, AdminVendor vendor) async {
    final confirmed = await AdminDialogs.confirmDelete(context,
        itemType: 'Vendor', itemName: vendor.name);
    if (confirmed && context.mounted) {
      await onDeleteVendor(vendor.id);
    }
  }

  void _showVendorWalletAdjustmentDialog(BuildContext context, Restaurant restaurant) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Adjust Wallet: ${restaurant.name}'),
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
                  hintText: 'e.g. 100 or -100',
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
                  hintText: 'e.g. Manual payout / adjustment settlement',
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

                final vendorsCubit = context.read<AdminVendorsCubit>();
                Navigator.pop(dialogCtx);

                await vendorsCubit.adjustVendorWallet(restaurant.id, amount, desc);

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
}

class _VendorFilterChip extends StatelessWidget {
  const _VendorFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.primaryOrange : AdminTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AdminTheme.primaryOrange : AdminTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AdminTheme.textDark,
          ),
        ),
      ),
    );
  }
}
