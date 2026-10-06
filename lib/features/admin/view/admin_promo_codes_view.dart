import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/order/datasource/promo_code_datasource.dart';
import 'package:z_speed/features/order/model/promo_code.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/permissions/permission_service.dart';
import 'package:z_speed/core/enums/user_enums.dart';

/// Simple data model representing a vendor option for search dropdown selection.
class VendorOption {
  final String id;
  final String name;
  final String? nameAr;
  final String? logoUrl;
  final String? vendorType;
  final bool isActive;

  const VendorOption({
    required this.id,
    required this.name,
    this.nameAr,
    this.logoUrl,
    this.vendorType,
    this.isActive = true,
  });

  factory VendorOption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VendorOption(
      id: doc.id,
      name: (data['name'] as String?) ??
          (data['restaurantName'] as String?) ??
          doc.id,
      nameAr: data['nameAr'] as String?,
      logoUrl:
          (data['logoUrl'] as String?) ?? (data['coverImageUrl'] as String?),
      vendorType: data['vendorType'] as String?,
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }
}

/// Admin panel screen for creating, editing, toggling, and deleting promo codes.
///
/// Shows all codes (global + restaurant-specific) in a live stream.
class AdminPromoCodesView extends StatelessWidget {
  const AdminPromoCodesView({super.key});

  @override
  Widget build(BuildContext context) {
    final datasource = PromoCodeDatasource();

    return StreamBuilder<List<VendorOption>>(
      stream: FirebaseFirestore.instance.collection('vendors').snapshots().map(
            (snap) =>
                snap.docs.map((doc) => VendorOption.fromFirestore(doc)).toList(),
          ),
      builder: (context, vendorSnapshot) {
        final vendors = vendorSnapshot.data ?? [];
        final vendorMap = {for (var v in vendors) v.id: v};

        return StreamBuilder<List<PromoCode>>(
          stream: datasource.streamAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                    color: AdminTheme.primaryOrange),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: AdminTheme.errorRed),
                ),
              );
            }

            final codes = snapshot.data ?? [];
            final currentUserType =
                context.read<AuthCubit>().state.user?.type ?? UserType.admin;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promo Codes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AdminTheme.textDark,
                      ),
                    ),
                    if (PermissionService.canEditContent(currentUserType))
                      ElevatedButton.icon(
                        onPressed: () => _showPromoForm(
                          context,
                          datasource,
                          vendors: vendors,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primaryOrange,
                          foregroundColor: AdminTheme.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Summary chips ──────────────────────────────────────
                Wrap(
                  spacing: 8,
                  children: [
                    _SummaryChip(
                      label: 'Total',
                      count: codes.length,
                      color: AdminTheme.infoBlue,
                    ),
                    _SummaryChip(
                      label: 'Active',
                      count: codes.where((c) => c.isActive).length,
                      color: AdminTheme.successGreen,
                    ),
                    _SummaryChip(
                      label: 'Expired',
                      count: codes.where((c) => c.isExpired).length,
                      color: AdminTheme.errorRed,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Code list ──────────────────────────────────────────
                codes.isEmpty
                    ? _EmptyState(
                        onCreateTap: () => _showPromoForm(
                          context,
                          datasource,
                          vendors: vendors,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: codes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _PromoCodeCard(
                          promo: codes[i],
                          datasource: datasource,
                          currentUserType: currentUserType,
                          vendorMap: vendorMap,
                          onEdit: () => _showPromoForm(
                            context,
                            datasource,
                            vendors: vendors,
                            existing: codes[i],
                          ),
                        ),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPromoForm(
    BuildContext context,
    PromoCodeDatasource datasource, {
    required List<VendorOption> vendors,
    PromoCode? existing,
  }) {
    final userId = context.read<AuthCubit>().state.user?.id ?? 'admin';
    showDialog<void>(
      context: context,
      builder: (_) => _PromoCodeFormDialog(
        datasource: datasource,
        existing: existing,
        createdBy: userId,
        vendors: vendors,
      ),
    );
  }
}

// ── Summary Chip ───────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 48,
            color: AdminTheme.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No promo codes yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first promo code to attract more customers.',
            style: TextStyle(fontSize: 13, color: AdminTheme.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreateTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryOrange,
              foregroundColor: AdminTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create First Code'),
          ),
        ],
      ),
    );
  }
}

// ── Promo Code Card ────────────────────────────────────────────────────────

class _PromoCodeCard extends StatelessWidget {
  const _PromoCodeCard({
    required this.promo,
    required this.datasource,
    required this.currentUserType,
    required this.vendorMap,
    required this.onEdit,
  });

  final PromoCode promo;
  final PromoCodeDatasource datasource;
  final UserType currentUserType;
  final Map<String, VendorOption> vendorMap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final expired = promo.isExpired;
    final maxed = promo.hasReachedMaxUsage;
    final statusColor = expired || maxed || !promo.isActive
        ? AdminTheme.errorRed
        : AdminTheme.successGreen;
    final statusLabel = expired
        ? 'Expired'
        : maxed
        ? 'Maxed Out'
        : promo.isActive
        ? 'Active'
        : 'Inactive';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Code badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AdminTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AdminTheme.primaryOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 14,
                          color: AdminTheme.primaryOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          promo.code,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AdminTheme.primaryOrange,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _copyCode(context),
                          child: Icon(
                            Icons.copy,
                            size: 13,
                            color: AdminTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Actions
                  if (isWide) ...[
                    if (PermissionService.canEditContent(currentUserType))
                      _buildToggleSwitch(),
                    const SizedBox(width: 8),
                    if (PermissionService.canEditContent(currentUserType))
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AdminTheme.primaryOrange,
                          size: 18,
                        ),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                    if (PermissionService.canDeleteContent(currentUserType))
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AdminTheme.errorRed,
                          size: 18,
                        ),
                        onPressed: () => _confirmDelete(context),
                        tooltip: 'Delete',
                      ),
                  ] else ...[
                    PopupMenuButton<String>(
                      onSelected: (v) => _onMenuAction(v, context),
                      itemBuilder: (_) => [
                        if (PermissionService.canEditContent(currentUserType))
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (PermissionService.canEditContent(currentUserType))
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              promo.isActive ? 'Deactivate' : 'Activate',
                            ),
                          ),
                        if (PermissionService.canDeleteContent(currentUserType))
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: AdminTheme.textLight,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Discount info
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.discount_outlined,
                    label: _discountLabel(),
                    color: AdminTheme.successGreen,
                  ),
                  if (promo.minOrderAmount > 0)
                    _InfoChip(
                      icon: Icons.shopping_bag_outlined,
                      label:
                          'Min EGP ${promo.minOrderAmount.toStringAsFixed(0)}',
                      color: AdminTheme.infoBlue,
                    ),
                  if (promo.restaurantId != null)
                    _InfoChip(
                      icon: Icons.store_outlined,
                      label: vendorMap[promo.restaurantId]?.name != null
                          ? 'Vendor: ${vendorMap[promo.restaurantId]!.name}'
                          : 'Vendor ID: ${promo.restaurantId}',
                      color: AdminTheme.warningAmber,
                    )
                  else
                    _InfoChip(
                      icon: Icons.public,
                      label: 'Global',
                      color: AdminTheme.infoBlue,
                    ),
                  if (promo.expiresAt != null)
                    _InfoChip(
                      icon: Icons.schedule_outlined,
                      label: 'Expires ${_formatDate(promo.expiresAt!)}',
                      color: expired
                          ? AdminTheme.errorRed
                          : AdminTheme.textMedium,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Usage bar
              _UsageBar(
                used: promo.usageCount,
                max: promo.maxUsageCount,
                orangeColor: AdminTheme.primaryOrange,
                bgColor: AdminTheme.borderColor,
                textMedium: AdminTheme.textMedium,
                textDark: AdminTheme.textDark,
              ),
            ],
          );
        },
      ),
    );
  }

  String _discountLabel() => switch (promo.type) {
    PromoCodeType.percentage =>
      '${promo.discountValue.toStringAsFixed(0)}% off',
    PromoCodeType.fixed => 'EGP ${promo.discountValue.toStringAsFixed(2)} off',
    PromoCodeType.freeDelivery => 'Free Delivery',
  };

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: promo.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${promo.code} copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: AdminTheme.successGreen,
      ),
    );
  }

  Widget _buildToggleSwitch() => Switch(
    value: promo.isActive,
    activeThumbColor: AdminTheme.successGreen,
    onChanged: (v) => datasource.toggleActive(promo.id, isActive: v),
  );

  void _onMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'edit':
        onEdit();
      case 'toggle':
        datasource.toggleActive(promo.id, isActive: !promo.isActive);
      case 'delete':
        _confirmDelete(context);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Promo Code'),
        content: Text('Delete "${promo.code}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await datasource.delete(promo.id);
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

// ── Usage progress bar ─────────────────────────────────────────────────────

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.used,
    required this.max,
    required this.orangeColor,
    required this.bgColor,
    required this.textMedium,
    required this.textDark,
  });

  final int used;
  final int max;
  final Color orangeColor;
  final Color bgColor;
  final Color textMedium;
  final Color textDark;

  @override
  Widget build(BuildContext context) {
    final unlimited = max == 0;
    final fraction = unlimited ? 0.0 : (used / max).clamp(0.0, 1.0);
    final label = unlimited ? 'Used: $used (unlimited)' : 'Used: $used / $max';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textMedium)),
        if (!unlimited) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation(
                fraction >= 1.0 ? Colors.red : orangeColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Create / Edit Form Dialog ──────────────────────────────────────────────

class _PromoCodeFormDialog extends StatefulWidget {
  const _PromoCodeFormDialog({
    required this.datasource,
    required this.createdBy,
    required this.vendors,
    this.existing,
  });

  final PromoCodeDatasource datasource;
  final PromoCode? existing;
  final String createdBy;
  final List<VendorOption> vendors;

  @override
  State<_PromoCodeFormDialog> createState() => _PromoCodeFormDialogState();
}

class _PromoCodeFormDialogState extends State<_PromoCodeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _maxUsageCtrl = TextEditingController();
  final _maxPerUserCtrl = TextEditingController();
  final _restaurantIdCtrl = TextEditingController();

  PromoCodeType _type = PromoCodeType.percentage;
  DateTime? _expiresAt;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _codeCtrl.text = p.code;
      _type = p.type;
      _valueCtrl.text = p.discountValue.toString();
      _minOrderCtrl.text = p.minOrderAmount > 0
          ? p.minOrderAmount.toString()
          : '';
      _maxUsageCtrl.text = p.maxUsageCount > 0
          ? p.maxUsageCount.toString()
          : '';
      _maxPerUserCtrl.text = p.maxUsagePerUser.toString();
      _restaurantIdCtrl.text = p.restaurantId ?? '';
      _expiresAt = p.expiresAt;
      _isActive = p.isActive;
    } else {
      _maxPerUserCtrl.text = '1';
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxUsageCtrl.dispose();
    _maxPerUserCtrl.dispose();
    _restaurantIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final promo = PromoCode(
        id: widget.existing?.id ?? '',
        code: _codeCtrl.text.trim().toUpperCase(),
        type: _type,
        discountValue: double.tryParse(_valueCtrl.text.trim()) ?? 0.0,
        minOrderAmount: double.tryParse(_minOrderCtrl.text.trim()) ?? 0.0,
        maxUsageCount: int.tryParse(_maxUsageCtrl.text.trim()) ?? 0,
        usageCount: widget.existing?.usageCount ?? 0,
        maxUsagePerUser: int.tryParse(_maxPerUserCtrl.text.trim()) ?? 1,
        restaurantId: _restaurantIdCtrl.text.trim().isEmpty
            ? null
            : _restaurantIdCtrl.text.trim(),
        isActive: _isActive,
        expiresAt: _expiresAt,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        createdBy: widget.existing?.createdBy ?? widget.createdBy,
      );

      if (_isEditing) {
        await widget.datasource.update(promo);
      } else {
        await widget.datasource.create(promo);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_isEditing ? 'Edit Promo Code' : 'New Promo Code'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code field
                TextFormField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Promo Code *',
                    hintText: 'e.g. SUMMER20',
                    prefixIcon: Icon(Icons.local_offer_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Code is required' : null,
                ),

                const SizedBox(height: 16),

                // Type selector
                const Text(
                  'Discount Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PromoCodeType>(
                  segments: const [
                    ButtonSegment(
                      value: PromoCodeType.percentage,
                      label: Text('% Off'),
                      icon: Icon(Icons.percent, size: 16),
                    ),
                    ButtonSegment(
                      value: PromoCodeType.fixed,
                      label: Text('EGP Off'),
                      icon: Icon(Icons.money, size: 16),
                    ),
                    ButtonSegment(
                      value: PromoCodeType.freeDelivery,
                      label: Text('Free Ship'),
                      icon: Icon(Icons.local_shipping_outlined, size: 16),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AdminTheme.primaryOrange.withValues(alpha: 0.1)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Discount value (hidden for freeDelivery)
                if (_type != PromoCodeType.freeDelivery)
                  TextFormField(
                    controller: _valueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _type == PromoCodeType.percentage
                          ? 'Discount % *'
                          : 'Discount Amount (EGP) *',
                      prefixIcon: Icon(
                        _type == PromoCodeType.percentage
                            ? Icons.percent
                            : Icons.attach_money,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_type == PromoCodeType.freeDelivery) return null;
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) {
                        return 'Enter a valid value';
                      }
                      if (_type == PromoCodeType.percentage && n > 100) {
                        return 'Cannot exceed 100%';
                      }
                      return null;
                    },
                  ),

                if (_type != PromoCodeType.freeDelivery)
                  const SizedBox(height: 16),

                // Min order
                TextFormField(
                  controller: _minOrderCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Minimum Order (EGP)',
                    hintText: 'Leave blank for no minimum',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Max total usage
                TextFormField(
                  controller: _maxUsageCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Max Total Uses',
                    hintText: 'Leave blank for unlimited',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Max per user
                TextFormField(
                  controller: _maxPerUserCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Max Uses Per User',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) {
                      return 'At least 1';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Searchable Vendor Selection Dropdown
                _VendorSearchDropdown(
                  selectedVendorId: _restaurantIdCtrl.text.trim().isEmpty
                      ? null
                      : _restaurantIdCtrl.text.trim(),
                  vendors: widget.vendors,
                  onChanged: (vendorId) {
                    setState(() {
                      _restaurantIdCtrl.text = vendorId ?? '';
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Expiry date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(
                    _expiresAt == null
                        ? 'No expiry date'
                        : 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _expiresAt = null),
                          tooltip: 'Clear expiry',
                        ),
                      TextButton(
                        onPressed: _pickExpiry,
                        child: Text(
                          _expiresAt == null ? 'Set Date' : 'Change',
                          style: TextStyle(color: AdminTheme.primaryOrange),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active', style: TextStyle(fontSize: 14)),
                    Switch(
                      value: _isActive,
                      activeThumbColor: AdminTheme.successGreen,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(_isEditing ? 'Save Changes' : 'Create Code'),
        ),
      ],
    );
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AdminTheme.primaryOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }
}

// ── Searchable Vendor Dropdown Component ───────────────────────────────────

class _VendorSearchDropdown extends StatelessWidget {
  const _VendorSearchDropdown({
    required this.selectedVendorId,
    required this.vendors,
    required this.onChanged,
  });

  final String? selectedVendorId;
  final List<VendorOption> vendors;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isGlobal = selectedVendorId == null || selectedVendorId!.isEmpty;
    final selectedVendor = isGlobal
        ? null
        : vendors.firstWhere(
            (v) => v.id == selectedVendorId,
            orElse: () => VendorOption(
              id: selectedVendorId!,
              name: 'Vendor ID: $selectedVendorId',
            ),
          );

    return InkWell(
      onTap: () => _showSearchModal(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Target Vendor / Restaurant (Optional)',
          hintText: 'Select a vendor or keep as global',
          prefixIcon: Icon(
            isGlobal ? Icons.public : Icons.storefront_outlined,
            color: isGlobal ? AdminTheme.infoBlue : AdminTheme.primaryOrange,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isGlobal)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear vendor (make Global)',
                  onPressed: () => onChanged(null),
                ),
              const Icon(Icons.arrow_drop_down),
              const SizedBox(width: 8),
            ],
          ),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Row(
          children: [
            if (!isGlobal &&
                selectedVendor?.logoUrl != null &&
                selectedVendor!.logoUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  selectedVendor.logoUrl!,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.store, size: 18),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                isGlobal
                    ? 'Global Code (All Vendors)'
                    : selectedVendor?.name ?? 'Selected Vendor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isGlobal ? FontWeight.w500 : FontWeight.w600,
                  color: isGlobal ? AdminTheme.textMedium : AdminTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _VendorSearchDialog(
        vendors: vendors,
        selectedVendorId: selectedVendorId,
        onSelected: (vendorId) {
          onChanged(vendorId);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

// ── Search Vendor Dialog ───────────────────────────────────────────────────

class _VendorSearchDialog extends StatefulWidget {
  const _VendorSearchDialog({
    required this.vendors,
    required this.selectedVendorId,
    required this.onSelected,
  });

  final List<VendorOption> vendors;
  final String? selectedVendorId;
  final ValueChanged<String?> onSelected;

  @override
  State<_VendorSearchDialog> createState() => _VendorSearchDialogState();
}

class _VendorSearchDialogState extends State<_VendorSearchDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.vendors.where((v) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      final nameMatches = v.name.toLowerCase().contains(q);
      final nameArMatches =
          v.nameAr != null && v.nameAr!.toLowerCase().contains(q);
      final idMatches = v.id.toLowerCase().contains(q);
      return nameMatches || nameArMatches || idMatches;
    }).toList();

    final hasSelection = widget.selectedVendorId != null &&
        widget.selectedVendorId!.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Vendor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        height: 480,
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by vendor name, Arabic name, or ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Options List
            Expanded(
              child: ListView(
                children: [
                  // Global Option
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: !hasSelection
                        ? AdminTheme.primaryOrange.withValues(alpha: 0.1)
                        : null,
                    leading: CircleAvatar(
                      backgroundColor:
                          AdminTheme.infoBlue.withValues(alpha: 0.15),
                      child: Icon(Icons.public,
                          color: AdminTheme.infoBlue, size: 20),
                    ),
                    title: const Text(
                      'Global Code (All Vendors)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Applies to orders from any restaurant or vendor',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: !hasSelection
                        ? Icon(Icons.check_circle,
                            color: AdminTheme.primaryOrange, size: 20)
                        : null,
                    onTap: () => widget.onSelected(null),
                  ),

                  const Divider(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Vendors (${filtered.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.textMedium,
                      ),
                    ),
                  ),

                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off,
                              size: 36, color: AdminTheme.textLight),
                          const SizedBox(height: 8),
                          Text(
                            'No vendors match "$_query"',
                            style: TextStyle(
                                color: AdminTheme.textMedium, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((vendor) {
                      final isSelected = widget.selectedVendorId == vendor.id;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: isSelected
                            ? AdminTheme.primaryOrange.withValues(alpha: 0.1)
                            : null,
                        leading: CircleAvatar(
                          backgroundColor: AdminTheme.primaryOrange
                              .withValues(alpha: 0.1),
                          backgroundImage: vendor.logoUrl != null &&
                                  vendor.logoUrl!.isNotEmpty
                              ? NetworkImage(vendor.logoUrl!)
                              : null,
                          child: vendor.logoUrl == null ||
                                  vendor.logoUrl!.isEmpty
                              ? Icon(Icons.storefront,
                                  color: AdminTheme.primaryOrange, size: 20)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                vendor.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (vendor.vendorType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  vendor.vendorType!,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.black87),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'ID: ${vendor.id}${vendor.nameAr != null && vendor.nameAr!.isNotEmpty ? " • ${vendor.nameAr}" : ""}',
                          style: TextStyle(
                              fontSize: 11, color: AdminTheme.textMedium),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: AdminTheme.primaryOrange, size: 20)
                            : null,
                        onTap: () => widget.onSelected(vendor.id),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
