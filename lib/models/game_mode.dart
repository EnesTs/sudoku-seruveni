import 'package:flutter/material.dart';

enum GameModeType {
  classic,
  dailyChallenge,
  timeAttack,
  campaign,
}

class GameMode {
  final GameModeType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isAvailable;

  const GameMode({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isAvailable = true,
  });
}