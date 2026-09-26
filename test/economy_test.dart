import 'package:flutter_test/flutter_test.dart';
import 'package:finny/data/models/event_models.dart';
import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/game/content/shop_items.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:finny/game/content/goals.dart';
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

  group('Economy & Balance Rules', () {
    test('Initial balance is 50 coins and has 1 day of food', () {
      final state = engine.state;
      expect(state.balance, 50);
      expect(state.savings, 0);
      expect(state.inventory.foodReserveDays, 1);
      expect(state.finny.mood, FinnyMood.happy);
    });

    test('Avatar animation preference persists', () async {
      engine.setAvatarAnimations(false);
      expect(engine.state.settings.animationsEnabled, false);
      await repository.saveGameState(engine.state);
      expect(GameEngine(repository).state.settings.animationsEnabled, false);
      engine.setAvatarAnimations(true);
      await repository.saveGameState(engine.state);
      expect(GameEngine(repository).state.settings.animationsEnabled, true);
    });

    test('Cannot confirm budget plan exceeding balance', () {
      const invalidPlan = BudgetPlan(
        needs: 30,
        wants: 20,
        reserve: 10,
        savings: 10,
        leftover: 0,
      ); // Total = 70 > 50 balance
      final result = engine.confirmBudgetPlan(invalidPlan);
      expect(result, false);
      expect(engine.state.plannedBudget, null);
    });

    test('Can confirm budget plan within balance', () {
      const validPlan = BudgetPlan(
        needs: 15,
        wants: 10,
        reserve: 10,
        savings: 10,
        leftover: 5,
      ); // Total = 50 == 50 balance
      final result = engine.confirmBudgetPlan(validPlan);
      expect(result, true);
      expect(engine.state.plannedBudget?.isConfirmed, true);
    });

    test('Negative categories and replacing a confirmed plan are rejected', () {
      const invalid = BudgetPlan(needs: -5, wants: 0, reserve: 0,
        savings: 0, leftover: 0);
      expect(engine.confirmBudgetPlan(invalid), false);
      const valid = BudgetPlan(needs: 15, wants: 10, reserve: 10,
        savings: 10, leftover: 5);
      expect(engine.confirmBudgetPlan(valid), true);
      expect(engine.confirmBudgetPlan(const BudgetPlan(needs: 0, wants: 50,
        reserve: 0, savings: 0, leftover: 0)), false);
      engine.finishDayAction();
      engine.advanceToNextDay();
      expect(engine.state.plannedBudget, null);
      expect(engine.confirmBudgetPlan(valid), true);
    });

    test('Changing goals preserves saved coins', () {
      expect(kAvailableGoals.length, greaterThanOrEqualTo(3));
      expect(engine.depositToGoal(25), true);
      engine.selectGoal(kAvailableGoals[1].id);
      expect(engine.state.savings, 25);
      expect(engine.state.goal.savedAmount, 25);
      engine.selectGoal(kAvailableGoals[0].id);
      expect(engine.state.goal.savedAmount, 25);
    });

    test('A funded goal is claimed from savings exactly once', () async {
      engine.selectGoal('skate');
      expect(engine.depositToGoal(50), true);
      expect(engine.completeWork(), true);
      expect(engine.depositToGoal(10), true);
      expect(engine.state.savings, 60);
      expect(engine.state.inventory.hasItem('goal_skate'), false);
      expect(engine.claimGoal(), true);
      expect(engine.state.savings, 0);
      expect(engine.state.inventory.hasItem('goal_skate'), true);
      expect(engine.claimGoal(), false);
      expect(engine.state.purchases.last.itemName, 'Турбо-скейт');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repository.loadGameState().inventory.hasItem('goal_skate'), true);
    });

    test('A permanent item cannot be bought twice', () {
      final item = kShopCatalog.firstWhere((i) => i.id == 'cozy_bed');
      expect(engine.buyItem(item), true);
      expect(engine.buyItem(item), false);
      expect(engine.state.balance, 50 - item.price);
    });

    test('A learning task awards once and records its explanation', () async {
      expect(engine.completeFinancialTask('task_day_2', ''), false);
      final before = engine.state.balance;
      expect(engine.completeFinancialTask('task_day_2', 'Еда и накопления'), true);
      expect(engine.completeFinancialTask('task_day_2', 'Вторая попытка'), false);
      expect(engine.state.balance, before + 5);
      expect(engine.state.completedTasks.single.outcomeDescription, 'Еда и накопления');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repository.loadGameState().completedTasks.single.taskId, 'task_day_2');
    });

    test('Purchase decreases balance and updates inventory', () {
      final item = kShopCatalog.firstWhere((i) => i.id == 'food_3'); // 18 coins, +3 food days
      final success = engine.buyItem(item);

      expect(success, true);
      expect(engine.state.balance, 50 - 18);
      expect(engine.state.inventory.foodReserveDays, 1 + 3);
      expect(engine.state.purchases.length, 1);
    });

    test('Cannot buy item if balance is insufficient', () {
      engine.depositToGoal(45); // Balance drops to 5
      final expensiveItem = kShopCatalog.firstWhere((i) => i.id == 'cozy_bed'); // 25 coins
      final success = engine.buyItem(expensiveItem);

      expect(success, false);
      expect(engine.state.balance, 5);
      expect(engine.state.inventory.hasItem('cozy_bed'), false);
    });

    test('Deposit to goal increases savings and updates goal progress', () {
      final success = engine.depositToGoal(25);
      expect(success, true);
      expect(engine.state.balance, 25);
      expect(engine.state.savings, 25);
      expect(engine.state.goal.savedAmount, 25);
      expect(engine.state.goal.visualStageIndex, 1); // 25% = stage 1
    });

    test('Withdrawal from goal safely returns coins to balance', () {
      engine.depositToGoal(30);
      expect(engine.state.savings, 30);

      final success = engine.withdrawFromGoal(10);
      expect(success, true);
      expect(engine.state.balance, 30);
      expect(engine.state.savings, 20);
      expect(engine.state.goal.savedAmount, 20);
    });

    test('Daily work adds guaranteed +10 coins once per day', () {
      final initialBalance = engine.state.balance;
      final workDone = engine.completeWork();

      expect(workDone, true);
      expect(engine.state.balance, initialBalance + 10);
      expect(engine.state.workCompletedToday, true);

      // Second attempt on the same day must be rejected
      final secondWork = engine.completeWork();
      expect(secondWork, false);
      expect(engine.state.balance, initialBalance + 10);
    });

    test('Safety net: Emergency food aid adds 1 food day', () {
      expect(engine.state.inventory.foodReserveDays, 1);
      engine.triggerEmergencyAid();
      expect(engine.state.inventory.foodReserveDays, 2);
    });
  });
}
