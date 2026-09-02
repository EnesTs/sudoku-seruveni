import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/classic_board_generator.dart';
import '../logic/star_manager.dart';
import '../logic/theme_manager.dart';
import '../models/classic_cell.dart';
import '../models/theme_model.dart';
import '../widgets/themed_background.dart';

class ClassicTimeAttackScreen extends StatefulWidget {
  const ClassicTimeAttackScreen({Key? key}) : super(key: key);

  @override
  State<ClassicTimeAttackScreen> createState() => _ClassicTimeAttackScreenState();
}

class _ClassicTimeAttackScreenState extends State<ClassicTimeAttackScreen> with WidgetsBindingObserver {
  List<List<ClassicCell>>? _board;
  Timer? _gameTimer;

  int _remainingSeconds = 180;
  int _solvedCount = 0;
  int _earnedStars = 0;
  int _currentStars = 0;
  int _highScore = 0;
  bool _isGameOver = false;
  bool _isLoading = true;

  int _completed3x3Count = 0;
  int _totalBonusSecondsEarned = 0;

  int? _selectedRow;
  int? _selectedCol;
  bool _isNoteMode = false;

  bool _showErrorFlash = false;
  String? _timeFeedbackText;
  Color _timeFeedbackColor = Colors.green;

  Set<int> _completedNumbers = {};
  Set<String> _completed3x3Boxes = {};
  Set<String> _highlightedConflictCells = {};
  Set<String> _goldFlashCells = {};

  static const String _saveKey = 'classic_time_attack_saved_state';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHighScoreAndStars();
    _checkSavedGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveGameState();
    }
  }

  Future<void> _loadHighScoreAndStars() async {
    final prefs = await SharedPreferences.getInstance();
    int stars = await StarManager.getStars();
    setState(() {
      _highScore = prefs.getInt('classic_time_attack_high_score') ?? 0;
      _currentStars = stars;
    });
  }

  Future<void> _saveHighScore() async {
    if (_solvedCount > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('classic_time_attack_high_score', _solvedCount);
    }
  }

  Future<void> _checkSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString(_saveKey);

    if (savedData != null && savedData.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResumeDialog(savedData);
      });
    } else {
      _startNewGame();
    }
  }

  void _startNewGame() {
    _solvedCount = 0;
    _earnedStars = 0;
    _remainingSeconds = 180;
    _totalBonusSecondsEarned = 0;
    _loadNextPuzzle();
    setState(() {
      _isLoading = false;
    });
    _startTimer();
  }

  Future<void> _saveGameState() async {
    if (_isGameOver || _board == null) return;
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> boardFlat = [];
    for (var r in _board!) {
      for (var c in r) {
        boardFlat.add({
          'row': c.row,
          'col': c.col,
          'value': c.value,
          'userValue': c.userValue,
          'isInitial': c.isInitial,
          'notes': c.notes.toList(),
        });
      }
    }

    Map<String, dynamic> state = {
      'remainingSeconds': _remainingSeconds,
      'solvedCount': _solvedCount,
      'earnedStars': _earnedStars,
      'completed3x3Count': _completed3x3Count,
      'totalBonusSecondsEarned': _totalBonusSecondsEarned,
      'completed3x3Boxes': _completed3x3Boxes.toList(),
      'board': boardFlat,
    };

    await prefs.setString(_saveKey, jsonEncode(state));
  }

  Future<void> _clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  void _restoreSavedGame(String jsonString) {
    try {
      Map<String, dynamic> state = jsonDecode(jsonString);
      List<dynamic> boardData = state['board'];

      List<List<ClassicCell>> loadedBoard = List.generate(9, (_) => List.generate(9, (_) => ClassicCell(row: 0, col: 0, value: 0)));

      for (var item in boardData) {
        int r = item['row'];
        int c = item['col'];
        loadedBoard[r][c] = ClassicCell(
          row: r,
          col: c,
          value: item['value'],
          userValue: item['userValue'],
          isInitial: item['isInitial'],
          notes: Set<int>.from(item['notes'] ?? []),
        );
      }

      setState(() {
        _remainingSeconds = state['remainingSeconds'];
        _solvedCount = state['solvedCount'];
        _earnedStars = state['earnedStars'];
        _completed3x3Count = state['completed3x3Count'] ?? 0;
        _totalBonusSecondsEarned = state['totalBonusSecondsEarned'] ?? 0;
        _completed3x3Boxes = Set<String>.from(state['completed3x3Boxes'] ?? []);
        _board = loadedBoard;
        _selectedRow = null;
        _selectedCol = null;
        _isLoading = false;
      });

      _updateCompletedNumbers();
      _startTimer();
    } catch (e) {
      _startNewGame();
    }
  }

  void _showResumeDialog(String savedData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Devam Edilsin mi? ⏱️', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Yarıda kalmış bir Zamana Karşı oyunun var. Kaldığın yerden devam etmek ister misin?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearSavedGame();
              _startNewGame();
            },
            child: const Text('Yeni Oyun', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _restoreSavedGame(savedData);
            },
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  ClassicDifficulty _getDynamicDifficulty() {
    if (_solvedCount == 0) {
      return ClassicDifficulty.easy;
    } else if (_solvedCount < 3) {
      return ClassicDifficulty.medium;
    } else {
      return ClassicDifficulty.hard;
    }
  }

  int _getCorrectNumberTimeBonus() {
    if (_solvedCount < 3) return 3;
    return 2;
  }

  int _getBlockCompletionTimeBonus() {
    if (_solvedCount >= 10) return 6;
    return 5;
  }

  int _getBoardCompletionTimeBonus() {
    if (_solvedCount >= 10) return 25;
    return 20;
  }

  void _loadNextPuzzle() {
    ClassicDifficulty diff = _getDynamicDifficulty();
    List<List<int>> solved = ClassicBoardGenerator.generateSolvedBoard();
    List<List<int>> puzzle = ClassicBoardGenerator.createPuzzle(solved, diff);

    setState(() {
      _selectedRow = null;
      _selectedCol = null;
      _completed3x3Count = 0;
      _completed3x3Boxes.clear();
      _completedNumbers.clear();
      _highlightedConflictCells.clear();
      _goldFlashCells.clear();

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
    });
    _updateCompletedNumbers();
    _saveGameState();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds % 5 == 0) {
          _saveGameState();
        }
      } else {
        _timerEnded();
      }
    });
  }

  void _timerEnded() {
    _gameTimer?.cancel();
    _clearSavedGame();
    _saveHighScore();
    setState(() {
      _isGameOver = true;
    });
    StarManager.addStars(_earnedStars);
    _showGameOverDialog();
  }

  void _addBonusTime(int seconds, String msg, Color color) {
    _remainingSeconds += seconds;
    _totalBonusSecondsEarned += seconds;
    _showFloatingFeedback(msg, color);
  }

  void _showFloatingFeedback(String text, Color color) {
    setState(() {
      _timeFeedbackText = text;
      _timeFeedbackColor = color;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _timeFeedbackText = null;
        });
      }
    });
  }

  void _showBuyTimeDialog() async {
    int availableStars = await StarManager.getStars();
    int cost = 20;
    int secondsToBuy = 30;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Süre Satın Al ⏳', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mevcut Yıldızın: $availableStars ⭐', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 12),
            Text(
              '$cost Yıldız karşılığında +$secondsToBuy Saniye kazanmak ister misin?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (availableStars >= cost) {
                await StarManager.spendStars(cost);
                int updatedStars = await StarManager.getStars();
                Navigator.pop(context);
                setState(() {
                  _currentStars = updatedStars;
                });
                _addBonusTime(secondsToBuy, '+$secondsToBuy s Satın Alındı! ⚡', Colors.amber.shade900);
                HapticFeedback.mediumImpact();
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yeterli yıldızın yok! ❌')),
                );
              }
            },
            child: const Text('Satın Al (-20 ⭐)'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Oyun Kuralları', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('⏱️ Süreye Karşı Yarış:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text('Başlangıç Süresi: 180 Saniye (3 Dk)\nSüren bitmeden yapabildiğin kadar çok tahta tamamlamalısın.\n'),
              Text('⚡ Süre Ödülleri:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text('• Doğru Sayı: +2s / +3s'),
              Text('• Satır / Sütun / 3x3 Blok: +5s (+6s Uzman Mod)'),
              Text('• 3x3 Üçleme Kombo: +10s (Her 3 adet 3x3 tamamlama)'),
              Text('• Tahta Tamamlama: +20s / +25s\n'),
              Text('🌬️ Nefes Bonusu:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text('• 11. tahtadan itibaren (Uzman Mod) her 3 tahtada bir ekstra +15s Nefes Bonusu verilir!\n'),
              Text('🛑 Yanlış Hamle Cezası:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              Text('• Her hatalı hamle için -10 saniye düşer.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _updateCompletedNumbers() {
    if (_board == null) return;
    Map<int, int> counts = {};
    for (var row in _board!) {
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

  void _checkRowColBoxCompletions(int r, int c) {
    if (_board == null) return;
    Set<String> newGoldCells = {};
    String? bonusMsg;
    int bonusAmount = _getBlockCompletionTimeBonus();
    bool newlyCompleted3x3 = false;

    bool rowComplete = true;
    for (int i = 0; i < 9; i++) {
      if (_board![r][i].userValue != _board![r][i].value) {
        rowComplete = false;
        break;
      }
    }
    if (rowComplete) {
      for (int i = 0; i < 9; i++) newGoldCells.add('$r-$i');
      bonusMsg = '+$bonusAmount s Satır Bonusu ✨';
    }

    bool colComplete = true;
    for (int i = 0; i < 9; i++) {
      if (_board![i][c].userValue != _board![i][c].value) {
        colComplete = false;
        break;
      }
    }
    if (colComplete) {
      for (int i = 0; i < 9; i++) newGoldCells.add('$i-$c');
      bonusMsg = '+$bonusAmount s Sütun Bonusu ✨';
    }

    int boxRow = r ~/ 3;
    int boxCol = c ~/ 3;
    String boxKey = '$boxRow-$boxCol';

    int startRow = boxRow * 3;
    int startCol = boxCol * 3;
    bool boxComplete = true;

    for (int i = startRow; i < startRow + 3; i++) {
      for (int j = startCol; j < startCol + 3; j++) {
        if (_board![i][j].userValue != _board![i][j].value) {
          boxComplete = false;
          break;
        }
      }
    }

    if (boxComplete && !_completed3x3Boxes.contains(boxKey)) {
      _completed3x3Boxes.add(boxKey);
      _completed3x3Count++;
      newlyCompleted3x3 = true;

      for (int i = startRow; i < startRow + 3; i++) {
        for (int j = startCol; j < startCol + 3; j++) {
          newGoldCells.add('$i-$j');
        }
      }
      bonusMsg = '+$bonusAmount s 3x3 Bonusu ✨';
    }

    if (newGoldCells.isNotEmpty && bonusMsg != null) {
      HapticFeedback.mediumImpact();
      _addBonusTime(bonusAmount, bonusMsg, Colors.amber.shade900);

      if (newlyCompleted3x3 && _completed3x3Count % 3 == 0) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            HapticFeedback.heavyImpact();
            _addBonusTime(10, '+10s 🔥 3x3 Üçleme Kombo!', Colors.deepOrange);
          }
        });
      }

      setState(() {
        _goldFlashCells.addAll(newGoldCells);
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _goldFlashCells.removeAll(newGoldCells);
          });
        }
      });
    }
  }

  void _onNumberInput(int number) {
    if (_isGameOver || _selectedRow == null || _selectedCol == null || _board == null) return;
    if (_completedNumbers.contains(number)) return;

    ClassicCell cell = _board![_selectedRow!][_selectedCol!];
    if (cell.isInitial) return;

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
            HapticFeedback.heavyImpact();
            _remainingSeconds = (_remainingSeconds - 10).clamp(0, 999);
            _showErrorFlash = true;
            _showFloatingFeedback('-10s 🛑', Colors.redAccent);
            _triggerConflictHighlight(_selectedRow!, _selectedCol!, number);

            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) setState(() => _showErrorFlash = false);
            });
          } else {
            HapticFeedback.lightImpact();
            int addSec = _getCorrectNumberTimeBonus();
            _addBonusTime(addSec, '+$addSec s ⚡', Colors.green.shade700);
            _updateCompletedNumbers();
            _checkRowColBoxCompletions(_selectedRow!, _selectedCol!);
            _checkWinCondition();
          }
        }
      }
    });
    _saveGameState();
  }

  void _triggerConflictHighlight(int r, int c, int wrongNum) {
    if (_board == null) return;
    Set<String> conflicts = {};
    for (int i = 0; i < 9; i++) {
      if (i != c && _board![r][i].userValue == wrongNum) conflicts.add('$r-$i');
      if (i != r && _board![i][c].userValue == wrongNum) conflicts.add('$i-$c');
    }
    setState(() => _highlightedConflictCells = conflicts);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _highlightedConflictCells.clear());
    });
  }

  void _onErase() {
    if (_isGameOver || _selectedRow == null || _selectedCol == null || _board == null) return;
    ClassicCell cell = _board![_selectedRow!][_selectedCol!];
    if (cell.isInitial) return;

    HapticFeedback.selectionClick();
    setState(() {
      cell.userValue = null;
      cell.notes.clear();
    });
    _updateCompletedNumbers();
    _saveGameState();
  }

  void _checkWinCondition() {
    if (_board == null) return;
    bool isCompleted = true;
    for (var row in _board!) {
      for (var cell in row) {
        if (cell.userValue != cell.value) {
          isCompleted = false;
          break;
        }
      }
    }

    if (isCompleted) {
      HapticFeedback.vibrate();

      int nextSolvedCount = _solvedCount + 1;
      int boardBonus = _getBoardCompletionTimeBonus();

      bool isExpertMode = nextSolvedCount >= 11;
      bool isEvery3rdBoardInExpert = isExpertMode && (nextSolvedCount % 3 == 0);

      int extraBreathBonus = isEvery3rdBoardInExpert ? 15 : 0;
      int totalBonus = boardBonus + extraBreathBonus;

      String msg = isEvery3rdBoardInExpert
          ? '+$totalBonus s Nefes Bonusu! 🌬️'
          : '+$totalBonus s Tahta Bonusu! 🎉';

      _addBonusTime(totalBonus, msg, Colors.amber.shade900);

      setState(() {
        _solvedCount = nextSolvedCount;
        _earnedStars += 10;
      });
      _loadNextPuzzle();
    }
  }

  void _showGameOverDialog() {
    bool isNewRecord = _solvedCount > _highScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            isNewRecord ? '🏆 YENİ REKOR!' : '⏱️ Süre Doldu!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNewRecord ? Colors.amber.shade900 : Colors.redAccent,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tamamlanan Tahta: $_solvedCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('En Yüksek Skor: ${isNewRecord ? _solvedCount : _highScore}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Kazanılan Yıldız: +$_earnedStars ⭐',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Ana Menüye Dön'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, currentTheme, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: currentTheme.primaryColor,
            foregroundColor: Colors.white,
            title: const Text('Klasik: Zamana Karşı ⏱️'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: _showInfoDialog,
              ),
              GestureDetector(
                onTap: _showBuyTimeDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text('$_currentStars', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _remainingSeconds <= 15 ? Colors.red.shade100 : Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: _remainingSeconds <= 15 ? Colors.red.shade900 : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_remainingSeconds}s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _remainingSeconds <= 15 ? Colors.red.shade900 : Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          body: ThemedBackground(
            theme: currentTheme,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: _showErrorFlash ? Colors.red.withOpacity(0.3) : Colors.transparent,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // İSTATİSTİK BARI
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Çözülen: $_solvedCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('Rekor: $_highScore', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey.shade300,
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.grid_view_rounded, size: 18, color: Colors.indigo),
                                    const SizedBox(width: 4),
                                    Text(
                                      '3x3: ${_completed3x3Count % 3}/3',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey.shade300,
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, size: 18, color: Colors.amber),
                                    Text(
                                      '+${_totalBonusSecondsEarned}s',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ANLIK SÜRE BİLDİRİMİ
                        SizedBox(
                          height: 28,
                          child: Center(
                            child: _timeFeedbackText != null
                                ? AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: _timeFeedbackText != null ? 1.0 : 0.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _timeFeedbackColor.withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Text(
                                        _timeFeedbackText!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _timeFeedbackColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),

                        // TAM BOYUT SÜDOKU IZGARASI
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: currentTheme.gridBorderColor, width: 2.5),
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 81,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
                                itemBuilder: (context, index) {
                                  int r = index ~/ 9;
                                  int c = index % 9;
                                  ClassicCell cell = _board![r][c];

                                  String cellKey = '$r-$c';
                                  bool isSelected = _selectedRow == r && _selectedCol == c;
                                  bool isSameRowOrCol = _selectedRow == r || _selectedCol == c;
                                  bool isSameBox = (_selectedRow != null && _selectedCol != null) &&
                                      (_selectedRow! ~/ 3 == r ~/ 3 && _selectedCol! ~/ 3 == c ~/ 3);

                                  // Seçili hücredeki sayıyı bulma (Boş hücrelerde sayı aranmaz)
                                  int? selectedNumber;
                                  if (_selectedRow != null && _selectedCol != null && _board != null) {
                                    ClassicCell selectedCell = _board![_selectedRow!][_selectedCol!];
                                    selectedNumber = selectedCell.userValue ?? (selectedCell.isInitial ? selectedCell.value : null);
                                  }

                                  int? currentCellNum = cell.userValue ?? (cell.isInitial ? cell.value : null);
                                  // Sadece dolu ve eşleşen sayılar yanacak (Boş hücreler asla yanmaz)
                                  bool isSameNumber = selectedNumber != null && currentCellNum != null && currentCellNum == selectedNumber;

                                  bool isConflict = _highlightedConflictCells.contains(cellKey);
                                  bool isGoldFlash = _goldFlashCells.contains(cellKey);

                                  Color bgColor = Colors.transparent;
                                  if (isGoldFlash) {
                                    bgColor = Colors.amber.shade300;
                                  } else if (isConflict) {
                                    bgColor = Colors.red.shade300;
                                  } else if (isSelected) {
                                    bgColor = currentTheme.selectedCellColor;
                                  } else if (isSameNumber) {
                                    // Aynı sayıların net görünmesi için opaklık oranı artırıldı
                                    bgColor = currentTheme.selectedCellColor.withOpacity(0.85);
                                  } else if (isSameRowOrCol || isSameBox) {
                                    bgColor = currentTheme.selectedCellColor.withOpacity(0.3);
                                  }

                                  BorderSide thickBorder = BorderSide(color: currentTheme.gridBorderColor, width: 2.0);
                                  BorderSide thinBorder = BorderSide(color: currentTheme.gridBorderColor.withOpacity(0.3), width: 1.0);

                                  bool isEmptyAndSelected = isSelected && cell.userValue == null && !cell.isInitial;
                                  BoxBorder customBorder = Border(
                                    top: r % 3 == 0 ? thickBorder : thinBorder,
                                    left: c % 3 == 0 ? thickBorder : thinBorder,
                                    bottom: r == 8 ? thickBorder : BorderSide.none,
                                    right: c == 8 ? thickBorder : BorderSide.none,
                                  );

                                  if (isEmptyAndSelected) {
                                    customBorder = Border.all(color: Colors.amber.shade700, width: 2.5);
                                  }

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
                                        border: customBorder,
                                        boxShadow: isEmptyAndSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.amber.withOpacity(0.5),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Center(child: _buildCellContent(cell, currentTheme)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // ESNEK BOŞLUK
                        const Spacer(flex: 1),

                        // KUSURSUZ SIĞAN 3x3 KONTROL PANELİ
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            height: 160,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // SOL KANAT: NOT MODU
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: _isGameOver ? null : () => setState(() => _isNoteMode = !_isNoteMode),
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: _isNoteMode
                                            ? currentTheme.primaryColor.withOpacity(0.85)
                                            : Colors.white.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isNoteMode ? Icons.edit : Icons.edit_outlined,
                                            color: _isNoteMode ? Colors.white : currentTheme.primaryColor,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
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
                                ),

                                const SizedBox(width: 8),

                                // ORTA KISIM: 9 EŞ PARÇAYA BÖLÜNMÜŞ SAYI PANELİ
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.30),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: List.generate(3, (rowIndex) {
                                        return Expanded(
                                          child: Row(
                                            children: List.generate(3, (colIndex) {
                                              int num = rowIndex * 3 + colIndex + 1;
                                              bool isCompleted = _completedNumbers.contains(num);

                                              return Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(2.0),
                                                  child: InkWell(
                                                    onTap: (_isGameOver || isCompleted) ? null : () => _onNumberInput(num),
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: AnimatedContainer(
                                                      duration: const Duration(milliseconds: 150),
                                                      decoration: BoxDecoration(
                                                        color: isCompleted
                                                            ? Colors.green.withOpacity(0.25)
                                                            : Colors.white.withOpacity(0.65),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(
                                                          color: isCompleted ? Colors.green.shade400 : Colors.white.withOpacity(0.8),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: isCompleted
                                                            ? const Icon(Icons.check, color: Colors.green, size: 18)
                                                            : Text(
                                                                '$num',
                                                                style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: currentTheme.primaryColor,
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // SAĞ KANAT: SİLGEÇ
                                Expanded(
                                  flex: 2,
                                  child: InkWell(
                                    onTap: _isGameOver ? null : _onErase,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.backspace_outlined,
                                            color: Colors.red.shade400,
                                            size: 22,
                                          ),
                                          const SizedBox(height: 4),
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
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ALT ESNEK BOŞLUK
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCellContent(ClassicCell cell, AppTheme theme) {
    if (cell.userValue != null) {
      bool isWrong = !cell.isInitial && cell.userValue != cell.value;
      return Text(
        '${cell.userValue}',
        style: TextStyle(
          fontSize: 22,
          fontWeight: cell.isInitial ? FontWeight.bold : FontWeight.normal,
          color: cell.isInitial ? Colors.black : (isWrong ? Colors.red : theme.primaryColor),
        ),
      );
    } else if (cell.notes.isNotEmpty) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(2),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1),
        itemBuilder: (context, i) {
          int n = i + 1;
          return Center(
            child: Text(
              cell.notes.contains(n) ? '$n' : '',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          );
        },
      );
    }
    return const SizedBox();
  }
}