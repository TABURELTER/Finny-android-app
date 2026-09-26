import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/event_models.dart';
import '../../data/models/game_state.dart';
import '../../data/models/goal_models.dart';
import '../../data/models/history_models.dart';
import '../../data/models/item_models.dart';
import '../../data/models/task_models.dart';
import '../../data/repositories/game_repository.dart';
import '../content/days.dart';
import '../content/goals.dart';
import '../content/financial_tasks.dart';
import '../content/shop_items.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  throw UnimplementedError(
    'Initialize gameRepositoryProvider in ProviderScope',
  );
});

final gameEngineProvider = StateNotifierProvider<GameEngine, GameState>((ref) {
  final repository = ref.watch(gameRepositoryProvider);
  return GameEngine(repository);
});

class GameEngine extends StateNotifier<GameState> {
  final GameRepository _repository;

  bool get isDemoActive => _repository.isDemoActive;

  GameEngine(this._repository) : super(_repository.loadGameState());

  void _save() {
    _repository.saveGameState(state);
  }

  // --- Утренний запуск дня ---
  void startDay() {
    final currentDay = state.day;
    final config = kDaysConfig.firstWhere(
      (c) => c.day == currentDay,
      orElse: () => kDaysConfig.last,
    );

    int newFood = state.inventory.foodReserveDays;
    FinnyMood newMood = state.finny.mood;
    String newMoodReason = state.finny.moodReason;

    // 1. Потребление еды
    if (newFood > 0) {
      newFood -= 1;
      newMood = FinnyMood.good;
      newMoodReason = 'Финни сыт: покушал свежую еду из запасов!';
    } else {
      newMood = FinnyMood.worried;
      newMoodReason = 'В кладовке нет еды! Финни проголодался и ждёт завтрака.';
    }

    // 2. Начисление дохода
    final newBalance = state.balance + config.baseIncome;

    state = state.copyWith(
      balance: newBalance,
      phase: GamePhase.morning,
      plannedBudget: null,
      inventory: state.inventory.copyWith(foodReserveDays: newFood),
      finny: state.finny.copyWith(mood: newMood, moodReason: newMoodReason),
      workCompletedToday: false,
      forecast: config.forecast,
      dayEarned: config.baseIncome,
      daySpent: 0,
      daySaved: 0,
    );
    _save();
  }

  // --- Подтверждение плана бюджета ---
  bool confirmBudgetPlan(BudgetPlan plan) {
    if (plan.needs < 0 ||
        plan.wants < 0 ||
        plan.reserve < 0 ||
        plan.savings < 0 ||
        plan.leftover < 0 ||
        plan.total > state.balance ||
        state.plannedBudget?.isConfirmed == true) {
      return false; // Превышение доступных средств
    }
    state = state.copyWith(
      plannedBudget: plan.copyWith(isConfirmed: true),
      phase: GamePhase.dayAction,
    );
    _save();
    return true;
  }

  void skipPlanning() {
    state = state.copyWith(phase: GamePhase.dayAction);
    _save();
  }

  // --- Покупка в магазине ---
  bool buyItem(ShopItem item) {
    if (item.price < 0 ||
        state.balance < item.price ||
        (item.isPermanent && state.inventory.hasItem(item.id))) {
      return false;
    }

    final newBalance = state.balance - item.price;
    final newOwned = Set<String>.from(state.inventory.ownedItemIds);
    final newConsumables = Map<String, int>.from(state.inventory.consumables);
    if (item.isPermanent) {
      newOwned.add(item.id);
    } else if (item.foodDaysProvided == 0) {
      newConsumables[item.id] = (newConsumables[item.id] ?? 0) + 1;
    }

    final newFood = state.inventory.foodReserveDays + item.foodDaysProvided;

    // Реакция Финни
    FinnyMood newMood = state.finny.mood;
    String newMoodReason = state.finny.moodReason;

    if (item.category == ItemCategory.want) {
      newMood = FinnyMood.happy;
      newMoodReason = 'Финни в восторге от новой игрушки: ${item.name}!';
    } else if (item.foodDaysProvided > 1) {
      newMood = FinnyMood.good;
      newMoodReason =
          'Запас еды на ${item.foodDaysProvided} дн. пополнен! Можно быть спокойным.';
    } else if (item.id == 'raincoat') {
      newMood = FinnyMood.good;
      newMoodReason = 'Дождевик защитит в любую непогоду!';
    }

    final purchase = PurchaseRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: item.id,
      itemName: item.name,
      cost: item.price,
      day: state.day,
    );

    state = state.copyWith(
      balance: newBalance,
      daySpent: state.daySpent + item.price,
      inventory: state.inventory.copyWith(
        ownedItemIds: newOwned,
        consumables: newConsumables,
        foodReserveDays: newFood,
      ),
      finny: state.finny.copyWith(mood: newMood, moodReason: newMoodReason),
      purchases: [...state.purchases, purchase],
    );
    _save();
    return true;
  }

  // --- Копилка: Взнос ---
  bool depositToGoal(int amount) {
    if (amount <= 0 || state.balance < amount) return false;

    final remainingForGoal = state.goal.targetAmount - state.goal.savedAmount;
    final actualDeposit = amount.clamp(0, remainingForGoal);
    if (actualDeposit <= 0) return false;

    final newBalance = state.balance - actualDeposit;
    final newSaved = state.goal.savedAmount + actualDeposit;
    final isDone = newSaved >= state.goal.targetAmount;

    FinnyMood newMood = state.finny.mood;
    String newMoodReason = state.finny.moodReason;

    if (isDone) {
      newMood = FinnyMood.happy;
      newMoodReason = 'На мечту собрано достаточно! Теперь её можно получить.';
    } else {
      newMood = FinnyMood.good;
      newMoodReason =
          'Отложено $actualDeposit монет в копилку. Мечта всё ближе!';
    }

    state = state.copyWith(
      balance: newBalance,
      savings: state.savings + actualDeposit,
      daySaved: state.daySaved + actualDeposit,
      goal: state.goal.copyWith(savedAmount: newSaved, isCompleted: isDone),
      finny: state.finny.copyWith(mood: newMood, moodReason: newMoodReason),
    );
    _save();
    return true;
  }

  // --- Копилка: Бережное снятие ---
  bool withdrawFromGoal(int amount) {
    if (amount <= 0 || state.goal.savedAmount < amount) return false;

    final newSaved = state.goal.savedAmount - amount;
    final newBalance = state.balance + amount;

    state = state.copyWith(
      balance: newBalance,
      savings: (state.savings - amount).clamp(0, 999999),
      goal: state.goal.copyWith(savedAmount: newSaved, isCompleted: false),
      finny: state.finny.copyWith(
        moodReason:
            'Взято $amount монет из копилки. До цели теперь чуть дольше.',
      ),
    );
    _save();
    return true;
  }

  /// A funded goal is acquired explicitly from the savings balance once.
  /// The reward remains in the local inventory after switching goals.
  bool claimGoal() {
    final goalId = state.goal.goalId;
    final definition = kAvailableGoals.firstWhere(
      (goal) => goal.id == goalId,
      orElse: () => kAvailableGoals.first,
    );
    final itemId = 'goal_$goalId';
    if (state.savings < definition.targetCost ||
        state.inventory.hasItem(itemId)) {
      return false;
    }
    final remaining = state.savings - definition.targetCost;
    state = state.copyWith(
      savings: remaining,
      daySpent: state.daySpent + definition.targetCost,
      goal: state.goal.copyWith(
        savedAmount: remaining,
        isCompleted: remaining >= definition.targetCost,
      ),
      inventory: state.inventory.copyWith(
        ownedItemIds: {...state.inventory.ownedItemIds, itemId},
      ),
      purchases: [
        ...state.purchases,
        PurchaseRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemId: itemId,
          itemName: definition.name,
          cost: definition.targetCost,
          day: state.day,
        ),
      ],
      finny: state.finny.copyWith(
        mood: FinnyMood.happy,
        moodReason:
            '${definition.name} теперь у Финни! Копилка уменьшилась на ${definition.targetCost} монет.',
      ),
    );
    _save();
    return true;
  }

  // --- Выбор цели ---
  void selectGoal(String goalId) {
    final def = kAvailableGoals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => kAvailableGoals.first,
    );

    if (def.id == state.goal.goalId) return;
    // Savings belong to the child, not to a particular goal. A smaller goal
    // can already be complete when the child switches to it.
    final saved = state.savings;
    state = state.copyWith(
      goal: GoalState(
        goalId: def.id,
        savedAmount: saved,
        targetAmount: def.targetCost,
        isCompleted: saved >= def.targetCost,
      ),
    );
    _save();
  }

  // --- Короткое поручение: 10 монет один раз за день ---
  bool completeWork({int reward = 10}) {
    if (state.workCompletedToday || reward <= 0) return false;

    final newBalance = state.balance + reward;
    state = state.copyWith(
      balance: newBalance,
      workCompletedToday: true,
      dayEarned: state.dayEarned + reward,
      finny: state.finny.copyWith(
        mood: FinnyMood.good,
        moodReason:
            'Отличная работа! Соседи довольны, а в кармане +$reward монет!',
      ),
    );
    _save();
    return true;
  }

  /// A learning challenge can award coins once, after the child tests a plan.
  bool completeFinancialTask(String taskId, String outcome) {
    final available = kFinancialTasks.any(
      (task) => task.id == taskId && task.day <= state.day,
    );
    if (!available ||
        outcome.trim().isEmpty ||
        state.completedTasks.any((task) => task.taskId == taskId)) {
      return false;
    }
    const reward = 5;
    state = state.copyWith(
      balance: state.balance + reward,
      dayEarned: state.dayEarned + reward,
      completedTasks: [
        ...state.completedTasks,
        CompletedTask(
          taskId: taskId,
          day: state.day,
          outcomeDescription: outcome.trim(),
        ),
      ],
      finny: state.finny.copyWith(
        mood: FinnyMood.good,
        moodReason: 'За решение финансовой задачи получено 5 монет.',
      ),
    );
    _save();
    return true;
  }

  // --- Завершение дня и переход к событию / сводке ---
  void finishDayAction() {
    if (state.phase == GamePhase.eventResolution ||
        state.phase == GamePhase.eveningSummary ||
        state.phase == GamePhase.finalSummary) {
      return;
    }
    final currentDay = state.day;
    final config = kDaysConfig.firstWhere(
      (c) => c.day == currentDay,
      orElse: () => kDaysConfig.last,
    );

    if (config.scheduledEventId != null) {
      // Запускаем событие дня
      state = state.copyWith(phase: GamePhase.eventResolution);
    } else {
      // Сразу к вечерней сводке
      _prepareEveningSummary();
    }
    _save();
  }

  // --- Разрешение выбора в событии дня ---
  bool resolveEventChoice(
    EventDefinition event,
    EventChoice choice, {
    bool useSavings = false,
  }) {
    if (state.phase != GamePhase.eventResolution ||
        event.triggerDay != state.day ||
        !event.choices.any((option) => option.id == choice.id) ||
        choice.cost < 0 ||
        (choice.requiredItemId != null &&
            !state.inventory.hasItem(choice.requiredItemId!))) {
      return false;
    }
    int cost = choice.cost;
    final newConsumables = Map<String, int>.from(state.inventory.consumables);

    // Если есть предмет для бесплатного устранения (например repair_kit)
    if (choice.freeWithItemId != null &&
        state.inventory.hasItem(choice.freeWithItemId!)) {
      cost = 0;
      final id = choice.freeWithItemId!;
      if ((newConsumables[id] ?? 0) > 0) {
        newConsumables[id] = newConsumables[id]! - 1;
      }
    }

    final fromSavings = (cost - state.balance).clamp(0, cost);
    if (fromSavings > 0 &&
        (!useSavings ||
            event.id != 'rain_roof' ||
            choice.id != 'repair_now' ||
            state.savings < fromSavings ||
            state.goal.savedAmount < fromSavings)) {
      return false;
    }
    if (useSavings && fromSavings == 0) return false;

    final newBalance = state.balance - (cost - fromSavings);
    int newFood = state.inventory.foodReserveDays;
    if (choice.foodReserveChange != null) {
      newFood = (newFood + choice.foodReserveChange!).clamp(0, 9999);
    }

    state = state.copyWith(
      balance: newBalance,
      savings: state.savings - fromSavings,
      daySpent: state.daySpent + cost,
      daySaved: (state.daySaved - fromSavings).clamp(0, 999999),
      goal: fromSavings == 0
          ? state.goal
          : state.goal.copyWith(
              savedAmount: state.goal.savedAmount - fromSavings,
              isCompleted: false,
            ),
      inventory: state.inventory.copyWith(
        foodReserveDays: newFood,
        consumables: newConsumables,
      ),
      finny: state.finny.copyWith(
        mood: choice.moodEffect,
        moodReason: cost == 0 && choice.cost > 0
            ? 'Набор мастера помог починить крышу без новой траты.'
            : fromSavings == 0
            ? choice.consequenceText
            : '${choice.consequenceText} Из копилки взяли $fromSavings монет; до мечты теперь дальше.',
      ),
    );

    _prepareEveningSummary();
    _save();
    return true;
  }

  void _prepareEveningSummary() {
    int needs = 0;
    int wants = 0;
    int reserveSpent = 0;
    int purchaseTotal = 0;
    for (final purchase in state.purchases.where((p) => p.day == state.day)) {
      purchaseTotal += purchase.cost;
      final item = kShopCatalog
          .where((item) => item.id == purchase.itemId)
          .firstOrNull;
      switch (item?.category) {
        case ItemCategory.need:
          needs += purchase.cost;
        case ItemCategory.reserve:
          reserveSpent += purchase.cost;
        case ItemCategory.want:
        case ItemCategory.useful:
        case null:
          wants += purchase.cost;
      }
    }
    // Unexpected event costs belong to the safety reserve.
    reserveSpent += (state.daySpent - purchaseTotal).clamp(0, state.daySpent);
    final plan = state.plannedBudget?.isConfirmed == true
        ? state.plannedBudget
        : null;
    // Формируем нейтральную рефлексию без морализаторства
    String reflection = '';
    if (state.daySaved > 0) {
      reflection += 'Ты отложил ${state.daySaved} монет на мечту. ';
    }
    if (state.inventory.foodReserveDays >= 2) {
      reflection += 'Запас еды на будущее надёжно закрыт. ';
    } else if (state.inventory.foodReserveDays == 0) {
      reflection +=
          'Еда подошла к концу — завтра нужно позаботиться о завтраке. ';
    }
    if (state.daySpent > 0 && state.daySaved == 0) {
      reflection +=
          'Потрачено ${state.daySpent} монет, а в копилку сегодня ничего не добавлено. ';
    }

    if (reflection.isEmpty) {
      reflection = 'Спокойный день. Завтра появятся новые возможности!';
    }

    final summary = DaySummaryRecord(
      day: state.day,
      income: state.dayEarned,
      spent: state.daySpent,
      saved: state.daySaved,
      foodReserve: state.inventory.foodReserveDays,
      mood: state.finny.mood,
      moodReason: state.finny.moodReason,
      reflection: reflection,
      plannedNeeds: plan?.needs,
      plannedWants: plan?.wants,
      plannedReserve: plan?.reserve,
      plannedSavings: plan?.savings,
      actualNeeds: needs,
      actualWants: wants,
      actualReserve: state.balance,
      actualReserveSpent: reserveSpent,
      reserveIsCash: true,
    );

    final nextPhase = (state.day >= 10)
        ? GamePhase.finalSummary
        : GamePhase.eveningSummary;

    state = state.copyWith(
      phase: nextPhase,
      history: [...state.history, summary],
    );
  }

  // --- Переход к новому дню ---
  void advanceToNextDay() {
    if (state.phase != GamePhase.eveningSummary) return;
    if (state.day < 10) {
      final nextDay = state.day + 1;

      // Growth reflects care, consistent plans and real deposits. A single
      // difficult day never takes an already reached stage away.
      final careDays = state.history.where((day) => day.foodReserve > 0).length;
      final planDays = state.history.where((day) => day.followedPlan).length;
      final savingDays = state.history.where((day) => day.saved > 0).length;
      final earnedStage = careDays >= 4 && planDays >= 3 && savingDays >= 3
          ? DevelopmentStage.independent
          : careDays >= 2 && planDays >= 2 && savingDays >= 1
          ? DevelopmentStage.planner
          : DevelopmentStage.start;
      final stage = earnedStage.index > state.finny.stage.index
          ? earnedStage
          : state.finny.stage;
      final grew = stage != state.finny.stage;

      state = state.copyWith(
        day: nextDay,
        finny: state.finny.copyWith(stage: stage),
      );
      startDay();
      if (grew) {
        state = state.copyWith(
          finny: state.finny.copyWith(
            mood: FinnyMood.happy,
            moodReason: stage == DevelopmentStage.independent
                ? 'Финни подрос: ты заботился о нужном, выполнял планы и откладывал на мечту.'
                : 'Финни учится планировать: несколько дней заботы и первый взнос дали результат.',
          ),
        );
        _save();
      }
    } else {
      state = state.copyWith(phase: GamePhase.finalSummary);
      _save();
    }
  }

  // --- Safety Net: Сосед выручает яблоком, если 0 еды и 0 монет ---
  void triggerEmergencyAid() {
    state = state.copyWith(
      inventory: state.inventory.copyWith(
        foodReserveDays: state.inventory.foodReserveDays + 1,
      ),
      finny: state.finny.copyWith(
        mood: FinnyMood.good,
        moodReason:
            'Добрый сосед поделился хрустящим яблоком! Выход есть всегда.',
      ),
    );
    _save();
  }

  // --- Демо-функции для жюри ---
  void jumpToDay(int targetDay) {
    if (targetDay < 1 || targetDay > 10) return;

    if (targetDay == 1) {
      final initial = GameState.initial();
      state = initial.copyWith(profile: state.profile);
      _save();
      return;
    }

    final config = kDaysConfig.firstWhere((c) => c.day == targetDay);
    state = state.copyWith(
      day: targetDay,
      phase: GamePhase.morning,
      forecast: config.forecast,
    );
    startDay();
  }

  void addCoins(int amount) {
    state = state.copyWith(balance: (state.balance + amount).clamp(0, 99999));
    _save();
  }

  void setFinnyMood(FinnyMood mood, String reason) {
    state = state.copyWith(
      finny: state.finny.copyWith(mood: mood, moodReason: reason),
    );
    _save();
  }

  void setAvatarAnimations(bool enabled) {
    state = state.copyWith(
      settings: state.settings.copyWith(animationsEnabled: enabled),
    );
    _save();
  }

  bool completeOnboarding(String petName, String goalId) {
    final name = petName.trim();
    if (name.isEmpty ||
        name.runes.length > 16 ||
        !kAvailableGoals.any((goal) => goal.id == goalId)) {
      return false;
    }
    selectGoal(goalId);
    state = state.copyWith(
      profile: PlayerProfile(
        petName: name,
        startDate: state.profile.startDate,
        onboardingComplete: true,
      ),
    );
    _save();
    return true;
  }

  Future<bool> enterDemo() async {
    if (_repository.isDemoActive || !await _repository.setDemoActive(true)) {
      return false;
    }
    final initial = GameState.initial();
    state = initial.copyWith(
      profile: PlayerProfile(
        petName: 'Финни',
        startDate: initial.profile.startDate,
        onboardingComplete: true,
      ),
    );
    if (await _repository.saveGameState(state)) return true;
    await _repository.setDemoActive(false);
    state = _repository.loadGameState();
    return false;
  }

  Future<bool> exitDemo() async {
    if (!_repository.isDemoActive || !await _repository.setDemoActive(false)) {
      return false;
    }
    state = _repository.loadGameState();
    return true;
  }

  void resetGame() {
    state = GameState.initial();
    _save();
  }
}
