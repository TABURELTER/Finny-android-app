import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final finnyAppearanceProvider = ChangeNotifierProvider(
  (ref) => FinnyAppearance(),
);

class FinnyAppearance extends ChangeNotifier {
  static const _mainKey = 'finny_appearance_v1';
  static const _demoKey = 'finny_demo_appearance_v1';
  static const _demoActiveKey = 'finny_demo_active_v1';
  static const palettes = {
    'original': 'Лесная магия',
    'lagoon': 'Лагуна',
    'apricot': 'Абрикос',
    'custom': 'Свой окрас',
  };
  static const jackets = {
    'none': 'Без куртки',
    'blue': 'Синяя',
    'coral': 'Коралловая',
    'mint': 'Мятная',
    'custom': 'Свой цвет',
  };
  static const hats = {
    'none': 'Без шапки',
    'beanie': 'С помпоном',
    'beret': 'Берет',
  };

  String palette = 'original', jacket = 'none', hat = 'none';
  Color furColor = const Color(0xFF8549E8);
  Color tuftColor = const Color(0xFFA7E75B);
  Color bellyColor = const Color(0xFFF1E4FF);
  Color eyeColor = const Color(0xFF83C945);
  Color jacketColor = const Color(0xFF398CB3);
  bool glasses = false, bow = false, _edited = false, _disposed = false;
  bool _demoActive = false;
  Future<void> _writes = Future<void>.value();

  FinnyAppearance() {
    _load();
  }

  String get _activeKey => _demoActive ? _demoKey : _mainKey;

  void _readAppearance(SharedPreferences prefs) {
    palette = 'original';
    jacket = 'none';
    hat = 'none';
    glasses = false;
    bow = false;
    furColor = const Color(0xFF8549E8);
    tuftColor = const Color(0xFFA7E75B);
    bellyColor = const Color(0xFFF1E4FF);
    eyeColor = const Color(0xFF83C945);
    jacketColor = const Color(0xFF398CB3);
    try {
      final data = jsonDecode(
        prefs.getString(_activeKey) ?? '{}',
      ) as Map<String, dynamic>;
      if (palettes.containsKey(data['palette'])) palette = data['palette'];
      if (jackets.containsKey(data['jacket'])) jacket = data['jacket'];
      if (hats.containsKey(data['hat'])) hat = data['hat'];
      glasses = data['glasses'] == true;
      bow = data['bow'] == true;
      if (data['furColor'] is int) furColor = Color(data['furColor'] as int);
      if (data['tuftColor'] is int) tuftColor = Color(data['tuftColor'] as int);
      if (data['bellyColor'] is int) {
        bellyColor = Color(data['bellyColor'] as int);
      }
      if (data['eyeColor'] is int) eyeColor = Color(data['eyeColor'] as int);
      if (data['jacketColor'] is int) {
        jacketColor = Color(data['jacketColor'] as int);
      }
    } catch (_) {
      // Invalid cosmetic data does not affect game progress.
    }
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_edited || _disposed) return;
      _demoActive = prefs.getBool(_demoActiveKey) ?? false;
      _readAppearance(prefs);
    } catch (_) {
      // Missing cosmetic settings must not prevent the game from starting.
    }
  }

  /// Refresh cosmetics after the game engine switches profiles.
  Future<void> syncWithGameProfile() async {
    _edited = true;
    await _writes.catchError((Object _) {});
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    _demoActive = prefs.getBool(_demoActiveKey) ?? false;
    _readAppearance(prefs);
  }

  Future<void> update({
    String? palette,
    String? jacket,
    String? hat,
    bool? glasses,
    bool? bow,
    Color? furColor,
    Color? tuftColor,
    Color? bellyColor,
    Color? eyeColor,
    Color? jacketColor,
  }) {
    _edited = true;
    if (palettes.containsKey(palette)) this.palette = palette!;
    if (jackets.containsKey(jacket)) this.jacket = jacket!;
    if (hats.containsKey(hat)) this.hat = hat!;
    this.glasses = glasses ?? this.glasses;
    this.bow = bow ?? this.bow;
    if (furColor != null ||
        tuftColor != null ||
        bellyColor != null ||
        eyeColor != null) {
      this.palette = 'custom';
    }
    if (jacketColor != null) {
      this.jacket = 'custom';
      this.jacketColor = jacketColor;
    }
    this.furColor = furColor ?? this.furColor;
    this.tuftColor = tuftColor ?? this.tuftColor;
    this.bellyColor = bellyColor ?? this.bellyColor;
    this.eyeColor = eyeColor ?? this.eyeColor;
    notifyListeners();
    final encoded = jsonEncode({
      'palette': this.palette,
      'jacket': this.jacket,
      'hat': this.hat,
      'glasses': this.glasses,
      'bow': this.bow,
      'furColor': this.furColor.toARGB32(),
      'tuftColor': this.tuftColor.toARGB32(),
      'bellyColor': this.bellyColor.toARGB32(),
      'eyeColor': this.eyeColor.toARGB32(),
      'jacketColor': this.jacketColor.toARGB32(),
    });
    final key = _activeKey;
    _writes = _writes.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(key, encoded)) {
        throw StateError('Appearance save failed');
      }
    });
    return _writes;
  }

  Future<void> reset() {
    _edited = true;
    palette = 'original';
    jacket = 'none';
    hat = 'none';
    glasses = false;
    bow = false;
    furColor = const Color(0xFF8549E8);
    tuftColor = const Color(0xFFA7E75B);
    bellyColor = const Color(0xFFF1E4FF);
    eyeColor = const Color(0xFF83C945);
    jacketColor = const Color(0xFF398CB3);
    notifyListeners();
    final key = _activeKey;
    _writes = _writes.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.remove(key)) {
        throw StateError('Appearance reset failed');
      }
    });
    return _writes;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
