import 'package:flutter/material.dart';

enum AppThemeMode {
  dark,
  light,
  custom,
}

class AppThemeData {
  final AppThemeMode mode;
  final Color background;
  final Color surface;
  final Color accent;
  final Color text;
  final Color subtext;
  final Color border;
  final String fontFamily;
  final double fontSizeScale;

  const AppThemeData({
    required this.mode,
    required this.background,
    required this.surface,
    required this.accent,
    required this.text,
    required this.subtext,
    required this.border,
    this.fontFamily = 'System',
    this.fontSizeScale = 1.0,
  });

  static const AppThemeData dark = AppThemeData(
    mode: AppThemeMode.dark,
    background: Color(0xFF1E1E1E),
    surface: Color(0xFF2C2C2C),
    accent: Color(0xFFFA5252),
    text: Color(0xFFFFFFFF),
    subtext: Color(0xFFA0A0A0),
    border: Color(0xFF3D3D3D),
    fontFamily: 'System',
    fontSizeScale: 1.0,
  );

  static const AppThemeData light = AppThemeData(
    mode: AppThemeMode.light,
    background: Color(0xFFF4F5F8),
    surface: Color(0xFFFFFFFF),
    accent: Color(0xFFFA5252),
    text: Color(0xFF1F2937),
    subtext: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    fontFamily: 'System',
    fontSizeScale: 1.0,
  );

  AppThemeData copyWith({
    AppThemeMode? mode,
    Color? background,
    Color? surface,
    Color? accent,
    Color? text,
    Color? subtext,
    Color? border,
    String? fontFamily,
    double? fontSizeScale,
  }) {
    return AppThemeData(
      mode: mode ?? this.mode,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      accent: accent ?? this.accent,
      text: text ?? this.text,
      subtext: subtext ?? this.subtext,
      border: border ?? this.border,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
    );
  }
}

/// 16 Curated Presets for Quick Selection
const List<Color> presetThemeColors = [
  Color(0xFFFA5252), // Coral / Red (Default)
  Color(0xFFFF6B6B), // Soft Red
  Color(0xFFFF922B), // Orange
  Color(0xFFFCC419), // Amber / Gold
  Color(0xFF51CF66), // Emerald Green
  Color(0xFF20C997), // Teal
  Color(0xFF22B8CF), // Cyan
  Color(0xFF339AF0), // Sky Blue
  Color(0xFF4C6EF5), // Indigo
  Color(0xFF7950F2), // Deep Purple
  Color(0xFFBE4BD6), // Violet
  Color(0xFFF06595), // Hot Pink
  Color(0xFF12B886), // Mint
  Color(0xFFD9480F), // Rust
  Color(0xFF868E96), // Slate Grey
  Color(0xFF343A40), // Charcoal
];

/// List of font family choices
const List<String> availableFontFamilies = [
  'System',
  'Roboto',
  'Inter',
  'Outfit',
  'Monospace',
  'Serif',
];

class AppTheme {
  AppTheme._();

  static final ValueNotifier<AppThemeData> notifier =
      ValueNotifier<AppThemeData>(AppThemeData.dark);

  static AppThemeData get current => notifier.value;

  static void set(AppThemeData theme) {
    notifier.value = theme;
  }
}
