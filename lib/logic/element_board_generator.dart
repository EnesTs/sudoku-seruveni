import 'dart:math' as math;
import '../models/element_cell.dart';

class ElementBoardGenerator {
  static List<List<ElementCell>> generateBoard(int size, double fillRatio) {
    int boardSize = 5;
    
    List<List<ElementCell>> board = List.generate(
      boardSize,
      (row) => List.generate(
        boardSize,
        (col) => ElementCell(row: row, col: col),
      ),
    );

    List<ElementType> allElements = [
      ElementType.water,
      ElementType.fire,
      ElementType.plant,
      ElementType.wind,
      ElementType.electric,
    ];

    math.Random random = math.Random();
    int placedCount = 0;
    int targetInitialCount = 5; // 5 adet başlangıç ipucu
    int maxAttempts = 100;
    int attempts = 0;

    while (placedCount < targetInitialCount && attempts < maxAttempts) {
      attempts++;
      int r = random.nextInt(boardSize);
      int c = random.nextInt(boardSize);

      if (board[r][c].type == ElementType.none) {
        List<ElementType> shuffledElements = List.from(allElements)..shuffle(random);
        ElementType chosenType = ElementType.none;

        for (var el in shuffledElements) {
          if (!_checkRowColConflict(board, r, c, el, boardSize)) {
            chosenType = el;
            break;
          }
        }

        if (chosenType != ElementType.none) {
          board[r][c].type = chosenType;
          board[r][c].isInitial = true;
          placedCount++;
        }
      }
    }

    return board;
  }

  static bool _checkRowColConflict(List<List<ElementCell>> board, int row, int col, ElementType element, int size) {
    for (int i = 0; i < size; i++) {
      if (i != col && board[row][i].type == element) return true;
      if (i != row && board[i][col].type == element) return true;
    }
    return false;
  }
}