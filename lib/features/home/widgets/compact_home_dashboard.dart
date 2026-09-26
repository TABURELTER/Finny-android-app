import 'package:flutter/material.dart';

import '../../../data/models/game_state.dart';
import '../../../game/content/financial_tasks.dart';
import '../../../game/content/goals.dart';
import '../../../game/content/shop_items.dart';
import '../../../shared/widgets/pet_avatar_widget.dart';
import 'home_dashboard.dart' show FinnyRoomPainter;

const _ink = Color(0xFF342B50);
const _purple = Color(0xFF6B3DC6);
const _cream = Color(0xFFFFFCF6);

/// A single-screen home: the scene takes the remaining height, while every
/// action and the current financial state remain visible on a small phone.
class CompactHomeDashboard extends StatelessWidget {
  final GameState state;
  final VoidCallback wardrobe,
      pet,
      work,
      shop,
      plan,
      goal,
      task,
      finish,
      guide,
      adult,
      progress,
      demo;

  const CompactHomeDashboard({
    super.key,
    required this.state,
    required this.wardrobe,
    required this.pet,
    required this.work,
    required this.shop,
    required this.plan,
    required this.goal,
    required this.task,
    required this.finish,
    required this.guide,
    required this.adult,
    required this.progress,
    required this.demo,
  });

  @override
  Widget build(BuildContext context) {
    final compactWidth = MediaQuery.sizeOf(context).width < 350;
    final goalDef = kAvailableGoals.firstWhere(
      (item) => item.id == state.goal.goalId,
      orElse: () => kAvailableGoals.first,
    );
    final goalOwned = state.inventory.hasItem('goal_${goalDef.id}');
    final displayedReward = kAvailableGoals
        .where((item) => state.inventory.hasItem('goal_${item.id}'))
        .toList();
    final planned = state.plannedBudget?.isConfirmed == true;
    final hasTask = kFinancialTasks.any(
      (challenge) =>
          challenge.day <= state.day &&
          !state.completedTasks.any((done) => done.taskId == challenge.id),
    );
    final foodNeedsAttention = state.inventory.foodReserveDays < 2;
    final oneDayFoodPrice = kShopCatalog
        .firstWhere((item) => item.id == 'food_1')
        .price;
    final canBuyFood = state.balance >= oneDayFoodPrice;
    final shouldShop = foodNeedsAttention && canBuyFood;
    final shouldSave = state.daySaved == 0 && state.balance > 0;
    final careComplete = !foodNeedsAttention && !shouldSave;
    final step = !planned
        ? 0
        : !state.workCompletedToday
        ? 1
        : hasTask
        ? 2
        : careComplete
        ? 4
        : 3;
    final nextAction = switch (step) {
      0 => plan,
      1 => work,
      2 => task,
      _ when shouldShop => shop,
      _ when shouldSave => goal,
      _ => finish,
    };
    final nextTitle = switch (step) {
      0 => 'Решим, куда пойдут монеты',
      1 => 'Заработаем ещё монеты',
      2 => 'Потренируемся вместе',
      _ when shouldShop => 'Купим еду на завтра',
      _ when foodNeedsAttention => 'Посмотрим итоги дня',
      _ when shouldSave => 'Отложим часть на мечту',
      _ => 'Посмотрим итоги дня',
    };
    final nextDetail = switch (step) {
      0 => 'План не списывает деньги',
      1 => 'Поручение добавит 10 монет',
      2 => 'Задача добавит 5 монет',
      _ when shouldShop => 'Один завтрак стоит $oneDayFoodPrice монет',
      _ when foodNeedsAttention => 'На еду пока не хватает монет',
      _ when shouldSave => 'Взнос перейдёт из кошелька в копилку',
      _ => 'Что получилось за сегодняшний день?',
    };
    final roomMessage = !planned
        ? 'У меня ${state.balance} монет! Сначала решим, что нужно, а что можно отложить.'
        : planned && !state.workCompletedToday
        ? 'План готов! Монеты пока в кошельке. Поможешь мне заработать ещё?'
        : state.finny.moodReason;
    final rain = RegExp('дожд|ливень')
        .hasMatch(state.forecast.title.toLowerCase());

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'finny',
                    style: TextStyle(
                      color: _purple,
                      fontSize: compactWidth ? 22 : 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.3,
                    ),
                  ),
                  const Spacer(),
                  _AmountPill(
                    Icons.toll_rounded,
                    state.balance,
                    'Монеты',
                    const Color(0xFFFFE9A3),
                  ),
                  const SizedBox(width: 6),
                  _AmountPill(
                    Icons.savings_rounded,
                    state.savings,
                    'Копилка',
                    const Color(0xFFE5D5FF),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Меню',
                    icon: const Icon(Icons.more_horiz_rounded, color: _ink),
                    onSelected: (value) => switch (value) {
                      'progress' => progress(),
                      'tasks' => task(),
                      'adult' => adult(),
                      'demo' => demo(),
                      'guide' => guide(),
                      _ => null,
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'guide', child: Text('Как играть')),
                      PopupMenuItem(value: 'progress', child: Text('Дневник')),
                      PopupMenuItem(value: 'tasks', child: Text('Задачи')),
                      PopupMenuItem(value: 'adult', child: Text('Родителям')),
                      PopupMenuItem(value: 'demo', child: Text('Демо')),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Домик · ${state.profile.petName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  Text(
                    'День ${state.day}',
                    style: const TextStyle(
                      color: _purple,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final (index, label) in [
                    'План',
                    'Работа',
                    'Задача',
                    'Забота',
                  ].indexed)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 3 ? 0 : 4),
                        child: _JourneyStep(
                          label: label,
                          number: index + 1,
                          active: step == index,
                          completed: step > index,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LayoutBuilder(
                    builder: (context, room) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: FinnyRoomPainter(
                              rain: rain,
                              bed: state.inventory.hasItem('cozy_bed'),
                              lamp: state.inventory.hasItem('warm_lamp'),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 9,
                          left: 12,
                          right: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _cream,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                roomMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 7,
                          child: PetAvatarWidget(
                            mood: state.finny.mood,
                            stage: state.finny.stage,
                            size: (room.maxHeight * .76).clamp(
                              105.0,
                              room.maxWidth - 70,
                            ),
                            hasRaincoat:
                                rain && state.inventory.hasItem('raincoat'),
                            onTap: pet,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: IconButton.filledTonal(
                            tooltip: 'Гардероб',
                            onPressed: wardrobe,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              backgroundColor: _cream,
                              foregroundColor: _purple,
                            ),
                            icon: const Icon(Icons.checkroom_rounded),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _cream,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              state.inventory.foodReserveDays > 0
                                  ? 'Еда: ${state.inventory.foodReserveDays} дн.'
                                  : 'Пора поесть',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ),
                        ),
                        if (displayedReward.isNotEmpty)
                          Positioned(
                            right: 15,
                            top: 55,
                            child: Tooltip(
                              message:
                                  'Мечта сбылась: ${displayedReward.first.name}',
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: _cream,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  displayedReward.first.id == 'skate'
                                      ? Icons.skateboarding_rounded
                                      : displayedReward.first.id == 'treehouse'
                                      ? Icons.forest_rounded
                                      : Icons.rocket_launch_rounded,
                                  color: _purple,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    rain ? Icons.umbrella_rounded : Icons.wb_sunny_rounded,
                    size: 15,
                    color: const Color(0xFF977954),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      state.forecast.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF776C80),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                elevation: 3,
                shadowColor: _purple.withValues(alpha: .22),
                child: InkWell(
                  onTap: nextAction,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8152DF), Color(0xFF582EB4)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SizedBox(
                      height: 61,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Color(0xFFFFE9A3),
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nextTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    nextDetail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFEADFFF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Material(
                color: const Color(0xFFEEE1FF),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: goal,
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 54,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: _purple,
                            size: 24,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        goalOwned
                                            ? 'Мечта получена: ${goalDef.name}'
                                            : 'Мечта: ${goalDef.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _ink,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      goalOwned
                                          ? '✓'
                                          : '${state.goal.savedAmount}/${state.goal.targetAmount}',
                                      style: const TextStyle(
                                        color: _purple,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                LinearProgressIndicator(
                                  value: goalOwned
                                      ? 1
                                      : state.goal.progress.clamp(0, 1),
                                  minHeight: 6,
                                  color: _purple,
                                  backgroundColor: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  _DockAction(
                    Icons.eco_rounded,
                    'Работа',
                    work,
                    const Color(0xFFDDF5E4),
                    const Color(0xFF187B52),
                  ),
                  const SizedBox(width: 7),
                  _DockAction(
                    Icons.storefront_rounded,
                    'Лавка',
                    shop,
                    const Color(0xFFFFE8D2),
                    const Color(0xFF9D4A22),
                  ),
                  const SizedBox(width: 7),
                  _DockAction(
                    Icons.donut_small_rounded,
                    'План',
                    plan,
                    const Color(0xFFE5D5FF),
                    _purple,
                  ),
                  const SizedBox(width: 7),
                  _DockAction(
                    Icons.star_rounded,
                    'Мечта',
                    goal,
                    const Color(0xFFFCE4F1),
                    const Color(0xFFB73778),
                  ),
                ],
              ),
              SizedBox(
                height: 48,
                child: Center(
                  child: TextButton.icon(
                    onPressed: finish,
                    icon: const Icon(Icons.bedtime_outlined, size: 17),
                    label: const Text('Завершить день'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5A456E),
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  final IconData icon;
  final int value;
  final String meaning;
  final Color color;
  const _AmountPill(this.icon, this.value, this.meaning, this.color);

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$meaning: $value',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _ink),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _JourneyStep extends StatelessWidget {
  final String label;
  final int number;
  final bool active;
  final bool completed;

  const _JourneyStep({
    required this.label,
    required this.number,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final background = active
        ? _purple
        : completed
        ? const Color(0xFFDDF5E4)
        : const Color(0xFFF1E9DF);
    final foreground = active
        ? Colors.white
        : completed
        ? const Color(0xFF165E42)
        : const Color(0xFF665D70);
    return Semantics(
      label:
          '$number. $label: ${completed
              ? 'готово'
              : active
              ? 'сейчас'
              : 'впереди'}',
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              completed ? Icons.check_rounded : Icons.circle,
              size: completed ? 15 : 8,
              color: foreground,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback action;
  final Color background;
  final Color foreground;
  const _DockAction(
    this.icon,
    this.label,
    this.action,
    this.background,
    this.foreground,
  );

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 65,
        child: Column(
          children: [
            Container(
              height: 42,
              width: double.infinity,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: foreground),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
