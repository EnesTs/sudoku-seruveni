import 'package:flutter/material.dart';
import '../logic/classic_board_generator.dart';
import '../logic/star_manager.dart';
import '../logic/theme_manager.dart';
import '../models/theme_model.dart';
import '../widgets/themed_background.dart';
import 'classic_sudoku_screen.dart';
import 'classic_time_attack_screen.dart';
import 'game_setup_dialog.dart';
import 'shop_screen.dart';
import 'visual_sudoku_screen.dart';
import 'element_game_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  void _showClassicDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Klasik Sudoku Modları',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogButton(
              context,
              text: '⏱️ Zamana Karşı (Hızlı)',
              color: Colors.purple.shade600,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassicTimeAttackScreen(),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(thickness: 1),
            ),
            _buildDialogButton(
              context, 
              text: '🟢 Kolay', 
              color: Colors.green.shade600,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassicSudokuScreen(
                      difficulty: ClassicDifficulty.easy,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildDialogButton(
              context, 
              text: '🟠 Orta', 
              color: Colors.orange.shade700,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassicSudokuScreen(
                      difficulty: ClassicDifficulty.medium,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildDialogButton(
              context, 
              text: '🔴 Zor', 
              color: Colors.red.shade600,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassicSudokuScreen(
                      difficulty: ClassicDifficulty.hard,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton(
    BuildContext context, {
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, currentTheme, child) {
        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
          body: ThemedBackground(
            theme: currentTheme,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Üst Bar / Sudoku Serüveni Banner Kartı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.95),
                            Colors.blue.shade50.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.blue.shade100, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Sudoku Serüveni',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text('🌟', style: TextStyle(fontSize: 18)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Zihnini tazeleyecek eğlenceli bulmacalar!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Yıldız Sayacı (Puan Kutusu)
                          ValueListenableBuilder<int>(
                            valueListenable: StarManager.starNotifier,
                            builder: (context, stars, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.amber.shade100, Colors.amber.shade200],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.amber.shade400, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$stars',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ana Menü Kartları Listesi
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildMenuCard(
                          context,
                          title: 'Klasik Sudoku',
                          subtitle: 'Zamana Karşı ve Standart bulmaca zorlukları',
                          badgeText: 'Zorluklar',
                          icon: Icons.grid_view_rounded,
                          gradientColors: [Colors.indigo.shade500, Colors.blue.shade600],
                          onTap: () => _showClassicDifficultyDialog(context),
                        ),

                        const SizedBox(height: 16),

                        _buildMenuCard(
                          context,
                          title: 'Sevimli Dostlar',
                          subtitle: 'Dostunu seç, eğlence dolu bulmacaya başla',
                          badgeText: 'Popüler',
                          icon: Icons.pets_rounded,
                          gradientColors: [Colors.teal.shade500, Colors.green.shade600],
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => const GameSetupDialog(modeName: 'Sevimli Dostlar'),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildMenuCard(
                          context,
                          title: 'Elementler Dengesi',
                          subtitle: 'Su, Ateş, Bitki ve Rüzgar ile doğayı canlandır',
                          badgeText: 'Yeni Mod 💧',
                          icon: Icons.bubble_chart_rounded,
                          gradientColors: [Colors.teal.shade700, Colors.cyan.shade600],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ElementGameScreen(
                                  gridSize: 4,
                                  levelTitle: 'Elementler Dengesi (4x4)',
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildMenuCard(
                          context,
                          title: 'Görsel Sudoku',
                          subtitle: 'Renkler, şekiller ve görsellerle zihnini çalıştır',
                          badgeText: 'Yaratıcı',
                          icon: Icons.palette_rounded,
                          gradientColors: [Colors.purple.shade500, Colors.pink.shade500],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VisualSudokuScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildMenuCard(
                          context,
                          title: 'Mağaza & Temalar',
                          subtitle: 'Yeni temalar, renkler ve karakterler keşfet',
                          badgeText: 'Market',
                          icon: Icons.storefront_rounded,
                          gradientColors: [Colors.orange.shade700, Colors.amber.shade600],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ShopScreen()),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}