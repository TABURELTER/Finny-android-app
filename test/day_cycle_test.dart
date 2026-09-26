import 'package:flutter_test/flutter_test.dart';
import 'package:finny/data/models/event_models.dart';
import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/models/history_models.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/game/content/events.dart';
import 'package:finny/game/content/shop_items.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameRepository repository;
  late GameEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = GameRepository(prefs);
    engine = GameEngine(repository);
  });

  group('Day Cycle & Consequences', () {
    test('Advancing day consumes food and credits daily income', () {
      expect(engine.state.day, 1);
      expect(engine.state.inventory.foodReserveDays, 1);

      // Finish Day 1
      engine.finishDayAction();
      expect(engine.state.phase, GamePhase.eveningSummary);
      expect(engine.state.history.length, 1);

      // Advance to Day 2
      engine.advanceToNextDay();
      expect(engine.state.day, 2);
      expect(engine.state.inventory.foodReserveDays, 0); // Consumed 1 day
      expect(engine.state.balance, 50 + 10); // Day 2 income is 10
    });

    test('Finny becomes worried when food runs out', () {
      // Day 1 to Day 2 (food drops to 0)
      engine.finishDayAction();
      engine.advanceToNextDay();
      expect(engine.state.inventory.foodReserveDays, 0);

      // Day 2 to Day 3 with 0 food
      engine.finishDayAction();
      engine.advanceToNextDay();
      expect(engine.state.day, 3);
      expect(engine.state.inventory.foodReserveDays, 0);
      expect(engine.state.finny.mood, FinnyMood.worried);
      expect(engine.state.finny.moodReason.contains('нет еды'), true);
    });

    test('Day 5 triggers rain & roof event', () {
      engine.jumpToDay(5);
      expect(engine.state.day, 5);

      engine.finishDayAction();
      expect(engine.state.phase, GamePhase.eventResolution);

      // Choose repair
      final event = kGameEvents.firstWhere((e) => e.id == 'rain_roof');
      final choice = event.choices.firstWhere(
        (c) => c.id == 'repair_now',
      ); // 25 coins
      final initialBalance = engine.state.balance;

      final success = engine.resolveEventChoice(event, choice);
      expect(success, true);
      expect(engine.state.balance, initialBalance - 25);
      expect(engine.state.phase, GamePhase.eveningSummary);
    });

    test('Repair kit prevents event cost and is consumed once', () {
      final kit = kShopCatalog.firstWhere((item) => item.id == 'repair_kit');
      expect(engine.buyItem(kit), true);
      expect(engine.state.inventory.hasItem('repair_kit'), true);
      engine.jumpToDay(5);
      engine.finishDayAction();
      final event = kGameEvents.firstWhere((event) => event.id == 'rain_roof');
      final repair = event.choices.firstWhere(
        (choice) => choice.id == 'repair_now',
      );
      final before = engine.state.balance;
      expect(engine.resolveEventChoice(event, repair), true);
      expect(engine.state.balance, before);
      expect(engine.state.inventory.hasItem('repair_kit'), false);
      expect(engine.state.history.last.actualReserve, before);
      expect(engine.state.history.last.actualReserveSpent, 0);
      expect(engine.state.finny.moodReason, contains('без новой траты'));
    });

    test(
      'Rain repair uses the piggy bank only after explicit consent',
      () async {
        final initial = GameState.initial();
        await repository.saveGameState(
          initial.copyWith(
            day: 5,
            phase: GamePhase.eventResolution,
            balance: 5,
            savings: 20,
            goal: initial.goal.copyWith(savedAmount: 20),
          ),
        );
        engine = GameEngine(repository);
        final event = kGameEvents.firstWhere((item) => item.id == 'rain_roof');
        final repair = event.choices.firstWhere(
          (item) => item.id == 'repair_now',
        );

        expect(engine.resolveEventChoice(event, repair), false);
        expect(engine.state.balance, 5);
        expect(engine.state.savings, 20);
        expect(engine.state.history, isEmpty);

        expect(
          engine.resolveEventChoice(event, repair, useSavings: true),
          true,
        );
        expect(engine.state.balance, 0);
        expect(engine.state.savings, 0);
        expect(engine.state.goal.savedAmount, 0);
        expect(engine.state.daySpent, 25);
        expect(engine.state.history.length, 1);
        expect(
          engine.resolveEventChoice(event, repair, useSavings: true),
          false,
        );
      },
    );

    test('Day 10 leads to final summary', () {
      engine.jumpToDay(10);
      engine.finishDayAction();
      expect(engine.state.phase, GamePhase.finalSummary);
    });

    test(
      'Five consecutive days retain plan versus actual and grow Finny',
      () async {
        final apple = kShopCatalog.firstWhere((item) => item.id == 'food_1');
        for (var day = 1; day <= 5; day++) {
          expect(engine.state.day, day);
          expect(engine.state.plannedBudget, null);
          final plan = BudgetPlan(
            needs: 7,
            wants: 0,
            reserve: 8,
            savings: 5,
            leftover: engine.state.balance - 20,
          );
          expect(engine.confirmBudgetPlan(plan), true);
          expect(engine.buyItem(apple), true);
          expect(engine.depositToGoal(5), true);
          engine.finishDayAction();
          if (day == 5) {
            final event = kGameEvents.firstWhere(
              (event) => event.id == 'rain_roof',
            );
            final patch = event.choices.firstWhere(
              (choice) => choice.id == 'patch_roof',
            );
            expect(engine.resolveEventChoice(event, patch), true);
          }
          expect(engine.state.history.length, day);
          final summary = engine.state.history.last;
          expect(summary.plannedNeeds, 7);
          expect(summary.actualNeeds, 7);
          expect(summary.actualWants, 0);
          expect(summary.saved, 5);
          expect(summary.followedPlan, true);
          if (day < 5) engine.advanceToNextDay();
        }
        expect(engine.state.finny.stage, DevelopmentStage.independent);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        final restored = repository.loadGameState();
        expect(restored.history.length, 5);
        expect(restored.finny.stage, DevelopmentStage.independent);
        expect(restored.history.last.actualReserve, 22);
        expect(restored.history.last.actualReserveSpent, 8);
        expect(restored.history.last.reserveIsCash, true);
      },
    );

    test('Unspent coins stay visible as cash reserve in the evening', () {
      expect(
        engine.confirmBudgetPlan(
          const BudgetPlan(
            needs: 15,
            wants: 10,
            reserve: 20,
            savings: 5,
            leftover: 0,
          ),
        ),
        true,
      );
      expect(
        engine.buyItem(kShopCatalog.firstWhere((item) => item.id == 'food_1')),
        true,
      );
      expect(engine.depositToGoal(5), true);
      engine.finishDayAction();

      final summary = engine.state.history.last;
      expect(engine.state.balance, 38);
      expect(summary.actualReserve, 38);
      expect(summary.actualReserveSpent, 0);
      expect(summary.followedPlan, true);
    });

    test('Food bought for later is shown as reserve used, not cash left', () {
      expect(
        engine.confirmBudgetPlan(
          const BudgetPlan(
            needs: 0,
            wants: 0,
            reserve: 18,
            savings: 0,
            leftover: 32,
          ),
        ),
        true,
      );
      expect(
        engine.buyItem(kShopCatalog.firstWhere((item) => item.id == 'food_3')),
        true,
      );
      engine.finishDayAction();

      final summary = engine.state.history.last;
      expect(summary.actualReserve, 32);
      expect(summary.actualReserveSpent, 18);
      expect(summary.actualNeeds, 0);
      expect(summary.followedPlan, true);
    });

    test('Older saved days keep their old reserve-spending meaning', () {
      expect(
        engine.confirmBudgetPlan(
          const BudgetPlan(
            needs: 7,
            wants: 0,
            reserve: 8,
            savings: 5,
            leftover: 30,
          ),
        ),
        true,
      );
      expect(
        engine.buyItem(kShopCatalog.firstWhere((item) => item.id == 'food_1')),
        true,
      );
      expect(engine.depositToGoal(5), true);
      engine.finishDayAction();
      final oldJson = engine.state.history.last.toJson()
        ..remove('reserveIsCash')
        ..remove('actualReserveSpent')
        ..['actualReserve'] = 8;
      final restored = DaySummaryRecord.fromJson(oldJson);
      expect(restored.reserveIsCash, false);
      expect(restored.actualReserve, 8);
      expect(restored.followedPlan, true);
    });
  });
}
