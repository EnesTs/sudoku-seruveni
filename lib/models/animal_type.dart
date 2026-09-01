import 'package:flutter/material.dart';

enum AnimalType {
  cat('Kedi', '🐱', Colors.orangeAccent),
  dog('Köpek', '🐶', Colors.amber),
  fox('Tilki', '🦊', Colors.deepOrange),
  panda('Panda', '🐼', Colors.blueGrey),
  rabbit('Tavşan', '🐰', Colors.pinkAccent);

  final String name;
  final String icon;
  final Color themeColor;

  const AnimalType(this.name, this.icon, this.themeColor);
}