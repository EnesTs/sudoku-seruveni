import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/animal_type.dart';
import '../models/board_cell.dart';
import '../models/cell_state.dart';
import '../models/game_config.dart';
import '../models/theme_model.dart';
import '../logic/board_generator.dart';
import '../logic/star_calculator.dart';
import '../logic/star_manager.dart';
import '../logic/theme_manager.dart';
import '../widgets/how_to_play_dialog.dart';
import '../widgets/themed_background.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final AnimalType selectedAnimal;

  const GameScreen({
    Key? key,
    required this.difficulty,
    required this.selectedAnimal,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late List<List<BoardCell>> _board;
  late ConfettiController _confettiController;
  late AnimationController _shakeController;

  int _lives = 3;
  bool _isGameOver = false;
  bool _isGameWon = false;
  bool _showRedFlash = false;
  bool _isLoading = true;

  Timer? _pressTimer;
  bool _longPressHandled = false;
  static const Duration _longPressDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _checkSavedGameOrNew();
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // Benzersiz bir kayıt anahtarı oluşturalım (Hayvan türüne ve zorluğa göre)
  String get _saveKey => 'saved_animal_game_${widget.selectedAnimal.name}_${widget.difficulty.name}';

  Future<void> _checkSavedGameOrNew() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString(_saveKey);

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
                    'Yarım kalmış heyecan dolu bir ${widget.selectedAnimal.name} bulmacan var. Nasıl devam etmek istersin?',
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
                            _startNewGame();
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
      _startNewGame();
    }
  }

  void _loadGame(String jsonStr) {
    try {
      Map<String, dynamic> data = jsonDecode(jsonStr);
      setState(() {
        _lives = data['lives'] ?? 3;
        _isGameOver = false;
        _isGameWon = false;

        var boardList = data['board'] as List;
        // Not: BoardCell modelinde .fromJson ve .toJson metodlarının tanımlı olduğundan emin olmalısın.
        _board = boardList.map((row) {
          var rowList = row as List;
          return rowList.map((cellJson) => BoardCell.fromJson(cellJson)).toList();
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      _startNewGame();
    }
  }

  Future<void> _saveGame() async {
    if (_isGameOver || _isGameWon) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_saveKey);
      return;
    }

    Map<String, dynamic> gameData = {
      'lives': _lives,
      'board': _board.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(gameData));
  }

  void _startNewGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);

    setState(() {
      _board = BoardGenerator.generateBoard(widget.difficulty);
      _lives = 3;
      _isGameOver = false;
      _isGameWon = false;
      _showRedFlash = false;
      _isLoading = false;
    });
    _saveGame();
  }

  void _triggerDamageEffect() {
    HapticFeedback.heavyImpact();
    
    setState(() {
      _showRedFlash = true;
    });

    _shakeController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showRedFlash = false;
        });
      }
    });
  }

  void _onCellTap(int r, int c) {
    if (_isGameOver || _isGameWon) return;

    BoardCell cell = _board[r][c];
    if (cell.isInitial || cell.state == CellState.hasAnimal) return;

    HapticFeedback.selectionClick();

    setState(() {
      if (cell.state == CellState.empty) {
        cell.state = CellState.wrongAttempt;
      } else if (cell.state == CellState.wrongAttempt) {
        cell.state = CellState.empty;
      }
    });
    _saveGame();
  }

  void _onCellLongPress(int r, int c) {
    if (_isGameOver || _isGameWon) return;

    BoardCell cell = _board[r][c];
    if (cell.isInitial || cell.state == CellState.hasAnimal) return;

    setState(() {
      if (cell.isSolution) {
        HapticFeedback.mediumImpact();
        cell.state = CellState.hasAnimal;
        _checkWinCondition();
      } else {
        cell.state = CellState.wrongAttempt;
        _lives--;
        _triggerDamageEffect();

        if (_lives <= 0) {
          _isGameOver = true;
        }
      }
    });
    _saveGame();
  }

  Future<void> _checkWinCondition() async {
    bool won = true;
    for (var row in _board) {
      for (var cell in row) {
        if (cell.isSolution && cell.state != CellState.hasAnimal) {
          won = false;
          break;
        }
      }
    }

    if (won) {
      _confettiController.play();
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_saveKey);

      int totalEarned = StarCalculator.calculateEarnedStars(
        difficulty: widget.difficulty,
        remainingLives: _lives,
      );
      
      await StarManager.addStars(totalEarned);

      if (!mounted) return;
      setState(() {
        _isGameWon = true;
      });

      _showWinDialog(totalEarned);
    }
  }

  void _showWinDialog(int earnedStars) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Text('🎉 TEBRİKLER! 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              SizedBox(height: 8),
              Text('Bulmacayı Çözdün!', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kalan Can Bonus:'),
                  Text('❤️ x $_lives', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Zorluk Seviyesi:'),
                  Text(widget.difficulty.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Kazanılan Yıldız: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('+$earnedStars ⭐', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _startNewGame();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Yeni Oyun', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, currentTheme, child) {
        return AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            double offset = 0.0;
            if (_shakeController.isAnimating) {
              offset = (0.5 - (_shakeController.value - 0.5).abs()) * 15 * (_shakeController.value * 10 % 2 == 0 ? 1 : -1);
            }

            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: currentTheme.primaryColor,
              foregroundColor: Colors.white,
              title: Text('${widget.selectedAnimal.name.toUpperCase()} Bulmacası'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => HowToPlayDialog.show(context),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: List.generate(
                      3,
                      (index) => Icon(
                        index < _lives ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                  ),
                )
              ],
            ),
            body: ThemedBackground(
              theme: currentTheme,
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: currentTheme.gridBorderColor, width: 2.5),
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: widget.difficulty.gridSize,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: widget.difficulty.gridSize * widget.difficulty.gridSize,
                            itemBuilder: (context, index) {
                              int r = index ~/ widget.difficulty.gridSize;
                              int c = index % widget.difficulty.gridSize;
                            BoardCell cell = _board[r][c];

                              Widget content = const SizedBox();
                              if (cell.state == CellState.hasAnimal) {
                                content = Text(widget.selectedAnimal.icon, style: const TextStyle(fontSize: 24));
                              } else if (cell.state == CellState.wrongAttempt) {
                                content = const Text('❌', style: TextStyle(fontSize: 20));
                              }

                              return GestureDetector(
                                onTapDown: (_) {
                                  _longPressHandled = false;
                                  _pressTimer?.cancel();
                                  _pressTimer = Timer(_longPressDuration, () {
                                    _longPressHandled = true;
                                    _onCellLongPress(r, c);
                                  });
                                },
                                onTapUp: (_) {
                                  _pressTimer?.cancel();
                                  if (!_longPressHandled) {
                                    _onCellTap(r, c);
                                  }
                                },
                                onTapCancel: () {
                                  _pressTimer?.cancel();
                                  _longPressHandled = false;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cell.regionColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: currentTheme.gridBorderColor.withOpacity(0.3), width: 1),
                                  ),
                                  child: Center(child: content),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (_isGameOver)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _startNewGame,
                          child: const Text('Yeniden Dene'),
                        ),
                    ],
                  ),
                  
                  if (_showRedFlash)
                    IgnorePointer(
                      child: Container(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),

                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
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
}