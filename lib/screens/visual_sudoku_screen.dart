import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/classic_board_generator.dart';
import '../logic/star_manager.dart';
import '../logic/theme_manager.dart';
import '../models/classic_cell.dart';
import '../models/theme_model.dart';
import '../widgets/themed_background.dart';

enum VisualThemeType { colors, animals, fruits, plants, vehicles, junkFood }

class VisualThemeData {
  final String title;
  final String icon;
  final Map<int, String> mapping;

  VisualThemeData({required this.title, required this.icon, required this.mapping});

  static final Map<int, Color> colorPalette = {
    1: const Color(0xFFE53935),
    2: const Color(0xFF0D47A1),
    3: const Color(0xFF00E676),
    4: const Color(0xFFFFEA00),
    5: const Color(0xFFFF6D00),
    6: const Color(0xFFAA00FF),
    7: const Color(0xFF00E5FF),
    8: const Color(0xFFFF4081),
    9: const Color(0xFF3E2723),
  };

  static Map<VisualThemeType, VisualThemeData> themes = {
    VisualThemeType.colors: VisualThemeData(
      title: 'Renk Paleti',
      icon: '🎨',
      mapping: {1: '🔴', 2: '🔵', 3: '🟢', 4: '🟡', 5: '🟠', 6: '🟣', 7: '🩵', 8: '🩷', 9: '🟤'},
    ),
    VisualThemeType.animals: VisualThemeData(
      title: 'Sevimli Dostlar',
      icon: '🐶',
      mapping: {
        1: '🐶', 2: '🦄', 3: '🐥', 4: '🐳', 5: '🦊', 6: '🐞', 7: '🐼', 8: '🐉', 9: '🦑',
      },
    ),
    VisualThemeType.fruits: VisualThemeData(
      title: 'Meyve Bahçesi',
      icon: '🍎',
      mapping: {1: '🍎', 2: '🍌', 3: '🍇', 4: '🍊', 5: '🍓', 6: '🍉', 7: '🍍', 8: '🥝', 9: '🍒'},
    ),
    VisualThemeType.plants: VisualThemeData(
      title: 'Çiçek Dünyası',
      icon: '🌿',
      mapping: {
        1: '🌹', 2: '🌻', 3: '🌸', 4: '🌵', 5: '🌼', 6: '🌷', 7: '☘️', 8: '🍄', 9: '🍁',
      },
    ),
    VisualThemeType.vehicles: VisualThemeData(
      title: 'Çılgın Taşıtlar',
      icon: '🚗',
      mapping: {
        1: '🚗', 2: '🚀', 3: '✈️', 4: '🚂', 5: '🚢', 6: '🚁', 7: '🚜', 8: '🚲', 9: '🛵',
      },
    ),
    VisualThemeType.junkFood: VisualThemeData(
      title: 'Lezzet Şöleni',
      icon: '🍕',
      mapping: {
        1: '🍕', 2: '🍔', 3: '🍟', 4: '🍦', 5: '🍩', 6: '🍿', 7: '🍰', 8: '🌭', 9: '🌮',
      },
    ),
  };
}

class VisualSudokuScreen extends StatefulWidget {
  const VisualSudokuScreen({Key? key}) : super(key: key);

  @override
  State<VisualSudokuScreen> createState() => _VisualSudokuScreenState();
}

enum GameStep { themeSelect, resumeOrNew, difficultySelect, playing }

class _VisualSudokuScreenState extends State<VisualSudokuScreen> {
  GameStep _currentStep = GameStep.themeSelect;

  late List<List<ClassicCell>> _board;
  ClassicDifficulty _currentDifficulty = ClassicDifficulty.easy;
  VisualThemeType _currentVisualTheme = VisualThemeType.colors;

  int? _selectedRow;
  int? _selectedCol;
  bool _isNoteMode = false;
  int _mistakes = 0;
  bool _isGameOver = false;

  bool _showErrorFlash = false;

  Set<int> _completedNumbers = {};
  Set<String> _highlightedConflictCells = {};
  Set<String> _recentlyCompletedGroupCells = {};

  int _correctCellCount = 0;

  final List<String> _progressIcons = ['🚀', '🦊', '🐱', '🦄', '🏎️', '🐝', '🎈', '🛸', '🐢', '🐬'];
  String _currentProgressIcon = '🚀';

  // --- KOMBO VE MOTİVASYON SİSTEMİ ---
  int _comboCount = 0;
  String _motivationalText = '';
  Timer? _toastTimer;

  final List<String> _singleMoveMessages = [
    'Mükemmel Hamle! ✨',
    'Harika İlerliyorsun! 🌟',
    'Nokta Atışı! 🎯',
    'Süper Devam! 👍',
    'Zihin Açıcı! 💫',
    'Şahane Gidiyor! 🔮',
  ];

  final List<String> _rowCompleteMessages = [
    'Yatay Çizgi Tertemiz! 📏',
    'Satırı Fethettin! ⚡',
    'Mükemmel Bir Satır Tamamlama! 🎯',
    'Yolun Yarısı Temizlendi! 🔥',
  ];

  final List<String> _colCompleteMessages = [
    'Dikey Sütun Akıp Gidiyor! 🏛️',
    'Sütunu Dominere Ettin! 💎',
    'Harika Bir Sütun Temizliği! 🚀',
    'Dikey Hat Kusursuz! ✨',
  ];

  final List<String> _boxCompleteMessages = [
    'Kutu Tamamen Senin! 📦👑',
    'Bölge Kontrol Altında! 🌟',
    'Muhteşem Alan Temizliği! 💥',
    'Harika Bir 3x3 Alan Zaferi! 🏆',
  ];

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSavedGame = prefs.getBool('visual_sudoku_has_save') ?? false;
    if (hasSavedGame && mounted) {}
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> boardData = [];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        var cell = _board[r][c];
        boardData.add({
          'r': r,
          'c': c,
          'val': cell.value,
          'userVal': cell.userValue,
          'isInitial': cell.isInitial,
          'notes': cell.notes.toList(),
        });
      }
    }

    await prefs.setString('visual_sudoku_board', jsonEncode(boardData));
    await prefs.setInt('visual_sudoku_mistakes', _mistakes);
    await prefs.setInt('visual_sudoku_diff', _currentDifficulty.index);
    await prefs.setInt('visual_sudoku_theme', _currentVisualTheme.index);
    await prefs.setString('visual_sudoku_icon', _currentProgressIcon);
    await prefs.setBool('visual_sudoku_has_save', true);
  }

  Future<bool> _loadSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    String? boardJson = prefs.getString('visual_sudoku_board');
    if (boardJson == null) return false;

    List<dynamic> list = jsonDecode(boardJson);
    List<List<ClassicCell>> loadedBoard = List.generate(9, (_) => List.generate(9, (_) => ClassicCell(row: 0, col: 0, value: 0)));

    for (var item in list) {
      int r = item['r'];
      int c = item['c'];
      loadedBoard[r][c] = ClassicCell(
        row: r,
        col: c,
        value: item['val'],
        userValue: item['userVal'],
        isInitial: item['isInitial'],
        notes: Set<int>.from(item['notes'] ?? []),
      );
    }

    setState(() {
      _board = loadedBoard;
      _mistakes = prefs.getInt('visual_sudoku_mistakes') ?? 0;
      _currentDifficulty = ClassicDifficulty.values[prefs.getInt('visual_sudoku_diff') ?? 0];
      _currentVisualTheme = VisualThemeType.values[prefs.getInt('visual_sudoku_theme') ?? 0];
      _currentProgressIcon = prefs.getString('visual_sudoku_icon') ?? '🚀';
      _currentStep = GameStep.playing;
    });

    _updateProgressMetrics();
    return true;
  }

  Future<void> _clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('visual_sudoku_has_save');
    await prefs.remove('visual_sudoku_board');
  }

  void _generateNewGame() {
    _clearSavedGame();
    List<List<int>> solved = ClassicBoardGenerator.generateSolvedBoard();
    List<List<int>> puzzle = ClassicBoardGenerator.createPuzzle(solved, _currentDifficulty);

    setState(() {
      _mistakes = 0;
      _isGameOver = false;
      _showErrorFlash = false;
      _selectedRow = null;
      _selectedCol = null;
      _completedNumbers.clear();
      _highlightedConflictCells.clear();
      _recentlyCompletedGroupCells.clear();
      _comboCount = 0;
      _motivationalText = '';

      _currentProgressIcon = _progressIcons[Random().nextInt(_progressIcons.length)];

      _board = List.generate(9, (r) {
        return List.generate(9, (c) {
          int val = solved[r][c];
          int? initialVal = puzzle[r][c] != 0 ? puzzle[r][c] : null;
          return ClassicCell(
            row: r,
            col: c,
            value: val,
            userValue: initialVal,
            isInitial: initialVal != null,
          );
        });
      });
      _currentStep = GameStep.playing;
    });
    _updateProgressMetrics();
    _saveGameState();
  }

  void _updateProgressMetrics() {
    Map<int, int> counts = {};
    int correctCount = 0;

    for (var row in _board) {
      for (var cell in row) {
        if (cell.userValue != null && cell.userValue == cell.value) {
          correctCount++;
          counts[cell.userValue!] = (counts[cell.userValue!] ?? 0) + 1;
        }
      }
    }

    Set<int> completed = {};
    counts.forEach((num, count) {
      if (count == 9) completed.add(num);
    });

    setState(() {
      _correctCellCount = correctCount;
      _completedNumbers = completed;
    });
  }

  void _showMotivationalToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _motivationalText = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _motivationalText = '';
        });
      }
    });
  }

  void _handleMoveFeedback({bool isRowDone = false, bool isColDone = false, bool isBoxDone = false}) {
    _comboCount++;

    if (isRowDone) {
      String msg = _rowCompleteMessages[Random().nextInt(_rowCompleteMessages.length)];
      _showMotivationalToast(msg);
    } else if (isColDone) {
      String msg = _colCompleteMessages[Random().nextInt(_colCompleteMessages.length)];
      _showMotivationalToast(msg);
    } else if (isBoxDone) {
      String msg = _boxCompleteMessages[Random().nextInt(_boxCompleteMessages.length)];
      _showMotivationalToast(msg);
    } else if (_comboCount >= 2) {
      String msg = '';
      if (_comboCount == 2) msg = 'Harika Seri! ⚡';
      else if (_comboCount == 3) msg = 'Üçte Üç, Ateş Ediyorsun! 🔥';
      else if (_comboCount == 4) msg = 'Durdurulamıyorsun! 🚀';
      else msg = 'Efsane Seride! 💥 (x$_comboCount)';
      _showMotivationalToast(msg);
    } else {
      String msg = _singleMoveMessages[Random().nextInt(_singleMoveMessages.length)];
      _showMotivationalToast(msg);
    }
  }

  void _resetCombo() {
    _comboCount = 0;
    _showMotivationalToast('Dikkat, Hata! Seri Bozuldu 💔');
  }

  void _triggerConflictHighlight(int r, int c, int wrongNum) {
    Set<String> conflicts = {};

    for (int i = 0; i < 9; i++) {
      if (i != c && _board[r][i].userValue == wrongNum) conflicts.add('$r-$i');
      if (i != r && _board[i][c].userValue == wrongNum) conflicts.add('$i-$c');
    }

    int boxStartRow = (r ~/ 3) * 3;
    int boxStartCol = (c ~/ 3) * 3;
    for (int br = boxStartRow; br < boxStartRow + 3; br++) {
      for (int bc = boxStartCol; bc < boxStartCol + 3; bc++) {
        if ((br != r || bc != c) && _board[br][bc].userValue == wrongNum) {
          conflicts.add('$br-$bc');
        }
      }
    }

    setState(() {
      _highlightedConflictCells = conflicts;
      _showErrorFlash = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showErrorFlash = false);
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _highlightedConflictCells.clear();
        });
      }
    });
  }

  bool _checkAndFlashCompletedGroups(int r, int c) {
    Set<String> newGroupCells = {};
    bool rowComplete = true;
    bool colComplete = true;
    bool boxComplete = true;

    for (int col = 0; col < 9; col++) {
      if (_board[r][col].userValue != _board[r][col].value) rowComplete = false;
    }
    if (rowComplete) {
      for (int col = 0; col < 9; col++) newGroupCells.add('$r-$col');
    }

    for (int row = 0; row < 9; row++) {
      if (_board[row][c].userValue != _board[row][c].value) colComplete = false;
    }
    if (colComplete) {
      for (int row = 0; row < 9; row++) newGroupCells.add('$row-$c');
    }

    int boxStartRow = (r ~/ 3) * 3;
    int boxStartCol = (c ~/ 3) * 3;
    for (int br = boxStartRow; br < boxStartRow + 3; br++) {
      for (int bc = boxStartCol; bc < boxStartCol + 3; bc++) {
        if (_board[br][bc].userValue != _board[br][bc].value) boxComplete = false;
      }
    }
    if (boxComplete) {
      for (int br = boxStartRow; br < boxStartRow + 3; br++) {
        for (int bc = boxStartCol; bc < boxStartCol + 3; bc++) {
          newGroupCells.add('$br-$bc');
        }
      }
    }

    if (newGroupCells.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() {
        _recentlyCompletedGroupCells = newGroupCells;
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _recentlyCompletedGroupCells.clear();
          });
        }
      });

      _handleMoveFeedback(isRowDone: rowComplete, isColDone: colComplete && !rowComplete, isBoxDone: boxComplete && !rowComplete && !colComplete);
      return true;
    }

    _handleMoveFeedback();
    return false;
  }

  void _showHintDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _useHint() async {
    if (_isGameOver) return;

    if (_selectedRow == null || _selectedCol == null) {
      _showHintDialog(
        title: '💡 İpucu Kullanımı',
        message: 'İpucu almak için önce panodan boş bir hücre seçmelisin.',
      );
      return;
    }

    ClassicCell cell = _board[_selectedRow!][_selectedCol!];

    if (cell.isInitial || cell.userValue == cell.value) {
      _showHintDialog(
        title: '💡 İpucu Gereksiz',
        message: 'Bu hücre zaten doğru doldurulmuş. Başka bir boş hücre seçebilirsin.',
      );
      return;
    }

    const int hintCost = 10;
    bool success = await StarManager.spendStars(hintCost);

    if (!success) {
      if (!mounted) return;
      _showHintDialog(
        title: '⭐ Yetersiz Yıldız',
        message: 'İpucu kullanabilmek için 10 Yıldız gereklidir. Bulmaca çözerek yıldız kazanabilirsin!',
      );
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      cell.userValue = cell.value;
      cell.notes.clear();
    });

    _checkAndFlashCompletedGroups(_selectedRow!, _selectedCol!);
    _updateProgressMetrics();
    _checkWinCondition();
    _saveGameState();
  }

  void _onNumberInput(int number) {
    if (_isGameOver || _selectedRow == null || _selectedCol == null) return;
    if (_completedNumbers.contains(number)) return;

    ClassicCell cell = _board[_selectedRow!][_selectedCol!];
    if (cell.isInitial) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (_isNoteMode) {
        if (cell.notes.contains(number)) {
          cell.notes.remove(number);
        } else {
          cell.notes.add(number);
        }
        cell.userValue = null;
      } else {
        cell.notes.clear();
        if (cell.userValue == number) {
          cell.userValue = null;
        } else {
          cell.userValue = number;
          if (cell.userValue != cell.value) {
            _mistakes++;
            _resetCombo();
            HapticFeedback.heavyImpact();
            _triggerConflictHighlight(_selectedRow!, _selectedCol!, number);

            if (_mistakes >= 3) {
              _isGameOver = true;
              _clearSavedGame();
              _showGameOverDialog();
            }
          } else {
            _checkAndFlashCompletedGroups(_selectedRow!, _selectedCol!);
            _updateProgressMetrics();
            _checkWinCondition();
          }
        }
      }
    });
    _saveGameState();
  }

  void _onErase() {
    if (_isGameOver || _selectedRow == null || _selectedCol == null) return;
    ClassicCell cell = _board[_selectedRow!][_selectedCol!];
    if (cell.isInitial) return;

    HapticFeedback.selectionClick();
    setState(() {
      cell.userValue = null;
      cell.notes.clear();
    });
    _updateProgressMetrics();
    _saveGameState();
  }

  void _checkWinCondition() {
    bool isCompleted = true;
    for (var row in _board) {
      for (var cell in row) {
        if (cell.userValue != cell.value) {
          isCompleted = false;
          break;
        }
      }
    }

    if (isCompleted) {
      _isGameOver = true;
      _clearSavedGame();
      HapticFeedback.mediumImpact();

      int rewardStars = 5;
      if (_currentDifficulty == ClassicDifficulty.medium) rewardStars = 10;
      if (_currentDifficulty == ClassicDifficulty.hard) rewardStars = 15;

      StarManager.addStars(rewardStars);
      _showWinDialog(rewardStars);
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text('💔 Oyun Bitti', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ),
        content: const Text('Tüm canlarını kaybettin! Tekrar denemek ister misin?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentStep = GameStep.themeSelect);
            },
            child: const Text('Ana Menü'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _generateNewGame();
            },
            child: const Text('Yeniden Dene'),
          ),
        ],
      ),
    );
  }

  void _showWinDialog(int earnedStars) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('🎉 Tebrikler!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Görsel bulmacayı başarıyla tamamladın!', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text('Ödül: +$earnedStars ⭐', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentStep = GameStep.themeSelect);
            },
            child: const Text('Ana Menü'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _generateNewGame();
            },
            child: const Text('Sonraki Bulmaca'),
          ),
        ],
      ),
    );
  }

  Widget _buildHearts() {
    int maxLives = 3;
    int currentLives = maxLives - _mistakes;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0),
          child: Icon(
            index < currentLives ? Icons.favorite : Icons.heart_broken,
            color: index < currentLives ? Colors.redAccent : Colors.grey.shade400,
            size: 18,
          ),
        );
      }),
    );
  }

  String _getDifficultyBadge(ClassicDifficulty diff) {
    switch (diff) {
      case ClassicDifficulty.easy: return '🟢 Kolay';
      case ClassicDifficulty.medium: return '🟠 Orta';
      case ClassicDifficulty.hard: return '🔴 Zor';
    }
  }

  Widget _buildProgressBar(AppTheme currentTheme) {
    double progress = (_correctCellCount / 81).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double barWidth = constraints.maxWidth;
          double iconPosition = (barWidth - 22) * progress;

          return SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 10,
                  width: barWidth * progress,
                  decoration: BoxDecoration(
                    color: _comboCount >= 2 ? Colors.orangeAccent : Colors.amberAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (_comboCount >= 2 ? Colors.orangeAccent : Colors.amberAccent).withOpacity(0.6),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: iconPosition,
                  child: Text(
                    _currentProgressIcon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
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
              child: _buildCurrentStepView(currentTheme),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStepView(AppTheme currentTheme) {
    switch (_currentStep) {
      case GameStep.themeSelect:
        return _buildThemeSelectionView(currentTheme);
      case GameStep.resumeOrNew:
        return _buildResumeOrNewView(currentTheme);
      case GameStep.difficultySelect:
        return _buildDifficultySelectionView(currentTheme);
      case GameStep.playing:
        return _buildPlayingView(currentTheme);
    }
  }

  Widget _buildThemeSelectionView(AppTheme currentTheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Görsel Sudoku',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Görsel Tema Seç 🎨', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 2),
                const Text('Oynamak istediğin sembol paketini belirle:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    children: VisualThemeType.values.map((type) {
                      final themeData = VisualThemeData.themes[type]!;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () async {
                              _currentVisualTheme = type;
                              final prefs = await SharedPreferences.getInstance();
                              bool hasSave = prefs.getBool('visual_sudoku_has_save') ?? false;

                              if (hasSave) {
                                setState(() => _currentStep = GameStep.resumeOrNew);
                              } else {
                                setState(() => _currentStep = GameStep.difficultySelect);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: currentTheme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: currentTheme.primaryColor.withOpacity(0.25), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${themeData.title} ${themeData.icon}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentTheme.primaryColor),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          themeData.mapping.values.take(5).join(' '),
                                          style: const TextStyle(fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, color: currentTheme.primaryColor, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeOrNewView(AppTheme currentTheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => setState(() => _currentStep = GameStep.themeSelect),
              ),
              const Expanded(
                child: Text('Oyun Modu', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.extension_rounded, size: 60, color: Colors.indigo),
                const SizedBox(height: 16),
                const Text('Kaydedilmiş Bir Oyun Var!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Kaldığın yerden devam edebilir veya yeni zorluk seçerek baştan başlayabilirsin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text('Kaldığın Yerden Devam Et ⏯️', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    bool loaded = await _loadSavedGame();
                    if (!loaded) _generateNewGame();
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: Colors.indigo, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  label: const Text('Yeni Oyuna Başla (Baştan) 🔄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() => _currentStep = GameStep.difficultySelect);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelectionView(AppTheme currentTheme) {
    final activeTheme = VisualThemeData.themes[_currentVisualTheme]!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => setState(() => _currentStep = GameStep.themeSelect),
              ),
              const Expanded(
                child: Text('Zorluk Derecesi', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${activeTheme.title} ${activeTheme.icon}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: currentTheme.primaryColor)),
                const SizedBox(height: 6),
                const Text('Zorluk seviyesini seçerek oyuna başla:', style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 30),
                _buildDifficultyCard('🟢 Kolay', ClassicDifficulty.easy, Colors.green.shade600, 'Başlangıç için harika seçim'),
                const SizedBox(height: 16),
                _buildDifficultyCard('🟠 Orta', ClassicDifficulty.medium, Colors.orange.shade700, 'Dengeli bulmaca deneyimi'),
                const SizedBox(height: 16),
                _buildDifficultyCard('🔴 Zor', ClassicDifficulty.hard, Colors.redAccent, 'Zihnini zorlayacak gerçek meydan okuma'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(String title, ClassicDifficulty diff, Color color, String subtitle) {
    return InkWell(
      onTap: () {
        _currentDifficulty = diff;
        _generateNewGame();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingView(AppTheme currentTheme) {
    final activeThemeData = VisualThemeData.themes[_currentVisualTheme]!;
    final mapping = activeThemeData.mapping;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => setState(() => _currentStep = GameStep.themeSelect),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeThemeData.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          activeThemeData.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text('•', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                      Text(
                        _getDifficultyBadge(_currentDifficulty),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<int>(
                valueListenable: StarManager.starNotifier,
                builder: (context, stars, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text('$stars', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _isGameOver ? null : _useHint,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Colors.amber.shade800, size: 16),
                      const SizedBox(width: 3),
                      Text('İpucu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _buildHearts(),
            ],
          ),
        ),

        _buildProgressBar(currentTheme),

        SizedBox(
          height: 32,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _motivationalText.isNotEmpty ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Text(
                  _motivationalText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _comboCount >= 2 ? Colors.amberAccent : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: _showErrorFlash ? Colors.red.withOpacity(0.25) : Colors.transparent,
            child: Column(
              children: [
                const Spacer(flex: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: currentTheme.gridBorderColor, width: 2.5),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 81,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
                        itemBuilder: (context, index) {
                          int r = index ~/ 9;
                          int c = index % 9;
                          ClassicCell cell = _board[r][c];
                          String cellKey = '$r-$c';

                          bool isSelected = _selectedRow == r && _selectedCol == c;
                          bool isSameRowOrCol = _selectedRow == r || _selectedCol == c;
                          bool isSameBox = (_selectedRow != null && _selectedCol != null) &&
                              (_selectedRow! ~/ 3 == r ~/ 3 && _selectedCol! ~/ 3 == c ~/ 3);

                          bool isConflict = _highlightedConflictCells.contains(cellKey);
                          bool isJustCompletedGroup = _recentlyCompletedGroupCells.contains(cellKey);

                          int? selectedNumber;
                          if (_selectedRow != null && _selectedCol != null) {
                            ClassicCell selectedCell = _board[_selectedRow!][_selectedCol!];
                            selectedNumber = selectedCell.userValue ?? (selectedCell.isInitial ? selectedCell.value : null);
                          }

                          int? currentCellNum = cell.userValue ?? (cell.isInitial ? cell.value : null);
                          bool isSameNumber = selectedNumber != null && currentCellNum != null && currentCellNum == selectedNumber;

                          Color bgColor = Colors.transparent;
                          Border? customBorder;

                          BorderSide thickBorder = BorderSide(color: currentTheme.gridBorderColor, width: 2.0);
                          BorderSide thinBorder = BorderSide(color: currentTheme.gridBorderColor.withOpacity(0.3), width: 1.0);

                          if (_currentVisualTheme == VisualThemeType.colors && cell.userValue != null) {
                            bgColor = VisualThemeData.colorPalette[cell.userValue!] ?? Colors.transparent;
                          } else if (isConflict) {
                            bgColor = Colors.red.shade300;
                          } else if (isJustCompletedGroup) {
                            bgColor = Colors.amber.shade300;
                          } else if (isSelected) {
                            bgColor = currentTheme.selectedCellColor;
                          } else if (isSameNumber) {
                            bgColor = currentTheme.selectedCellColor.withOpacity(0.9);
                          } else if (isSameRowOrCol || isSameBox) {
                            bgColor = currentTheme.selectedCellColor.withOpacity(0.35);
                          }

                          // Seçilen veya aynı numaraya sahip karelerin altın sarısı çerçeve ile parlaması
                          if (isSelected || isSameNumber) {
                            customBorder = Border.all(color: const Color(0xFFFFD700), width: 2.5);
                          }

                          Border finalBorder = customBorder ?? Border(
                            top: r % 3 == 0 ? thickBorder : thinBorder,
                            left: c % 3 == 0 ? thickBorder : thinBorder,
                            bottom: r == 8 ? thickBorder : BorderSide.none,
                            right: c == 8 ? thickBorder : BorderSide.none,
                          );

                          return GestureDetector(
                            onTap: () {
                              if (_isGameOver) return;
                              setState(() {
                                _selectedRow = r;
                                _selectedCol = c;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: finalBorder,
                              ),
                              child: Center(child: _buildVisualCellContent(cell, mapping)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),

                _build3x3Numpad(currentTheme, mapping),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _build3x3Numpad(AppTheme currentTheme, Map<int, String> mapping) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _isGameOver ? null : () => setState(() => _isNoteMode = !_isNoteMode),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    height: 190,
                    decoration: BoxDecoration(
                      color: _isNoteMode
                          ? currentTheme.primaryColor.withOpacity(0.85)
                          : Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isNoteMode
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isNoteMode ? Icons.edit : Icons.edit_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Not',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  width: 190,
                  height: 190,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 9,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      int num = index + 1;
                      String symbol = mapping[num] ?? '$num';
                      bool isCompleted = _completedNumbers.contains(num);

                      Widget buttonContent;
                      if (isCompleted) {
                        buttonContent = const Icon(Icons.check, color: Colors.greenAccent, size: 24);
                      } else if (_currentVisualTheme == VisualThemeType.colors) {
                        buttonContent = Container(
                          decoration: BoxDecoration(
                            color: VisualThemeData.colorPalette[num],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      } else {
                        buttonContent = Text(
                          symbol,
                          style: const TextStyle(fontSize: 22),
                        );
                      }

                      return InkWell(
                        onTap: (_isGameOver || isCompleted) ? null : () => _onNumberInput(num),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: _currentVisualTheme == VisualThemeType.colors && !isCompleted ? const EdgeInsets.all(6) : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.3)
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCompleted
                                  ? Colors.green.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Center(child: buttonContent),
                        ),
                      );
                    },
                  ),
                ),

                InkWell(
                  onTap: _isGameOver ? null : _onErase,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 54,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.backspace_outlined, color: Colors.redAccent, size: 26),
                        SizedBox(height: 6),
                        Text(
                          'Sil',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCellContent(ClassicCell cell, Map<int, String> mapping) {
    if (cell.userValue != null) {
      bool isWrong = !cell.isInitial && cell.userValue != cell.value;

      if (_currentVisualTheme == VisualThemeType.colors) {
        if (isWrong) return const Icon(Icons.close, color: Colors.white, size: 24);
        return const SizedBox();
      }

      String symbol = mapping[cell.userValue!] ?? '${cell.userValue}';

      return Container(
        decoration: BoxDecoration(
          border: isWrong ? Border.all(color: Colors.red, width: 2) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(symbol, style: const TextStyle(fontSize: 20)),
      );
    } else if (cell.notes.isNotEmpty) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(1),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1),
        itemBuilder: (context, i) {
          int n = i + 1;
          if (_currentVisualTheme == VisualThemeType.colors) {
            return cell.notes.contains(n)
                ? Container(margin: const EdgeInsets.all(1), decoration: BoxDecoration(color: VisualThemeData.colorPalette[n], shape: BoxShape.circle))
                : const SizedBox();
          }

          String noteSymbol = mapping[n] ?? '$n';
          return Center(child: Text(cell.notes.contains(n) ? noteSymbol : '', style: const TextStyle(fontSize: 8)));
        },
      );
    }
    return const SizedBox();
  }
}