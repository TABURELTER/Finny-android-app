import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/models/task_models.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/adult/adult_screen.dart';
import 'package:finny/features/progress/progress_screen.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameRepository> repository() async {
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    await repo.saveGameState(
      GameState.initial().copyWith(
        day: 2,
        completedTasks: const [
          CompletedTask(
            taskId: 'task_day_4',
            day: 2,
            outcomeDescription: 'По одному: 21 · набор: 18. Я выбрал отдельные завтраки и увидел разницу 3 монеты.',
          ),
        ],
      ),
    );
    return repo;
  }

  testWidgets('Task diary shows the saved decision, not a generic lesson', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await repository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ProgressScreen(initialTab: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Я выбрал отдельные завтраки'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Adult view gives a concrete child decision to discuss', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await (FontLoader('Nunito')
            ..addFont(rootBundle.load('fonts/Nunito-Regular.ttf'))
            ..addFont(rootBundle.load('fonts/Nunito-Bold.ttf')))
          .load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    });
    final repo = await repository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: AdultScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Решения для разговора'), findsOneWidget);
    expect(find.textContaining('Я выбрал отдельные завтраки'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
