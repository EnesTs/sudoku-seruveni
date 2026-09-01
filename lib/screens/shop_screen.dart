import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_type.dart';
import '../models/theme_model.dart';
import '../logic/star_manager.dart';
import '../logic/theme_manager.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _userStars = 0;
  Set<String> _unlockedAnimalNames = {'cat'};
  Set<String> _unlockedThemes = {'default'};

  final Map<AnimalType, int> _animalPrices = {
    AnimalType.cat: 0,
    AnimalType.dog: 15,
    AnimalType.rabbit: 25,
    AnimalType.fox: 40,
    AnimalType.panda: 100,
  };

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    int stars = await StarManager.getStars();
    final prefs = await SharedPreferences.getInstance();
    
    List<String> savedAnimals = prefs.getStringList('unlocked_animals') ?? ['cat'];
    List<String> savedThemes = prefs.getStringList('unlocked_themes') ?? ['default'];

    if (!mounted) return;
    setState(() {
      _userStars = stars;
      _unlockedAnimalNames = savedAnimals.toSet();
      _unlockedThemes = savedThemes.toSet();
    });
  }

  Future<void> _buyAnimal(AnimalType animal, int price) async {
    if (_userStars < price) {
      _showSnackBar('Yetersiz Yıldız! 🌟 Biraz daha bulmaca çözmelisin.', Colors.redAccent);
      return;
    }

    bool success = await StarManager.spendStars(price);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      _unlockedAnimalNames.add(animal.name);
      await prefs.setStringList('unlocked_animals', _unlockedAnimalNames.toList());

      await _loadShopData();
      _showSnackBar('${animal.icon} ${animal.name.toUpperCase()} kilidi açıldı! 🎉', Colors.green);
    }
  }

  Future<void> _buyOrSelectTheme(AppTheme theme) async {
    if (_unlockedThemes.contains(theme.id)) {
      await ThemeManager.setTheme(theme);
      setState(() {});
      _showSnackBar('${theme.name} teması uygulandı! 🎨', Colors.blue);
    } else {
      if (_userStars < theme.price) {
        _showSnackBar('Yetersiz Yıldız! 🌟', Colors.redAccent);
        return;
      }

      bool success = await StarManager.spendStars(theme.price);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        _unlockedThemes.add(theme.id);
        await prefs.setStringList('unlocked_themes', _unlockedThemes.toList());

        await ThemeManager.setTheme(theme);
        await _loadShopData();
        _showSnackBar('${theme.name} teması açıldı ve uygulandı! 🎉', Colors.green);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedAnimals = AnimalType.values.toList()
      ..sort((a, b) {
        int priceA = _animalPrices[a] ?? 50;
        int priceB = _animalPrices[b] ?? 50;
        return priceA.compareTo(priceB);
      });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mağaza & Koleksiyon', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade800),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    '$_userStars',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pets), text: "Karakterler"),
              Tab(icon: Icon(Icons.palette), text: "Temalar"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. SEKME: KARAKTERLER (HAYVANLAR)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: sortedAnimals.length,
                itemBuilder: (context, index) {
                  final animal = sortedAnimals[index];
                  final bool isUnlocked = _unlockedAnimalNames.contains(animal.name);
                  final int price = _animalPrices[animal] ?? 50;

                  return Container(
                    decoration: BoxDecoration(
                      color: isUnlocked ? Colors.amber.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked ? Colors.amber.shade400 : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          animal.icon,
                          style: TextStyle(
                            fontSize: 48,
                            color: isUnlocked ? null : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          animal.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Açık',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _buyAnimal(animal, price),
                            icon: const Icon(Icons.star, size: 16),
                            label: Text('$price ⭐'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 2. SEKME: TEMALAR
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: AppTheme.themes.length,
              itemBuilder: (context, index) {
                final theme = AppTheme.themes[index];
                final isUnlocked = _unlockedThemes.contains(theme.id);
                final isSelected = ThemeManager.currentTheme.value.id == theme.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? theme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.primaryColor,
                      child: Text(
                        theme.backgroundIcons.first,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    title: Text(theme.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(theme.description, style: const TextStyle(fontSize: 12)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.green
                            : (isUnlocked ? theme.primaryColor : Colors.amber.shade700),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _buyOrSelectTheme(theme),
                      child: isSelected
                          ? const Text('Seçili')
                          : (isUnlocked
                              ? const Text('Kullan')
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amberAccent),
                                    const SizedBox(width: 4),
                                    Text('${theme.price}'),
                                  ],
                                )),
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
}