import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'constants.dart';

class WillTheme {
  WillTheme._();

  static final ThemeData appTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: WillConstants.fontFamily,
    scaffoldBackgroundColor: WillColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: WillColors.primary,
      brightness: Brightness.light,
      surface: WillColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: WillColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 60,
        fontWeight: FontWeight.w700,
        height: 0.9,
      ),
      displayMedium: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
      headlineSmall: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
      bodyLarge: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamily: WillConstants.fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
