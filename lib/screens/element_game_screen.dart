import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/element_cell.dart';
import '../logic/element_board_generator.dart';
import '../logic/star_manager.dart';

class ElementGameScreen extends StatefulWidget {
  final int gridSize; 
  final String levelTitle;

  const ElementGameScreen({
    Key? key,
    required this.gridSize,
    required this.levelTitle,
  }) : super(key: key);

  @override
  State<ElementGameScreen> createState() => _ElementGameScreenState();
}

class _ElementGameScreenState extends State<ElementGameScreen> with SingleTickerProviderStateMixin {
  late List<List<ElementCell>> _board;
  ElementType _selectedElement = ElementType.water;

  late AnimationController _effectController;
  String? _activeEffectText;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _effectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadOrInitializeGame();
  }

  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }

  // Kayıtlı oyun var mı kontrol et, varsa sor veya yükle
  Future<void> _loadOrInitializeGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedBoardJson = prefs.getString('saved_element_board_5x5');

    if (savedBoardJson != null) {
      // Kayıt bulundu, kullanıcıya soralım
      _showResumeOrNewDialog(prefs);
    } else {
      // Kayıt yoksa yeni oyun başlat
      setState(() {
        _board = ElementBoardGenerator.generateBoard(5, 0.45);
        _isLoading = false;
      });
      _saveCurrentBoard();
    }
  }

  // Devam et / Yeniden başla seçim penceresi
  void _showResumeOrNewDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kayıtlı Oyun Bulundu', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Yarım kalan bir Elementler Dengesi oyunun var. Kaldığın yerden devam etmek ister misin?',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  prefs.remove('saved_element_board_5x5');
                  Navigator.pop(context);
                  setState(() {
                    _board = ElementBoardGenerator.generateBoard(5, 0.45);
                    _isLoading = false;
                  });
                  _saveCurrentBoard();
                },
                child: const Text('Yeniden Başla', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _restoreBoard(prefs.getString('saved_element_board_5x5')!);
                },
                child: const Text('Kaldığım Yerden'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Kayıtlı JSON verisini tahtaya çevir
  void _restoreBoard(String jsonString) {
    try {
      List<dynamic> decodedList = jsonDecode(jsonString);
      List<List<ElementCell>> restoredBoard = List.generate(5, (r) {
        List<dynamic> rowList = decodedList[r];
        return List.generate(5, (c) {
          Map<String, dynamic> cellMap = rowList[c];
          return ElementCell(
            row: cellMap['row'],
            col: cellMap['col'],
          )
            ..isInitial = cellMap['isInitial']
            ..type = ElementType.values[cellMap['type']];
        });
      });

      setState(() {
        _board = restoredBoard;
        _isLoading = false;
      });
    } catch (e) {
      // Hata olursa yeni oyun aç
      setState(() {
        _board = ElementBoardGenerator.generateBoard(5, 0.45);
        _isLoading = false;
      });
    }
  }

  // Tahtanın anlık durumunu hafızaya kaydet
  Future<void> _saveCurrentBoard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<List<Map<String, dynamic>>> boardList = _board.map((row) {
      return row.map((cell) {
        return {
          'row': cell.row,
          'col': cell.col,
          'isInitial': cell.isInitial,
          'type': cell.type.index,
        };
      }).toList();
    }).toList();

    prefs.setString('saved_element_board_5x5', jsonEncode(boardList));
  }

  // Oyunu bitirince veya sıfırlayınca kayıtlı veriyi temizle
  Future<void> _clearSavedGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('saved_element_board_5x5');
  }

  void _initializeNewGame() async {
    await _clearSavedGame();
    setState(() {
      _board = ElementBoardGenerator.generateBoard(5, 0.45);
    });
    _saveCurrentBoard();
  }

  String _getElementSymbol(ElementType type) {
    switch (type) {
      case ElementType.water: return '💧';
      case ElementType.fire: return '🔥';
      case ElementType.plant: return '🌱';
      case ElementType.wind: return '💨';
      case ElementType.electric: return '⚡';
      default: return '';
    }
  }

  void _onCellTap(ElementCell cell) {
    if (cell.isInitial) return;

    setState(() {
      if (cell.type == _selectedElement) {
        cell.type = ElementType.none;
      } else {
        int size = 5;
        if (_hasConflictOnBoard(cell.row, cell.col, _selectedElement, size)) {
          _showSnackBar('Bu satır veya sütunda zaten bu elementten var!', Colors.orange);
          return;
        }
        cell.type = _selectedElement;
      }
    });
    // Her hamleden sonra tahtayı otomatik kaydet
    _saveCurrentBoard();
  }

  bool _hasConflictOnBoard(int row, int col, ElementType element, int size) {
    for (int i = 0; i < size; i++) {
      if (i != col && _board[row][i].type == element) return true;
      if (i != row && _board[i][col].type == element) return true;
    }
    return false;
  }

  void _checkSolution() async {
    int size = 5;
    bool isFullyFilled = true;

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_board[r][c].type == ElementType.none) {
          isFullyFilled = false;
          break;
        }
      }
    }

    if (!isFullyFilled) {
      _showSnackBar('Tahtada henüz boş yerler var!', Colors.orange);
      return;
    }

    double calculatedScore = 3.0; // Taban Puan
    List<String> breakdownDetails = ['🌟 Taban Yıldız: +3.0'];
    List<String> interactions = [];

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        ElementType current = _board[r][c].type;
        String currentSym = _getElementSymbol(current);

        // Sağ Komşu Kontrolü
        if (c + 1 < size) {
          ElementType rightNeighbor = _board[r][c + 1].type;
          String rightSym = _getElementSymbol(rightNeighbor);

          if (_isConflict(current, rightNeighbor)) {
            calculatedScore -= 1.0;
            breakdownDetails.add('❌ Çatışma ($currentSym & $rightSym): -1.0 Yıldız');
            interactions.add('💥 Çatışma! ($currentSym + $rightSym)');
          } else if (_isSynergy(current, rightNeighbor)) {
            calculatedScore += 0.75;
            breakdownDetails.add('✨ Sinerji ($currentSym & $rightSym): +0.75 Yıldız');
            interactions.add('✨ Sinerji! ($currentSym + $rightSym)');
          }
        }

        // Alt Komşu Kontrolü
        if (r + 1 < size) {
          ElementType bottomNeighbor = _board[r + 1][c].type;
          String bottomSym = _getElementSymbol(bottomNeighbor);

          if (_isConflict(current, bottomNeighbor)) {
            calculatedScore -= 1.0;
            breakdownDetails.add('❌ Çatışma ($currentSym & $bottomSym): -1.0 Yıldız');
            interactions.add('💥 Çatışma! ($currentSym + $bottomSym)');
          } else if (_isSynergy(current, bottomNeighbor)) {
            calculatedScore += 0.75;
            breakdownDetails.add('✨ Sinerji ($currentSym & $bottomSym): +0.75 Yıldız');
            interactions.add('✨ Sinerji! ($currentSym + $bottomSym)');
          }
        }
      }
    }

    // Efektleri sırayla oynat
    if (interactions.isNotEmpty) {
      for (var effectText in interactions) {
        setState(() {
          _activeEffectText = effectText;
        });
        _effectController.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    // Oyun bittiği için kayıtlı veriyi temizle
    await _clearSavedGame();

    int finalStars = math.max(1, calculatedScore.round());
    StarManager.addStars(finalStars);

    String starDisplay = finalStars <= 10 
        ? '⭐' * finalStars 
        : '${'⭐' * 10} (+${finalStars - 10})';

    _showResultDialog(
      title: '🎉 Doğanın Dengesi Kuruldu!',
      message: 'Kazanılan Yıldız: $starDisplay ($finalStars Yıldız)\n(Hesaplanan Toplam: ${calculatedScore.toStringAsFixed(2)})',
      starsEarned: finalStars,
      isSuccess: true,
      breakdown: breakdownDetails,
    );
  }

  bool _isConflict(ElementType e1, ElementType e2) {
    if ((e1 == ElementType.water && e2 == ElementType.fire) || (e1 == ElementType.fire && e2 == ElementType.water)) return true;
    if ((e1 == ElementType.fire && e2 == ElementType.plant) || (e1 == ElementType.plant && e2 == ElementType.fire)) return true;
    if ((e1 == ElementType.water && e2 == ElementType.electric) || (e1 == ElementType.electric && e2 == ElementType.water)) return true;
    return false;
  }

  bool _isSynergy(ElementType e1, ElementType e2) {
    if ((e1 == ElementType.water && e2 == ElementType.plant) || (e1 == ElementType.plant && e2 == ElementType.water)) return true;
    if ((e1 == ElementType.fire && e2 == ElementType.wind) || (e1 == ElementType.wind && e2 == ElementType.fire)) return true;
    if ((e1 == ElementType.plant && e2 == ElementType.electric) || (e1 == ElementType.electric && e2 == ElementType.plant)) return true;
    return false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
    required int starsEarned,
    required bool isSuccess,
    required List<String> breakdown,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 12),
                if (breakdown.isNotEmpty) ...[
                  const Divider(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('📊 Puan Detayları:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                  const SizedBox(height: 6),
                  ...breakdown.map((detail) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(detail, style: const TextStyle(fontSize: 12)),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Ana Menü'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _initializeNewGame();
                  });
                },
                child: const Text('Yeniden Başla'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Elementler Dengesi 5x5', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yeniden Başla',
            onPressed: () => _initializeNewGame(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              primaryColor.withOpacity(0.12),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📜 Oyun Kuralları ve Puan Dengesi:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• 5 Rastgele başlangıç ipucu ile başla, satır/sütun çakışmadan doldur.\n'
                      '• ⭐ Taban Puan: 3 Yıldız (Üst sınır yok! Sinerjiyle artar)\n'
                      '• ✨ Sinerji Komşuluğu: +0.75 Yıldız (💧+🌱, 🔥+💨, 🌱+⚡)\n'
                      '• ❌ Çatışma Komşuluğu: -1.0 Yıldız (💧+🔥, 🔥+🌱, 💧+⚡)',
                      style: TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: 25,
                          itemBuilder: (context, index) {
                            int row = index ~/ 5;
                            int col = index % 5;
                            ElementCell cell = _board[row][col];

                            return GestureDetector(
                              onTap: () => _onCellTap(cell),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cell.isInitial ? Colors.grey.shade300 : theme.cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: cell.isInitial ? Colors.grey.shade500 : primaryColor.withOpacity(0.5),
                                    width: cell.isInitial ? 2 : 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: cell.type != ElementType.none
                                      ? Text(
                                          _getElementSymbol(cell.type),
                                          style: const TextStyle(fontSize: 22),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_activeEffectText != null)
                        FadeTransition(
                          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_effectController),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.5, end: 1.5).animate(
                              CurvedAnimation(parent: _effectController, curve: Curves.easeOut),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 10)],
                              ),
                              child: Text(
                                _activeEffectText!,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ElementType.values.where((e) => e != ElementType.none).map((type) {
                      bool isSelected = _selectedElement == type;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedElement = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withOpacity(0.2) : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: Text(
                            _getElementSymbol(type),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _checkSolution,
                      child: const Text('Tahtayı Bitir ve Kontrol Et', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}