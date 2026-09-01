import 'package:flutter/material.dart';

class ClassicCell {
  final int row;
  final int col;
  final int value; // 1-9 arası doğru çözüm değeri
  int? userValue; // Oyuncunun girdiği değer
  final bool isInitial; // Başlangıçta verilen sabit sayı mı?
  Set<int> notes; // Oyuncunun aldığı notlar (1-9)

  ClassicCell({
    required this.row,
    required this.col,
    required this.value,
    this.userValue,
    this.isInitial = false,
    Set<int>? notes,
  }) : notes = notes ?? {};

  bool get isCorrect => userValue == value;
  bool get isEmpty => userValue == null;

  // JSON'a dönüştürme (SharedPreferences ile kaydetmek için)
  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'value': value,
      'userValue': userValue,
      'isInitial': isInitial,
      'notes': notes.toList(),
    };
  }

  // JSON'dan nesne üretme (Kaydedilen oyunu yüklemek için)
  factory ClassicCell.fromJson(Map<String, dynamic> json) {
    return ClassicCell(
      row: json['row'],
      col: json['col'],
      value: json['value'],
      userValue: json['userValue'],
      isInitial: json['isInitial'],
      notes: Set<int>.from(json['notes'] ?? []),
    );
  }
}