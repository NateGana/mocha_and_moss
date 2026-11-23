import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_widgets.dart';
import 'brand_logo.dart';

/// The soft gradient banner with brand mark that tops the login and sign-up
/// screens (same layout as the original design).
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.heightFactor = 0.30});
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = (MediaQuery.of(context).size.height * heightFactor).clamp(190.0, 260.0).toDouble();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.latte.withValues(alpha: 0.05),
                  colors.espresso.withValues(alpha: 0.55),
                  colors.espresso,
                ],
                stops: const [0.0, 0.75, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 12),
                child: ThemeToggleButton(isDark: isDark),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: const BrandLockup(markSize: 36, nameSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
