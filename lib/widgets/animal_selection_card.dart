import 'package:flutter/material.dart';
import '../models/animal_type.dart';

class AnimalSelectionCard extends StatelessWidget {
  final AnimalType animal;
  final bool isSelected;
  final bool isUnlocked; // Kilit durum kontrolü
  final VoidCallback onTap;

  const AnimalSelectionCard({
    Key? key,
    required this.animal,
    required this.isSelected,
    this.isUnlocked = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isUnlocked
              ? (isSelected ? Colors.amber.shade100 : Colors.white)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: isUnlocked ? 1.0 : 0.3,
                    child: Text(animal.icon, style: const TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      animal.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isUnlocked ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isUnlocked)
                const Icon(
                  Icons.lock,
                  color: Colors.black54,
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}