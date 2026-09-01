enum ElementType {
  none,
  water,    // 💧 Su
  fire,     // 🔥 Ateş
  plant,    // 🌱 Bitki
  wind,     // 💨 Rüzgar
  electric, // ⚡ Elektrik
}

class ElementCell {
  final int row;
  final int col;
  ElementType type;
  bool isInitial;
  Set<ElementType> notes;

  ElementCell({
    required this.row,
    required this.col,
    this.type = ElementType.none,
    this.isInitial = false,
    Set<ElementType>? notes,
  }) : notes = notes ?? {};
}