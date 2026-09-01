import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final String description;
  final int price;
  final Color primaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color gridBorderColor;
  final Color selectedCellColor;
  final List<String> backgroundIcons;

  const AppTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.primaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.gridBorderColor,
    required this.selectedCellColor,
    required this.backgroundIcons,
  });

  static const List<AppTheme> themes = [
    // 1. Doğa & Orman (Ücretsiz / Varsayılan)
    AppTheme(
      id: 'default',
      name: 'Doğa & Orman 🌿',
      description: 'Huzur veren yeşil tonları ve yapraklar.',
      price: 0,
      primaryColor: Colors.teal,
      backgroundColor: Color(0xFFF4F9F5),
      cardColor: Colors.white,
      gridBorderColor: Color(0xFF004D40),
      selectedCellColor: Color(0xFFB2DFDB),
      backgroundIcons: ['🍃', '🌿', '🌱', '☘️', '🌸'],
    ),

    // 2. Derin Okyanus
    AppTheme(
      id: 'ocean',
      name: 'Derin Okyanus 🌊',
      description: 'Serinletici mavi tonları ve deniz simgeleri.',
      price: 75,
      primaryColor: Colors.indigo,
      backgroundColor: Color(0xFFF0F4F9),
      cardColor: Colors.white,
      gridBorderColor: Color(0xFF1A237E),
      selectedCellColor: Color(0xFFC5CAE9),
      backgroundIcons: ['🫧', '🌊', '🐚', '🪸', '💧'],
    ),

    // 3. Tatlı Gün Batımı
    AppTheme(
      id: 'sunset',
      name: 'Tatlı Gün Batımı 🌅',
      description: 'Sıcak turuncu ve pembe gökyüzü renkleri.',
      price: 100,
      primaryColor: Colors.deepOrange,
      backgroundColor: Color(0xFFFFF5F0),
      cardColor: Colors.white,
      gridBorderColor: Color(0xFFBF360C),
      selectedCellColor: Color(0xFFFFCCBC),
      backgroundIcons: ['✨', '⭐', '☁️', '☀️', '🌾'],
    ),

    // 4. Şeker Diyarı
    AppTheme(
      id: 'candy',
      name: 'Şeker Diyarı 🍬',
      description: 'Rengarenk şekerlemeler ve tatlı pembe tonlar.',
      price: 125,
      primaryColor: Colors.pink,
      backgroundColor: Color(0xFFFFF0F5),
      cardColor: Colors.white,
      gridBorderColor: Color(0xFF880E4F),
      selectedCellColor: Color(0xFFF8BBD0),
      backgroundIcons: ['🍭', '🍬', '✨', '🎈', '💖'],
    ),

    // 5. Gece & Uzay
    AppTheme(
      id: 'space',
      name: 'Derin Uzay 🌌',
      description: 'Karanlık mor ve parlak yıldızlar.',
      price: 150,
      primaryColor: Colors.purple,
      backgroundColor: Color(0xFFF3E5F5),
      cardColor: Colors.white,
      gridBorderColor: Color(0xFF4A148C),
      selectedCellColor: Color(0xFFE1BEE7),
      backgroundIcons: ['🚀', '🪐', '⭐', '☄️', '🌙'],
    ),

    // 6. Sihirli Krallık
    AppTheme(
      id: 'magic',
      name: 'Sihirli Krallık 👑',
      description: 'Altın sarısı şato ve büyü simgeleri.',
      price: 200,
      primaryColor: Colors.amber,
      backgroundColor: Color(0xFFFFFDE7),
      cardColor: Colors.white,
      gridBorderColor: Color(0xFFFF6F00),
      selectedCellColor: Color(0xFFFFECB3),
      backgroundIcons: ['👑', '🪄', '⭐', '💎', '🏰'],
    ),

    // 7. Buz Ülkesi
    AppTheme(
      id: 'ice',
      name: 'Buz Diyarı ❄️',
      description: 'Buz mavisi ferahlatıcı kar kristalleri.',
      price: 250,
      primaryColor: Colors.cyan,
      backgroundColor: Color(0xFFE0F7FA),
      cardColor: Colors.white,
      gridBorderColor: Color(0xFF006064),
      selectedCellColor: Color(0xFFB2EBF2),
      backgroundIcons: ['❄️', '☃️', '🧊', '✨', '🏔️'],
    ),

    // 8. Volkan & Ateş
    AppTheme(
      id: 'volcano',
      name: 'Volkan Enerjisi 🌋',
      description: 'Ateşli kırmızı tonlar ve enerjik semboller.',
      price: 300,
      primaryColor: Colors.redAccent,
      backgroundColor: Color(0xFFFFEBEE),
      cardColor: Colors.white,
      gridBorderColor: Color(0xFFB71C1C),
      selectedCellColor: Color(0xFFFFCDD2),
      backgroundIcons: ['🔥', '🌋', '⚡', '💥', '☀️'],
    ),
  ];
}