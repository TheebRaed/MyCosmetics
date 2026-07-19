import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../data/models/admin_models.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dashboardOverviewProvider);
    final charts   = ref.watch(dashboardChartsProvider);
    final fmt      = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      padding: AdminSpacing.pagePadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AdminPageHeader(
          title: 'Dashboard',
          subtitle: 'Overview of your business performance',
          actions: [
            OutlinedButton.icon(
              onPressed: () { ref.invalidate(dashboardOverviewProvider); ref.invalidate(dashboardChartsProvider); },
              icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh'),
            ),
          ],
        ),
        overview.when(
          loading: () => GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6, children: List.generate(12, (_) => const KpiCardSkeleton())),
          error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(dashboardOverviewProvider)),
          data: (o) => GridView.count(
            crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6,
            children: [
              KpiCard(label: 'Total Revenue',       value: fmt.format(o.revenueTotal),       icon: Icons.attach_money,           color: AdminColors.success),
              KpiCard(label: 'Revenue Today',       value: fmt.format(o.revenueToday),       icon: Icons.today,                  color: AdminColors.primary),
              KpiCard(label: 'Revenue This Month',  value: fmt.format(o.revenueThisMonth),   icon: Icons.calendar_month,         color: AdminColors.accent),
              KpiCard(label: 'Total Orders',        value: '${o.totalOrders}',               icon: Icons.receipt_long,           color: AdminColors.info),
              KpiCard(label: 'Pending Orders',      value: '${o.pendingOrders}',             icon: Icons.pending_outlined,       color: AdminColors.warning),
              KpiCard(label: 'Processing Orders',   value: '${o.processingOrders}',          icon: Icons.settings_outlined,      color: AdminColors.info),
              KpiCard(label: 'Completed Orders',    value: '${o.completedOrders}',           icon: Icons.check_circle_outline,   color: AdminColors.success),
              KpiCard(label: 'Cancelled Orders',    value: '${o.cancelledOrders}',           icon: Icons.cancel_outlined,        color: AdminColors.error),
              KpiCard(label: 'Active Customers',    value: '${o.activeCustomers}',           icon: Icons.people_alt_outlined,    color: AdminColors.primary),
              KpiCard(label: 'Registered Users',    value: '${o.registeredUsers}',           icon: Icons.person_outline,         color: AdminColors.info),
              KpiCard(label: 'Low Stock',           value: '${o.lowStockProducts}',          icon: Icons.warning_amber_outlined, color: AdminColors.warning),
              KpiCard(label: 'Out of Stock',        value: '${o.outOfStockProducts}',        icon: Icons.remove_shopping_cart,   color: AdminColors.error),
            ],
          ),
        ),
        const SizedBox(height: 32),
        charts.when(
          loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => AdminError(message: e.toString()),
          data: (c) => Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: _card('Daily Sales (Last 90 Days)', _LineChart(c.dailySales))),
              const SizedBox(width: 16),
              Expanded(child: _card('Revenue by Category', _PieChart(c.revenueByCategory))),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _card('Monthly Sales', _BarChart(c.monthlySales))),
              const SizedBox(width: 16),
              Expanded(child: _card('Revenue by Brand', _BarChart(c.revenueByBrand))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _card(String title, Widget child) => Card(child: Padding(padding: AdminSpacing.cardPadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: AdminTextStyles.title.copyWith(fontSize: 15)),
    const SizedBox(height: 16),
    SizedBox(height: 220, child: child),
  ])));
}

class _LineChart extends StatelessWidget {
  const _LineChart(this.data);
  final List<SalesDataPoint> data;
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const AdminEmpty(message: 'No data yet');
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList();
    return LineChart(LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles:AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles:  AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48)),
      ),
      lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: AdminColors.primary, barWidth: 2.5, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AdminColors.primary.withOpacity(0.08)))],
    ));
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart(this.data);
  final List<SalesDataPoint> data;
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const AdminEmpty(message: 'No data yet');
    final top = data.take(6).toList();
    return BarChart(BarChartData(
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i >= top.length) return const SizedBox.shrink();
          final l = top[i].label.length > 8 ? '${top[i].label.substring(0, 8)}…' : top[i].label;
          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(l, style: AdminTextStyles.caption));
        })),
      ),
      barGroups: top.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.revenue, color: AdminColors.accent, width: 18, borderRadius: BorderRadius.circular(4))])).toList(),
    ));
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart(this.data);
  final List<SalesDataPoint> data;
  static const _colors = [AdminColors.primary, AdminColors.accent, AdminColors.info, AdminColors.success, AdminColors.warning, Color(0xFF9C27B0)];
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const AdminEmpty(message: 'No data yet');
    final total = data.fold<double>(0, (s, d) => s + d.revenue);
    return PieChart(PieChartData(
      sections: data.take(6).toList().asMap().entries.map((e) {
        final pct = total > 0 ? e.value.revenue / total * 100 : 0.0;
        return PieChartSectionData(value: e.value.revenue, color: _colors[e.key % _colors.length], title: '${pct.toStringAsFixed(0)}%', radius: 60, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700));
      }).toList(),
      sectionsSpace: 2,
    ));
  }
}
