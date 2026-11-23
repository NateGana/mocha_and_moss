import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

/// Brand splash. Decides where to go next: onboarding on first launch,
/// otherwise the saved session or the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), _continue);
  }

  void _continue() {
    if (!mounted) return;
    String route;
    if (store.isLoggedIn) {
      route = store.isAdmin ? '/admin' : '/home';
    } else if (!store.onboardingSeen) {
      route = '/onboarding';
    } else {
      route = '/login';
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: colors.espresso,
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(fade),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: const BrandLockup(markSize: 72, nameSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}
