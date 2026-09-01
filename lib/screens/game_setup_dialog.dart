import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_type.dart';
import '../models/game_config.dart';
import '../widgets/animal_selection_card.dart';
import 'game_screen.dart';

class GameSetupDialog extends StatefulWidget {
  final String modeName;

  const GameSetupDialog({Key? key, required this.modeName}) : super(key: key);

  @override
  State<GameSetupDialog> createState() => _GameSetupDialogState();
}

class _GameSetupDialogState extends State<GameSetupDialog> {
  AnimalType _selectedAnimal = AnimalType.cat;
  Difficulty _selectedDifficulty = Difficulty.easy;
  
  Set<AnimalType> _unlockedAnimals = {AnimalType.cat};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnlockedAnimals();
  }

  Future<void> _loadUnlockedAnimals() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedUnlocked = prefs.getStringList('unlocked_animals') ?? ['cat'];

    setState(() {
      _unlockedAnimals = savedUnlocked
          .map((name) => AnimalType.values.firstWhere(
              (a) => a.name == name,
              orElse: () => AnimalType.cat,
            ))
          .toSet();
      
      if (!_unlockedAnimals.contains(_selectedAnimal) && _unlockedAnimals.isNotEmpty) {
        _selectedAnimal = _unlockedAnimals.first;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.modeName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hangi dostunla yarışmak istersin?',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: AnimalType.values.length,
                      itemBuilder: (context, index) {
                        final animal = AnimalType.values[index];
                        final isUnlocked = _unlockedAnimals.contains(animal);

                        return AnimalSelectionCard(
                          animal: animal,
                          isSelected: _selectedAnimal == animal,
                          isUnlocked: isUnlocked,
                          onTap: () {
                            if (isUnlocked) {
                              setState(() {
                                _selectedAnimal = animal;
                              });
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Zorluk Seviyesi Seç',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: Difficulty.values.map((diff) {
                        bool isSelected = _selectedDifficulty == diff;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: ChoiceChip(
                            label: Text(
                              '${diff.label} (${diff.gridSize}x${diff.gridSize}) - ${diff.hintCount} İpucu',
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: isSelected,
                            selectedColor: primaryColor.withOpacity(0.3),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedDifficulty = diff);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Dialogu kapat
                        
                        // Oyun ekranına yönlendir
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              difficulty: _selectedDifficulty,
                              selectedAnimal: _selectedAnimal,
                            ),
                          ),
                        );
                      },
                      child: const Text('Başla 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}