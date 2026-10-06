import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_analytics_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_analytics_state.dart';
import 'package:intl/intl.dart';

/// Full analytics page with date-range filtering, revenue & order charts,
/// top-selling items, peak hours, completion rate, and customer stats.
class RestaurantAnalyticsScreen extends StatelessWidget {
  const RestaurantAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RestaurantAnalyticsCubit(),
      child: BlocBuilder<RestaurantAnalyticsCubit, RestaurantAnalyticsState>(
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
                    onPressed: () =>
                        context.read<RestaurantAnalyticsCubit>().init(),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          return _AnalyticsBody(
            state: state,
            cubit: context.read<RestaurantAnalyticsCubit>(),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Main analytics body
// ═══════════════════════════════════════════════════════════════════════════════

class _AnalyticsBody extends StatelessWidget {
  final RestaurantAnalyticsState state;
  final RestaurantAnalyticsCubit cubit;
  const _AnalyticsBody({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    final currencyFmt = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: AppLocalizations.of(context)!.currencySymbol,
      decimalDigits: 2,
    );

    return RefreshIndicator(
      onRefresh: () => cubit.init(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Date range selector ──
          _DateRangeSelector(state: state, cubit: cubit),
          const SizedBox(height: 16),

          // ── KPI cards row ──
          _KpiCardsGrid(data: data, currencyFmt: currencyFmt),
          const SizedBox(height: 20),

          // ── Revenue trend chart ──
          _SectionCard(
            title: AppLocalizations.of(context)!.revenueTrend,
            icon: Icons.trending_up,
            child: _BarChart(
              dataPoints: data.revenueByDay,
              color: const Color(0xFF4CAF50),
              valueFormatter: (v) => currencyFmt.format(v),
            ),
          ),
          const SizedBox(height: 16),

          // ── Orders volume chart ──
          _SectionCard(
            title: AppLocalizations.of(context)!.orderVolume,
            icon: Icons.bar_chart,
            child: _BarChart(
              dataPoints: data.ordersByDay,
              color: const Color(0xFF2196F3),
              valueFormatter: (v) => v.toInt().toString(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Order breakdown row ──
          _OrderBreakdownRow(data: data),
          const SizedBox(height: 16),

          // ── Top selling items ──
          _SectionCard(
            title: AppLocalizations.of(context)!.topSellingItems,
            icon: Icons.emoji_events,
            child: data.topItems.isEmpty
                ? _EmptyState(
                    message: AppLocalizations.of(context)!.noItemDataAvailable)
                : _TopItemsList(items: data.topItems, currencyFmt: currencyFmt),
          ),
          const SizedBox(height: 16),

          // ── Peak hours ──
          _SectionCard(
            title: AppLocalizations.of(context)!.peakHours,
            icon: Icons.schedule,
            child: data.ordersByHour.isEmpty
                ? _EmptyState(
                    message:
                        AppLocalizations.of(context)!.noHourlyDataAvailable)
                : _PeakHoursChart(hourCounts: data.ordersByHour),
          ),
          const SizedBox(height: 16),

          // ── Customer stats ──
          _CustomerStatsCard(data: data),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Date range selector
// ═══════════════════════════════════════════════════════════════════════════════

class _DateRangeSelector extends StatelessWidget {
  final RestaurantAnalyticsState state;
  final RestaurantAnalyticsCubit cubit;
  const _DateRangeSelector({required this.state, required this.cubit});

  String _rangeLabel(BuildContext context, AnalyticsRange range) {
    final l10n = AppLocalizations.of(context)!;
    switch (range) {
      case AnalyticsRange.today:
        return l10n.today;
      case AnalyticsRange.thisWeek:
        return l10n.thisWeek;
      case AnalyticsRange.thisMonth:
        return l10n.thisMonth;
      case AnalyticsRange.lastMonth:
        return l10n.lastMonth;
      case AnalyticsRange.custom:
        return l10n.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AnalyticsRange.values.map((range) {
          final selected = state.selectedRange == range;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(_rangeLabel(context, range)),
              selected: selected,
              selectedColor: const Color(0xFFF35535),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (val) async {
                if (range == AnalyticsRange.custom) {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: const Color(0xFFF35535),
                            ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    cubit.setRange(range, start: picked.start, end: picked.end);
                  }
                } else {
                  cubit.setRange(range);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// KPI cards
// ═══════════════════════════════════════════════════════════════════════════════

class _KpiCardsGrid extends StatelessWidget {
  final AnalyticsData data;
  final NumberFormat currencyFmt;
  const _KpiCardsGrid({required this.data, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(
          title: AppLocalizations.of(context)!.totalRevenue,
          value: currencyFmt.format(data.totalRevenue),
          icon: Icons.attach_money,
          color: const Color(0xFF4CAF50),
        ),
        _KpiCard(
          title: AppLocalizations.of(context)!.totalOrders,
          value: data.totalOrders.toString(),
          icon: Icons.receipt_long,
          color: const Color(0xFF2196F3),
        ),
        _KpiCard(
          title: AppLocalizations.of(context)!.avgOrderValue,
          value: currencyFmt.format(data.avgOrderValue),
          icon: Icons.analytics,
          color: const Color(0xFF9C27B0),
        ),
        _KpiCard(
          title: AppLocalizations.of(context)!.completionRate,
          value: '${(data.completionRate * 100).toStringAsFixed(1)}%',
          icon: Icons.check_circle,
          color: const Color(0xFFFF9800),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Section card wrapper
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFF35535), size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bar chart (simple custom painter, no external dependency)
// ═══════════════════════════════════════════════════════════════════════════════

class _BarChart extends StatelessWidget {
  final List<DailyDataPoint> dataPoints;
  final Color color;
  final String Function(double) valueFormatter;

  const _BarChart({
    required this.dataPoints,
    required this.color,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return _EmptyState(
          message: AppLocalizations.of(context)!.noDataForThisPeriod);
    }

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(
          dataPoints: dataPoints,
          barColor: color,
          localeName: Localizations.localeOf(context).toString(),
          valueFormatter: valueFormatter,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<DailyDataPoint> dataPoints;
  final Color barColor;
  final String localeName;
  final String Function(double) valueFormatter;

  _BarChartPainter({
    required this.dataPoints,
    required this.barColor,
    required this.localeName,
    required this.valueFormatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final maxVal =
        dataPoints.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    final barMax = maxVal > 0 ? maxVal : 1.0;

    final barWidth = (size.width / dataPoints.length) * 0.6;
    final gap = (size.width / dataPoints.length) * 0.4;
    final totalBarSpace = barWidth + gap;

    final barPaint = Paint()
      ..shader = LinearGradient(
        colors: [barColor, barColor.withValues(alpha: 0.6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, barWidth, size.height));

    final textStyle = ui.TextStyle(
      color: Colors.grey[600],
      fontSize: 10,
    );

    final dateFmt = DateFormat.Md(localeName);
    const bottomPadding = 24.0;
    final chartHeight = size.height - bottomPadding;

    // Horizontal grid lines (drawn first, behind bars)
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < dataPoints.length; i++) {
      final dp = dataPoints[i];
      final barHeight = (dp.value / barMax) * chartHeight * 0.85;
      final x = i * totalBarSpace + gap / 2;
      final y = chartHeight - barHeight;

      // Bar
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(barRect, barPaint);

      // Only show every N-th label if too many
      if (dataPoints.length <= 14 || i % (dataPoints.length ~/ 7 + 1) == 0) {
        final labelText = dateFmt.format(dp.date);
        final paragraphBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textDirection: ui.TextDirection.ltr,
            maxLines: 1,
          ),
        )
          ..pushStyle(textStyle)
          ..addText(labelText);
        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: totalBarSpace));

        canvas.drawParagraph(
          paragraph,
          Offset(x + barWidth / 2 - paragraph.width / 2,
              size.height - bottomPadding + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.dataPoints != dataPoints;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Order breakdown row (delivered / cancelled / rejected)
// ═══════════════════════════════════════════════════════════════════════════════

class _OrderBreakdownRow extends StatelessWidget {
  final AnalyticsData data;
  const _OrderBreakdownRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactStatCard(
            label: AppLocalizations.of(context)!.delivered,
            value: data.deliveredOrders.toString(),
            icon: Icons.check_circle_outline,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactStatCard(
            label: AppLocalizations.of(context)!.cancelled,
            value: data.cancelledOrders.toString(),
            icon: Icons.cancel_outlined,
            color: const Color(0xFFF44336),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactStatCard(
            label: AppLocalizations.of(context)!.refunded,
            value: data.rejectedOrders.toString(),
            icon: Icons.undo,
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Top items list
// ═══════════════════════════════════════════════════════════════════════════════

class _TopItemsList extends StatelessWidget {
  final List<TopItem> items;
  final NumberFormat currencyFmt;

  const _TopItemsList({required this.items, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final maxQty =
            items.fold<int>(0, (m, i) => i.quantity > m ? i.quantity : m);
        final ratio = maxQty > 0 ? item.quantity / maxQty : 0.0;

        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: index < 3 ? const Color(0xFFF35535) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index < 3 ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFFF35535),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.of(context)!.soldCount(item.quantity),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    currencyFmt.format(item.revenue),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Peak hours chart
// ═══════════════════════════════════════════════════════════════════════════════

class _PeakHoursChart extends StatelessWidget {
  final Map<int, int> hourCounts;
  const _PeakHoursChart({required this.hourCounts});

  @override
  Widget build(BuildContext context) {
    // Show hours 6 AM to 2 AM (most restaurant hours)
    final hours = List.generate(20, (i) => (i + 6) % 24);
    final maxCount = hourCounts.values.fold<int>(0, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: hours.map((hour) {
          final count = hourCounts[hour] ?? 0;
          final ratio = maxCount > 0 ? count / maxCount : 0.0;
          final isPeak = count == maxCount && maxCount > 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPeak)
                    const Icon(Icons.star, size: 10, color: Color(0xFFF35535)),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: ratio > 0 ? ratio : 0.02,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isPeak
                              ? const Color(0xFFF35535)
                              : const Color(0xFF2196F3).withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Only show label every 2 hours to avoid crowding
                  if (hour % 2 == 0)
                    Text(
                      hour.toString().padLeft(2, '0'),
                      style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                    )
                  else
                    const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Customer stats card
// ═══════════════════════════════════════════════════════════════════════════════

class _CustomerStatsCard extends StatelessWidget {
  final AnalyticsData data;
  const _CustomerStatsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppLocalizations.of(context)!.customerInsights,
      icon: Icons.people,
      child: Row(
        children: [
          Expanded(
            child: _CustomerStat(
              label: AppLocalizations.of(context)!.totalCustomers,
              value: data.uniqueCustomers.toString(),
              icon: Icons.group,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CustomerStat(
              label: AppLocalizations.of(context)!.new_,
              value: data.newCustomers.toString(),
              icon: Icons.person_add,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CustomerStat(
              label: AppLocalizations.of(context)!.returning,
              value: data.returningCustomers.toString(),
              icon: Icons.replay,
              color: const Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CustomerStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
