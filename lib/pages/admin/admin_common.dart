import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Scaffold wrapper shared by the admin sub-screens.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.fab,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.espresso,
      appBar: AppBar(
        backgroundColor: colors.espresso,
        foregroundColor: colors.latte,
        title: Text(title, style: AppFonts.serif(fontSize: 22, color: colors.latte)),
        actions: actions,
      ),
      floatingActionButton: fab,
      body: PhoneFrame(child: child),
    );
  }
}

/// Header row for the tab screens inside the admin shell.
class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key, required this.title, this.actions = const []});
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppFonts.serif(fontSize: 26, color: colors.latte)),
          ),
          ...actions,
        ],
      ),
    );
  }
}

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Simple bar chart drawn with plain widgets (no chart package needed).
class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.data, required this.format});
  final List<MapEntry<DateTime, double>> data;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final maxValue = data.fold<double>(0, (a, e) => e.value > a ? e.value : a);
    const chartHeight = 110.0;
    final showLabels = data.length <= 10;
    return SizedBox(
      height: chartHeight + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showLabels)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          e.value == 0 ? '' : format(e.value),
                          style: TextStyle(color: colors.oat, fontSize: 9),
                        ),
                      ),
                    const SizedBox(height: 3),
                    Container(
                      height: maxValue == 0 ? 3 : (e.value / maxValue * chartHeight).clamp(3.0, chartHeight).toDouble(),
                      decoration: BoxDecoration(
                        color: e.value == 0 ? colors.line : colors.cinnamon,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (showLabels)
                      Text(
                        data.length <= 7 ? _days[e.key.weekday - 1] : '${e.key.day}',
                        style: TextStyle(color: colors.oat, fontSize: 10),
                      )
                    else
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
