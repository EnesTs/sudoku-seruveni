import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/board_cell.dart';
import '../models/cell_state.dart';
import '../models/game_config.dart';

class BoardGenerator {
  static final List<Color> _regionColors = [
    const Color(0xFFFFCDD2), // Soft Kırmızı
    const Color(0xFFBBDEFB), // Soft Mavi
    const Color(0xFFC8E6C9), // Soft Yeşil
    const Color(0xFFE1BEE7), // Soft Mor
    const Color(0xFFFFE0B2), // Soft Turuncu
    const Color(0xFFB2DFDB), // Soft Turkuaz
    const Color(0xFFF8BBD0), // Soft Pembe
    const Color(0xFFFFF9C4), // Soft Sarı
  ];

  static List<List<BoardCell>> generateBoard(Difficulty difficulty) {
    int size = difficulty.gridSize;
    Random rnd = Random();

    while (true) {
      List<int> animalCols = List.filled(size, -1);
      bool solved = _placeAnimals(0, size, animalCols, rnd);

      if (!solved) {
        animalCols = List.generate(size, (i) => i)..shuffle(rnd);
      }

      List<List<int>> regionMap = List.generate(size, (_) => List.filled(size, -1));
      Queue<Point<int>> queue = Queue();

      for (int r = 0; r < size; r++) {
        int c = animalCols[r];
        regionMap[r][c] = r;
        queue.add(Point(r, c));
      }

      int? singleCellRegionId;
      if (difficulty.hintCount == 0) {
        singleCellRegionId = rnd.nextInt(size);
      }

      final List<Point<int>> directions = [
        const Point(-1, 0),
        const Point(1, 0),
        const Point(0, -1),
        const Point(0, 1),
      ];

      while (queue.isNotEmpty) {
        int index = rnd.nextInt(queue.length);
        Point<int> current = queue.elementAt(index);
        queue.remove(current);

        int currentRegionId = regionMap[current.x][current.y];

        if (currentRegionId == singleCellRegionId) {
          continue;
        }

        List<Point<int>> emptyNeighbors = [];
        for (var dir in directions) {
          int nr = current.x + dir.x;
          int nc = current.y + dir.y;

          if (nr >= 0 && nr < size && nc >= 0 && nc < size && regionMap[nr][nc] == -1) {
            emptyNeighbors.add(Point(nr, nc));
          }
        }

        if (emptyNeighbors.isNotEmpty) {
          Point<int> nextCell = emptyNeighbors[rnd.nextInt(emptyNeighbors.length)];
          regionMap[nextCell.x][nextCell.y] = currentRegionId;
          queue.add(nextCell);
          queue.add(current);
        }
      }

      // TEK ÇÖZÜMLÜLÜK KONTROLÜ (Unique Solution Check)
      // Üretilen renk haritasının sadece 1 geçerli dizilimi olup olmadığını kontrol et
      int solutionCount = _countSolutions(0, size, List.filled(size, -1), regionMap);
      
      // Eğer tek bir çözüm varsa haritayı kabul et ve tahtayı döndür
      if (solutionCount == 1) {
        List<List<BoardCell>> board = [];
        for (int r = 0; r < size; r++) {
          List<BoardCell> row = [];
          for (int c = 0; c < size; c++) {
            bool isAnimalHere = (animalCols[r] == c);
            int regId = regionMap[r][c];

            row.add(
              BoardCell(
                row: r,
                col: c,
                regionId: regId,
                regionColor: _regionColors[regId % _regionColors.length],
                isSolution: isAnimalHere,
              ),
            );
          }
          board.add(row);
        }

        int targetHints = min(difficulty.hintCount, size);
        if (targetHints > 0) {
          List<int> hintRows = List.generate(size, (i) => i)..shuffle(rnd);

          for (int i = 0; i < targetHints; i++) {
            int hRow = hintRows[i];
            int hCol = animalCols[hRow];

            board[hRow][hCol].state = CellState.hasAnimal;
            board[hRow][hCol].isInitial = true;
          }
        }

        return board;
      }
      // Çözüm sayısı 1 değilse döngü yeniden çalışır ve yeni bir tahta üretilir.
    }
  }

  // Tahtadaki tüm geçerli çözümleri sayan Backtracking algoritması
  static int _countSolutions(int row, int size, List<int> animalCols, List<List<int>> regionMap) {
    if (row == size) return 1;

    int count = 0;
    for (int c = 0; c < size; c++) {
      if (_isValidPlacementWithRegions(row, c, animalCols, size, regionMap)) {
        animalCols[row] = c;
        count += _countSolutions(row + 1, size, animalCols, regionMap);
        animalCols[row] = -1;
        
        // 1'den fazla çözüm bulduğu an aramayı kes (performans optimizasyonu)
        if (count > 1) return count;
      }
    }
    return count;
  }

  static bool _isValidPlacementWithRegions(int row, int col, List<int> animalCols, int size, List<List<int>> regionMap) {
    int currentRegion = regionMap[row][col];
    
    for (int r = 0; r < row; r++) {
      int c = animalCols[r];
      // Sütun kontrolü
      if (c == col) return false;
      // Komşuluk (3x3 temas) kontrolü
      if ((r - row).abs() <= 1 && (c - col).abs() <= 1) return false;
      // Renk Bölgesi kontrolü (Aynı bölgede 2. kedi olamaz)
      if (regionMap[r][c] == currentRegion) return false;
    }
    return true;
  }

  static bool _placeAnimals(int row, int size, List<int> animalCols, Random rnd) {
    if (row == size) return true;

    List<int> cols = List.generate(size, (i) => i)..shuffle(rnd);
    for (int c in cols) {
      if (_isValidPlacement(row, c, animalCols, size)) {
        animalCols[row] = c;
        if (_placeAnimals(row + 1, size, animalCols, rnd)) return true;
        animalCols[row] = -1;
      }
    }
    return false;
  }

  static bool _isValidPlacement(int row, int col, List<int> animalCols, int size) {
    for (int r = 0; r < row; r++) {
      int c = animalCols[r];
      if (c == col) return false;
      if ((r - row).abs() <= 1 && (c - col).abs() <= 1) return false;
    }
    return true;
  }
}