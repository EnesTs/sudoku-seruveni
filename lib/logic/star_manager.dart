import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StarManager {
  static const String _starKey = 'user_stars';
  static final ValueNotifier<int> starNotifier = ValueNotifier<int>(0);

  static int get stars => starNotifier.value;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    starNotifier.value = prefs.getInt(_starKey) ?? 0;
  }

  static Future<int> getStars() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_starKey) ?? 0;
    starNotifier.value = current;
    return current;
  }

  static Future<void> addStars(int count) async {
    final prefs = await SharedPreferences.getInstance();
    int current = starNotifier.value;
    int updated = current + count;
    await prefs.setInt(_starKey, updated);
    starNotifier.value = updated;
  }

  static Future<bool> spendStars(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = starNotifier.value;
    if (current >= amount) {
      int updated = current - amount;
      await prefs.setInt(_starKey, updated);
      starNotifier.value = updated;
      return true;
    }
    return false;
  }
}