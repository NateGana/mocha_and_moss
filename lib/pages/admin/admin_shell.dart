import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'admin_dashboard.dart';
import 'admin_inventory.dart';
import 'admin_menu.dart';
import 'admin_more.dart';
import 'admin_orders.dart';

final ValueNotifier<int> adminTab = ValueNotifier<int>(0);

/// Café owner shell: Dashboard, Orders, Menu, Inventory, More.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: adminTab,
      builder: (context, index, _) {
        return Scaffold(
          backgroundColor: colors.espresso,
          body: PhoneFrame(
            child: IndexedStack(
              index: index,
              children: const [
                AdminDashboard(),
                AdminOrders(),
                AdminMenu(),
                AdminInventory(),
                AdminMore(),
              ],
            ),
          ),
          bottomNavigationBar: ColoredBox(
            color: colors.espressoDark,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListenableBuilder(
                  listenable: store,
                  builder: (context, _) {
                    final newOrders =
                        store.orders.where((o) => o.status == OrderStatus.received).length;
                    return NavigationBar(
                      selectedIndex: index,
                      onDestinationSelected: (i) => adminTab.value = i,
                      destinations: [
                        const NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: 'Dashboard',
                        ),
                        NavigationDestination(
                          icon: Badge(
                            isLabelVisible: newOrders > 0,
                            label: Text('$newOrders'),
                            child: const Icon(Icons.receipt_long_outlined),
                          ),
                          selectedIcon: const Icon(Icons.receipt_long),
                          label: 'Orders',
                        ),
                        const NavigationDestination(
                          icon: Icon(Icons.local_cafe_outlined),
                          selectedIcon: Icon(Icons.local_cafe),
                          label: 'Menu',
                        ),
                        const NavigationDestination(
                          icon: Icon(Icons.inventory_2_outlined),
                          selectedIcon: Icon(Icons.inventory_2),
                          label: 'Inventory',
                        ),
                        const NavigationDestination(
                          icon: Icon(Icons.more_horiz),
                          selectedIcon: Icon(Icons.more_horiz),
                          label: 'More',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
