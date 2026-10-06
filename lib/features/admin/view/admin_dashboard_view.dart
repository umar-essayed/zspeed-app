import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_dashboard_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';

/// Dashboard view for the admin panel.
///

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key, this.onStatCardTap});

  /// Called when a stat card is tapped. Index maps to:
  /// 0 = Total Users, 1 = Total Orders, 2 = Total Revenue, 3 = Pending Orders
  final void Function(int index)? onStatCardTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
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
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AdminTheme.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  state.failure?.getLocalizedMessage(context) ??
                      'An error occurred',
                  style: TextStyle(
                    color: AdminTheme.textDark,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<AdminDashboardCubit>().loadDashboard(),
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

        // Success state - render dashboard
        return _DashboardContent(
          stats: state.statCards,
          orders: state.recentOrders,
          activities: state.recentActivities,
          onStatCardTap: onStatCardTap,
        );
      },
    );
  }
}

/// Internal widget to render the dashboard content when data is loaded.
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.stats,
    required this.orders,
    required this.activities,
    this.onStatCardTap,
  });

  final List<StatCardData> stats;
  final List<AdminOrder> orders;
  final List<AdminActivity> activities;
  final void Function(int index)? onStatCardTap;

  String _localizeStatTitle(BuildContext context, StatCardData stat) {
    final l10n = AppLocalizations.of(context)!;
    switch (stat.key) {
      case StatCardKey.totalUsers:
        return l10n.statTotalUsers;
      case StatCardKey.totalOrders:
        return l10n.statTotalOrders;
      case StatCardKey.totalRevenue:
        return l10n.statTotalRevenue;
      case StatCardKey.pendingOrders:
        return l10n.statPendingOrders;
      case null:
        return stat.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics Grid - Responsive
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final crossAxisCount = isMobile ? 2 : 4;
            // Use intrinsic height wrapping on mobile to avoid fixed-ratio overflow
            if (isMobile) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: stats
                    .asMap()
                    .entries
                    .map((entry) => SizedBox(
                          width: (constraints.maxWidth - 16) / 2,
                          child: _buildStatCard(context, entry.value,
                              index: entry.key),
                        ))
                    .toList(),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) =>
                  _buildStatCard(context, stats[index], index: index),
            );
          },
        ),

        const SizedBox(height: 20),

        // Recent Activity and Orders Row - Responsive
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  _buildRecentActivity(context),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _buildRecentActivity(context)),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // ── Stat Card ────────────────────────────────────────────────────────

  Widget _buildStatCard(BuildContext context, StatCardData stat,
      {int index = 0}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStatCardTap != null ? () => onStatCardTap!(index) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AdminTheme.cardWhite,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [stat.color, stat.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: stat.color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(stat.icon, color: AdminTheme.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_localizeStatTitle(context, stat),
                          style: TextStyle(
                              fontSize: 12,
                              color: AdminTheme.textLight,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(stat.value,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AdminTheme.textDark,
                                    letterSpacing: -0.5),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          _buildTrendBadge(stat),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge(StatCardData stat) {
    final isUp = stat.trend == StatTrend.up;
    final color = isUp ? AdminTheme.successGreen : AdminTheme.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 12, color: color),
          const SizedBox(width: 2),
          Text(stat.change,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Recent Activity ──────────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context) {
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
              spreadRadius: -5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.recentActivity,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.textDark)),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(AppLocalizations.of(context)!.noRecentActivity,
                    style:
                        TextStyle(color: AdminTheme.textLight, fontSize: 13)),
              ),
            )
          else
            ...activities.map((a) => _buildActivityRow(a)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(AdminActivity activity) {
    IconData icon;
    Color color;
    switch (activity.type) {
      case AdminActivityType.userRegistration:
        icon = Icons.person_add;
        color = AdminTheme.successGreen;
      case AdminActivityType.orderCompleted:
        icon = Icons.check_circle;
        color = AdminTheme.infoBlue;
      case AdminActivityType.restaurantApproved:
        icon = Icons.store;
        color = AdminTheme.warningAmber;
      case AdminActivityType.orderPlaced:
        icon = Icons.shopping_bag;
        color = AdminTheme.primaryOrange;
      case AdminActivityType.applicationSubmitted:
        icon = Icons.description;
        color = const Color(0xFF9C27B0);
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AdminTheme.textDark)),
                Text(activity.description,
                    style:
                        TextStyle(fontSize: 11, color: AdminTheme.textLight)),
              ],
            ),
          ),
          Text(activity.timeAgo,
              style: TextStyle(fontSize: 11, color: AdminTheme.textLight)),
        ],
      ),
    );
  }
}
