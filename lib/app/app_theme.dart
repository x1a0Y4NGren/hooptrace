import 'package:flutter/material.dart';

class HoopTraceColors {
  const HoopTraceColors._();

  static const offWhite = Color(0xFFFFF8E8);
  static const cream = Color(0xFFF4EADB);
  static const orange = Color(0xFFFF7A1A);
  static const red = Color(0xFFD94735);
  static const blue = Color(0xFF2F67D8);
  static const ink = Color(0xFF2B2520);
}

ThemeData buildHoopTraceTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: HoopTraceColors.orange,
    brightness: Brightness.light,
    primary: HoopTraceColors.orange,
    surface: HoopTraceColors.offWhite,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: HoopTraceColors.offWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: HoopTraceColors.offWhite,
      foregroundColor: HoopTraceColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
