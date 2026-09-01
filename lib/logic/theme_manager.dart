import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_model.dart';

class ThemeManager {
  static final ValueNotifier<AppTheme> currentTheme =
      ValueNotifier<AppTheme>(AppTheme.themes[0]);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString('selected_theme') ?? 'default';
    currentTheme.value = AppTheme.themes.firstWhere(
      (t) => t.id == savedThemeId,
      orElse: () => AppTheme.themes[0],
    );
  }

  static Future<void> setTheme(AppTheme theme) async {
    currentTheme.value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme.id);
  }
}