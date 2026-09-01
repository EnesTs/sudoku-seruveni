enum Difficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Kolay';
      case Difficulty.medium:
        return 'Orta';
      case Difficulty.hard:
        return 'Zor';
    }
  }

  int get gridSize {
    switch (this) {
      case Difficulty.easy:
        return 4; // 4x4
      case Difficulty.medium:
        return 6; // 6x6
      case Difficulty.hard:
        return 8; // 8x8
    }
  }

  // İpucu dengesi: Kolay: 1, Orta: 1, Zor: 0 (Saf Mantık)
  int get hintCount {
    switch (this) {
      case Difficulty.easy:
        return 1;
      case Difficulty.medium:
        return 1;
      case Difficulty.hard:
        return 0;
    }
  }

  int get maxStars {
    switch (this) {
      case Difficulty.easy:
        return 3;
      case Difficulty.medium:
        return 5;
      case Difficulty.hard:
        return 8;
    }
  }
}