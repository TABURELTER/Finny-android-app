import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final finnyAppearanceProvider =
    ChangeNotifierProvider((ref) => FinnyAppearance());

class FinnyAppearance extends ChangeNotifier {
  static const _mainKey = 'finny_appearance_v1';
  static const _demoKey = 'finny_demo_appearance_v1';
  static const _demoActiveKey = 'finny_demo_active_v1';
  static const palettes = {
    'original': 'Лесная магия',
    'lagoon': 'Лагуна',
    'apricot': 'Абрикос',
  };
  static const jackets = {
    'none': 'Без куртки',
    'blue': 'Синяя',
    'coral': 'Коралловая',
    'mint': 'Мятная',
  };
  static const hats = {
    'none': 'Без шапки',
    'beanie': 'С помпоном',
    'beret': 'Берет',
  };

  String palette = 'original', jacket = 'none', hat = 'none';
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
    try {
      final data = jsonDecode(prefs.getString(_activeKey) ?? '{}')
          as Map<String, dynamic>;
      if (palettes.containsKey(data['palette'])) palette = data['palette'];
      if (jackets.containsKey(data['jacket'])) jacket = data['jacket'];
      if (hats.containsKey(data['hat'])) hat = data['hat'];
      glasses = data['glasses'] == true;
      bow = data['bow'] == true;
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
  }) {
    _edited = true;
    if (palettes.containsKey(palette)) this.palette = palette!;
    if (jackets.containsKey(jacket)) this.jacket = jacket!;
    if (hats.containsKey(hat)) this.hat = hat!;
    this.glasses = glasses ?? this.glasses;
    this.bow = bow ?? this.bow;
    notifyListeners();
    final encoded = jsonEncode({
      'palette': this.palette,
      'jacket': this.jacket,
      'hat': this.hat,
      'glasses': this.glasses,
      'bow': this.bow,
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
