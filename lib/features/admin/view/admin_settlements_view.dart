import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/utils/image_utils.dart';
import 'package:z_speed/features/admin/cubit/admin_settlements_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_settlements_state.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminSettlementsView
//
// StatefulWidget so we can manually track the selected tab index.
// Avoids TabBarView (needs bounded height, incompatible with the mobile shell's
// SingleChildScrollView body).
// ─────────────────────────────────────────────────────────────────────────────

class AdminSettlementsView extends StatefulWidget {
  const AdminSettlementsView({super.key});

  @override
  State<AdminSettlementsView> createState() => _AdminSettlementsViewState();
}

class _AdminSettlementsViewState extends State<AdminSettlementsView> {
  int _tab = 0; // 0 = Vendors, 1 = Drivers

  static const _tabs = ['Vendors', 'Drivers'];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminSettlementsCubit, AdminSettlementsState>(
      listener: (context, state) {
        if (state is AdminSettlementsError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AdminTheme.errorRed,
          ));
        } else if (state is AdminSettlementSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Settlement completed successfully'),
            backgroundColor: Color(0xFF38A169),
          ));
        }
      },
      builder: (context, state) {
        // ── Loading / in-progress ──────────────────────────────────────
        if (state is AdminSettlementsLoading ||
            state is AdminSettlementInProgress) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // ── Error ─────────────────────────────────────────────────────
        if (state is AdminSettlementsError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      color: AdminTheme.errorRed, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: TextStyle(color: AdminTheme.textMedium)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AdminSettlementsCubit>().loadWallets(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final loaded = state is AdminSettlementsLoaded ? state : null;
        final restaurants = loaded?.restaurants ?? [];
        final drivers = loaded?.drivers ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Manual tab bar ─────────────────────────────────────────
            Row(
              children: List.generate(_tabs.length, (i) {
                final selected = i == _tab;
                return GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AdminTheme.primaryOrange
                          : AdminTheme.primaryOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                        color:
                            selected ? Colors.white : AdminTheme.primaryOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ── Refresh hint ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      context.read<AdminSettlementsCubit>().loadWallets(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: AdminTheme.textLight,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── List ───────────────────────────────────────────────────
            if (_tab == 0) ...[
              if (restaurants.isEmpty)
                const _EmptyState(label: 'No vendors registered yet')
              else
                ...restaurants.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VendorCard(
                        name: r.name,
                        subtitle: r.address.isNotEmpty ? r.address : r.phone,
                        vendorType: r.vendorType,
                        balance: r.walletBalance,
                        totalEarnings: r.totalEarnings,
                        payoutPhone: r.payoutPhoneNumber,
                        payoutMethod: r.payoutMethod,
                        onSettle: () => _showSettleSheet(
                          context,
                          name: r.name,
                          balance: r.walletBalance,
                          payoutPhone: r.payoutPhoneNumber,
                          payoutMethod: r.payoutMethod,
                          onConfirm: (amount, method, evidenceUrl) => context
                              .read<AdminSettlementsCubit>()
                              .settleRestaurant(
                                restaurant: r,
                                amount: amount,
                                payoutMethod: method,
                                evidenceUrl: evidenceUrl,
                              ),
                        ),
                      ),
                    )),
            ] else ...[
              if (drivers.isEmpty)
                const _EmptyState(label: 'No drivers registered yet')
              else
                ...drivers.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VendorCard(
                        name: d.name.isNotEmpty ? d.name : d.userId,
                        subtitle: d.phoneNumber,
                        vendorType: null,
                        balance: d.walletBalance,
                        totalEarnings: d.totalEarnings,
                        payoutPhone: d.payoutPhoneNumber,
                        payoutMethod: d.payoutMethod,
                        onSettle: () => _showSettleSheet(
                          context,
                          name: d.name.isNotEmpty ? d.name : d.userId,
                          balance: d.walletBalance,
                          payoutPhone: d.payoutPhoneNumber,
                          payoutMethod: d.payoutMethod,
                          onConfirm: (amount, method, evidenceUrl) => context
                              .read<AdminSettlementsCubit>()
                              .settleDriver(
                                driver: d,
                                amount: amount,
                                payoutMethod: method,
                                evidenceUrl: evidenceUrl,
                                driverUserId: d.userId,
                              ),
                        ),
                      ),
                    )),
            ],
          ],
        );
      },
    );
  }

  void _showSettleSheet(
    BuildContext context, {
    required String name,
    required double balance,
    required String payoutPhone,
    required PayoutMethod? payoutMethod,
    required Future<void> Function(
            double amount, PayoutMethod method, String evidenceUrl)
        onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AdminSettlementsCubit>(),
        child: _SettleSheet(
          name: name,
          balance: balance,
          prefilledPhone: payoutPhone,
          prefilledMethod: payoutMethod,
          onConfirm: onConfirm,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: AdminTheme.textLight),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(color: AdminTheme.textMedium, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VendorCard
// ─────────────────────────────────────────────────────────────────────────────

class _VendorCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VendorType? vendorType; // null = driver
  final double balance;
  final double totalEarnings;
  final String payoutPhone;
  final PayoutMethod? payoutMethod;
  final VoidCallback onSettle;

  const _VendorCard({
    required this.name,
    required this.subtitle,
    required this.vendorType,
    required this.balance,
    required this.totalEarnings,
    required this.payoutPhone,
    required this.payoutMethod,
    required this.onSettle,
  });

  IconData get _typeIcon {
    if (vendorType == null) return Icons.directions_car_outlined;
    switch (vendorType!) {
      case VendorType.supermarket:
        return Icons.shopping_cart_outlined;
      case VendorType.pharmacy:
        return Icons.local_pharmacy_outlined;
      case VendorType.bookstore:
        return Icons.menu_book_outlined;
      case VendorType.homeFurnishing:
        return Icons.chair_outlined;
      case VendorType.meatAndProteins:
        return Icons.restaurant_menu_outlined;
      case VendorType.clothes:
        return Icons.checkroom_outlined;
      case VendorType.buyAndSell:
        return Icons.swap_horiz_outlined;
      case VendorType.electronics:
        return Icons.devices_outlined;
      default:
        return Icons.store_outlined;
    }
  }

  String get _typeLabel {
    if (vendorType == null) return 'Driver';
    switch (vendorType!) {
      case VendorType.supermarket:
        return 'Supermarket';
      case VendorType.pharmacy:
        return 'Pharmacy';
      case VendorType.bookstore:
        return 'Bookstore';
      case VendorType.homeFurnishing:
        return 'Home & Furnishing';
      case VendorType.meatAndProteins:
        return 'Meat & Proteins';
      case VendorType.clothes:
        return 'Clothing';
      case VendorType.buyAndSell:
        return 'Buy & Sell';
      case VendorType.electronics:
        return 'Electronics';
      default:
        return 'Restaurant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPayoutInfo = payoutPhone.isNotEmpty && payoutMethod != null;
    final hasPendingBalance = balance > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPendingBalance
              ? AdminTheme.primaryOrange.withValues(alpha: 0.3)
              : AdminTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              // Icon + type badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AdminTheme.primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(_typeIcon, color: AdminTheme.primaryOrange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AdminTheme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AdminTheme.primaryOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AdminTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                            color: AdminTheme.textLight, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: AdminTheme.borderColor, height: 1),
          const SizedBox(height: 12),

          // ── Balance row ──────────────────────────────────────────────
          Row(
            children: [
              _InfoChip(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Balance',
                value: 'EGP ${balance.toStringAsFixed(2)}',
                valueColor: hasPendingBalance
                    ? const Color(0xFF38A169)
                    : AdminTheme.textMedium,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.trending_up,
                label: 'Total Earned',
                value: 'EGP ${totalEarnings.toStringAsFixed(2)}',
                valueColor: AdminTheme.textMedium,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Payout info row ──────────────────────────────────────────
          Row(
            children: [
              Icon(
                hasPayoutInfo
                    ? Icons.send_outlined
                    : Icons.warning_amber_outlined,
                size: 14,
                color:
                    hasPayoutInfo ? AdminTheme.textLight : AdminTheme.errorRed,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: hasPayoutInfo
                    ? Text(
                        '${payoutMethod!.label}  ·  $payoutPhone',
                        style: TextStyle(
                          fontSize: 13,
                          color: AdminTheme.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        'No payout account set by vendor',
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminTheme.errorRed,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Settle button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSettle,
              icon: const Icon(Icons.send, size: 16),
              label: Text(
                hasPendingBalance
                    ? 'Settle EGP ${balance.toStringAsFixed(2)}'
                    : 'Send Payment',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPendingBalance
                    ? AdminTheme.primaryOrange
                    : AdminTheme.textLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AdminTheme.contentBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AdminTheme.textLight),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 10, color: AdminTheme.textLight)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: valueColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SettleSheet  — bottom sheet that pre-fills payout info from vendor profile
// ─────────────────────────────────────────────────────────────────────────────

class _SettleSheet extends StatefulWidget {
  final String name;
  final double balance;
  final String prefilledPhone;
  final PayoutMethod? prefilledMethod;
  final Future<void> Function(
      double amount, PayoutMethod method, String evidenceUrl) onConfirm;

  const _SettleSheet({
    required this.name,
    required this.balance,
    required this.prefilledPhone,
    required this.prefilledMethod,
    required this.onConfirm,
  });

  @override
  State<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<_SettleSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _phoneCtrl;
  late PayoutMethod _method;
  XFile? _evidenceFile;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.balance.toStringAsFixed(2));
    _phoneCtrl = TextEditingController(text: widget.prefilledPhone);
    _method = widget.prefilledMethod ?? PayoutMethod.instapay;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
    final file =
        await ImageUtils.pickCompressedImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _evidenceFile = XFile(file.path));
  }

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_evidenceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload transfer proof')),
      );
      return;
    }
    setState(() => _uploading = true);

    final entityId = widget.name; // used as storage path prefix only
    final url = await context
        .read<AdminSettlementsCubit>()
        .uploadEvidence(_evidenceFile!, entityId);

    if (url == null) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload proof')),
        );
      }
      return;
    }

    setState(() => _uploading = false);
    if (!mounted) return;
    Navigator.of(context).pop();
    await widget.onConfirm(amount, _method, url);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Settle · ${widget.name}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (EGP)',
              prefixText: 'EGP ',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),

          // Payout method
          DropdownButtonFormField<PayoutMethod>(
            initialValue: _method,
            decoration: InputDecoration(
              labelText: 'Payout Method',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: PayoutMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                .toList(),
            onChanged: (m) {
              if (m != null) setState(() => _method = m);
            },
          ),
          const SizedBox(height: 14),

          // Phone / account
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone / Account number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              helperText: widget.prefilledPhone.isEmpty
                  ? 'Vendor has not set a payout account'
                  : null,
              helperStyle: TextStyle(color: AdminTheme.errorRed),
            ),
          ),
          const SizedBox(height: 14),

          // Evidence upload
          GestureDetector(
            onTap: _pickEvidence,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _evidenceFile != null
                      ? const Color(0xFF38A169)
                      : AdminTheme.borderColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _evidenceFile != null
                        ? Icons.check_circle_outline
                        : Icons.upload_file_outlined,
                    color: _evidenceFile != null
                        ? const Color(0xFF38A169)
                        : AdminTheme.textLight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _evidenceFile != null
                          ? _evidenceFile!.name
                          : 'Upload transfer proof (required)',
                      style: TextStyle(
                        color: _evidenceFile != null
                            ? AdminTheme.textDark
                            : AdminTheme.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploading ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirm Settlement',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
