import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:finny/main.dart';
import 'package:finny/data/models/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FinnyApp home screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = GameRepository(prefs);
    final initial = GameState.initial();
    await repository.saveGameState(initial.copyWith(profile: PlayerProfile(
      petName: 'Финни', startDate: initial.profile.startDate,
      onboardingComplete: true,
    )));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FinnyApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Проверяем отображение дня и монет
    expect(find.text('День 1'), findsOneWidget);
    expect(find.text('50'), findsOneWidget); // Начальный баланс

    // Проверяем кнопки действий
    expect(find.text('Работа'), findsWidgets);
    expect(find.text('Лавка'), findsOneWidget);
    expect(find.text('План'), findsWidgets);
    expect(find.text('Мечта'), findsOneWidget);
    expect(find.textContaining('Завершить день'), findsOneWidget);
  });
}
