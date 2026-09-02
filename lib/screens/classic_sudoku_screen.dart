import 'dart:convert';
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

class ClassicSudokuScreen extends StatefulWidget {
  final ClassicDifficulty difficulty;

  const ClassicSudokuScreen({
    Key? key,
    this.difficulty = ClassicDifficulty.easy,
  }) : super(key: key);

  @override
  State<ClassicSudokuScreen> createState() => _ClassicSudokuScreenState();
}

class _ClassicSudokuScreenState extends State<ClassicSudokuScreen> with WidgetsBindingObserver {
  late List<List<ClassicCell>> _board;
  late ClassicDifficulty _currentDifficulty;

  bool _isLoading = true;
  int? _selectedRow;
  int? _selectedCol;
  bool _isNoteMode = false;
  int _mistakes = 0;
  bool _isGameOver = false;

  bool _showErrorFlash = false;
  String? _feedbackText;
  Color _feedbackColor = Colors.green;

  Set<int> _completedNumbers = {};
  Set<String> _highlightedConflictCells = {};
  Set<String> _recentlyCompletedGroupCells = {};
  Set<String> _completed3x3Boxes = {};

  final List<String> _progressIcons = [
    '🚀', '⚡', '🌟', '🎯', '💎', '🎨', '🧩', '🔮', '🦄', '🏆', '🦁', '👑', '🌈', '🐣'
  ];
  String _currentProgressIcon = '🚀';

  final List<String> _motivationalWords = [
    'Süper!', 'Harika!', 'Muazzam!', 'Böyle Devam!', 'Harika Görünüyor!', 'Çok İyi!',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentDifficulty = widget.difficulty;
    _checkSavedGameOrNew();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkSavedGameOrNew() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('saved_sudoku_game');

    if (savedData != null) {
      _loadGame(savedData);

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 16,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.indigo.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.history_edu_rounded,
                      size: 36,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Kaldığın Yerden Devam Et',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Yarım kalmış heyecan dolu bir bulmacan var. Nasıl devam etmek istersin?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _generateNewGame(difficulty: widget.difficulty);
                          },
                          child: const Text(
                            'Yeni Oyun',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          child: const Text(
                            'Devam Et',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      });
    } else {
      _generateNewGame(difficulty: widget.difficulty);
    }
  }

  void _loadGame(String jsonStr) {
    try {
      Map<String, dynamic> data = jsonDecode(jsonStr);
      setState(() {
        _currentDifficulty = ClassicDifficulty.values[data['difficulty']];
        _mistakes = data['mistakes'];
        _currentProgressIcon = data['progressIcon'] ?? '🚀';
        _completed3x3Boxes = Set<String>.from(data['completedBoxes'] ?? []);
        _isGameOver = false;

        var boardList = data['board'] as List;
        _board = boardList.map((row) {
          var rowList = row as List;
          return rowList.map((cellJson) => ClassicCell.fromJson(cellJson)).toList();
        }).toList();
      });
      _updateCompletedNumbers();
    } catch (e) {
      _generateNewGame(difficulty: widget.difficulty);
    }
  }

  void _generateNewGame({ClassicDifficulty? difficulty}) {
    if (difficulty != null) {
      _currentDifficulty = difficulty;
    }

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
      _completed3x3Boxes.clear();

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
      
      _isLoading = false;
    });
    
    _updateCompletedNumbers();
    _clearAndSaveNewGame();
  }

  Future<void> _clearAndSaveNewGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_sudoku_game');
    _saveGame();
  }

  Future<void> _saveGame() async {
    if (_isGameOver) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_sudoku_game');
      return;
    }

    Map<String, dynamic> gameData = {
      'difficulty': _currentDifficulty.index,
      'mistakes': _mistakes,
      'progressIcon': _currentProgressIcon,
      'completedBoxes': _completed3x3Boxes.toList(),
      'board': _board.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_sudoku_game', jsonEncode(gameData));
  }

  void _showFloatingFeedback(String text, Color color) {
    setState(() {
      _feedbackText = text;
      _feedbackColor = color;
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _feedbackText = null;
        });
      }
    });
  }

  double _calculateProgress() {
    int correctCount = 0;
    for (var row in _board) {
      for (var cell in row) {
        if (cell.userValue != null && cell.userValue == cell.value) {
          correctCount++;
        }
      }
    }
    return (correctCount / 81).clamp(0.0, 1.0);
  }

  void _updateCompletedNumbers() {
    Map<int, int> counts = {};
    for (var row in _board) {
      for (var cell in row) {
        if (cell.userValue != null && cell.userValue == cell.value) {
          counts[cell.userValue!] = (counts[cell.userValue!] ?? 0) + 1;
        }
      }
    }

    Set<int> completed = {};
    counts.forEach((num, count) {
      if (count == 9) completed.add(num);
    });

    setState(() {
      _completedNumbers = completed;
    });
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

    _showFloatingFeedback('Hatalı Hamle! ❌', Colors.redAccent);

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

  void _checkAndFlashCompletedGroups(int r, int c) {
    Set<String> newGroupCells = {};
    int completedGroupsCount = 0;
    String groupMsg = '';

    bool rowComplete = true;
    for (int col = 0; col < 9; col++) {
      if (_board[r][col].userValue != _board[r][col].value) rowComplete = false;
    }
    if (rowComplete) {
      completedGroupsCount++;
      groupMsg = 'Mükemmel Satır! ✨';
      for (int col = 0; col < 9; col++) newGroupCells.add('$r-$col');
    }

    bool colComplete = true;
    for (int row = 0; row < 9; row++) {
      if (_board[row][c].userValue != _board[row][c].value) colComplete = false;
    }
    if (colComplete) {
      completedGroupsCount++;
      groupMsg = 'Efsane Sütun! ✨';
      for (int row = 0; row < 9; row++) newGroupCells.add('$row-$c');
    }

    int boxRow = r ~/ 3;
    int boxCol = c ~/ 3;
    String boxKey = '$boxRow-$boxCol';

    bool boxComplete = true;
    int boxStartRow = boxRow * 3;
    int boxStartCol = boxCol * 3;
    for (int br = boxStartRow; br < boxStartRow + 3; br++) {
      for (int bc = boxStartCol; bc < boxStartCol + 3; bc++) {
        if (_board[br][bc].userValue != _board[br][bc].value) boxComplete = false;
      }
    }

    if (boxComplete && !_completed3x3Boxes.contains(boxKey)) {
      _completed3x3Boxes.add(boxKey);
      completedGroupsCount++;
      groupMsg = 'Harika 3x3 Blok! 💥';
      for (int br = boxStartRow; br < boxStartRow + 3; br++) {
        for (int bc = boxStartCol; bc < boxStartCol + 3; bc++) {
          newGroupCells.add('$br-$bc');
        }
      }
    }

    if (newGroupCells.isNotEmpty) {
      HapticFeedback.mediumImpact();
      if (completedGroupsCount > 1) {
        groupMsg = 'Çifte Tamamlama! 🔥';
      }
      _showFloatingFeedback(groupMsg, Colors.amber.shade900);

      setState(() {
        _recentlyCompletedGroupCells = newGroupCells;
      });

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _recentlyCompletedGroupCells.clear();
          });
        }
      });
    } else {
      String randomWord = (_motivationalWords..shuffle()).first;
      _showFloatingFeedback(randomWord, Colors.green.shade700);
    }
  }

  void _showHintDialog() {
    if (_isGameOver || _selectedRow == null || _selectedCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce boş bir kare seçin!')),
      );
      return;
    }

    ClassicCell cell = _board[_selectedRow!][_selectedCol!];
    if (cell.isInitial || cell.userValue == cell.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seçilen kare zaten doğru doldurulmuş!')),
      );
      return;
    }

    const int hintCost = 10;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('İpucu Kullan', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Seçili karenin doğru cevabını açmak istiyor musunuz?\n\nBu işlem 10 Yıldız ⭐ harcayacaktır.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _useHint(hintCost);
            },
            child: const Text('Kullan (-10 ⭐)'),
          ),
        ],
      ),
    );
  }

  Future<void> _useHint(int cost) async {
    bool success = await StarManager.spendStars(cost);

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yetersiz Yıldız! İpucu için $cost ⭐ gerekli.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      ClassicCell cell = _board[_selectedRow!][_selectedCol!];
      cell.userValue = cell.value;
      cell.notes.clear();
    });

    _updateCompletedNumbers();
    _checkAndFlashCompletedGroups(_selectedRow!, _selectedCol!);
    _checkWinCondition();
    _saveGame();
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
            HapticFeedback.heavyImpact();
            _triggerConflictHighlight(_selectedRow!, _selectedCol!, number);

            if (_mistakes >= 3) {
              _isGameOver = true;
              _showGameOverDialog();
            }
          } else {
            _updateCompletedNumbers();
            _checkAndFlashCompletedGroups(_selectedRow!, _selectedCol!);
            _checkWinCondition();
          }
        }
      }
    });
    _saveGame();
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
    _updateCompletedNumbers();
    _saveGame();
  }

  void _checkWinCondition() async {
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
      HapticFeedback.mediumImpact();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_sudoku_game');

      int rewardStars = 5;
      if (_currentDifficulty == ClassicDifficulty.medium) rewardStars = 10;
      if (_currentDifficulty == ClassicDifficulty.hard) rewardStars = 15;

      StarManager.addStars(rewardStars);
      _showWinDialog(rewardStars);
    }
  }

  void _showGameOverDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_sudoku_game');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            '💔 Oyun Bitti',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
        ),
        content: const Text(
          'Tüm canlarını kaybettin! Ne yapmak istersin?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Menü'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Zorluk Seçimi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _generateNewGame(difficulty: _currentDifficulty);
            },
            child: const Text('Yeniden Başlat'),
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
        title: const Center(
          child: Text(
            '🎉 Tebrikler!',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bulmacayı başarıyla tamamladın!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Kazanılan Ödül: +$earnedStars ⭐',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Menü'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _generateNewGame(difficulty: _currentDifficulty);
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
            color: index < currentLives ? Colors.red : Colors.grey.shade400,
            size: 20,
          ),
        );
      }),
    );
  }

  String _getDifficultyText(ClassicDifficulty diff) {
    switch (diff) {
      case ClassicDifficulty.easy: return 'Kolay';
      case ClassicDifficulty.medium: return 'Orta';
      case ClassicDifficulty.hard: return 'Zor';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double progress = _calculateProgress();
    int progressPercent = (progress * 100).toInt();

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, currentTheme, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: currentTheme.primaryColor,
            foregroundColor: Colors.white,
            title: Text('Klasik (${_getDifficultyText(_currentDifficulty)})'),
            actions: [
              IconButton(
                icon: const Icon(Icons.lightbulb, color: Colors.amber),
                tooltip: 'İpucu',
                onPressed: _showHintDialog,
              ),
              ValueListenableBuilder<int>(
                valueListenable: StarManager.starNotifier,
                builder: (context, stars, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$stars ⭐',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0, left: 4.0),
                child: Center(
                  child: _buildHearts(),
                ),
              )
            ],
          ),
          body: ThemedBackground(
            theme: currentTheme,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: _showErrorFlash ? Colors.red.withOpacity(0.25) : Colors.transparent,
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 32,
                    child: Center(
                      child: _feedbackText != null
                          ? AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _feedbackText != null ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _feedbackColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: Text(
                                  _feedbackText!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _feedbackColor,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double availableWidth = constraints.maxWidth;
                                double iconPosition = (availableWidth - 20) * progress;

                                return Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 10,
                                        backgroundColor: Colors.white.withOpacity(0.4),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          currentTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      left: iconPosition.clamp(0.0, availableWidth - 20),
                                      child: Text(
                                        _currentProgressIcon,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '%$progressPercent',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: currentTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

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
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 9,
                          ),
                          itemBuilder: (context, index) {
                            int r = index ~/ 9;
                            int c = index % 9;
                            ClassicCell cell = _board[r][c];

                            String cellKey = '$r-$c';
                            bool isSelected = _selectedRow == r && _selectedCol == c;
                            bool isSameRowOrCol = _selectedRow == r || _selectedCol == c;
                            bool isSameBox = (_selectedRow != null && _selectedCol != null) &&
                                (_selectedRow! ~/ 3 == r ~/ 3 && _selectedCol! ~/ 3 == c ~/ 3);

                            // Seçilen hücredeki sayı değeri (Eğer dolu bir hücre seçildiyse)
                            int? selectedNumber = (_selectedRow != null && _selectedCol != null)
                                ? _board[_selectedRow!][_selectedCol!].userValue
                                : null;

                            // Bu hücredeki sayı, seçilen hücredeki sayıyla aynı mı? (Parıldama efekti için)
                            bool isSameNumber = selectedNumber != null && 
                                cell.userValue != null && 
                                cell.userValue == selectedNumber;

                            bool isConflict = _highlightedConflictCells.contains(cellKey);
                            bool isJustCompletedGroup = _recentlyCompletedGroupCells.contains(cellKey);

                            Color bgColor = Colors.transparent;
                            if (isConflict) {
                              bgColor = Colors.red.shade300;
                            } else if (isJustCompletedGroup) {
                              bgColor = Colors.amber.shade300;
                            } else if (isSameNumber) {
                              bgColor = Colors.amber.withOpacity(0.35); // Aynı sayıların parıldama rengi
                            } else if (isSelected) {
                              bgColor = Colors.amber.withOpacity(0.15); // Seçilen karenin arka planı
                            } else if (isSameRowOrCol || isSameBox) {
                              bgColor = currentTheme.selectedCellColor.withOpacity(0.25);
                            }

                            BorderSide thickBorder = BorderSide(color: currentTheme.gridBorderColor, width: 2.0);
                            BorderSide thinBorder = BorderSide(color: currentTheme.gridBorderColor.withOpacity(0.3), width: 1.0);

                            return GestureDetector(
                              onTap: () {
                                if (_isGameOver) return;
                                setState(() {
                                  _selectedRow = r;
                                  _selectedCol = c;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  // Seçilen kareye net altın sarısı çerçeve (3.0 kalınlık)
                                  border: isSelected
                                      ? Border.all(color: const Color(0xFFFFD700), width: 3.0)
                                      : Border(
                                          top: r % 3 == 0 ? thickBorder : thinBorder,
                                          left: c % 3 == 0 ? thickBorder : thinBorder,
                                          bottom: r == 8 ? thickBorder : BorderSide.none,
                                          right: c == 8 ? thickBorder : BorderSide.none,
                                        ),
                                ),
                                child: Center(
                                  child: _buildCellContent(cell, currentTheme, isSameNumber),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 50.0, left: 16.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: _isGameOver ? null : () => setState(() => _isNoteMode = !_isNoteMode),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 135,
                            decoration: BoxDecoration(
                              color: _isNoteMode
                                  ? currentTheme.primaryColor.withOpacity(0.85)
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isNoteMode
                                    ? currentTheme.primaryColor
                                    : Colors.white.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isNoteMode ? Icons.edit : Icons.edit_outlined,
                                  color: _isNoteMode ? Colors.white : currentTheme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Not',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isNoteMode ? Colors.white : currentTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Container(
                          width: 175,
                          height: 175,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 9,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                            ),
                            itemBuilder: (context, index) {
                              int num = index + 1;
                              bool isCompleted = _completedNumbers.contains(num);

                              return InkWell(
                                onTap: (_isGameOver || isCompleted) ? null : () => _onNumberInput(num),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCompleted
                                          ? Colors.green.withOpacity(0.6)
                                          : currentTheme.primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? const Icon(Icons.check, color: Colors.green, size: 22)
                                        : Text(
                                            '$num',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: currentTheme.primaryColor,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 14),

                        InkWell(
                          onTap: _isGameOver ? null : _onErase,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 52,
                            height: 135,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.backspace_outlined,
                                  color: Colors.red.shade400,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sil',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCellContent(ClassicCell cell, AppTheme theme, bool isSameNumber) {
    if (cell.userValue != null) {
      bool isWrong = !cell.isInitial && cell.userValue != cell.value;
      return Text(
        '${cell.userValue}',
        style: TextStyle(
          fontSize: 22,
          fontWeight: (cell.isInitial || isSameNumber) ? FontWeight.bold : FontWeight.normal,
          color: cell.isInitial
              ? Colors.black
              : (isWrong ? Colors.red : (isSameNumber ? Colors.amber.shade900 : theme.primaryColor)),
        ),
      );
    } else if (cell.notes.isNotEmpty) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(2),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, i) {
          int n = i + 1;
          return Center(
            child: Text(
              cell.notes.contains(n) ? '$n' : '',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          );
        },
      );
    }
    return const SizedBox();
  }
}