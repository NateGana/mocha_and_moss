import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'favorites_tab.dart';
import 'home_tab.dart';
import 'menu_tab.dart';
import 'nav.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

/// Customer app shell: Home, Menu, Favorites, Orders, Profile.
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: customerTab,
      builder: (context, index, _) {
        return Scaffold(
          backgroundColor: colors.espresso,
          body: PhoneFrame(
            child: IndexedStack(
              index: index,
              children: const [
                HomeTab(),
                MenuTab(),
                FavoritesTab(),
                OrdersTab(),
                ProfileTab(),
              ],
            ),
          ),
          bottomNavigationBar: ColoredBox(
            color: colors.espressoDark,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => customerTab.value = i,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.local_cafe_outlined), selectedIcon: Icon(Icons.local_cafe), label: 'Menu'),
                NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
                NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
              ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
