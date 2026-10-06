import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/order/model/order.dart' as app_order;
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_dashboard_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_dashboard_state.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_orders_cubit.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_order_detail_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantDashboardCubit, RestaurantDashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  state.error ??
                      AppLocalizations.of(context)!.somethingWentWrong,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<RestaurantDashboardCubit>().init(),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        // No restaurant yet — show onboarding / create form
        if (state.noRestaurant) {
          return _CreateRestaurantForm(
            cubit: context.read<RestaurantDashboardCubit>(),
          );
        }

        return _DashboardBody(
          state: state,
          cubit: context.read<RestaurantDashboardCubit>(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Create restaurant onboarding form
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateRestaurantForm extends StatefulWidget {
  final RestaurantDashboardCubit cubit;
  const _CreateRestaurantForm({required this.cubit});

  @override
  State<_CreateRestaurantForm> createState() => _CreateRestaurantFormState();
}

class _CreateRestaurantFormState extends State<_CreateRestaurantForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _cuisineCtl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _cuisineCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final cuisines = _cuisineCtl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final ok = await widget.cubit.createRestaurant(
      name: _nameCtl.text.trim(),
      description: _descCtl.text.trim().isEmpty
          ? AppLocalizations.of(context)!.welcomeTo(_nameCtl.text.trim())
          : _descCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      address: _addressCtl.text.trim(),
      cuisineTypes: cuisines,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.restaurantCreatedWelcomeAboard),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF35535);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant, size: 64, color: orange),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.setUpYourRestaurant,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.fillInDetailsBelow,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // ── Form fields ──────────────────────────────
                _field(
                  controller: _nameCtl,
                  label: AppLocalizations.of(context)!.restaurantName,
                  icon: Icons.store,
                  required: true,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _descCtl,
                  label: AppLocalizations.of(context)!.descriptionOptional,
                  icon: Icons.description,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _phoneCtl,
                  label: AppLocalizations.of(context)!.phoneNumberLabel,
                  icon: Icons.phone,
                  keyboard: TextInputType.phone,
                  required: true,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _addressCtl,
                  label: AppLocalizations.of(context)!.address,
                  icon: Icons.location_on,
                  maxLines: 2,
                  required: true,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _cuisineCtl,
                  label: AppLocalizations.of(context)!.cuisineTypesCommaSeparated,
                  icon: Icons.food_bank,
                  hint: AppLocalizations.of(context)!.cuisineTypesHint,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.rocket_launch),
                    label: Text(
                      _submitting
                          ? AppLocalizations.of(context)!.creating
                          : AppLocalizations.of(context)!.createRestaurant,
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? AppLocalizations.of(context)!.fieldIsRequired(label)
              : null
          : null,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFF35535)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF35535), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Dashboard body — extracted to keep build method clean
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardBody extends StatelessWidget {
  final RestaurantDashboardState state;
  final RestaurantDashboardCubit cubit;
  const _DashboardBody({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final vendorType = state.restaurant?.vendorType ?? VendorType.restaurant;
    final vendorLabel = vendorType.getLocalizedLabel(AppLocalizations.of(context)!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.dashboardOverview,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!
                .monitorPerformance(vendorLabel.toLowerCase()),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // ── Toggle Open/Closed ─────────────────────────────────
          _ToggleOpenCard(state: state, cubit: cubit),
          const SizedBox(height: 20),

          // ── Stat cards ─────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 48) / 4
                  : (constraints.maxWidth - 16) / 2;
              final isAr = AppLocalizations.of(context)!.localeName == 'ar';
              final prepTimeLabel = switch (vendorType) {
                VendorType.supermarket =>
                  AppLocalizations.of(context)!.avgPickTime,
                VendorType.pharmacy =>
                  AppLocalizations.of(context)!.avgFillTime,
                VendorType.bookstore =>
                  isAr ? 'متوسط وقت التجهيز' : 'Avg. Packing Time',
                VendorType.homeFurnishing =>
                  isAr ? 'متوسط وقت التجهيز' : 'Avg. Packing Time',
                VendorType.meatAndProteins =>
                  AppLocalizations.of(context)!.avgPickTime,
                VendorType.clothes =>
                  isAr ? 'متوسط وقت التجهيز' : 'Avg. Packing Time',
                VendorType.buyAndSell =>
                  isAr ? 'متوسط وقت التجهيز' : 'Avg. Packing Time',
                VendorType.electronics =>
                  isAr ? 'متوسط وقت التجهيز' : 'Avg. Packing Time',
                _ => AppLocalizations.of(context)!.avgPrepTime,
              };
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _GradientStatCard(
                    width: cardWidth,
                    title: AppLocalizations.of(context)!.totalRevenue,
                    value: 'EGP ${stats.totalRevenue.toStringAsFixed(0)}',
                    change: _pctLabel(stats.revenueChange, context),
                    gradient: const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    icon: Icons.attach_money,
                    positive: stats.revenueChange >= 0,
                  ),
                  _GradientStatCard(
                    width: cardWidth,
                    title: AppLocalizations.of(context)!.activeOrders,
                    value: '${stats.activeOrders}',
                    change: _diffLabel(stats.activeOrdersChange, context),
                    gradient: const [Color(0xFF2196F3), Color(0xFF42A5F5)],
                    icon: Icons.receipt_long,
                    positive: stats.activeOrdersChange >= 0,
                  ),
                  _GradientStatCard(
                    width: cardWidth,
                    title: AppLocalizations.of(context)!.newCustomers,
                    value: '${stats.totalCustomers}',
                    change: _pctLabel(stats.customersChange, context),
                    gradient: const [Color(0xFF9C27B0), Color(0xFFAB47BC)],
                    icon: Icons.people,
                    positive: stats.customersChange >= 0,
                  ),
                  _GradientStatCard(
                    width: cardWidth,
                    title: prepTimeLabel,
                    value: '${stats.avgPrepMinutes}m',
                    change: _prepLabel(stats.prepTimeChange, context),
                    gradient: const [Color(0xFFFF9800), Color(0xFFFFA726)],
                    icon: Icons.timer,
                    positive: stats.prepTimeChange <= 0,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Revenue chart ──────────────────────────────────────
          _RevenueChart(dailyRevenue: stats.dailyRevenue),

          const SizedBox(height: 24),

          // ── Recent orders ──────────────────────────────────────
          _RecentOrdersCard(orders: state.recentOrders),

          const SizedBox(height: 24),

          // ── Help card ──────────────────────────────────────────
          _HelpCard(),
        ],
      ),
    );
  }

  String _pctLabel(double pct, BuildContext context) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% ${AppLocalizations.of(context)!.vsLastWeek}';
  }

  String _diffLabel(double diff, BuildContext context) {
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(0)} ${AppLocalizations.of(context)!.vsLastWeek}';
  }

  String _prepLabel(int diff, BuildContext context) {
    if (diff == 0) return AppLocalizations.of(context)!.sameAsLastWeek;
    if (diff < 0) {
      return '${diff}m ${AppLocalizations.of(context)!.gettingFaster}';
    }
    return '+${diff}m ${AppLocalizations.of(context)!.slower}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Toggle Open/Closed card
// ═══════════════════════════════════════════════════════════════════════════════

class _ToggleOpenCard extends StatelessWidget {
  final RestaurantDashboardState state;
  final RestaurantDashboardCubit cubit;
  const _ToggleOpenCard({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final isOpen = state.restaurant?.isOpen ?? false;
    final isBusy = state.restaurant?.isBusy ?? false;
    final color = !isOpen
        ? Colors.grey[600]!
        : isBusy
            ? const Color(0xFFFF9800)
            : const Color(0xFF4CAF50);

    final vendorType = state.restaurant?.vendorType ?? VendorType.restaurant;
    final vendorLabel = vendorType.getLocalizedLabel(AppLocalizations.of(context)!);
    final vendorIcon = switch (vendorType) {
      VendorType.supermarket => Icons.shopping_cart_outlined,
      VendorType.pharmacy => Icons.local_pharmacy_outlined,
      VendorType.bookstore => Icons.menu_book_outlined,
      VendorType.homeFurnishing => Icons.chair_outlined,
      VendorType.meatAndProteins => Icons.restaurant_menu_outlined,
      VendorType.clothes => Icons.checkroom_outlined,
      VendorType.buyAndSell => Icons.swap_horiz_outlined,
      VendorType.electronics => Icons.devices_outlined,
      _ => Icons.storefront,
    };

    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Open / Closed Row
          Row(
            children: [
              Icon(vendorIcon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen
                          ? loc.vendorIsOpen(vendorLabel)
                          : loc.vendorIsClosed(vendorLabel),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isOpen
                          ? (isBusy
                              ? loc.busyModeActive
                              : loc.customersCanPlaceOrders)
                          : loc.tapToStartAcceptingOrders,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOpen,
                activeThumbColor: const Color(0xFF4CAF50),
                onChanged: (_) => cubit.toggleOpen(),
              ),
            ],
          ),

          // Busy Mode Row (Only active when store is Open)
          if (isOpen) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.access_time_filled,
                    color: Color(0xFFFF9800), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.busyModeLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        loc.busyModeDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isBusy,
                  activeThumbColor: const Color(0xFFFF9800),
                  onChanged: (_) => cubit.toggleBusy(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Gradient stat card (enhanced)
// ═══════════════════════════════════════════════════════════════════════════════

class _GradientStatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String change;
  final List<Color> gradient;
  final IconData icon;
  final bool positive;

  const _GradientStatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.change,
    required this.gradient,
    required this.icon,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      positive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            change,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Revenue bar chart
// ═══════════════════════════════════════════════════════════════════════════════

class _RevenueChart extends StatelessWidget {
  final Map<String, double> dailyRevenue;
  const _RevenueChart({required this.dailyRevenue});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayLabels = {
      'Mon': AppLocalizations.of(context)!.dayMon,
      'Tue': AppLocalizations.of(context)!.dayTue,
      'Wed': AppLocalizations.of(context)!.dayWed,
      'Thu': AppLocalizations.of(context)!.dayThu,
      'Fri': AppLocalizations.of(context)!.dayFri,
      'Sat': AppLocalizations.of(context)!.daySat,
      'Sun': AppLocalizations.of(context)!.daySun,
    };
    final maxVal = dailyRevenue.values.fold<double>(
      1,
      (a, b) => a > b ? a : b,
    );

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.revenueOverview,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context)!.thisWeek,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth =
                    ((constraints.maxWidth - (6 * 8)) / 7).clamp(16.0, 40.0);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: days.map((day) {
                    final value = dailyRevenue[day] ?? 0;
                    final height = maxVal > 0 ? (value / maxVal) * 170 : 0.0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: barWidth,
                          height: height.clamp(4.0, 170.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFA726),
                                Color(0xFFF35535),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(dayLabels[day] ?? day,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recent orders card
// ═══════════════════════════════════════════════════════════════════════════════

class _RecentOrdersCard extends StatelessWidget {
  final List<app_order.Order> orders;
  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.recentOrders,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(AppLocalizations.of(context)!.noOrdersYet,
                    style: const TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...orders.map((order) => _OrderRow(order: order)),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final app_order.Order order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(context, order.status);
    final statusColor = _statusColor(order.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantOrderDetailScreen(
                initialOrder: order,
                cubit: RestaurantOrdersCubit(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(_statusIcon(order.status), color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.orderWithId(order.id.length > 8
                          ? order.id.substring(0, 8).toUpperCase()
                          : order.id.toUpperCase()),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(context, order.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Price + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .currencyEgp(order.total.toStringAsFixed(2)),
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, OrderStatus s) {
    final l10n = AppLocalizations.of(context)!;
    switch (s) {
      case OrderStatus.pending:
        return l10n.statusPending;
      case OrderStatus.accepted:
        return l10n.statusAccepted;
      case OrderStatus.preparing:
        return l10n.statusPreparing;
      case OrderStatus.ready:
        return l10n.statusReady;
      case OrderStatus.driverAssigned:
        return l10n.statusDriverAssigned;
      case OrderStatus.pickedUp:
        return l10n.statusPickedUp;
      case OrderStatus.onTheWay:
        return l10n.statusOnTheWay;
      case OrderStatus.delivered:
        return l10n.statusDelivered;
      case OrderStatus.searching:
      case OrderStatus.unassigned:
      case OrderStatus.cancelled:
        return l10n.statusCancelled;
      case OrderStatus.refunded:
        return l10n.statusRefunded;
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Colors.blue;
      case OrderStatus.accepted:
        return Colors.cyan;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
      case OrderStatus.driverAssigned:
        return Colors.teal;
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.searching:
      case OrderStatus.unassigned:
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return Colors.red;
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Icons.access_time;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.driverAssigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.searching:
      case OrderStatus.unassigned:
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return Icons.cancel;
    }
  }

  String _timeAgo(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Help card
// ═══════════════════════════════════════════════════════════════════════════════

class _HelpCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Colors.orange[50]!, Colors.orange[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF35535),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.help_outline, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.needHelp,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFF35535))),
                Text(AppLocalizations.of(context)!.checkOurDocumentationOr,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF35535),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppLocalizations.of(context)!.supportCenter),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF35535),
                        side: const BorderSide(color: Color(0xFFF35535)),
                      ),
                      child: Text(AppLocalizations.of(context)!.documentation),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
