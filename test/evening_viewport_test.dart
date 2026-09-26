import 'package:finny/core/theme/finny_tokens.dart';
import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/models/history_models.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/events/compact_evening_summary.dart';
import 'package:finny/game/content/shop_items.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Evening review and next day fit 360×640', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    final engine = GameEngine(repo);
    engine.finishDayAction();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Scaffold(body: CompactEveningSummary())),
      ),
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('Начать день 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Evening amounts explain income, spending, and saved cash', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    final engine = GameEngine(repo);
    expect(
      engine.confirmBudgetPlan(
        const BudgetPlan(
          needs: 7,
          wants: 0,
          reserve: 20,
          savings: 5,
          leftover: 18,
        ),
      ),
      isTrue,
    );
    expect(engine.completeWork(), isTrue);
    expect(
      engine.buyItem(kShopCatalog.firstWhere((item) => item.id == 'food_3')),
      isTrue,
    );
    expect(engine.depositToGoal(5), isTrue);
    engine.finishDayAction();
    await repo.saveGameState(engine.state);
    expect(repo.loadGameState().history.last.income, 60);
    expect(repo.loadGameState().history.last.spent, 18);
    expect(repo.loadGameState().history.last.saved, 5);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Scaffold(body: CompactEveningSummary())),
      ),
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('Получено'), findsOneWidget);
    expect(find.text('+60'), findsOneWidget);
    expect(find.text('Потрачено'), findsOneWidget);
    expect(find.text('-18'), findsOneWidget);
    expect(find.text('В копилку'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('+60')).style?.color,
      FinnyColors.success,
    );
    expect(
      tester.widget<Text>(find.text('-18')).style?.color,
      const Color(0xFFAD3B4C),
    );
    expect(
      tester.widget<Text>(find.text('+5')).style?.color,
      FinnyColors.primaryDark,
    );
    expect(find.text('Денежный запас'), findsOneWidget);
    expect(find.text('Осталось 37 · использовано 18'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Old history keeps its original reserve-spending meaning', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    final initial = GameState.initial();
    final oldSummary = DaySummaryRecord(
      day: 1,
      income: 50,
      spent: 4,
      saved: 0,
      foodReserve: 1,
      mood: initial.finny.mood,
      moodReason: initial.finny.moodReason,
      reflection: 'Покупка из запаса.',
      plannedNeeds: 10,
      plannedWants: 10,
      plannedReserve: 20,
      plannedSavings: 10,
      actualReserve: 4,
      reserveIsCash: false,
    );
    await repo.saveGameState(
      initial.copyWith(phase: GamePhase.eveningSummary, history: [oldSummary]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Scaffold(body: CompactEveningSummary())),
      ),
    );
    expect(find.text('Запас'), findsOneWidget);
    expect(find.text('план 20 · факт 4'), findsOneWidget);
    expect(find.text('Денежный запас'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
