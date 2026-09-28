import 'package:flutter/material.dart';

import '../../../data/models/game_state.dart';
import '../../../shared/widgets/pet_avatar_widget.dart';
import '../../../shared/widgets/room_scene_svg.dart';
import '../../../game/content/goals.dart';
import '../../../game/content/financial_tasks.dart';

const _ink = Color(0xFF342B50);
const _purple = Color(0xFF7952C4);

/// The room and controls share one illustration palette and visual hierarchy.
class HomeDashboard extends StatelessWidget {
  final GameState state;
  final VoidCallback wardrobe,
      pet,
      work,
      shop,
      plan,
      goal,
      task,
      finish,
      adult,
      progress,
      demo;
  const HomeDashboard({
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
    required this.adult,
    required this.progress,
    required this.demo,
  });

  @override
  Widget build(BuildContext context) {
    final goalDef = kAvailableGoals.firstWhere(
      (g) => g.id == state.goal.goalId,
      orElse: () => kAvailableGoals.first,
    );
    final planned = state.plannedBudget?.isConfirmed == true;
    final hasTask = kFinancialTasks.any(
      (challenge) =>
          challenge.day <= state.day &&
          !state.completedTasks.any((done) => done.taskId == challenge.id),
    );
    final rain = RegExp('дожд|ливень')
        .hasMatch(state.forecast.title.toLowerCase());
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'finny',
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            color: _purple,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                      _Balance(
                        icon: Icons.toll_rounded,
                        value: state.balance,
                        label: 'Монеты',
                        color: const Color(0xFFF9E8AD),
                      ),
                      const SizedBox(width: 8),
                      _Balance(
                        icon: Icons.savings_rounded,
                        value: state.savings,
                        label: 'Копилка',
                        color: const Color(0xFFE9DFF8),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Меню',
                        icon: const Icon(Icons.more_horiz_rounded, color: _ink),
                        onSelected: (value) {
                          switch (value) {
                            case 'progress':
                              progress();
                            case 'tasks':
                              task();
                            case 'adult':
                              adult();
                            case 'demo':
                              demo();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'progress',
                            child: Text('Дневник'),
                          ),
                          PopupMenuItem(value: 'tasks', child: Text('Задачи')),
                          PopupMenuItem(
                            value: 'adult',
                            child: Text('Родителям'),
                          ),
                          PopupMenuItem(value: 'demo', child: Text('Демо')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Домик · ${state.profile.petName}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                            letterSpacing: -.7,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'День ${state.day}/10',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _purple,
                            ),
                          ),
                          Text(
                            switch (state.finny.stage) {
                              DevelopmentStage.start => 'Знакомимся',
                              DevelopmentStage.planner => 'Учимся планировать',
                              DevelopmentStage.independent => 'Самостоятельный',
                            },
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: SizedBox(
                      height: (constraints.maxHeight * .43).clamp(290.0, 410.0),
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (_, room) => Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: RoomSceneSvg(
                                forecast: state.forecast,
                                bed: state.inventory.hasItem('cozy_bed'),
                                lamp: state.inventory.hasItem('warm_lamp'),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              left: 18,
                              right: 18,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFCF5),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  state.finny.moodReason,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                              ),
                            ),
                            if (state.inventory.hasItem('toy_ball') ||
                                state.inventory.hasItem('toy_robot') ||
                                state.inventory.hasItem('kite') ||
                                state.inventory.hasItem('repair_kit'))
                              Positioned(
                                right: 15,
                                top: 85,
                                child: Column(
                                  children: [
                                    for (final item in <String, IconData>{
                                      'toy_ball': Icons.sports_soccer_rounded,
                                      'toy_robot': Icons.smart_toy_rounded,
                                      'kite': Icons.air_rounded,
                                      'repair_kit':
                                          Icons.home_repair_service_rounded,
                                    }.entries)
                                      if (state.inventory.hasItem(item.key))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Icon(
                                            item.value,
                                            size: 23,
                                            color: const Color(0xFF88749C),
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                            Positioned(
                              bottom: 25,
                              child: PetAvatarWidget(
                                mood: state.finny.mood,
                                size: ((room.maxHeight - 80) / 1.125).clamp(
                                  150.0,
                                  room.maxWidth - 48,
                                ),
                                stage: state.finny.stage,
                                hasRaincoat:
                                    rain && state.inventory.hasItem('raincoat'),
                                onTap: pet,
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _purple,
                                  minimumSize: const Size(48, 48),
                                ),
                                tooltip: 'Гардероб',
                                onPressed: wardrobe,
                                icon: const Icon(Icons.checkroom_rounded),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 15,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFCF5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.restaurant_rounded,
                                      size: 15,
                                      color: state.inventory.foodReserveDays > 0
                                          ? const Color(0xFF508365)
                                          : const Color(0xFFB24E53),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      state.inventory.foodReserveDays > 0
                                          ? '${state.inventory.foodReserveDays} дн.'
                                          : 'Пора поесть',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          rain
                              ? Icons.umbrella_rounded
                              : Icons.wb_sunny_rounded,
                          size: 17,
                          color: const Color(0xFF9A8154),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            state.forecast.title,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF776C80),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: _purple,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: !planned
                          ? plan
                          : !state.workCompletedToday
                          ? work
                          : hasTask
                          ? task
                          : goal,
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                !planned
                                    ? Icons.pie_chart_rounded
                                    : !state.workCompletedToday
                                    ? Icons.eco_rounded
                                    : hasTask
                                    ? Icons.lightbulb_rounded
                                    : Icons.star_rounded,
                                color: const Color(0xFFE0F4B1),
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    !planned
                                        ? 'На что хватит монет?'
                                        : !state.workCompletedToday
                                        ? 'План готов. За дело!'
                                        : hasTask
                                        ? 'Решим задачку?'
                                        : 'Ещё ближе к мечте',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    !planned
                                        ? 'Решим: потратить или отложить'
                                        : !state.workCompletedToday
                                        ? 'Помоги Финни в саду'
                                        : hasTask
                                        ? 'Попробуй распределить монеты'
                                        : 'Реши, сколько отложить сегодня',
                                    style: const TextStyle(
                                      color: Color(0xFFEDE2FF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: const Color(0xFFEEE8F6),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: goal,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              state.goal.goalId == 'treehouse'
                                  ? Icons.forest_rounded
                                  : state.goal.goalId == 'skateboard'
                                  ? Icons.skateboarding_rounded
                                  : Icons.rocket_launch_rounded,
                              size: 31,
                              color: _purple,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          goalDef.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: _ink,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${state.goal.savedAmount}/${state.goal.targetAmount}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _purple,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: state.goal.progress.clamp(0, 1),
                                      minHeight: 7,
                                      color: _purple,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _purple,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Action(
                        icon: Icons.eco_rounded,
                        title: 'Работа',
                        color: const Color(0xFFDDECCF),
                        ink: const Color(0xFF587548),
                        tap: work,
                      ),
                      const SizedBox(width: 10),
                      _Action(
                        icon: Icons.storefront_rounded,
                        title: 'Лавка',
                        color: const Color(0xFFF8DECB),
                        ink: const Color(0xFFAD704F),
                        tap: shop,
                      ),
                      const SizedBox(width: 10),
                      _Action(
                        icon: Icons.donut_small_rounded,
                        title: 'План',
                        color: const Color(0xFFDCECF1),
                        ink: const Color(0xFF518293),
                        tap: plan,
                      ),
                      const SizedBox(width: 10),
                      _Action(
                        icon: Icons.star_rounded,
                        title: 'Мечта',
                        color: const Color(0xFFE9DFF6),
                        ink: _purple,
                        tap: goal,
                      ),
                    ],
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: finish,
                      icon: const Icon(Icons.bedtime_outlined, size: 17),
                      label: const Text('Завершить день'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF82768F),
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  const _Balance({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: _ink),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color, ink;
  final VoidCallback tap;
  const _Action({
    required this.icon,
    required this.title,
    required this.color,
    required this.ink,
    required this.tap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              height: 57,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: ink.withValues(alpha: .2),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: ink, size: 29),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
