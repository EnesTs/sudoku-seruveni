import 'dart:math';

enum ClassicDifficulty { easy, medium, hard }

class ClassicBoardGenerator {
  static List<List<int>> generateSolvedBoard() {
    List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(board);
    return board;
  }

  static bool _fillBoard(List<List<int>> board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle();
          for (int num in numbers) {
            if (_isValid(board, r, c, num)) {
              board[r][c] = num;
              if (_fillBoard(board)) return true;
              board[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _isValid(List<List<int>> board, int r, int c, int num) {
    for (int i = 0; i < 9; i++) {
      if (board[r][i] == num || board[i][c] == num) return false;
    }
    int startRow = (r ~/ 3) * 3;
    int startCol = (c ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[startRow + i][startCol + j] == num) return false;
      }
    }
    return true;
  }

  static List<List<int>> createPuzzle(List<List<int>> solved, ClassicDifficulty difficulty) {
    List<List<int>> puzzle = List.generate(9, (r) => List.from(solved[r]));
    int removeCount = 30; 
    if (difficulty == ClassicDifficulty.medium) removeCount = 40;
    if (difficulty == ClassicDifficulty.hard) removeCount = 50;

    Random rand = Random();
    while (removeCount > 0) {
      int r = rand.nextInt(9);
      int c = rand.nextInt(9);
      if (puzzle[r][c] != 0) {
        puzzle[r][c] = 0;
        removeCount--;
      }
    }
    return puzzle;
  }
}