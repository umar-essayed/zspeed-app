import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_wallet_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_wallet_state.dart';
import 'package:z_speed/features/restaurant_owner/model/restaurant_wallet_transaction.dart';

// ignore_for_file: use_build_context_synchronously

const _orange = Color(0xFFF35535);

class RestaurantWalletScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantWalletScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantWalletScreen> createState() => _RestaurantWalletScreenState();
}

class _RestaurantWalletScreenState extends State<RestaurantWalletScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.restaurantId.isNotEmpty) {
      context.read<RestaurantWalletCubit>().loadWallet(widget.restaurantId);
    }
  }

  void _showEditPayoutDialog(
    BuildContext context,
    RestaurantWalletLoaded loaded,
  ) {
    final phoneCtrl = TextEditingController(text: loaded.payoutPhoneNumber);
    PayoutMethod selected = loaded.payoutMethod ?? PayoutMethod.instapay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Payout Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone / Account number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
                context.read<RestaurantWalletCubit>().savePayoutInfo(
                  phoneNumber: phoneCtrl.text.trim(),
                  method: selected,
                );
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
    return BlocBuilder<RestaurantWalletCubit, RestaurantWalletState>(
      builder: (context, state) {
        if (state is RestaurantWalletLoading ||
            state is RestaurantWalletInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is RestaurantWalletError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final loaded = state as RestaurantWalletLoaded;
        return RefreshIndicator(
          onRefresh: () async {
            // Re-trigger by reloading (streams auto-update, but pull-to-refresh
            // is still a good UX signal)
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _WalletBalanceCard(
                  balance: loaded.walletBalance,
                  totalEarnings: loaded.totalEarnings,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _PayoutInfoCard(
                  phoneNumber: loaded.payoutPhoneNumber,
                  method: loaded.payoutMethod,
                  onEdit: () => _showEditPayoutDialog(context, loaded),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (loaded.transactions.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tx = loaded.transactions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: _TransactionCard(tx: tx),
                    );
                  }, childCount: loaded.transactions.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }
}

class _PayoutInfoCard extends StatelessWidget {
  final String phoneNumber;
  final PayoutMethod? method;
  final VoidCallback onEdit;

  const _PayoutInfoCard({
    required this.phoneNumber,
    required this.method,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasInfo = phoneNumber.isNotEmpty && method != null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasInfo
              ? _orange.withValues(alpha: 0.4)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasInfo
                  ? (method == PayoutMethod.instapay
                        ? Icons.flash_on_outlined
                        : method == PayoutMethod.vodafoneCash
                        ? Icons.phone_android_outlined
                        : Icons.account_balance_outlined)
                  : Icons.add_card_outlined,
              color: _orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: hasInfo
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method!.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phoneNumber,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  )
                : Text(
                    'Set payout account',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(foregroundColor: _orange),
            child: Text(hasInfo ? 'Edit' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final double balance;
  final double totalEarnings;

  const _WalletBalanceCard({
    required this.balance,
    required this.totalEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Total Earnings: EGP ${totalEarnings.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final RestaurantWalletTransaction tx;

  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == WalletTransactionType.credit;
    final amountColor = isCredit
        ? const Color(0xFF38A169)
        : const Color(0xFFE53E3E);
    final amountPrefix = isCredit ? '+' : '-';

    return Container(
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
          Row(
            textDirection: TextDirection.ltr,
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
                      tx.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(tx.createdAt),
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
                  _StatusBadge(tx.status),
                ],
              ),
            ],
          ),

          // Show View Proof / Confirm Receipt whenever evidence exists —
          // remains visible even after the transaction is confirmed.
          if (tx.evidenceUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              textDirection: TextDirection.ltr,
              children: [
                const SizedBox(width: 52),
                Expanded(
                  child: Row(
                    children: [
                      if (tx.status == WalletTransactionStatus.pending &&
                          !tx.confirmedByOwner)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmPayout(context, tx),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                            ),
                            label: const Text('Confirm Receipt'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38A169),
                              side: const BorderSide(color: Color(0xFF38A169)),
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
                        onPressed: () => _viewProof(context, tx.evidenceUrl!),
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
    );
  }

  void _confirmPayout(BuildContext context, RestaurantWalletTransaction tx) {
    context.read<RestaurantWalletCubit>().confirmPayout(
      tx.id,
      '', // adminUserId — pass empty; notification is best-effort
      tx.amount,
    );
  }

  void _viewProof(BuildContext context, String url) {
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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final WalletTransactionStatus status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
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
}
