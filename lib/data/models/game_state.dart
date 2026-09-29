import 'event_models.dart';
import 'goal_models.dart';
import 'history_models.dart';
import 'task_models.dart';

const _keepPlannedBudget = Object();

enum DevelopmentStage {
  start, // Уютный стартовый дом
  planner, // Организованный хозяин
  independent, // Самостоятельный Финни
}

enum GamePhase {
  morning, // Утренняя сводка
  planning, // Планирование бюджета
  dayAction, // Свободные действия (дом, работа, магазин, цель)
  eventResolution, // Событие дня
  eveningSummary, // Вечерняя сводка перед сном
  finalSummary, // Итог первых десяти дней, затем игра продолжается
}

class InventoryState {
  final int foodReserveDays;
  final Set<String> ownedItemIds;
  final Map<String, int> consumables;

  const InventoryState({
    required this.foodReserveDays,
    required this.ownedItemIds,
    required this.consumables,
  });

  bool hasItem(String itemId) =>
      ownedItemIds.contains(itemId) || (consumables[itemId] ?? 0) > 0;

  InventoryState copyWith({
    int? foodReserveDays,
    Set<String>? ownedItemIds,
    Map<String, int>? consumables,
  }) {
    return InventoryState(
      foodReserveDays: foodReserveDays ?? this.foodReserveDays,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      consumables: consumables ?? this.consumables,
    );
  }

  Map<String, dynamic> toJson() => {
    'foodReserveDays': foodReserveDays,
    'ownedItemIds': ownedItemIds.toList(),
    'consumables': consumables,
  };

  factory InventoryState.fromJson(Map<String, dynamic> json) => InventoryState(
    foodReserveDays: json['foodReserveDays'] as int? ?? 1,
    ownedItemIds:
        (json['ownedItemIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        {},
    consumables:
        (json['consumables'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as int),
        ) ??
        {},
  );
}

class FinnyState {
  final FinnyMood mood;
  final DevelopmentStage stage;
  final String moodReason;
  final String? activeOutfit;

  const FinnyState({
    required this.mood,
    required this.stage,
    required this.moodReason,
    this.activeOutfit,
  });

  FinnyState copyWith({
    FinnyMood? mood,
    DevelopmentStage? stage,
    String? moodReason,
    String? activeOutfit,
  }) {
    return FinnyState(
      mood: mood ?? this.mood,
      stage: stage ?? this.stage,
      moodReason: moodReason ?? this.moodReason,
      activeOutfit: activeOutfit ?? this.activeOutfit,
    );
  }

  Map<String, dynamic> toJson() => {
    'mood': mood.name,
    'stage': stage.name,
    'moodReason': moodReason,
    'activeOutfit': activeOutfit,
  };

  factory FinnyState.fromJson(Map<String, dynamic> json) => FinnyState(
    mood: FinnyMood.values.byName(json['mood'] as String? ?? 'good'),
    stage: DevelopmentStage.values.byName(json['stage'] as String? ?? 'start'),
    moodReason: json['moodReason'] as String? ?? 'Финни рад новому дню!',
    activeOutfit: json['activeOutfit'] as String?,
  );
}

class BudgetPlan {
  final int needs;
  final int wants;
  final int reserve;
  final int savings;
  final int leftover;
  final bool isConfirmed;

  const BudgetPlan({
    required this.needs,
    required this.wants,
    required this.reserve,
    required this.savings,
    required this.leftover,
    this.isConfirmed = false,
  });

  int get total => needs + wants + reserve + savings + leftover;

  BudgetPlan copyWith({
    int? needs,
    int? wants,
    int? reserve,
    int? savings,
    int? leftover,
    bool? isConfirmed,
  }) {
    return BudgetPlan(
      needs: needs ?? this.needs,
      wants: wants ?? this.wants,
      reserve: reserve ?? this.reserve,
      savings: savings ?? this.savings,
      leftover: leftover ?? this.leftover,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  Map<String, dynamic> toJson() => {
    'needs': needs,
    'wants': wants,
    'reserve': reserve,
    'savings': savings,
    'leftover': leftover,
    'isConfirmed': isConfirmed,
  };

  factory BudgetPlan.fromJson(Map<String, dynamic> json) => BudgetPlan(
    needs: json['needs'] as int? ?? 0,
    wants: json['wants'] as int? ?? 0,
    reserve: json['reserve'] as int? ?? 0,
    savings: json['savings'] as int? ?? 0,
    leftover: json['leftover'] as int? ?? 0,
    isConfirmed: json['isConfirmed'] as bool? ?? false,
  );
}

class ForecastInfo {
  final String title;
  final String icon;
  final String hint;

  const ForecastInfo({
    required this.title,
    required this.icon,
    required this.hint,
  });

  Map<String, dynamic> toJson() => {'title': title, 'icon': icon, 'hint': hint};

  factory ForecastInfo.fromJson(Map<String, dynamic> json) => ForecastInfo(
    title: json['title'] as String? ?? 'Ясно',
    icon: json['icon'] as String? ?? '🌤',
    hint: json['hint'] as String? ?? 'Хороший день для прогулок и дел!',
  );
}

class GameSettings {
  final bool soundEnabled;
  final bool animationsEnabled;
  final bool hapticsEnabled;
  final bool musicEnabled;
  final double musicVolume;

  const GameSettings({
    this.soundEnabled = true,
    this.animationsEnabled = true,
    this.hapticsEnabled = true,
    this.musicEnabled = true,
    this.musicVolume = 0.45,
  });

  GameSettings copyWith({
    bool? soundEnabled,
    bool? animationsEnabled,
    bool? hapticsEnabled,
    bool? musicEnabled,
    double? musicVolume,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
    );
  }

  Map<String, dynamic> toJson() => {
    'soundEnabled': soundEnabled,
    'animationsEnabled': animationsEnabled,
    'hapticsEnabled': hapticsEnabled,
    'musicEnabled': musicEnabled,
    'musicVolume': musicVolume,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
    soundEnabled: json['soundEnabled'] as bool? ?? true,
    animationsEnabled: json['animationsEnabled'] as bool? ?? true,
    hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    musicEnabled: json['musicEnabled'] as bool? ?? true,
    musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 0.45,
  );
}

class PlayerProfile {
  final String petName;
  final DateTime startDate;
  final bool onboardingComplete;

  const PlayerProfile({
    required this.petName,
    required this.startDate,
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toJson() => {
    'petName': petName,
    'startDate': startDate.toIso8601String(),
    'onboardingComplete': onboardingComplete,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    petName: json['petName'] as String? ?? 'Финни',
    // Existing profiles predate onboarding. Keep their saved progress accessible.
    onboardingComplete: json['onboardingComplete'] as bool? ?? true,
    startDate: json['startDate'] != null
        ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

/// Small, child-readable ranges; older saves start with a safe neutral state.
class FinnyBalance {
  final double satiety;
  final double energy;
  final double wellbeing;
  final int cardsToday;
  final String lastMeal;
  final int repeatMeals;

  const FinnyBalance({
    this.satiety = 3.0,
    this.energy = 3.0,
    this.wellbeing = 4.0,
    this.cardsToday = 0,
    this.lastMeal = '',
    this.repeatMeals = 0,
  });

  FinnyBalance change({
    double satiety = 0,
    double energy = 0,
    double wellbeing = 0,
    int? cardsToday,
    String? lastMeal,
    int? repeatMeals,
  }) => FinnyBalance(
    satiety: (this.satiety + satiety).clamp(0.0, 5.0),
    energy: (this.energy + energy).clamp(0.0, 5.0),
    wellbeing: (this.wellbeing + wellbeing).clamp(0.0, 5.0),
    cardsToday: cardsToday ?? this.cardsToday,
    lastMeal: lastMeal ?? this.lastMeal,
    repeatMeals: repeatMeals ?? this.repeatMeals,
  );

  Map<String, dynamic> toJson() => {
    'satiety': satiety,
    'energy': energy,
    'wellbeing': wellbeing,
    'cardsToday': cardsToday,
    'lastMeal': lastMeal,
    'repeatMeals': repeatMeals,
  };

  factory FinnyBalance.fromJson(Map<String, dynamic> json) => FinnyBalance(
    satiety: ((json['satiety'] as num?)?.toDouble() ?? 3.0).clamp(0.0, 5.0),
    energy: ((json['energy'] as num?)?.toDouble() ?? 3.0).clamp(0.0, 5.0),
    wellbeing: ((json['wellbeing'] as num?)?.toDouble() ?? 4.0).clamp(0.0, 5.0),
    cardsToday: (json['cardsToday'] as int? ?? 0).clamp(0, 4),
    lastMeal: json['lastMeal'] as String? ?? '',
    repeatMeals: json['repeatMeals'] as int? ?? 0,
  );
}

class GameState {
  final int day;
  final int balance;
  final int savings;
  final GoalState goal;
  final InventoryState inventory;
  final FinnyState finny;
  final List<PurchaseRecord> purchases;
  final List<CompletedTask> completedTasks;
  final List<DaySummaryRecord> history;
  final List<String> activeEvents;
  final GamePhase phase;
  final BudgetPlan? plannedBudget;
  final bool workCompletedToday;
  final bool roomActivityUsedToday;
  final ForecastInfo forecast;
  final GameSettings settings;
  final PlayerProfile profile;
  final int dayEarned;
  final int daySpent;
  final int daySaved;
  final FinnyBalance balanceStats;

  const GameState({
    required this.day,
    required this.balance,
    required this.savings,
    required this.goal,
    required this.inventory,
    required this.finny,
    required this.purchases,
    required this.completedTasks,
    required this.history,
    required this.activeEvents,
    required this.phase,
    this.plannedBudget,
    required this.workCompletedToday,
    this.roomActivityUsedToday = false,
    required this.forecast,
    required this.settings,
    required this.profile,
    this.dayEarned = 0,
    this.daySpent = 0,
    this.daySaved = 0,
    this.balanceStats = const FinnyBalance(),
  });

  factory GameState.initial() {
    return GameState(
      day: 1,
      balance: 20,
      savings: 0,
      goal: const GoalState(
        goalId: 'rocket',
        savedAmount: 0,
        targetAmount: 125,
      ),
      inventory: const InventoryState(
        foodReserveDays: 1, // 1 день еды на руках
        ownedItemIds: {},
        consumables: {},
      ),
      finny: const FinnyState(
        mood: FinnyMood.happy,
        stage: DevelopmentStage.start,
        moodReason: 'Финни рад познакомиться с тобой!',
      ),
      purchases: [],
      completedTasks: [],
      history: [],
      activeEvents: [],
      phase: GamePhase.morning,
      plannedBudget: null,
      workCompletedToday: false,
      forecast: const ForecastInfo(
        title: 'Солнечно',
        icon: '☀️',
        hint: 'Сегодня отличный день, чтобы познакомиться с Финни!',
      ),
      settings: const GameSettings(),
      profile: PlayerProfile(petName: 'Финни', startDate: DateTime.now()),
      dayEarned: 20,
      daySpent: 0,
      daySaved: 0,
    );
  }

  GameState copyWith({
    int? day,
    int? balance,
    int? savings,
    GoalState? goal,
    InventoryState? inventory,
    FinnyState? finny,
    List<PurchaseRecord>? purchases,
    List<CompletedTask>? completedTasks,
    List<DaySummaryRecord>? history,
    List<String>? activeEvents,
    GamePhase? phase,
    Object? plannedBudget = _keepPlannedBudget,
    bool? workCompletedToday,
    bool? roomActivityUsedToday,
    ForecastInfo? forecast,
    GameSettings? settings,
    PlayerProfile? profile,
    int? dayEarned,
    int? daySpent,
    int? daySaved,
    FinnyBalance? balanceStats,
  }) {
    return GameState(
      day: day ?? this.day,
      balance: balance ?? this.balance,
      savings: savings ?? this.savings,
      goal: goal ?? this.goal,
      inventory: inventory ?? this.inventory,
      finny: finny ?? this.finny,
      purchases: purchases ?? this.purchases,
      completedTasks: completedTasks ?? this.completedTasks,
      history: history ?? this.history,
      activeEvents: activeEvents ?? this.activeEvents,
      phase: phase ?? this.phase,
      plannedBudget: identical(plannedBudget, _keepPlannedBudget)
          ? this.plannedBudget
          : plannedBudget as BudgetPlan?,
      workCompletedToday: workCompletedToday ?? this.workCompletedToday,
      roomActivityUsedToday:
          roomActivityUsedToday ?? this.roomActivityUsedToday,
      forecast: forecast ?? this.forecast,
      settings: settings ?? this.settings,
      profile: profile ?? this.profile,
      dayEarned: dayEarned ?? this.dayEarned,
      daySpent: daySpent ?? this.daySpent,
      daySaved: daySaved ?? this.daySaved,
      balanceStats: balanceStats ?? this.balanceStats,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'balance': balance,
    'savings': savings,
    'goal': goal.toJson(),
    'inventory': inventory.toJson(),
    'finny': finny.toJson(),
    'purchases': purchases.map((p) => p.toJson()).toList(),
    'completedTasks': completedTasks.map((t) => t.toJson()).toList(),
    'history': history.map((h) => h.toJson()).toList(),
    'activeEvents': activeEvents,
    'phase': phase.name,
    'plannedBudget': plannedBudget?.toJson(),
    'workCompletedToday': workCompletedToday,
    'roomActivityUsedToday': roomActivityUsedToday,
    'forecast': forecast.toJson(),
    'settings': settings.toJson(),
    'profile': profile.toJson(),
    'dayEarned': dayEarned,
    'daySpent': daySpent,
    'daySaved': daySaved,
    'balanceStats': balanceStats.toJson(),
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    day: json['day'] as int? ?? 1,
    balance: json['balance'] as int? ?? 20,
    savings: json['savings'] as int? ?? 0,
    goal: json['goal'] != null
        ? GoalState.fromJson(json['goal'] as Map<String, dynamic>)
        : const GoalState(goalId: 'rocket', savedAmount: 0, targetAmount: 125),
    inventory: json['inventory'] != null
        ? InventoryState.fromJson(json['inventory'] as Map<String, dynamic>)
        : const InventoryState(
            foodReserveDays: 1,
            ownedItemIds: {},
            consumables: {},
          ),
    finny: json['finny'] != null
        ? FinnyState.fromJson(json['finny'] as Map<String, dynamic>)
        : const FinnyState(
            mood: FinnyMood.happy,
            stage: DevelopmentStage.start,
            moodReason: 'Финни рад!',
          ),
    purchases:
        (json['purchases'] as List<dynamic>?)
            ?.map((p) => PurchaseRecord.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [],
    completedTasks:
        (json['completedTasks'] as List<dynamic>?)
            ?.map((t) => CompletedTask.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [],
    history:
        (json['history'] as List<dynamic>?)
            ?.map((h) => DaySummaryRecord.fromJson(h as Map<String, dynamic>))
            .toList() ??
        [],
    activeEvents:
        (json['activeEvents'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    phase: GamePhase.values.byName(json['phase'] as String? ?? 'morning'),
    plannedBudget: json['plannedBudget'] != null
        ? BudgetPlan.fromJson(json['plannedBudget'] as Map<String, dynamic>)
        : null,
    workCompletedToday: json['workCompletedToday'] as bool? ?? false,
    roomActivityUsedToday: json['roomActivityUsedToday'] as bool? ?? false,
    forecast: json['forecast'] != null
        ? ForecastInfo.fromJson(json['forecast'] as Map<String, dynamic>)
        : const ForecastInfo(
            title: 'Солнечно',
            icon: '☀️',
            hint: 'Отличный день!',
          ),
    settings: json['settings'] != null
        ? GameSettings.fromJson(json['settings'] as Map<String, dynamic>)
        : const GameSettings(),
    profile: json['profile'] != null
        ? PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>)
        : PlayerProfile(petName: 'Финни', startDate: DateTime.now()),
    dayEarned: json['dayEarned'] as int? ?? 0,
    daySpent: json['daySpent'] as int? ?? 0,
    daySaved: json['daySaved'] as int? ?? 0,
    balanceStats: json['balanceStats'] is Map<String, dynamic>
        ? FinnyBalance.fromJson(json['balanceStats'] as Map<String, dynamic>)
        : const FinnyBalance(),
  );
}
