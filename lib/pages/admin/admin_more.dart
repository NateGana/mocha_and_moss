import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/common.dart';
import 'admin_common.dart';
import 'admin_shell.dart';
import 'admin_tools.dart';
import 'admin_settings.dart';

class AdminMore extends StatelessWidget {
  const AdminMore({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tile(IconData icon, String title, String subtitle, Widget page) => AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Row(
        children: [
          Icon(icon, color: colors.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: TextStyle(color: colors.oat, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.oat),
        ],
      ),
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AdminHeader(
            title: 'More',
            actions: [ThemeToggleButton(isDark: isDark), const SizedBox(width: 8)],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                tile(Icons.people_outline, 'Customers', 'Orders and spending per customer', const CustomersScreen()),
                tile(Icons.bar_chart_rounded, 'Reports', 'Sales by period, top products, CSV export', const ReportsScreen()),
                tile(Icons.local_offer_outlined, 'Promotions', 'Discount codes and limited-time offers', const PromotionsScreen()),
                tile(Icons.workspace_premium_outlined, 'Loyalty', 'Points rules and rewards', const LoyaltyAdminScreen()),
                tile(Icons.campaign_outlined, 'Announcements', 'Messages shown on the customer home page', const AnnouncementsScreen()),
                tile(Icons.reviews_outlined, 'Reviews', 'Moderate customer ratings', const ReviewsAdminScreen()),
                tile(Icons.settings_outlined, 'Settings', 'Café details, hours, payments, fees', const AdminSettingsScreen()),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Reset demo data',
                  outlined: true,
                  icon: Icons.restart_alt_rounded,
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Reset demo data?',
                      message: 'This replaces the menu, accounts, orders and settings on this device with the original sample data.',
                      confirmLabel: 'Reset',
                      destructive: true,
                    );
                    if (!ok) return;
                    await store.resetDemoData();
                    if (!context.mounted) return;
                    adminTab.value = 0;
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Sign out',
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    store.logout();
                    adminTab.value = 0;
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
