import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2196F3);
  static const secondary = Color(0xFF03A9F4);
  static const background = Color(0xFFFFFFFF);
  static const text = Color(0xFF000000);
  static const grey = Color(0xFF9E9E9E);

  // Position category colors
  static const Map<int, Color> positionColors = {
    1: Color(0xFF2196F3), // Class Representative - Blue
    2: Color(0xFF4CAF50), // Faculty Representative - Green
    3: Color(0xFF9C27B0), // President - Purple
    4: Color(0xFFFF9800), // Vice President - Orange
    5: Color(0xFF795548), // Secretary General - Brown
    6: Color(0xFF607D8B), // Other positions - Blue Grey
  };

  static Color getPositionColor(int positionId) {
    return positionColors[positionId] ?? primary;
  }
}
