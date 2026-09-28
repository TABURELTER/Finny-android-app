import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appAccentProvider = ChangeNotifierProvider((ref) => AppAccent());

class AppAccent extends ChangeNotifier {
  static const _key = 'finny_app_accent_v1';
  Color color = const Color(0xFFC94C19);
  bool _edited = false;

  AppAccent() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (_edited) return;
    final saved = prefs.getInt(_key);
    if (saved != null) {
      final previous = Color(saved);
      color =
          previous == const Color(0xFF6B3DC6) ||
              previous == const Color(0xFF5B249B) ||
              previous == const Color(0xFFD65321)
          ? const Color(0xFFC94C19)
          : previous;
      notifyListeners();
    }
  }

  Future<void> update(Color chosen) async {
    _edited = true;
    color = chosen;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt(_key, chosen.toARGB32())) {
      throw StateError('Accent save failed');
    }
  }
}
