import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global theme mode notifier shared by every screen's toggle button
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.dark,
);

// Switches between light and dark mode
void toggleTheme() {
  themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
}

/// Font helpers. Widget tests flip [offline] so nothing tries to download fonts.
class AppFonts {
  static bool offline = false;

  static TextStyle serif({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    if (offline) {
      return TextStyle(
        fontFamily: 'serif',
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        shadows: shadows,
      );
    }
    return GoogleFonts.dmSerifDisplay(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }
}

class AppColors {
  final Color espresso; // main background
  final Color espressoDark; // secondary surfaces / cards
  final Color latte; // primary text
  final Color oat; // secondary text
  final Color cinnamon; // caramel primary buttons
  final Color gold; // icons and highlights
  final Color line; // thin borders and dividers
  final Color matcha; // secondary matcha accent
  final Color coffee; // card borders / raised surfaces

  const AppColors({
    required this.espresso,
    required this.espressoDark,
    required this.latte,
    required this.oat,
    required this.cinnamon,
    required this.gold,
    required this.line,
    required this.matcha,
    required this.coffee,
  });

  // Color palette used for the light theme
  static const light = AppColors(
    espresso: Color(0xFFFAF3E7),
    espressoDark: Color(0xFFFFFFFF),
    latte: Color(0xFF2A1B12),
    oat: Color(0xFF8A7259),
    cinnamon: Color(0xFFB9652E),
    gold: Color(0xFFAD7A22),
    line: Color(0xFFDDCBB3),
    matcha: Color(0xFF5E7A4A),
    coffee: Color(0xFFEFE2CF),
  );

  // Color palette used for the dark theme (the default look of the app)
  static const dark = AppColors(
    espresso: Color(0xFF1B110D), // Deep Espresso
    espressoDark: Color(0xFF2C1D15), // Dark Mocha
    latte: Color(0xFFF1E4D5), // Warm Cream
    oat: Color(0xFFB8A18B), // Muted Beige
    cinnamon: Color(0xFFE48A45), // Caramel Orange
    gold: Color(0xFFDDAA45), // Golden Accent
    line: Color(0xFF493326), // Coffee Brown
    matcha: Color(0xFF91A77A), // Soft Matcha
    coffee: Color(0xFF493326),
  );

  // Returns the appropriate color palette based on the current theme
  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

// Builds the app's light or dark ThemeData using the selected color palette
ThemeData buildAppTheme(AppColors palette, Brightness brightness) {
  final base = brightness == Brightness.dark
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;
  final textTheme = AppFonts.offline ? base : GoogleFonts.manropeTextTheme(base);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.espresso,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.cinnamon,
      brightness: brightness,
      surface: palette.espresso,
    ),
    textTheme: textTheme.apply(
      bodyColor: palette.latte,
      displayColor: palette.latte,
    ),
    dividerColor: palette.line,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.espressoDark,
      contentTextStyle: TextStyle(color: palette.latte),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.espressoDark,
      indicatorColor: palette.cinnamon.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          color: selected ? palette.gold : palette.oat,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? palette.gold : palette.oat);
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.espressoDark,
      titleTextStyle: AppFonts.serif(fontSize: 20, color: palette.latte),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.espressoDark,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: palette.espressoDark,
      hintStyle: TextStyle(color: palette.oat.withValues(alpha: 0.6)),
      labelStyle: TextStyle(color: palette.oat),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.gold, width: 1.4),
      ),
    ),
  );
}
