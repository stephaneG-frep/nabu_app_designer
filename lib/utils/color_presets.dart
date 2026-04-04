import 'package:flutter/material.dart';

class ColorPreset {
  const ColorPreset({required this.label, required this.color});

  final String label;
  final Color color;
}

class ColorPresets {
  static const List<ColorPreset> all = [
    ColorPreset(label: 'Turquoise', color: Color(0xFF2A9D8F)),
    ColorPreset(label: 'Ocean', color: Color(0xFF1D3557)),
    ColorPreset(label: 'Coral', color: Color(0xFFE76F51)),
    ColorPreset(label: 'Sun', color: Color(0xFFF4A261)),
    ColorPreset(label: 'Lavender', color: Color(0xFF8D99AE)),
    ColorPreset(label: 'Mint', color: Color(0xFF52B788)),
    ColorPreset(label: 'Grey', color: Color(0xFF6C757D)),
  ];

  static Color fromValue(int value) {
    return Color(value);
  }
}
