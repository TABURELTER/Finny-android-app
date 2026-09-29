import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

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
import '../content/balance_cards.dart';

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
  bool get _dayPlanned => state.plannedBudget?.isConfirmed == true;
  bool get _dayActionsOpen =>
      _dayPlanned &&
      (state.phase == GamePhase.dayAction || state.phase == GamePhase.morning);

  GameEngine(this._repository) : super(_repository.loadGameState());

  void _save() {
    _repository.saveGameState(state);
  }

  // --- Утренний запуск дня ---
  void startDay() {
    final currentDay = state.day;
    final config = dayConfigFor(currentDay);

    final previous = state.balanceStats;
    final neglectedNeeds = previous.satiety <= 1 || previous.energy <= 1;
    final strainedNeeds = previous.satiety <= 2 || previous.energy <= 2;
    final nextBalance = previous.change(
      satiety: -0.75,
      energy: 0.75,
      wellbeing: neglectedNeeds
          ? -1
          : strainedNeeds
          ? -0.5
          : 0,
      cardsToday: 0,
    );
    final newBalance = state.balance + config.baseIncome;

    state = state.copyWith(
      balance: newBalance,
      phase: GamePhase.planning,
      plannedBudget: null,
      balanceStats: nextBalance,
      finny: state.finny.copyWith(
        mood:
            nextBalance.satiety <= 1 ||
                nextBalance.energy <= 1 ||
                nextBalance.wellbeing <= 1
            ? FinnyMood.worried
            : FinnyMood.good,
        moodReason: nextBalance.wellbeing <= 1
            ? 'Мне нехорошо. Сегодня начнём с заботы и отдыха.'
            : nextBalance.satiety <= 1
            ? 'Я проголодался. Давай выберем еду?'
            : nextBalance.energy <= 1
            ? 'Сегодня мне нужно отдохнуть и набраться сил.'
            : strainedNeeds
            ? 'Вчера мне не хватило еды или отдыха. Сегодня побережём здоровье.'
            : finnyMorningGreeting(currentDay),
      ),
      workCompletedToday: false,
      roomActivityUsedToday: false,
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
        plan.total != state.balance ||
        state.plannedBudget?.isConfirmed == true ||
        (state.phase != GamePhase.planning &&
            state.phase != GamePhase.morning &&
            state.phase != GamePhase.dayAction)) {
      return false; // Превышение доступных средств
    }
    state = state.copyWith(
      plannedBudget: plan.copyWith(isConfirmed: true),
      phase: GamePhase.dayAction,
    );
    _save();
    return true;
  }

  /// Resolves one of the two visible decisions on the current card.
  bool chooseBalanceCard(String cardId, String choiceId) {
    if (!_dayPlanned ||
        state.phase != GamePhase.dayAction &&
            state.phase != GamePhase.morning) {
      return false;
    }
    final card = balanceCardFor(state);
    if (card == null || card.id != cardId) return false;
    final matches = card.choices.where((choice) => choice.id == choiceId);
    if (matches.isEmpty) return false;
    final choice = matches.first;
    if (choice.opensWork ||
        (choice.useSavings
            ? state.savings + choice.coins < 0 ||
                  state.goal.savedAmount + choice.coins < 0
            : state.balance + choice.coins < 0) ||
        (choice.fromPantry && state.inventory.foodReserveDays == 0)) {
      return false;
    }

    final oldBalance = state.balanceStats;
    final repeatedMeal =
        choice.meal != null && choice.meal == oldBalance.lastMeal;
    final wellbeingGain = repeatedMeal && choice.wellbeing > 0
        ? 0.0
        : choice.wellbeing;
    final nextBalance = oldBalance.change(
      satiety: choice.satiety,
      energy: choice.energy,
      wellbeing: wellbeingGain,
      cardsToday: oldBalance.cardsToday + 1,
      lastMeal: choice.meal,
      repeatMeals: choice.meal == null
          ? null
          : repeatedMeal
          ? oldBalance.repeatMeals + 1
          : 0,
    );
    state = state.copyWith(
      phase: GamePhase.dayAction,
      balance: state.balance + (choice.useSavings ? 0 : choice.coins),
      savings: choice.useSavings ? state.savings + choice.coins : state.savings,
      goal: choice.useSavings
          ? state.goal.copyWith(
              savedAmount: state.goal.savedAmount + choice.coins,
              isCompleted: false,
            )
          : state.goal,
      daySaved: choice.useSavings
          ? (state.daySaved + choice.coins).clamp(0, 999999)
          : state.daySaved,
      daySpent: state.daySpent + (choice.coins < 0 ? -choice.coins : 0),
      purchases: choice.coins < 0 && (choice.meal != null || choice.id == 'buy')
          ? [
              ...state.purchases,
              PurchaseRecord(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                itemId: choice.meal == null
                    ? 'joy_${card.id}'
                    : 'meal_${choice.meal}',
                itemName: choice.title,
                cost: -choice.coins,
                day: state.day,
              ),
            ]
          : state.purchases,
      inventory: choice.fromPantry
          ? state.inventory.copyWith(
              foodReserveDays: state.inventory.foodReserveDays - 1,
            )
          : state.inventory,
      balanceStats: nextBalance,
      finny: state.finny.copyWith(
        mood:
            nextBalance.satiety <= 1 ||
                nextBalance.energy <= 1 ||
                nextBalance.wellbeing <= 1 ||
                choice.wellbeing < 0
            ? FinnyMood.worried
            : choice.wellbeing > 0
            ? FinnyMood.happy
            : FinnyMood.good,
        moodReason: repeatedMeal && choice.wellbeing > 0
            ? '${choice.title}: вкусно, но разнообразия сегодня не хватило.'
            : choice.meal != null
            ? 'Вкусно! Теперь можно подумать о новых делах.'
            : choice.wellbeing > 0 && choice.energy < 0
            ? 'Было весело! А теперь хочется немного отдохнуть.'
            : choice.energy > 0
            ? 'Спасибо за передышку! У меня снова есть силы.'
            : choice.wellbeing < 0
            ? 'Мне стало хуже. Давай позаботимся о здоровье.'
            : 'Хороший выбор! Что будем делать дальше?',
      ),
    );
    _save();
    return true;
  }

  /// A purchased room object becomes one playable action per day.
  bool interactRoomItem(String itemId) {
    if (!_dayPlanned ||
        !state.inventory.hasItem(itemId) ||
        state.roomActivityUsedToday ||
        state.balanceStats.cardsToday >= 4 ||
        (state.phase != GamePhase.dayAction &&
            state.phase != GamePhase.morning)) {
      return false;
    }
    final rainy = RegExp('дожд|ливень')
        .hasMatch(state.forecast.title.toLowerCase());
    if (itemId == 'kite' && rainy) return false;
    final effect = switch (itemId) {
      'toy_ball' => (-1.5, 0.75, 'Игра с мячом подняла настроение!'),
      'toy_robot' => (-0.5, 0.5, 'Робот развеселил Финни!'),
      'cozy_bed' => (1.5, 0.0, 'На лежанке Финни восстановил силы.'),
      'warm_lamp' => (0.0, 0.25, 'У тёплой лампы стало уютнее.'),
      'kite' => (-1.5, 0.75, 'Змей взлетел, и Финни счастлив!'),
      _ => null,
    };
    if (effect == null) return false;
    final (energy, wellbeing, reason) = effect;
    final nextStats = state.balanceStats.change(
      energy: energy,
      wellbeing: wellbeing,
      cardsToday: state.balanceStats.cardsToday + 1,
    );
    state = state.copyWith(
      roomActivityUsedToday: true,
      balanceStats: nextStats,
      finny: state.finny.copyWith(
        mood: nextStats.energy <= 1 || nextStats.wellbeing <= 1
            ? FinnyMood.worried
            : FinnyMood.happy,
        moodReason: nextStats.energy <= 1
            ? '$reason Теперь мне нужен отдых.'
            : reason,
      ),
    );
    _save();
    return true;
  }

  // --- Покупка в магазине ---
  bool buyItem(ShopItem item) {
    if (!_dayActionsOpen ||
        item.price < 0 ||
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
      newMoodReason = '${state.profile.petName} в восторге от новой игрушки: ${item.name}!';
    } else if (item.foodDaysProvided > 1) {
      newMood = FinnyMood.good;
      newMoodReason =
          'В кладовке стало на ${item.foodDaysProvided} порции больше!';
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
    if (!_dayActionsOpen || amount <= 0 || state.balance < amount) {
      return false;
    }

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
      newMoodReason = 'Отложено $actualDeposit 🪙 в копилку. Мечта всё ближе!';
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
    if (!_dayActionsOpen || amount <= 0 || state.goal.savedAmount < amount) {
      return false;
    }

    final newSaved = state.goal.savedAmount - amount;
    final newBalance = state.balance + amount;

    state = state.copyWith(
      balance: newBalance,
      savings: (state.savings - amount).clamp(0, 999999),
      daySaved: (state.daySaved - amount).clamp(0, 999999),
      goal: state.goal.copyWith(savedAmount: newSaved, isCompleted: false),
      finny: state.finny.copyWith(
        moodReason: 'Взято $amount 🪙 из копилки. До цели теперь чуть дольше.',
      ),
    );
    _save();
    return true;
  }

  /// A funded goal is acquired explicitly from the savings balance once.
  /// The reward remains in the local inventory after switching goals.
  bool claimGoal() {
    if (!_dayActionsOpen) return false;
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
      balanceStats: state.balanceStats.change(wellbeing: 2, energy: 1),
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
            '${definition.name} теперь у ${state.profile.petName}! Копилка уменьшилась на ${definition.targetCost} 🪙.',
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

  // --- Короткое поручение: 10 🪙 один раз за день ---
  bool completeWork({int reward = 10}) {
    if (!_dayPlanned ||
        state.workCompletedToday ||
        reward <= 0 ||
        (state.phase != GamePhase.dayAction &&
            state.phase != GamePhase.morning) ||
        state.balanceStats.cardsToday >= 4) {
      return false;
    }

    final newBalance = state.balance + reward;
    final impact = workImpact(state.balanceStats);
    final nextStats = state.balanceStats.change(
      satiety: impact.satiety,
      energy: impact.energy,
      wellbeing: impact.wellbeing,
      cardsToday: state.balanceStats.cardsToday + 1,
    );
    state = state.copyWith(
      balance: newBalance,
      workCompletedToday: true,
      balanceStats: nextStats,
      dayEarned: state.dayEarned + reward,
      finny: state.finny.copyWith(
        mood:
            nextStats.satiety <= 1 ||
                nextStats.energy <= 1 ||
                nextStats.wellbeing <= 1
            ? FinnyMood.worried
            : FinnyMood.good,
        moodReason: nextStats.satiety <= 1 || nextStats.energy <= 1
            ? 'Спасибо за помощь! +$reward 🪙. Я потратил силы, мне нужны еда и отдых.'
            : 'Спасибо за помощь! +$reward 🪙. После работы я немного устал.',
      ),
    );
    _save();
    return true;
  }

  /// A learning challenge can award coins once, after the child tests a plan.
  bool completeFinancialTask(String taskId, String outcome) {
    final available = kFinancialTasks.any(
      (task) => task.id == taskId && (isDemoActive || task.day <= state.day),
    );
    if (!available ||
        state.phase == GamePhase.eveningSummary ||
        state.phase == GamePhase.finalSummary ||
        outcome.trim().isEmpty ||
        state.completedTasks.any((task) => task.taskId == taskId)) {
      return false;
    }
    const reward = 3;
    state = state.copyWith(
      balance: state.balance + reward,
      dayEarned: state.dayEarned + reward,
      balanceStats: state.balanceStats.change(wellbeing: 1),
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
        moodReason: 'Задача решена! +3 🪙, и я чувствую себя лучше.',
      ),
    );
    _save();
    return true;
  }

  // --- Завершение дня и переход к событию / сводке ---
  void finishDayAction() {
    if (!_dayPlanned ||
        state.phase == GamePhase.eventResolution ||
        state.phase == GamePhase.eveningSummary ||
        state.phase == GamePhase.finalSummary) {
      return;
    }
    final currentDay = state.day;
    final config = dayConfigFor(currentDay);

    if (config.scheduledEventId != null &&
        !state.activeEvents.contains(config.scheduledEventId)) {
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
    final wasEveningEvent = state.phase == GamePhase.eventResolution;
    if (!_dayPlanned ||
        !wasEveningEvent &&
            state.phase != GamePhase.dayAction &&
            state.phase != GamePhase.morning) {
      return false;
    }
    if (state.activeEvents.contains(event.id) ||
        event.triggerDay != state.day ||
        !event.choices.any((option) => option.id == choice.id) ||
        choice.cost < 0 ||
        choice.reward < 0 ||
        (choice.requiredItemId != null &&
            !state.inventory.hasItem(choice.requiredItemId!))) {
      return false;
    }
    if (choice.grantItemId != null &&
        state.inventory.hasItem(choice.grantItemId!)) {
      return false;
    }
    int cost = choice.cost;
    final newConsumables = Map<String, int>.from(state.inventory.consumables);
    final newOwned = Set<String>.from(state.inventory.ownedItemIds);
    if (choice.grantItemId != null) {
      final itemId = choice.grantItemId!;
      final item = kShopCatalog
          .where((entry) => entry.id == itemId)
          .firstOrNull;
      if (item?.isPermanent == true) {
        newOwned.add(itemId);
      } else {
        newConsumables[itemId] = (newConsumables[itemId] ?? 0) + 1;
      }
    }

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

    final newBalance = state.balance - (cost - fromSavings) + choice.reward;
    int newFood = state.inventory.foodReserveDays;
    if (choice.foodReserveChange != null) {
      newFood = (newFood + choice.foodReserveChange!).clamp(0, 9999);
    }

    state = state.copyWith(
      balance: newBalance,
      activeEvents: [...state.activeEvents, event.id],
      phase: wasEveningEvent ? GamePhase.eventResolution : GamePhase.dayAction,
      balanceStats: state.balanceStats.change(
        satiety: choice.satiety.toDouble(),
        energy: choice.energy.toDouble(),
        wellbeing: choice.wellbeing.toDouble(),
        cardsToday: (state.balanceStats.cardsToday + 1).clamp(0, 4),
      ),
      dayEarned: state.dayEarned + choice.reward,
      savings: state.savings - fromSavings,
      daySpent: state.daySpent + cost,
      purchases: cost == 0
          ? state.purchases
          : [
              ...state.purchases,
              PurchaseRecord(
                id: 'event-${state.day}-${event.id}',
                itemId:
                    'event_${choice.expenseCategory.name}_${event.id}_${choice.id}',
                itemName: choice.title,
                cost: cost,
                day: state.day,
              ),
            ],
      daySaved: (state.daySaved - fromSavings).clamp(0, 999999),
      goal: fromSavings == 0
          ? state.goal
          : state.goal.copyWith(
              savedAmount: state.goal.savedAmount - fromSavings,
              isCompleted: false,
            ),
      inventory: state.inventory.copyWith(
        foodReserveDays: newFood,
        ownedItemIds: newOwned,
        consumables: newConsumables,
      ),
      finny: state.finny.copyWith(
        mood: choice.moodEffect,
        moodReason: cost == 0 && choice.cost > 0
            ? choice.consequenceText
            : fromSavings == 0
            ? choice.consequenceText
            : '${choice.consequenceText} Из копилки взяли $fromSavings 🪙; до мечты теперь дальше.',
      ),
    );

    if (wasEveningEvent) _prepareEveningSummary();
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
      // A fulfilled long-term goal was paid from accumulated savings,
      // not from today's envelope for ordinary treats.
      if (purchase.itemId.startsWith('goal_')) continue;
      if (purchase.itemId.startsWith('meal_')) {
        needs += purchase.cost;
        continue;
      }
      if (purchase.itemId.startsWith('joy_')) {
        wants += purchase.cost;
        continue;
      }
      if (purchase.itemId.startsWith('event_need_')) {
        needs += purchase.cost;
        continue;
      }
      if (purchase.itemId.startsWith('event_want_') ||
          purchase.itemId.startsWith('event_useful_')) {
        wants += purchase.cost;
        continue;
      }
      if (purchase.itemId.startsWith('event_reserve_')) {
        reserveSpent += purchase.cost;
        continue;
      }
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
    // Older or uncategorized day costs, such as medical help, use reserve.
    reserveSpent += (state.daySpent - purchaseTotal).clamp(0, state.daySpent);
    final plan = state.plannedBudget?.isConfirmed == true
        ? state.plannedBudget
        : null;
    final stats = state.balanceStats;
    final caredForFinny =
        stats.satiety >= 2 && stats.energy >= 2 && stats.wellbeing >= 2;
    final followedPlan =
        plan != null &&
        needs <= plan.needs &&
        wants <= plan.wants &&
        state.daySaved >= plan.savings &&
        reserveSpent <= plan.reserve &&
        state.balance + reserveSpent >= plan.reserve;
    final balanced = caredForFinny && followedPlan;
    final pet = state.profile.petName;
    final reflection = stats.satiety <= 1
        ? '$pet проголодался. Завтра начни с еды.'
        : stats.energy <= 1
        ? 'У $pet мало сил. Завтра можно выбрать отдых.'
        : stats.wellbeing <= 1
        ? '$pet нужно восстановиться. Попроси помощи взрослого.'
        : !followedPlan
        ? 'План сегодня изменился. Вечером посмотрим почему и попробуем снова.'
        : state.daySaved > 0
        ? '$pet в порядке, а мечта стала ближе на ${state.daySaved} 🪙.'
        : '$pet чувствует себя хорошо. Завтра ждут новые решения!';

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
      balancedDay: balanced,
    );

    final nextPhase = (state.day == 10)
        ? GamePhase.finalSummary
        : GamePhase.eveningSummary;

    state = state.copyWith(
      phase: nextPhase,
      history: [...state.history, summary],
    );
  }

  // --- Переход к новому дню ---
  void advanceToNextDay() {
    if (state.phase != GamePhase.eveningSummary &&
        state.phase != GamePhase.finalSummary) {
      return;
    }
    final nextDay = state.day + 1;

    // Growth reflects sustained care and savings. A difficult day never
    // takes a previously reached stage away.
    final balancedDays = state.history
        .where((day) => day.balancedDay && day.followedPlan)
        .length;
    final savingDays = state.history.where((day) => day.saved > 0).length;
    final earnedStage = balancedDays >= 4 && savingDays >= 3
        ? DevelopmentStage.independent
        : balancedDays >= 2 && savingDays >= 1
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
              ? '${state.profile.petName} подрос: ты заботился о нём и откладывал на мечту.'
              : '${state.profile.petName} стал самостоятельнее: забота и первый взнос помогли ему.',
        ),
      );
      _save();
    }
  }

  // --- Демо-функции для жюри ---
  void jumpToDay(int targetDay) {
    if (!_repository.isDemoActive || targetDay < 1 || targetDay > 10) return;
    final initial = GameState.initial();
    final config = kDaysConfig.firstWhere((c) => c.day == targetDay);
    state = initial.copyWith(
      profile: state.profile,
      day: targetDay,
      phase: GamePhase.morning,
      forecast: config.forecast,
    );
    if (targetDay == 1) {
      _save();
    } else {
      startDay();
    }
  }

  // Retained for existing economy fixtures; no child-facing action calls it.
  @visibleForTesting
  void addCoins(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(balance: (state.balance + amount).clamp(0, 99999));
    _save();
  }

  // Retained for existing economy fixtures; the playable help card is separate.
  @visibleForTesting
  void triggerEmergencyAid() {
    state = state.copyWith(
      inventory: state.inventory.copyWith(
        foodReserveDays: state.inventory.foodReserveDays + 1,
      ),
      finny: state.finny.copyWith(
        mood: FinnyMood.good,
        moodReason: 'Добрый сосед поделился яблоком. Выход есть всегда.',
      ),
    );
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

  bool renamePet(String petName) {
    final name = petName.trim();
    if (name.isEmpty || name.runes.length > 16) return false;
    state = state.copyWith(
      profile: PlayerProfile(
        petName: name,
        startDate: state.profile.startDate,
        onboardingComplete: state.profile.onboardingComplete,
      ),
    );
    _save();
    return true;
  }

  bool equipRaincoat(bool equipped) {
    if (equipped && !state.inventory.hasItem('raincoat')) return false;
    state = state.copyWith(
      finny: state.finny.copyWith(activeOutfit: equipped ? 'raincoat' : 'none'),
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
