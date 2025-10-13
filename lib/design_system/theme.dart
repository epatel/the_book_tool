import 'package:the_book_tool/index.dart';

class AppTheme {
  // Light Theme Colors
  static const primaryColor = Color(0xFF6750A4);
  static const secondaryColor = Color(0xFF625B71);
  static const backgroundColor = Color(0xFFFFFBFE);
  static const surfaceColor = Color(0xFFFFFBFE);
  static const surfaceVariantColor = Color(0xFFE7E0EC);
  static const onPrimaryColor = Color(0xFFFFFFFF);
  static const onSecondaryColor = Color(0xFFFFFFFF);
  static const onBackgroundColor = Color(0xFF1C1B1F);
  static const onSurfaceColor = Color(0xFF1C1B1F);
  static const errorColor = Color(0xFFB3261E);

  // Dark Theme Colors
  static const primaryColorDark = Color(0xFFD0BCFF);
  static const secondaryColorDark = Color(0xFFCCC2DC);
  static const backgroundColorDark = Color(0xFF1C1B1F);
  static const surfaceColorDark = Color(0xFF1C1B1F);
  static const surfaceVariantColorDark = Color(0xFF49454F);
  static const onPrimaryColorDark = Color(0xFF381E72);
  static const onSecondaryColorDark = Color(0xFF332D41);
  static const onBackgroundColorDark = Color(0xFFE6E1E5);
  static const onSurfaceColorDark = Color(0xFFE6E1E5);
  static const errorColorDark = Color(0xFFF2B8B5);

  // Typography
  static const displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static const displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
  );

  static const displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
  );

  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
  );

  static const headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
  );

  static const headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Spacing
  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing40 = 40.0;
  static const spacing48 = 48.0;

  // Border Radius
  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 16.0;

  // Elevation
  static const elevation0 = 0.0;
  static const elevation1 = 1.0;
  static const elevation2 = 3.0;
  static const elevation3 = 6.0;
  static const elevation4 = 8.0;
  static const elevation5 = 12.0;

  // Layout Widths
  static const sidebarWidth = 250.0;
  static const dialogWidth = 500.0;
  static const dialogWidthSmall = 400.0;

  // Icon Sizes
  static const iconSizeSmall = 18.0;
  static const iconSizeMedium = 24.0;
  static const iconSizeLarge = 64.0;

  // Component Heights
  static const collapsedContentHeight = 60.0;
  static const gradientOverlayHeight = 20.0;

  // Text MaxLines
  static const maxLinesPreview = 3;
  static const maxLinesContentField = 5;
  static const maxLinesAiPrompt = 2;

  // Stroke Widths
  static const strokeWidthThin = 2.0;
  static const strokeWidthNormal = 4.0;

  // Opacity Values
  static const opacityDisabled = 0.3;
  static const opacitySubtle = 0.4;
  static const opacityMedium = 0.6;
  static const opacityHigh = 0.7;
  static const opacityFull = 1.0;
  static const opacityTransparent = 0.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSecondaryColor,
        onSurface: onSurfaceColor,
        onError: onPrimaryColor,
        surfaceContainerHighest: surfaceVariantColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(
        elevation: elevation1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColorDark,
        secondary: secondaryColorDark,
        surface: surfaceColorDark,
        error: errorColorDark,
        onPrimary: onPrimaryColorDark,
        onSecondary: onSecondaryColorDark,
        onSurface: onSurfaceColorDark,
        onError: onPrimaryColorDark,
        surfaceContainerHighest: surfaceVariantColorDark,
      ),
      scaffoldBackgroundColor: backgroundColorDark,
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(
        elevation: elevation1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
    );
  }
}
