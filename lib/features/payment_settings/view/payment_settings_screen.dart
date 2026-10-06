// lib/pages/payment_settings_page.dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/driver/datasource/driver_firebase_datasource.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/driver/model/wallet_transaction.dart';
import 'package:z_speed/features/driver/repository/driver_repository_impl.dart';

const _orange = Color(0xFFF35535);

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({super.key});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  final _repo = DriverRepositoryImpl();
  final _datasource = DriverFirebaseDatasource();

  String? _uid;
  DriverProfile? _profile;
  bool _loadingProfile = true;

  StreamSubscription<List<WalletTransaction>>? _txSub;
  List<WalletTransaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    // Load driver profile directly from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('driverProfiles')
        .doc(_uid)
        .get();
    if (mounted) {
      setState(() {
        _loadingProfile = false;
        if (doc.exists) _profile = DriverProfile.fromMap(doc.data()!, doc.id);
      });
    }

    // Stream wallet transactions
    _txSub = _repo
        .streamDriverTransactions(_uid!)
        .listen(
          (txs) {
            if (mounted) setState(() => _transactions = txs);
          },
          onError: (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load transactions: $e')),
              );
            }
          },
        );
  }

  @override
  void dispose() {
    _txSub?.cancel();
    super.dispose();
  }

  Future<void> _savePayoutMethod(PayoutMethod method) async {
    if (_uid == null) return;
    await _datasource.updateDriverProfile(_uid!, {'payoutMethod': method.key});
    if (mounted) {
      setState(() {
        _profile =
            (_profile ??
                    DriverProfile(
                      id: _uid!,
                      userId: _uid!,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ))
                .copyWith(payoutMethod: method);
      });
    }
  }

  Future<void> _savePayoutPhone(String phone) async {
    if (_uid == null) return;
    await _datasource.updateDriverProfile(_uid!, {'payoutPhoneNumber': phone});
    if (mounted) {
      setState(() {
        _profile =
            (_profile ??
                    DriverProfile(
                      id: _uid!,
                      userId: _uid!,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ))
                .copyWith(payoutPhoneNumber: phone);
      });
    }
  }

  void _showPayoutAccountDialog(BuildContext context) {
    final phoneCtrl = TextEditingController(
      text: _profile?.payoutPhoneNumber ?? '',
    );
    PayoutMethod selected = _profile?.payoutMethod ?? PayoutMethod.instapay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Payout Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PayoutMethod>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Payout Method',
                  border: OutlineInputBorder(),
                ),
                items: PayoutMethod.values
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                    )
                    .toList(),
                onChanged: (m) {
                  if (m != null) setSt(() => selected = m);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone / Account number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _savePayoutMethod(selected);
                _savePayoutPhone(phoneCtrl.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double balance = _profile?.walletBalance ?? 0.0;
    final double totalEarnings = _profile?.totalEarnings ?? 0.0;
    final PayoutMethod? payoutMethod = _profile?.payoutMethod;
    final String payoutPhone = _profile?.payoutPhoneNumber ?? '';
    final bool hasPayoutInfo = payoutPhone.isNotEmpty && payoutMethod != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Balance Card ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_orange, Color(0xFFFF914D)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'EGP ${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: Colors.white24),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total Earnings: EGP ${totalEarnings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Payout Account ───────────────────────────────────
                  _buildCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasPayoutInfo
                              ? (payoutMethod == PayoutMethod.instapay
                                    ? Icons.flash_on_outlined
                                    : payoutMethod == PayoutMethod.vodafoneCash
                                    ? Icons.phone_android_outlined
                                    : Icons.account_balance_outlined)
                              : Icons.add_card_outlined,
                          color: _orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        (payoutMethod != null && payoutPhone.isNotEmpty)
                            ? payoutMethod.label
                            : 'Payout Account',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        hasPayoutInfo
                            ? payoutPhone
                            : 'Tap to set your payout details',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: TextButton(
                        onPressed: () => _showPayoutAccountDialog(context),
                        style: TextButton.styleFrom(foregroundColor: _orange),
                        child: Text(hasPayoutInfo ? 'Edit' : 'Add'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Transaction History ──────────────────────────────
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_transactions.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._transactions.map(_buildTransactionTile),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _buildTransactionTile(WalletTransaction tx) {
    final isCredit = tx.type == WalletTransactionType.credit;
    final amountColor = isCredit
        ? const Color(0xFF38A169)
        : const Color(0xFFE53E3E);
    final amountPrefix = isCredit ? '+' : '-';
    final canConfirm =
        !isCredit &&
        tx.status == WalletTransactionStatus.pending &&
        !tx.confirmedByDriver;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Force LTR so the row isn't flipped in Arabic/RTL mode
            Row(
              textDirection: ui.TextDirection.ltr,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCredit
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: amountColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description.isNotEmpty
                            ? tx.description
                            : 'Transaction',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, yyyy').format(tx.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix EGP ${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(tx.status),
                  ],
                ),
              ],
            ),
            // Show action row whenever there is any evidence attached,
            // regardless of credit/debit or confirmation status.
            if (tx.evidenceUrl != null) ...[
              const SizedBox(height: 12),
              Row(
                textDirection: ui.TextDirection.ltr,
                children: [
                  const SizedBox(width: 52),
                  Expanded(
                    child: Row(
                      children: [
                        if (canConfirm)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmPayout(tx),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                              ),
                              label: const Text('Confirm Receipt'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF38A169),
                                side: const BorderSide(
                                  color: Color(0xFF38A169),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _viewProof(tx.evidenceUrl!),
                          icon: const Icon(Icons.image_outlined, size: 16),
                          label: const Text('View Proof'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3182CE),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(WalletTransactionStatus status) {
    final (label, color) = switch (status) {
      WalletTransactionStatus.confirmed => (
        'Confirmed',
        const Color(0xFF38A169),
      ),
      WalletTransactionStatus.disputed => ('Disputed', const Color(0xFFE53E3E)),
      WalletTransactionStatus.pending => ('Pending', const Color(0xFFED8936)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _confirmPayout(WalletTransaction tx) async {
    if (_uid == null) return;
    await _repo.confirmPayout(tx.id, _uid!);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payout confirmed!')));
    }
  }

  void _viewProof(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}
