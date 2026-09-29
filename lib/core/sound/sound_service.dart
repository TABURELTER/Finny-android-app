import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/engine/game_engine.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService.instance;
  final settings = ref.watch(
    gameEngineProvider.select((state) => state.settings),
  );
  service.soundEnabled = settings.soundEnabled;
  service.hapticsEnabled = settings.hapticsEnabled;
  service.syncMusicSettings(
    enabled: settings.musicEnabled,
    volume: settings.musicVolume,
  );
  return service;
});

class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._() {
    _player.positionUpdater = null;
    _musicPlayer.positionUpdater = null;
    _initLifecycle();
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  AppLifecycleListener? _lifecycleListener;

  bool soundEnabled = true;
  bool hapticsEnabled = true;
  bool musicEnabled = true;
  double musicVolume = 0.45;
  double get _effectiveMusicVolume => (musicVolume * 0.5).clamp(0.0, 1.0);
  bool _initialized = false;
  bool _musicPlaying = false;
  bool _isAppBackgrounded = false;
  bool _wasPlayingBeforeBackground = false;

  void _initLifecycle() {
    _lifecycleListener ??= AppLifecycleListener(
      onStateChange: _handleLifecycleChange,
    );
  }

  void _handleLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppBackgrounded = false;
        if (_wasPlayingBeforeBackground && musicEnabled && musicVolume > 0.001) {
          _wasPlayingBeforeBackground = false;
          resumeAmbientMusic();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isAppBackgrounded = true;
        if (_musicPlaying) {
          _wasPlayingBeforeBackground = true;
          pauseAmbientMusic();
        }
        break;
    }
  }

  Future<void> _init() async {
    if (_initialized) return;
    try {
      _player.positionUpdater = null;
      _musicPlayer.positionUpdater = null;
      final sfxContext = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );
      await _player.setAudioContext(sfxContext);

      final musicContext = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );
      await _musicPlayer.setAudioContext(musicContext);

      await _player.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);

      // Auto-recover ambient music if interrupted by OS or sound focus
      _musicPlayer.onPlayerStateChanged.listen((state) {
        if (_isAppBackgrounded) return;
        if (state == PlayerState.paused &&
            _musicPlaying &&
            musicEnabled &&
            musicVolume > 0.001) {
          _musicPlayer.resume();
        } else if (state == PlayerState.completed &&
            _musicPlaying &&
            musicEnabled &&
            musicVolume > 0.001) {
          _musicPlayer.play(
            AssetSource('audio/ambient_music.wav'),
            volume: _effectiveMusicVolume,
          );
        }
      });

      _initialized = true;
    } catch (_) {}
  }

  Future<void> syncMusicSettings({
    required bool enabled,
    required double volume,
  }) async {
    musicEnabled = enabled;
    musicVolume = volume.clamp(0.0, 1.0);

    if (!musicEnabled || musicVolume <= 0.001) {
      await pauseAmbientMusic();
    } else {
      if (_isAppBackgrounded) {
        _wasPlayingBeforeBackground = true;
        return;
      }
      try {
        await _musicPlayer.setVolume(_effectiveMusicVolume);
        if (!_musicPlaying) {
          await startAmbientMusic();
        } else {
          await resumeAmbientMusic();
        }
      } catch (_) {}
    }
  }

  Future<void> startAmbientMusic() async {
    if (_isAppBackgrounded) {
      _wasPlayingBeforeBackground = true;
      return;
    }
    if (!musicEnabled || musicVolume <= 0.001) return;
    try {
      await _init();
      await _musicPlayer.setVolume(_effectiveMusicVolume);
      _musicPlaying = true;
      await _musicPlayer.play(
        AssetSource('audio/ambient_music.wav'),
        volume: _effectiveMusicVolume,
      );
    } catch (_) {}
  }

  Future<void> pauseAmbientMusic() async {
    _musicPlaying = false;
    try {
      await _musicPlayer.pause();
    } catch (_) {}
  }

  Future<void> resumeAmbientMusic() async {
    if (_isAppBackgrounded) return;
    if (!musicEnabled || musicVolume <= 0.001) return;
    try {
      await _init();
      await _musicPlayer.setVolume(_effectiveMusicVolume);
      _musicPlaying = true;
      if (_musicPlayer.state == PlayerState.paused) {
        await _musicPlayer.resume();
      } else if (_musicPlayer.state != PlayerState.playing) {
        await _musicPlayer.play(
          AssetSource('audio/ambient_music.wav'),
          volume: _effectiveMusicVolume,
        );
      }
    } catch (_) {
      await startAmbientMusic();
    }
  }

  Future<void> stopAmbientMusic() async {
    _musicPlaying = false;
    _wasPlayingBeforeBackground = false;
    try {
      await _musicPlayer.stop();
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
    _lifecycleListener?.dispose();
    _player.dispose();
    _musicPlayer.dispose();
  }
}
