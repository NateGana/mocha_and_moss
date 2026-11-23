import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../data/report_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';
import 'admin_shell.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  /// Best-selling product name for a kind among completed orders.
  String _best(SalesReport r, String kind) {
    final units = <String, int>{};
    for (final o in r.completed) {
      for (final l in o.lines) {
        if (l.kind == kind) units[l.name] = (units[l.name] ?? 0) + l.quantity;
      }
    }
    if (units.isEmpty) return 'No sales yet';
    final best = units.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${best.key} (${best.value})';
  }

  String _bestDrink(SalesReport r) {
    final units = <String, int>{};
    for (final o in r.completed) {
      for (final l in o.lines) {
        if (l.kind != Kinds.dessert && l.kind != Kinds.bundle) {
          units[l.name] = (units[l.name] ?? 0) + l.quantity;
        }
      }
    }
    if (units.isEmpty) return 'No sales yet';
    final best = units.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${best.key} (${best.value})';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final today = Fmt.dayStart(now);
        final all = SalesReport.build(store.orders, DateTime(2000), now);
        final daily = SalesReport.build(store.orders, today, today);
        final weekly = SalesReport.build(store.orders, today.subtract(const Duration(days: 6)), today);
        final monthly = SalesReport.build(store.orders, today.subtract(const Duration(days: 29)), today);
        final active = store.orders.where((o) => o.isActive).toList();
        final fresh = store.orders.where((o) => o.status == OrderStatus.received).length;
        final recent = store.orders.take(5).toList();
        final top = all.topProducts.take(5).toList();

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AdminHeader(
                title: 'Dashboard',
                actions: [ThemeToggleButton(isDark: isDark), const SizedBox(width: 8)],
              ),
              if (fresh > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: AppCard(
                    highlight: true,
                    onTap: () => adminTab.value = 1,
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, color: colors.cinnamon),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$fresh new order${fresh == 1 ? '' : 's'} waiting for confirmation',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: colors.oat),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    StatCard(
                      label: 'Total sales (completed)',
                      value: store.money(all.revenue),
                      icon: Icons.payments_outlined,
                    ),
                    StatCard(
                      label: 'Total orders',
                      value: '${store.orders.length}',
                      icon: Icons.receipt_long_outlined,
                      caption: '${store.orders.where((o) => o.status == OrderStatus.cancelled).length} cancelled',
                    ),
                    StatCard(
                      label: 'Pending orders',
                      value: '${active.length}',
                      icon: Icons.hourglass_bottom_rounded,
                      accent: colors.cinnamon,
                    ),
                    StatCard(
                      label: 'Completed orders',
                      value: '${all.orderCount}',
                      icon: Icons.check_circle_outline,
                      accent: colors.matcha,
                    ),
                    StatCard(
                      label: 'Menu items',
                      value: '${store.products.length}',
                      icon: Icons.local_cafe_outlined,
                    ),
                    StatCard(
                      label: 'Average order',
                      value: store.money(all.averageOrder),
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Sales'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _MiniStat('Today', store.money(daily.revenue), '${daily.orderCount} orders')),
                    const SizedBox(width: 10),
                    Expanded(child: _MiniStat('7 days', store.money(weekly.revenue), '${weekly.orderCount} orders')),
                    const SizedBox(width: 10),
                    Expanded(child: _MiniStat('30 days', store.money(monthly.revenue), '${monthly.orderCount} orders')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last 7 days', style: TextStyle(color: colors.oat, fontSize: 12)),
                      const SizedBox(height: 10),
                      SalesBarChart(
                        data: SalesReport.lastDays(store.orders, 7),
                        format: (v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0),
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: 'Best sellers'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  child: Column(
                    children: [
                      _bestRow(colors, Icons.local_cafe, 'Most popular drink', _bestDrink(all), colors.gold),
                      _bestRow(colors, Icons.coffee_rounded, 'Bestselling mocha', _best(all, Kinds.mocha), colors.gold),
                      _bestRow(colors, Icons.eco_outlined, 'Bestselling matcha', _best(all, Kinds.matcha), colors.matcha),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: 'Popular products'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  child: top.isEmpty
                      ? Text('No completed orders yet.', style: TextStyle(color: colors.oat))
                      : Column(
                          children: [
                            for (final e in top)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text('${e.value} sold', style: TextStyle(color: colors.oat)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              SectionHeader(
                title: 'Recent orders',
                actionLabel: 'View all',
                onAction: () => adminTab.value = 1,
              ),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('No orders yet.', style: TextStyle(color: colors.oat)),
                ),
              for (final o in recent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.orderNo, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${o.customerName} · ${store.money(o.total)}',
                                  style: TextStyle(color: colors.oat, fontSize: 12)),
                            ],
                          ),
                        ),
                        StatusChip(o),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _bestRow(AppColors colors, IconData icon, String label, String value, Color accent) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(color: colors.oat, fontSize: 12.5))),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.caption);
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.oat, fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppFonts.serif(fontSize: 18, color: colors.latte)),
          ),
          Text(caption, style: TextStyle(color: colors.oat, fontSize: 10.5)),
        ],
      ),
    );
  }
}
