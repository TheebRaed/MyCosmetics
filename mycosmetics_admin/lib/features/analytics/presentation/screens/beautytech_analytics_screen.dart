import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';

part 'beautytech_analytics_screen.g.dart';

@riverpod Future<List<Map<String,dynamic>>> btAnalytics(Ref ref) => ref.watch(adminRepositoryProvider).getBeautyTechAnalytics();
@riverpod Future<List<Map<String,dynamic>>> topRecommended(Ref ref) => ref.watch(adminRepositoryProvider).getTopRecommended();
@riverpod Future<List<Map<String,dynamic>>> undertoneDistribution(Ref ref) => ref.watch(adminRepositoryProvider).getUndertoneDistribution();

class BeautyTechAnalyticsScreen extends ConsumerWidget {
  const BeautyTechAnalyticsScreen({super.key});

  static const _colors = [AdminColors.primary, AdminColors.accent, AdminColors.info, AdminColors.success, Color(0xFF9C27B0)];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(btAnalyticsProvider);
    final topAsync       = ref.watch(topRecommendedProvider);
    final undertoneAsync = ref.watch(undertoneDistributionProvider);

    return SingleChildScrollView(
      padding: AdminSpacing.pagePadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AdminPageHeader(
          title: 'BeautyTech Analytics',
          subtitle: 'AI Recommendation & Try-On performance',
          actions: [OutlinedButton.icon(onPressed: () { ref.invalidate(btAnalyticsProvider); ref.invalidate(topRecommendedProvider); ref.invalidate(undertoneDistributionProvider); }, icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh'))],
        ),

        // ── Recommendation KPIs ───────────────────────────────────────────────
        analyticsAsync.when(
          loading: () => _KpiRow.skeleton(),
          error: (e, _) => AdminError(message: e.toString()),
          data: (rows) {
            double totalRecs = 0, totalAccept = 0, totalConvert = 0;
            for (final r in rows) {
              totalRecs    += (r['totalRecommendations'] as num? ?? 0);
              totalAccept  += (r['accepted']             as num? ?? 0);
              totalConvert += (r['converted']            as num? ?? 0);
            }
            final acceptRate  = totalRecs > 0 ? (totalAccept  / totalRecs * 100) : 0.0;
            final convertRate = totalRecs > 0 ? (totalConvert / totalRecs * 100) : 0.0;
            return _KpiRow(totalRecs: totalRecs.toInt(), acceptRate: acceptRate, convertRate: convertRate);
          },
        ),

        const SizedBox(height: 24),

        // ── Category acceptance table + Undertone pie ─────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: Card(child: Padding(padding: AdminSpacing.cardPadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recommendation Performance by Category', style: AdminTextStyles.title.copyWith(fontSize: 15)),
            const SizedBox(height: 12),
            analyticsAsync.when(
              loading: () => const AdminLoading(),
              error: (e, _) => AdminError(message: e.toString()),
              data: (rows) => DataTable(
                columns: const [DataColumn(label: Text('Category')), DataColumn(label: Text('Total')), DataColumn(label: Text('Accepted')), DataColumn(label: Text('Accept %')), DataColumn(label: Text('Convert %'))],
                rows: rows.map((r) => DataRow(cells: [
                  DataCell(Text((r['category'] as String? ?? '').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text('${r['totalRecommendations'] ?? 0}')),
                  DataCell(Text('${r['accepted'] ?? 0}')),
                  DataCell(Text('${(r['acceptanceRate'] as num? ?? 0).toStringAsFixed(1)}%')),
                  DataCell(Text('${(r['conversionRate'] as num? ?? 0).toStringAsFixed(1)}%')),
                ])).toList(),
              ),
            ),
          ])))),
          const SizedBox(width: 16),
          Expanded(child: Card(child: Padding(padding: AdminSpacing.cardPadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Undertone Distribution', style: AdminTextStyles.title.copyWith(fontSize: 15)),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: undertoneAsync.when(
              loading: () => const AdminLoading(),
              error: (e, _) => AdminError(message: e.toString()),
              data: (rows) => rows.isEmpty ? const AdminEmpty(message: 'No data') : Column(children: [
                Expanded(child: PieChart(PieChartData(
                  sections: rows.asMap().entries.map((e) => PieChartSectionData(
                    value: (e.value['count'] as BigInt? ?? BigInt.zero).toDouble(),
                    color: _colors[e.key % _colors.length],
                    title: '${e.value['undertone']}\n${(e.value['percentage'] as num? ?? 0).toStringAsFixed(0)}%',
                    radius: 70, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                  )).toList(),
                  sectionsSpace: 2,
                ))),
              ]),
            )),
          ])))),
        ]),

        const SizedBox(height: 16),

        // ── Top Recommended Variants ──────────────────────────────────────────
        Card(child: Padding(padding: AdminSpacing.cardPadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Top Recommended Variants', style: AdminTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          topAsync.when(
            loading: () => const AdminLoading(),
            error: (e, _) => AdminError(message: e.toString()),
            data: (rows) => rows.isEmpty ? const AdminEmpty(message: 'No recommendation data yet') : DataTable(
              columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('Product')), DataColumn(label: Text('Shade')), DataColumn(label: Text('Colour')), DataColumn(label: Text('Recommendations')), DataColumn(label: Text('Purchases'))],
              rows: rows.asMap().entries.map((e) {
                final r = e.value;
                final hex = r['hexColor'] as String?;
                return DataRow(cells: [
                  DataCell(Text('${e.key + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  DataCell(Text(r['productName'] as String? ?? '')),
                  DataCell(Text(r['shadeName'] as String? ?? '—')),
                  DataCell(hex != null ? Row(children: [
                    Container(width: 18, height: 18, decoration: BoxDecoration(color: _hexColor(hex), shape: BoxShape.circle, border: Border.all(color: AdminColors.divider))),
                    const SizedBox(width: 6), Text(hex, style: AdminTextStyles.caption),
                  ]) : const Text('—')),
                  DataCell(Text('${(r['recommendationCount'] as BigInt? ?? BigInt.zero).toInt()}')),
                  DataCell(Text('${(r['purchaseCount'] as BigInt? ?? BigInt.zero).toInt()}')),
                ]);
              }).toList(),
            ),
          ),
        ]))),
      ]),
    );
  }

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); } catch (_) { return AdminColors.blush; }
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.totalRecs, required this.acceptRate, required this.convertRate});
  final int totalRecs; final double acceptRate, convertRate;

  static Widget skeleton() => Row(children: List.generate(3, (_) => const Expanded(child: Padding(padding: EdgeInsets.only(right: 12), child: KpiCardSkeleton()))));

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: KpiCard(label: 'Total Recommendations', value: '$totalRecs', icon: Icons.auto_awesome, color: AdminColors.primary))),
    Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: KpiCard(label: 'Acceptance Rate', value: '${acceptRate.toStringAsFixed(1)}%', icon: Icons.thumb_up_outlined, color: AdminColors.success))),
    Expanded(child: KpiCard(label: 'Conversion Rate', value: '${convertRate.toStringAsFixed(1)}%', icon: Icons.shopping_cart_checkout, color: AdminColors.accent)),
  ]);
}
