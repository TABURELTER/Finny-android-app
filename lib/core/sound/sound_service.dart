import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/engine/game_engine.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService.instance;
  final settings = ref.watch(
    gameEngineProvider.select((state) => state.settings),
  );
  service.soundEnabled = settings.soundEnabled;
  service.hapticsEnabled = settings.hapticsEnabled;
  return service;
});

class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  bool soundEnabled = true;
  bool hapticsEnabled = true;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      _initialized = true;
    } catch (_) {}
  }

  Future<void> playCoin() async {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/coin.wav'), volume: 0.9);
    } catch (_) {}
  }

  Future<void> playTap() async {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/tap.wav'), volume: 0.55);
    } catch (_) {}
  }

  Future<void> playSuccess() async {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/success.wav'), volume: 0.9);
    } catch (_) {}
  }

  Future<void> playWarning() async {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/warning.wav'), volume: 0.85);
    } catch (_) {}
  }

  Future<void> playHappy() async {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/happy.wav'), volume: 0.85);
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
