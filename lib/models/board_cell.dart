import 'package:flutter/material.dart';
import 'cell_state.dart';

class BoardCell {
  final int row;
  final int col;
  final int regionId;       // Ait olduğu renk bölgesi ID'si
  final Color regionColor;  // Görsel bölge rengi
  final bool isSolution;    // Bu hücrede gerçekte hayvan var mı?
  
  CellState state;
  bool isInitial;           // Başlangıçta verilen kilitli ipucu mu?

  BoardCell({
    required this.row,
    required this.col,
    required this.regionId,
    required this.regionColor,
    required this.isSolution,
    this.state = CellState.empty,
    this.isInitial = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'regionId': regionId,
      'regionColorValue': regionColor.value,
      'isSolution': isSolution,
      'state': state.index,
      'isInitial': isInitial,
    };
  }

  factory BoardCell.fromJson(Map<String, dynamic> json) {
    return BoardCell(
      row: json['row'] ?? 0,
      col: json['col'] ?? 0,
      regionId: json['regionId'] ?? 0,
      regionColor: Color(json['regionColorValue'] ?? Colors.grey.value),
      isSolution: json['isSolution'] ?? false,
      state: CellState.values[json['state'] ?? 0],
      isInitial: json['isInitial'] ?? false,
    );
  }
}