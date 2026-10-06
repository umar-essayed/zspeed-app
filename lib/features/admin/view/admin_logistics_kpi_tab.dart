import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/admin/cubit/admin_logistics_kpi_cubit.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/model/logistics_kpi_models.dart';
import 'package:z_speed/features/admin/utils/logistics_kpi_export_helper.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class AdminLogisticsKpiTab extends StatefulWidget {
  const AdminLogisticsKpiTab({super.key});

  @override
  State<AdminLogisticsKpiTab> createState() => _AdminLogisticsKpiTabState();
}

class _AdminLogisticsKpiTabState extends State<AdminLogisticsKpiTab> {
  final currencyFormat = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _ordersTableScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _ordersTableScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) => LogisticsKpiCubit()..init(),
      child: BlocBuilder<LogisticsKpiCubit, LogisticsKpiState>(
        builder: (context, state) {
          if (state is LogisticsKpiLoading || state is LogisticsKpiInitial) {
            return Center(
              child: CircularProgressIndicator(color: AdminTheme.primaryOrange),
            );
          }

          if (state is LogisticsKpiError) {
            return Center(
              child: Text(
                l10n.errorLoadingKpiMetrics(state.message),
                style: TextStyle(color: AdminTheme.errorRed),
              ),
            );
          }

          final loaded = state as LogisticsKpiLoaded;
          final cubit = context.read<LogisticsKpiCubit>();

          return Container(
            color: AdminTheme.contentBg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER & FILTER BAR ───────────────────────────────────────
                  _buildHeaderAndFilters(context, l10n, cubit, loaded),
                  const SizedBox(height: 20),

                  // ── TOP 6 KPI CARDS ──────────────────────────────────────────
                  _buildTopKpiCards(l10n, loaded.stats, loaded.filter.calculateWithFees),
                  const SizedBox(height: 24),

                  // ── MIDDLE SECTION: VENDOR & RIDER PANELS ─────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildVendorFinancialsPanel(l10n, loaded)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildRiderPerformancePanel(l10n, loaded)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildVendorFinancialsPanel(l10n, loaded),
                            const SizedBox(height: 20),
                            _buildRiderPerformancePanel(l10n, loaded),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── BOTTOM SECTION: DETAILED ORDERS LISTING WITH PAGINATION & EXPORT ─────────────
                  _buildOrdersDetailedTable(context, l10n, cubit, loaded),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderAndFilters(
    BuildContext context,
    AppLocalizations l10n,
    LogisticsKpiCubit cubit,
    LogisticsKpiLoaded loaded,
  ) {
    final filter = loaded.filter;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.masterLogisticsKpiDashboard,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.kpiDashboardSubtitle,
                      style: TextStyle(color: AdminTheme.textLight, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Export Buttons
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final bytes = await LogisticsKpiExportHelper.exportToExcel(
                        orders: loaded.filteredOrders,
                        stats: loaded.stats,
                        calculateWithFees: filter.calculateWithFees,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(bytes != null ? l10n.excelExportedSuccess : l10n.exportFailed),
                            backgroundColor: bytes != null ? AdminTheme.successGreen : AdminTheme.errorRed,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.table_chart_outlined, size: 16),
                    label: Text(l10n.exportExcel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.successGreen,
                      side: BorderSide(color: AdminTheme.successGreen),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      LogisticsKpiExportHelper.exportToPdf(
                        orders: loaded.filteredOrders,
                        stats: loaded.stats,
                        calculateWithFees: filter.calculateWithFees,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: Text(l10n.exportPdfPrint),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primaryOrange,
                      foregroundColor: AdminTheme.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 28),

          // Filters row
          Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Input
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    cubit.updateFilter(filter.copyWith(searchQuery: val, pageIndex: 0));
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchOrderIdCustomerHint,
                    hintStyle: TextStyle(color: AdminTheme.textLight, fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 18, color: AdminTheme.textLight),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AdminTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AdminTheme.primaryOrange),
                    ),
                  ),
                ),
              ),

              // Date Range Filter Dropdown
              _buildDropdownContainer(
                child: DropdownButton<DateRangeFilter>(
                  value: filter.dateRange,
                  dropdownColor: AdminTheme.white,
                  style: TextStyle(color: AdminTheme.textDark, fontSize: 13),
                  items: [
                    DropdownMenuItem(value: DateRangeFilter.today, child: Text(l10n.today)),
                    DropdownMenuItem(value: DateRangeFilter.yesterday, child: Text(l10n.yesterday)),
                    DropdownMenuItem(value: DateRangeFilter.last7Days, child: Text(l10n.last7Days)),
                    DropdownMenuItem(value: DateRangeFilter.lastMonth, child: Text(l10n.lastMonth)),
                    DropdownMenuItem(value: DateRangeFilter.custom, child: Text(l10n.customDateRange)),
                  ],
                  onChanged: (val) async {
                    if (val == DateRangeFilter.custom) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AdminTheme.primaryOrange,
                                onPrimary: AdminTheme.white,
                                surface: AdminTheme.white,
                                onSurface: AdminTheme.textDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        cubit.updateFilter(filter.copyWith(
                          dateRange: DateRangeFilter.custom,
                          customStartDate: picked.start,
                          customEndDate: picked.end.add(const Duration(days: 1)),
                          pageIndex: 0,
                        ));
                      }
                    } else if (val != null) {
                      final now = DateTime.now();
                      DateTime? start;
                      DateTime? end;

                      switch (val) {
                        case DateRangeFilter.today:
                          start = DateTime(now.year, now.month, now.day);
                          end = start.add(const Duration(days: 1));
                          break;
                        case DateRangeFilter.yesterday:
                          end = DateTime(now.year, now.month, now.day);
                          start = end.subtract(const Duration(days: 1));
                          break;
                        case DateRangeFilter.last7Days:
                          end = now;
                          start = now.subtract(const Duration(days: 7));
                          break;
                        case DateRangeFilter.lastMonth:
                          end = now;
                          start = DateTime(now.year, now.month - 1, now.day);
                          break;
                        case DateRangeFilter.custom:
                          break;
                      }

                      cubit.updateFilter(filter.copyWith(
                        dateRange: val,
                        customStartDate: start,
                        customEndDate: end,
                        pageIndex: 0,
                      ));
                    }
                  },
                ),
              ),

              // Vendor Filter Dropdown
              _buildDropdownContainer(
                child: DropdownButton<String?>(
                  value: filter.vendorId,
                  hint: Text(l10n.allVendorsCombined, style: TextStyle(color: AdminTheme.textDark, fontSize: 13)),
                  dropdownColor: AdminTheme.white,
                  style: TextStyle(color: AdminTheme.textDark, fontSize: 13),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.allVendorsCombined),
                    ),
                    ...loaded.vendorsList.map((v) {
                      return DropdownMenuItem<String?>(
                        value: v['id'],
                        child: Text(v['name']),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val == null) {
                      cubit.updateFilter(filter.copyWith(clearVendor: true, pageIndex: 0));
                    } else {
                      cubit.updateFilter(filter.copyWith(vendorId: val, pageIndex: 0));
                    }
                  },
                ),
              ),

              // Rider Filter Dropdown
              _buildDropdownContainer(
                child: DropdownButton<String?>(
                  value: filter.driverId,
                  hint: Text(l10n.allRidersCombined, style: TextStyle(color: AdminTheme.textDark, fontSize: 13)),
                  dropdownColor: AdminTheme.white,
                  style: TextStyle(color: AdminTheme.textDark, fontSize: 13),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.allRidersCombined),
                    ),
                    ...loaded.driversList.map((d) {
                      return DropdownMenuItem<String?>(
                        value: d['id'],
                        child: Text(d['name']),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val == null) {
                      cubit.updateFilter(filter.copyWith(clearDriver: true, pageIndex: 0));
                    } else {
                      cubit.updateFilter(filter.copyWith(driverId: val, pageIndex: 0));
                    }
                  },
                ),
              ),

              // Status Filter
              _buildDropdownContainer(
                child: DropdownButton<OrderStatus?>(
                  value: filter.status,
                  hint: Text(l10n.allStatuses, style: TextStyle(color: AdminTheme.textDark, fontSize: 13)),
                  dropdownColor: AdminTheme.white,
                  style: TextStyle(color: AdminTheme.textDark, fontSize: 13),
                  items: [
                    DropdownMenuItem<OrderStatus?>(
                      value: null,
                      child: Text(l10n.allStatuses),
                    ),
                    ...OrderStatus.values.map((st) {
                      return DropdownMenuItem<OrderStatus?>(
                        value: st,
                        child: Text(st.name.toUpperCase()),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val == null) {
                      cubit.updateFilter(filter.copyWith(clearStatus: true, pageIndex: 0));
                    } else {
                      cubit.updateFilter(filter.copyWith(status: val, pageIndex: 0));
                    }
                  },
                ),
              ),

              // Payment Method Filter
              _buildDropdownContainer(
                child: DropdownButton<PaymentMethodType?>(
                  value: filter.paymentMethod,
                  hint: Text(l10n.allPaymentMethods, style: TextStyle(color: AdminTheme.textDark, fontSize: 13)),
                  dropdownColor: AdminTheme.white,
                  style: TextStyle(color: AdminTheme.textDark, fontSize: 13),
                  items: [
                    DropdownMenuItem<PaymentMethodType?>(
                      value: null,
                      child: Text(l10n.allPaymentMethods),
                    ),
                    ...PaymentMethodType.values.map((pm) {
                      return DropdownMenuItem<PaymentMethodType?>(
                        value: pm,
                        child: Text(pm.name.toUpperCase()),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val == null) {
                      cubit.updateFilter(filter.copyWith(clearPaymentMethod: true, pageIndex: 0));
                    } else {
                      cubit.updateFilter(filter.copyWith(paymentMethod: val, pageIndex: 0));
                    }
                  },
                ),
              ),

              // Fee Toggle Switch
              Row(
                children: [
                  Text(
                    l10n.platformDeliveryFeeToggle,
                    style: TextStyle(color: AdminTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: filter.calculateWithFees,
                    activeThumbColor: AdminTheme.primaryOrange,
                    onChanged: (val) {
                      cubit.updateFilter(filter.copyWith(calculateWithFees: val));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AdminTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  Widget _buildTopKpiCards(AppLocalizations l10n, LogisticsKpiStats stats, bool withFees) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 6
            : width > 800
                ? 3
                : 2;

        final childAspectRatio = width > 1200
            ? 1.7
            : width > 800
                ? 1.5
                : width > 400
                    ? 1.35
                    : 1.25;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: childAspectRatio,
          children: [
            _buildKpiCard(
              title: l10n.restaurantGrossSales,
              value: currencyFormat.format(stats.restaurantGrossSales),
              subtitle: l10n.subtotalAcrossOrders,
              color: AdminTheme.primaryOrange,
              icon: Icons.storefront_rounded,
            ),
            _buildKpiCard(
              title: l10n.totalDeliveryFeesCollected,
              value: currencyFormat.format(stats.totalDeliveryFeesCollected),
              subtitle: l10n.collectedFromClients,
              color: AdminTheme.infoBlue,
              icon: Icons.local_shipping_rounded,
            ),
            _buildKpiCard(
              title: l10n.tripsCompleted,
              value: '${stats.totalTripsCompleted}',
              subtitle: l10n.deliveredOrdersSubtitle,
              color: AdminTheme.warningAmber,
              icon: Icons.check_circle_rounded,
            ),
            _buildKpiCard(
              title: l10n.activeOrdersKpi,
              value: '${stats.activeOrdersCount}',
              subtitle: l10n.inProgressSubtitle,
              color: const Color(0xFF29B6C0),
              icon: Icons.access_time_filled_rounded,
            ),
            _buildKpiCard(
              title: l10n.rideAcceptanceRate,
              value: '${(stats.overallRideAcceptanceRate * 100).toInt()}%',
              subtitle: l10n.driverResponseRate,
              color: AdminTheme.successGreen,
              icon: Icons.thumb_up_alt_rounded,
            ),
            _buildKpiCard(
              title: withFees ? l10n.masterNetProfit : l10n.masterCommission,
              value: currencyFormat.format(stats.totalNetProfit),
              subtitle: withFees ? l10n.comm10PlusFee15 : l10n.comm10Only,
              color: const Color(0xFF8B5CF6),
              icon: Icons.account_balance_wallet_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminTheme.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: AdminTheme.textDark,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AdminTheme.textLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorFinancialsPanel(AppLocalizations l10n, LogisticsKpiLoaded loaded) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.restaurantFinancialsPayouts,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textDark),
          ),
          const SizedBox(height: 14),
          if (loaded.vendorSummaries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text(l10n.noVendorFinancialData, style: const TextStyle(color: Colors.grey))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: loaded.vendorSummaries.length,
              separatorBuilder: (context, index) => Divider(color: AdminTheme.borderColor),
              itemBuilder: (context, idx) {
                final v = loaded.vendorSummaries[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.vendorName, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold)),
                            Text(l10n.deliveredOrdersCount(v.orderCount), style: TextStyle(color: AdminTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(v.netSales), style: TextStyle(color: AdminTheme.textDark)),
                            Text(l10n.netSalesLabel, style: TextStyle(color: AdminTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(v.masterCommissionDeducted), style: TextStyle(color: AdminTheme.warningAmber)),
                            Text(l10n.adminComm10, style: TextStyle(color: AdminTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(v.amountDueToVendor), style: TextStyle(color: AdminTheme.successGreen, fontWeight: FontWeight.bold)),
                            Text(l10n.amountDue, style: TextStyle(color: AdminTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRiderPerformancePanel(AppLocalizations l10n, LogisticsKpiLoaded loaded) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.riderPerformanceEarnings,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textDark),
          ),
          const SizedBox(height: 14),
          if (loaded.riderSummaries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text(l10n.noRiderTripData, style: const TextStyle(color: Colors.grey))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: loaded.riderSummaries.length,
              separatorBuilder: (context, index) => Divider(color: AdminTheme.borderColor),
              itemBuilder: (context, idx) {
                final r = loaded.riderSummaries[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.riderName, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold)),
                            Text(l10n.tripsCompletedCount(r.tripsCompleted), style: TextStyle(color: AdminTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(r.totalDeliveryFeesEarned), style: TextStyle(color: AdminTheme.textDark)),
                            Text(l10n.totalFeesLabel, style: TextStyle(color: AdminTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(r.riderPayout), style: TextStyle(color: AdminTheme.successGreen)),
                            Text(l10n.riderShare85, style: TextStyle(color: AdminTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormat.format(r.platformFeeCut), style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                            Text(l10n.platformCut15, style: TextStyle(color: AdminTheme.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersDetailedTable(
    BuildContext context,
    AppLocalizations l10n,
    LogisticsKpiCubit cubit,
    LogisticsKpiLoaded loaded,
  ) {
    final filter = loaded.filter;
    final paginatedOrders = loaded.paginatedOrders;
    final totalCount = loaded.totalOrdersCount;
    final totalPages = (totalCount / filter.pageSize).ceil();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.tripOrderDetailedRecords,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.totalOrdersCountLabel(totalCount),
                style: TextStyle(color: AdminTheme.textLight, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (paginatedOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text(l10n.noOrdersMatchFilter, style: const TextStyle(color: Colors.grey))),
            )
          else
            Scrollbar(
              controller: _ordersTableScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _ordersTableScrollController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AdminTheme.contentBg),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 56,
                    columns: [
                      DataColumn(label: Text(l10n.tableColDate, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColOrderTripId, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColStatus, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColChangedBy, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColPayment, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColSubtotal, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColDeliveryFee, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColRiderCut, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColAdminComm, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.tableColPlatformFee, style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold))),
                    ],
                    rows: paginatedOrders.map((order) {
                      final subtotal = order.subtotal;
                      final deliveryFee = order.deliveryFee;

                      final riderCut = deliveryFee * 0.85;
                      final adminComm = subtotal * 0.10;
                      final platformCut = deliveryFee * 0.15;
                      final actorInfo = _resolveStatusActor(order, l10n);

                      return DataRow(
                        onSelectChanged: (_) {
                          _showOrderDetailDialog(context, l10n, order);
                        },
                        cells: [
                          DataCell(Text(
                            DateFormat('MM/dd/yyyy HH:mm').format(order.createdAt),
                            style: TextStyle(color: AdminTheme.textDark, fontSize: 12),
                          )),
                          DataCell(Text(
                            '#${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                            style: TextStyle(color: AdminTheme.infoBlue, fontWeight: FontWeight.bold),
                          )),
                          DataCell(_buildStatusChip(order.status)),
                          DataCell(_buildActorChip(actorInfo)),
                          DataCell(Text(
                            order.paymentMethod.name.toUpperCase(),
                            style: TextStyle(color: AdminTheme.textDark, fontSize: 11),
                          )),
                          DataCell(Text(currencyFormat.format(subtotal), style: TextStyle(color: AdminTheme.textDark))),
                          DataCell(Text(currencyFormat.format(deliveryFee), style: TextStyle(color: AdminTheme.textDark))),
                          DataCell(Text(currencyFormat.format(riderCut), style: TextStyle(color: AdminTheme.successGreen))),
                          DataCell(Text(currencyFormat.format(adminComm), style: TextStyle(color: AdminTheme.warningAmber))),
                          DataCell(Text(currencyFormat.format(platformCut), style: const TextStyle(color: Color(0xFF8B5CF6)))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Pagination Controls Bar
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.pageXOfY(filter.pageIndex + 1, totalPages),
                  style: TextStyle(color: AdminTheme.textLight, fontSize: 13),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: filter.pageIndex > 0
                          ? () {
                              cubit.updateFilter(filter.copyWith(pageIndex: filter.pageIndex - 1));
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: (filter.pageIndex + 1) < totalPages
                          ? () {
                              cubit.updateFilter(filter.copyWith(pageIndex: filter.pageIndex + 1));
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  (String, Color) _resolveStatusActor(Order order, AppLocalizations l10n) {
    final rawActor = order.status == OrderStatus.cancelled
        ? (order.cancelledBy ?? order.statusUpdatedBy)
        : order.statusUpdatedBy;

    if (rawActor != null && rawActor.isNotEmpty) {
      final normalized = rawActor.toLowerCase();
      if (normalized == 'customer') return (l10n.actorCustomer, AdminTheme.infoBlue);
      if (normalized == 'vendor' || normalized == 'restaurant') return (l10n.actorVendor, const Color(0xFF8B5CF6));
      if (normalized == 'driver') return (l10n.actorDriver, AdminTheme.warningAmber);
      if (normalized == 'admin') return (l10n.actorAdmin, AdminTheme.errorRed);
      return (rawActor, AdminTheme.textDark);
    }

    switch (order.status) {
      case OrderStatus.pending:
        return (l10n.actorCustomer, AdminTheme.infoBlue);
      case OrderStatus.accepted:
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return (l10n.actorVendor, const Color(0xFF8B5CF6));
      case OrderStatus.driverAssigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
      case OrderStatus.delivered:
        return (l10n.actorDriver, AdminTheme.warningAmber);
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return (l10n.actorAdmin, AdminTheme.errorRed);
      default:
        return (l10n.actorSystem, AdminTheme.textLight);
    }
  }

  Widget _buildActorChip((String, Color) actorInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: actorInfo.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: actorInfo.$2.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        actorInfo.$1.toUpperCase(),
        style: TextStyle(color: actorInfo.$2, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color bg;
    Color text;
    switch (status) {
      case OrderStatus.delivered:
        bg = AdminTheme.successGreen.withValues(alpha: 0.12);
        text = AdminTheme.successGreen;
        break;
      case OrderStatus.cancelled:
        bg = AdminTheme.errorRed.withValues(alpha: 0.12);
        text = AdminTheme.errorRed;
        break;
      default:
        bg = AdminTheme.warningAmber.withValues(alpha: 0.12);
        text = AdminTheme.warningAmber;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showOrderDetailDialog(BuildContext context, AppLocalizations l10n, Order order) {
    final shortId = '#${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}';
    final actorInfo = _resolveStatusActor(order, l10n);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.orderDetailsTitleParam(shortId), style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.orderIdParam(order.id), style: TextStyle(color: AdminTheme.textDark, fontWeight: FontWeight.w600)),
              Text(l10n.customerIdParam(order.customerId), style: TextStyle(color: AdminTheme.textLight)),
              Text(l10n.statusParam(order.status.name.toUpperCase()), style: TextStyle(color: AdminTheme.textLight)),
              Text(l10n.changedByParam(actorInfo.$1), style: TextStyle(color: actorInfo.$2, fontWeight: FontWeight.w600)),
              if (order.status == OrderStatus.cancelled && order.cancellationReason != null && order.cancellationReason!.isNotEmpty)
                Text(l10n.cancellationReasonParam(order.cancellationReason!), style: TextStyle(color: AdminTheme.errorRed)),
              Text(l10n.paymentMethodParam(order.paymentMethod.name.toUpperCase()), style: TextStyle(color: AdminTheme.textLight)),
              Divider(color: AdminTheme.borderColor, height: 24),
              Text(l10n.subtotalParam(currencyFormat.format(order.subtotal)), style: TextStyle(color: AdminTheme.textDark)),
              Text(l10n.deliveryFeeParam(currencyFormat.format(order.deliveryFee)), style: TextStyle(color: AdminTheme.textDark)),
              Text(l10n.taxParam(currencyFormat.format(order.tax)), style: TextStyle(color: AdminTheme.textDark)),
              Text(l10n.totalParam(currencyFormat.format(order.total)), style: TextStyle(color: AdminTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close, style: TextStyle(color: AdminTheme.primaryOrange)),
          ),
        ],
      ),
    );
  }
}
