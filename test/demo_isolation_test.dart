import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Demo changes survive restart but never change the main game', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = GameRepository(await SharedPreferences.getInstance());
    final engine = GameEngine(repository);
    expect(engine.completeOnboarding('Лисёнок', 'skate'), true);
    engine.addCoins(17);
    await repository.saveGameState(engine.state);
    expect(engine.state.balance, 67);

    expect(await engine.enterDemo(), true);
    expect(repository.isDemoActive, true);
    expect(engine.state.balance, 50);
    expect(engine.state.profile.onboardingComplete, true);
    engine.jumpToDay(1);
    expect(engine.state.balance, 50);
    engine.addCoins(100);
    await repository.saveGameState(engine.state);

    final reopenedDemo = GameEngine(repository);
    expect(reopenedDemo.isDemoActive, true);
    expect(reopenedDemo.state.balance, 150);
    expect(await reopenedDemo.exitDemo(), true);
    expect(reopenedDemo.state.balance, 67);
    expect(reopenedDemo.state.profile.petName, 'Лисёнок');
    expect(reopenedDemo.state.goal.goalId, 'skate');
    expect(GameEngine(repository).state.balance, 67);
  });
}
