import 'package:flutter/material.dart';

import 'config/brand.dart';
import 'data/app_store.dart';
import 'pages/admin/admin_shell.dart';
import 'pages/customer/cart_screen.dart';
import 'pages/customer/checkout_screen.dart';
import 'pages/customer/customer_shell.dart';
import 'pages/customer/extra_screens.dart';
import 'pages/login_screen.dart';
import 'pages/onboarding_screen.dart';
import 'pages/signup_screen.dart';
import 'pages/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load saved menu, accounts, orders and settings before the first frame.
  await store.init();
  runApp(const MochaAndMossApp());
}

/// Shows [page] only for a signed-in customer; otherwise falls back to login.
Widget _customerOnly(Widget page) =>
    store.isLoggedIn && !store.isAdmin ? page : const LoginScreen();

Widget _adminOnly(Widget page) =>
    store.isLoggedIn && store.isAdmin ? page : const LoginScreen();

class MochaAndMossApp extends StatelessWidget {
  const MochaAndMossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: Brand.shortName,
          debugShowCheckedModeBanner: false,

          // Applies the currently selected light or dark theme
          themeMode: mode,
          theme: buildAppTheme(AppColors.light, Brightness.light),
          darkTheme: buildAppTheme(AppColors.dark, Brightness.dark),

          // Defines the app's named navigation routes
          initialRoute: '/', // The splash screen decides where to go next
          routes: {
            '/': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => _customerOnly(const CustomerShell()),
            '/cart': (context) => _customerOnly(const CartScreen()),
            '/checkout': (context) => _customerOnly(const CheckoutScreen()),
            '/loyalty': (context) => _customerOnly(const LoyaltyScreen()),
            '/notifications': (context) =>
                _customerOnly(const NotificationsScreen()),
            '/admin': (context) => _adminOnly(const AdminShell()),
          },
        );
      },
    );
  }
}
