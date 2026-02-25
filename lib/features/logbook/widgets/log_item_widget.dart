import 'package:flutter/material.dart';

/// Konfigurasi kategori dengan warna yang berbeda
class CategoryConfig {
  final String name;
  final Color color;
  final Color cardColor;
  final IconData icon;

  const CategoryConfig({
    required this.name,
    required this.color,
    required this.cardColor,
    required this.icon,
  });
}

class Categories {
  Categories._(); // Prevent instantiation

  static const Map<String, CategoryConfig> all = {
    'Pekerjaan': CategoryConfig(
      name: 'Pekerjaan',
      color: Color(0xFF2196F3), // Blue
      cardColor: Color(0xFFE3F2FD), // Light Blue
      icon: Icons.work,
    ),
    'Pribadi': CategoryConfig(
      name: 'Pribadi',
      color: Color(0xFF4CAF50), // Green
      cardColor: Color(0xFFE8F5E9), // Light Green
      icon: Icons.person,
    ),
    'Urgent': CategoryConfig(
      name: 'Urgent',
      color: Color(0xFFFF6B6B), // Red
      cardColor: Color(0xFFFFEBEE), // Light Red
      icon: Icons.priority_high,
    ),
  };

  static List<String> get categoryNames => all.keys.toList();

  static CategoryConfig getCategory(String name) {
    return all[name] ?? all['Pribadi']!;
  }
}
