import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import '../../game/content/days.dart';
import '../../game/content/goals.dart';

class GameRepository {
  static const String _kGameStateKey = 'finny_game_state_v1';
  static const String _kDemoStateKey = 'finny_demo_state_v1';
  static const String _kDemoActiveKey = 'finny_demo_active_v1';
  final SharedPreferences _prefs;
  Future<void> _writes = Future<void>.value();

  bool get isDemoActive => _prefs.getBool(_kDemoActiveKey) ?? false;

  String get _activeStateKey => isDemoActive ? _kDemoStateKey : _kGameStateKey;

  GameRepository(this._prefs);

  static Future<GameRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    return GameRepository(prefs);
  }

  Future<bool> saveGameState(GameState state) async {
    try {
      final jsonString = jsonEncode(state.toJson());
      final key = _activeStateKey;
      final write = _writes.then((_) => _prefs.setString(key, jsonString));
      _writes = write.then<void>((_) {}, onError: (Object _) {});
      return await write;
    } catch (e) {
      return false;
    }
  }

  GameState loadGameState() {
    try {
      final jsonString = _prefs.getString(_activeStateKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final loaded = GameState.fromJson(jsonMap);
        final currentGoal = kAvailableGoals.firstWhere(
          (goal) => goal.id == loaded.goal.goalId,
          orElse: () => kAvailableGoals.first,
        );
        // Earlier versions stored the old price with each profile. Keep every
        // earned coin and acquired reward, but use the current price for the
        // active goal so the balance and goal screen agree after an update.
        final oldDayTenForecast =
            loaded.day == 10 && loaded.forecast.title == 'Торжественный день';
        if (loaded.goal.targetAmount != currentGoal.targetCost ||
            loaded.goal.savedAmount != loaded.savings ||
            oldDayTenForecast) {
          final migrated = loaded.copyWith(
            goal: loaded.goal.copyWith(
              targetAmount: currentGoal.targetCost,
              savedAmount: loaded.savings,
              isCompleted: loaded.savings >= currentGoal.targetCost,
            ),
            forecast: oldDayTenForecast
                ? dayConfigFor(10).forecast
                : loaded.forecast,
          );
          saveGameState(migrated);
          return migrated;
        }
        return loaded;
      }
    } catch (e) {
      // Fallback to initial state on corruption
    }
    return GameState.initial();
  }

  Future<bool> clearGameState() async {
    final key = _activeStateKey;
    final write = _writes.then((_) => _prefs.remove(key));
    _writes = write.then<void>((_) {}, onError: (Object _) {});
    return write;
  }

  Future<bool> setDemoActive(bool enabled) async {
    try {
      await _writes;
      return await _prefs.setBool(_kDemoActiveKey, enabled);
    } catch (_) {
      return false;
    }
  }
}
