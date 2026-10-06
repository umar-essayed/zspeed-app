import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_analytics_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_analytics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';

/// Analytics dashboard view for the admin panel.
///
// ignore: unintended_html_in_doc_comment
/// Uses Consumer<AdminAnalyticsViewModel> to fetch live analytics data.
/// Displays revenue trends, user distribution, and order statistics.
class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminAnalyticsCubit, AdminAnalyticsState>(
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
                      context.read<AdminAnalyticsCubit>().loadAnalytics(),
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
        return _AnalyticsContent(
          revenueByDay: state.revenueByDay,
          userCounts: state.userCounts,
          orderCounts: state.orderCounts,
          range: state.range ??
              DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now()),
          onDateRangeChanged: context.read<AdminAnalyticsCubit>().setDateRange,
        );
      },
    );
  }
}

/// Internal widget to render analytics when data is loaded.
class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.revenueByDay,
    required this.userCounts,
    required this.orderCounts,
    required this.range,
    required this.onDateRangeChanged,
  });

  final Map<String, double> revenueByDay;
  final Map<UserType, int> userCounts;
  final Map<OrderStatus, int> orderCounts;
  final DateTimeRange range;
  final void Function(DateTimeRange) onDateRangeChanged;

  int get _totalUsers => userCounts.values.fold(0, (a, b) => a + b);
  int get _totalOrders => orderCounts.values.fold(0, (a, b) => a + b);
  double get _totalRevenue => revenueByDay.values.fold(0.0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with date range picker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.analyticsInsights,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textDark,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickDateRange(context),
              icon: const Icon(Icons.date_range, size: 16),
              label: Text(
                '${_formatDate(range.start)} - ${_formatDate(range.end)}',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.primaryOrange,
                side: BorderSide(color: AdminTheme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary cards grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final crossAxisCount = isMobile ? 2 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isMobile ? 1.0 : 1.5,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final cards = [
                  {
                    'title': AppLocalizations.of(context)!.totalUsersLabel,
                    'value': _totalUsers.toString(),
                    'icon': Icons.people,
                    'color': AdminTheme.successGreen,
                  },
                  {
                    'title': AppLocalizations.of(context)!.totalOrdersLabel,
                    'value': _totalOrders.toString(),
                    'icon': Icons.shopping_cart,
                    'color': AdminTheme.primaryOrange,
                  },
                  {
                    'title': AppLocalizations.of(context)!.totalRevenueLabel,
                    'value': 'EGP ${_totalRevenue.toStringAsFixed(0)}',
                    'icon': Icons.attach_money,
                    'color': AdminTheme.infoBlue,
                  },
                  {
                    'title': AppLocalizations.of(context)!.avgRevenueDay,
                    'value': revenueByDay.isNotEmpty
                        ? 'EGP ${(_totalRevenue / revenueByDay.length).toStringAsFixed(0)}'
                        : 'EGP 0',
                    'icon': Icons.trending_up,
                    'color': AdminTheme.warningAmber,
                  },
                ];

                final card = cards[index];
                return _buildMetricCard(
                  title: card['title'] as String,
                  value: card['value'] as String,
                  icon: card['icon'] as IconData,
                  color: card['color'] as Color,
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),

        // User distribution section
        _buildSectionCard(
          title: AppLocalizations.of(context)!.userDistribution,
          child: userCounts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppLocalizations.of(context)!.noUserData,
                      style: TextStyle(color: AdminTheme.textLight),
                    ),
                  ),
                )
              : Column(
                  children: userCounts.entries.map((entry) {
                    final percentage = _totalUsers > 0
                        ? (entry.value / _totalUsers * 100)
                        : 0.0;
                    return _buildDistributionRow(
                      label: entry.key.toString().split('.').last,
                      count: entry.value,
                      percentage: percentage,
                      color: _userTypeColor(entry.key),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // Order status breakdown section
        _buildSectionCard(
          title: AppLocalizations.of(context)!.orderStatusBreakdown,
          child: orderCounts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppLocalizations.of(context)!.noOrderData,
                      style: TextStyle(color: AdminTheme.textLight),
                    ),
                  ),
                )
              : Column(
                  children: orderCounts.entries.map((entry) {
                    final percentage = _totalOrders > 0
                        ? (entry.value / _totalOrders * 100)
                        : 0.0;
                    return _buildDistributionRow(
                      label: entry.key.toString().split('.').last,
                      count: entry.value,
                      percentage: percentage,
                      color: _orderStatusColor(entry.key),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // Revenue trend section
        _buildSectionCard(
          title: AppLocalizations.of(context)!.dailyRevenueTrend,
          child: revenueByDay.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppLocalizations.of(context)!.noRevenueData,
                      style: TextStyle(color: AdminTheme.textLight),
                    ),
                  ),
                )
              : Column(
                  children: revenueByDay.entries.take(10).map((entry) {
                    final maxRevenue =
                        revenueByDay.values.fold(0.0, (a, b) => a > b ? a : b);
                    final barWidth =
                        maxRevenue > 0 ? entry.value / maxRevenue : 0.0;
                    return _buildRevenueBar(
                      context: context,
                      date: entry.key,
                      amount: entry.value,
                      barWidth: barWidth,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AdminTheme.textLight),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AdminTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDistributionRow({
    required String label,
    required int count,
    required double percentage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
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
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AdminTheme.borderColor,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: AdminTheme.textLight,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBar({
    required BuildContext context,
    required String date,
    required double amount,
    required double barWidth,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              date,
              style: TextStyle(fontSize: 11, color: AdminTheme.textLight),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barWidth,
                backgroundColor: AdminTheme.borderColor,
                color: AdminTheme.primaryOrange,
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              AppLocalizations.of(context)!
                  .egpAmount(amount.toStringAsFixed(0).toString()),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminTheme.textDark,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ── Date range picker ──────────────────────────────────────────────

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: range,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AdminTheme.primaryOrange,
              onPrimary: AdminTheme.white,
              surface: AdminTheme.surfaceWhite,
              onSurface: AdminTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Extend end to 23:59:59 so the last selected day is fully included
      // (showDateRangePicker returns midnight 00:00:00 for the end date).
      final endOfDay = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      onDateRangeChanged(DateTimeRange(start: picked.start, end: endOfDay));
    }
  }

  // ── Color helpers ──────────────────────────────────────────────────

  Color _userTypeColor(UserType type) {
    switch (type) {
      case UserType.superAdmin:
      case UserType.admin:
        return AdminTheme.errorRed;
      case UserType.vendor:
        return AdminTheme.warningAmber;
      case UserType.customer:
        return AdminTheme.infoBlue;
      case UserType.driver:
        return AdminTheme.successGreen;
    }
  }

  Color _orderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AdminTheme.successGreen;
      case OrderStatus.preparing:
      case OrderStatus.ready:
      case OrderStatus.driverAssigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return AdminTheme.warningAmber;
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return AdminTheme.primaryOrange;
      case OrderStatus.searching:
      case OrderStatus.unassigned:
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return AdminTheme.errorRed;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
