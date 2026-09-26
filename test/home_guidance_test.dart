import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/models/task_models.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/home/widgets/compact_home_dashboard.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:finny/shared/widgets/finny_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('A toy purchase does not complete the food step', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await (FontLoader('Nunito')
            ..addFont(rootBundle.load('fonts/Nunito-Regular.ttf'))
            ..addFont(rootBundle.load('fonts/Nunito-Bold.ttf'))
            ..addFont(rootBundle.load('fonts/Nunito-Black.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    final initial = GameState.initial();
    final scenario = initial.copyWith(
      balance: 40,
      daySpent: 10,
      phase: GamePhase.dayAction,
      inventory: initial.inventory.copyWith(foodReserveDays: 1),
      plannedBudget: const BudgetPlan(
        needs: 15,
        wants: 5,
        reserve: 10,
        savings: 15,
        leftover: 5,
        isConfirmed: true,
      ),
      workCompletedToday: true,
      completedTasks: const [
        CompletedTask(
          taskId: 'task_day_2',
          day: 1,
          outcomeDescription: 'Готово',
        ),
      ],
    );
    await repo.saveGameState(scenario);
    var openedShop = false;
    void noop() {}
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: CompactHomeDashboard(
              state: scenario,
              wardrobe: noop,
              pet: noop,
              work: noop,
              shop: () => openedShop = true,
              plan: noop,
              goal: noop,
              task: noop,
              finish: noop,
              guide: noop,
              adult: noop,
              progress: noop,
              demo: noop,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => FinnySvg.assets);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Купим еду на завтра'), findsOneWidget);
    expect(find.text('Один завтрак стоит 7 монет'), findsOneWidget);
    await tester.tap(find.text('Купим еду на завтра'));
    expect(openedShop, isTrue);
    expect(tester.takeException(), isNull);
  });
}
