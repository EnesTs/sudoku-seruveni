import 'package:flutter/material.dart';
import '../logic/classic_board_generator.dart';
import 'classic_sudoku_screen.dart';
import 'main_menu_screen.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({Key? key}) : super(key: key);

  void _showClassicDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Zorluk Seçin',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyButton(
              context,
              title: 'Kolay',
              color: Colors.green,
              difficulty: ClassicDifficulty.easy,
            ),
            const SizedBox(height: 8),
            _buildDifficultyButton(
              context,
              title: 'Orta',
              color: Colors.orange,
              difficulty: ClassicDifficulty.medium,
            ),
            const SizedBox(height: 8),
            _buildDifficultyButton(
              context,
              title: 'Zor',
              color: Colors.redAccent,
              difficulty: ClassicDifficulty.hard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context, {
    required String title,
    required Color color,
    required ClassicDifficulty difficulty,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassicSudokuScreen(difficulty: difficulty),
            ),
          );
        },
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Sudoku Hub 🧩',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Oynamak istediğin Sudoku tarzını seç!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: [
                    // 1. KART: CAT SUDOKU
                    _buildHubCard(
                      context,
                      title: 'Cat Sudoku',
                      subtitle: 'Renk ve Hayvan Mantığı • Kolay/Zor • Zamana Karşı',
                      icon: Icons.pets,
                      badgeText: 'POPÜLER',
                      color: Colors.amber.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. KART: KLASİK SUDOKU
                    _buildHubCard(
                      context,
                      title: 'Klasik Sudoku',
                      subtitle: 'Geleneksel 9x9 Rakamlar • Mantık Dizilimi',
                      icon: Icons.grid_on_rounded,
                      badgeText: 'YENİ',
                      color: Colors.indigoAccent,
                      onTap: () => _showClassicDifficultyDialog(context),
                    ),
                    const SizedBox(height: 16),

                    // 3. KART: YAKINDA GELECEK MODLAR
                    _buildHubCard(
                      context,
                      title: 'Katil (Killer) Sudoku',
                      subtitle: 'Bölge Toplamları ve Sayısal Hesaplama',
                      icon: Icons.calculate_outlined,
                      badgeText: 'YAKINDA',
                      color: Colors.grey,
                      isLocked: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.shade100 : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked ? Colors.grey.shade300 : color.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey : color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.grey : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey.shade300 : color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? Colors.grey.shade600 : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isLocked ? Colors.grey.shade500 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isLocked ? Colors.grey.shade400 : color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}