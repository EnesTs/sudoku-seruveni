import '../models/game_config.dart';

class StarCalculator {
  static int calculateEarnedStars({
    required Difficulty difficulty,
    required int remainingLives,
  }) {
    if (remainingLives <= 0) return 0;
    
    // gridSize yerine maxStars ve kalan can hesabı kullanılıyor
    int baseStars = (difficulty.maxStars / 2).ceil();
    return baseStars + (remainingLives - 1);
  }

  static int calculateStreakBonus({
    required Difficulty difficulty,
    required int remainingLives,
    required int currentPerfectStreak,
  }) {
    if (remainingLives < 3 || currentPerfectStreak == 0) return 0;
    return currentPerfectStreak * 2;
  }
}