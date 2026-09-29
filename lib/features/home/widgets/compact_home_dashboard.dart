import 'package:flutter/material.dart';

import '../../../core/theme/finny_tokens.dart';
import '../../../data/models/game_state.dart';
import '../../../game/content/financial_tasks.dart';
import '../../../game/content/days.dart';
import '../../../game/content/goals.dart';
import '../../../shared/widgets/pet_avatar_widget.dart';
import '../../../shared/widgets/room_scene_svg.dart';
import '../../../core/sound/sound_service.dart';
import 'balance_decision_card.dart';
import 'window_weather_view.dart';

const _ink = FinnyColors.textPrimary;
const _cream = FinnyColors.surface;

String _displayCoinAmounts(String message) => message.replaceAllMapped(
  RegExp(r'(\d+)\s+монет(?:а|ы)?', caseSensitive: false),
  (match) => '${match[1]} 🪙',
);

/// One playable scene: the room, Finny's condition, and the next decision
/// share a single surface without moving the screen.
class CompactHomeDashboard extends StatelessWidget {
  final GameState state;
  final bool demoActive;
  final VoidCallback wardrobe,
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
  final VoidCallback? accent;
  final VoidCallback? rename;
  final VoidCallback? pet;
  final ValueChanged<FinnyReaction>? onPetReact;
  final ValueChanged<String>? onRoomItem;
  final String? petSpeech;
  final String? activeRoomItem;
  final FinnyReaction? requestedReaction;
  final double reactionTravel;
  final int reactionToken;

  const CompactHomeDashboard({
    super.key,
    required this.state,
    this.demoActive = false,
    required this.wardrobe,
    required this.work,
    this.rename,
    this.pet,
    required this.shop,
    required this.plan,
    required this.goal,
    required this.task,
    required this.finish,
    required this.guide,
    required this.adult,
    required this.progress,
    required this.demo,
    this.accent,
    this.onPetReact,
    this.onRoomItem,
    this.petSpeech,
    this.activeRoomItem,
    this.requestedReaction,
    this.reactionTravel = 0,
    this.reactionToken = 0,
  });

  @override
  Widget build(BuildContext context) {
    final petName = state.profile.petName;
    final roomMessage =
        petSpeech ??
        (state.plannedBudget?.isConfirmed != true
            ? dayConfigFor(state.day).morningMessage.replaceAll('Финни', petName)
            : state.balanceStats.cardsToday == 0 &&
                  state.balanceStats.satiety <= 1
            ? 'Я проголодался. Поможешь выбрать еду?'
            : _displayCoinAmounts(state.finny.moodReason)
                  .replaceFirst(RegExp('^(${RegExp.escape(petName)}|Финни) '), 'Я '));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _HomeHeader(
              state: state,
              rename: rename,
              guide: guide,
              work: work,
              plan: plan,
              task: task,
              adult: adult,
              progress: progress,
              demo: demo,
              accent: accent,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final roomHeight = (viewport.maxHeight * .38).clamp(
                    112.0,
                    245.0,
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 7),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _cream,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: FinnyColors.border),
                        boxShadow: FinnyShadows.sm,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Column(
                          children: [
                            SizedBox(
                              height: roomHeight,
                              child: LayoutBuilder(
                                builder: (context, room) {
                                  final rw = room.maxWidth;
                                  final rh = room.maxHeight;
                                  double rx(double x) => x / 360.0 * rw;
                                  double ry(double y) => y / 360.0 * rh;

                                  final hasBed = state.inventory.hasItem('cozy_bed');
                                  final hasLamp = state.inventory.hasItem('warm_lamp');
                                  final hasBall = state.inventory.hasItem('toy_ball');
                                  final hasRobot = state.inventory.hasItem('toy_robot');
                                  final hasKite = state.inventory.hasItem('kite');

                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // ── СЛОЙ 1: Погода за окном (через прозрачное окно) ──
                                      Positioned(
                                        left: rx(33),
                                        top: ry(80),
                                        width: rx(50),
                                        height: ry(94),
                                        child: WindowWeatherView(
                                          forecast: state.forecast,
                                          motion: state.settings.animationsEnabled,
                                        ),
                                      ),

                                      // ── СЛОЙ 2: Неизменный интерьер комнаты с прозрачным окном ──
                                      const Positioned.fill(
                                        child: RepaintBoundary(
                                          child: RoomSceneSvg(),
                                        ),
                                      ),

                                      // ── СЛОЙ 3: Купленные AI-предметы ──
                                      if (hasBed)
                                        Positioned(
                                          left: rx(10),
                                          top: ry(260),
                                          width: rx(80),
                                          height: ry(62),
                                          child: GestureDetector(
                                            onTap: onRoomItem != null ? () => onRoomItem!('cozy_bed') : null,
                                            child: Image.asset(
                                              'assets/finny/items/cozy_bed.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),

                                      if (hasLamp)
                                        Positioned(
                                          left: rx(248),
                                          top: ry(184),
                                          width: rx(52),
                                          height: ry(104),
                                          child: GestureDetector(
                                            onTap: onRoomItem != null ? () => onRoomItem!('warm_lamp') : null,
                                            child: Image.asset(
                                              'assets/finny/items/warm_lamp.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),

                                      if (hasBall)
                                        Positioned(
                                          left: rx(78),
                                          top: ry(280),
                                          width: rx(30),
                                          height: ry(30),
                                          child: GestureDetector(
                                            onTap: onRoomItem != null ? () => onRoomItem!('toy_ball') : null,
                                            child: Image.asset(
                                              'assets/finny/items/toy_ball.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),

                                      if (hasRobot)
                                        Positioned(
                                          left: rx(218),
                                          top: ry(260),
                                          width: rx(34),
                                          height: ry(42),
                                          child: GestureDetector(
                                            onTap: onRoomItem != null ? () => onRoomItem!('toy_robot') : null,
                                            child: Image.asset(
                                              'assets/finny/items/toy_robot.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),

                                      if (hasKite)
                                        Positioned(
                                          left: rx(276),
                                          top: ry(42),
                                          width: rx(52),
                                          height: ry(54),
                                          child: GestureDetector(
                                            onTap: onRoomItem != null ? () => onRoomItem!('kite') : null,
                                            child: Image.asset(
                                              'assets/finny/items/kite.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                    Positioned(
                                      top: 9,
                                      left: 10,
                                      right: 10,
                                      child: _SpeechBubble(roomMessage),
                                    ),
                                    Positioned(
                                      bottom: 3,
                                      child: RepaintBoundary(
                                        child: PetAvatarWidget(
                                          mood: state.finny.mood,
                                          stage: state.finny.stage,
                                          size: (room.maxHeight * .68).clamp(
                                            82.0,
                                            room.maxWidth - 70,
                                          ),
                                          hasRaincoat:
                                              state.inventory.hasItem('raincoat') &&
                                                  (state.finny.activeOutfit ==
                                                          'raincoat' ||
                                                      state.forecast.title
                                                          .toLowerCase()
                                                          .contains('ливень') ||
                                                      state.forecast.title
                                                          .toLowerCase()
                                                          .contains('дождь')),
                                          onTap: pet,
                                          onReact: onPetReact,
                                          requestedReaction: requestedReaction,
                                          reactionTravel: reactionTravel,
                                          reactionToken: reactionToken,
                                        ),
                                      ),
                                    ),
                                    if (onRoomItem != null &&
                                        state.inventory.hasItem('cozy_bed'))
                                      _RoomHotspot(
                                        room: room,
                                        x: 49,
                                        y: 282,
                                        label: 'Полежать на лежанке',
                                        onTap: () => onRoomItem!('cozy_bed'),
                                      ),
                                    if (onRoomItem != null &&
                                        state.inventory.hasItem('warm_lamp'))
                                      _RoomHotspot(
                                        room: room,
                                        x: 273,
                                        y: 218,
                                        label: 'Включить лампу',
                                        onTap: () => onRoomItem!('warm_lamp'),
                                      ),
                                    if (onRoomItem != null &&
                                        state.inventory.hasItem('toy_ball'))
                                      _RoomHotspot(
                                        room: room,
                                        x: 88,
                                        y: 281,
                                        label: 'Поиграть с мячом',
                                        onTap: () => onRoomItem!('toy_ball'),
                                      ),
                                    if (onRoomItem != null &&
                                        state.inventory.hasItem('toy_robot'))
                                      _RoomHotspot(
                                        room: room,
                                        x: 244,
                                        y: 260,
                                        label: 'Поиграть с роботом',
                                        onTap: () => onRoomItem!('toy_robot'),
                                      ),
                                    if (onRoomItem != null &&
                                        state.inventory.hasItem('kite'))
                                      _RoomHotspot(
                                        room: room,
                                        x: 295,
                                        y: 65,
                                        label: 'Посмотреть на воздушного змея',
                                        onTap: () => onRoomItem!('kite'),
                                      ),
                                    Positioned(
                                      left: 9,
                                      bottom: 9,
                                      child: IconButton.filledTonal(
                                        tooltip: 'Одежда Финни',
                                        onPressed: wardrobe,
                                        style: IconButton.styleFrom(
                                          minimumSize: const Size(46, 46),
                                          backgroundColor: _cream,
                                          foregroundColor: FinnyColors.primary,
                                        ),
                                        icon: const Icon(
                                          Icons.checkroom_rounded,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 9,
                                      bottom: 9,
                                      child: _WeatherChip(state.forecast.title),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          BalanceStatsStrip(stats: state.balanceStats),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: FinnyColors.primary.withValues(alpha: .12),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, cardSpace) => FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: cardSpace.maxWidth,
                                    child: BalanceDecisionCard(
                                      state: state,
                                      finish: finish,
                                      plan: plan,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _HomeNavigation(
              state: state,
              demoActive: demoActive,
              goal: goal,
              shop: shop,
              task: task,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final GameState state;
  final VoidCallback? rename, accent;
  final VoidCallback guide, work, plan, task, adult, progress, demo;

  const _HomeHeader({
    required this.state,
    required this.rename,
    required this.guide,
    required this.work,
    required this.plan,
    required this.task,
    required this.adult,
    required this.progress,
    required this.demo,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 3, 9, 6),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: rename,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.profile.petName,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: FinnyColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: FinnyColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FinnyColors.borderLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'День ${state.day}',
                    style: const TextStyle(
                      color: FinnyColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    switch (state.finny.stage) {
                      DevelopmentStage.start => 'Новичок',
                      DevelopmentStage.planner => 'Планировщик',
                      DevelopmentStage.independent => 'Самостоятельный',
                    },
                    style: TextStyle(
                      color: FinnyColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Как играть',
              onPressed: guide,
              icon: Icon(
                Icons.help_outline_rounded,
                color: FinnyColors.primary,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ещё',
              icon: const Icon(Icons.more_horiz_rounded, color: _ink),
              onSelected: (value) => switch (value) {
                'progress' => progress(),
                'work' => work(),
                'tasks' => task(),
                'adult' => adult(),
                'demo' => demo(),
                'accent' => accent?.call(),
                'plan' => plan(),
                _ => null,
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'progress', child: Text('Дневник')),
                PopupMenuItem(value: 'work', child: Text('Мини-игры')),
                PopupMenuItem(value: 'plan', child: Text('План бюджета')),
                PopupMenuItem(value: 'accent', child: Text('Цвет приложения')),
                PopupMenuItem(value: 'adult', child: Text('Родителям')),
                PopupMenuItem(value: 'demo', child: Text('Демо')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            _MoneyStatus('🪙', '${state.balance}', 'на руках'),
            const SizedBox(width: 8),
            _MoneyStatus('🐷', '${state.savings}', 'в копилке'),
          ],
        ),
      ],
    ),
  );
}

class _MoneyStatus extends StatelessWidget {
  final String icon, amount, label;
  const _MoneyStatus(this.icon, this.amount, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FinnyColors.borderLight),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 5),
          Text(
            amount,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: FinnyColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WeatherChip extends StatelessWidget {
  final String forecast;
  const _WeatherChip(this.forecast);

  @override
  Widget build(BuildContext context) {
    final rain = RegExp('дожд|ливень').hasMatch(forecast.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rain ? Icons.umbrella_rounded : Icons.wb_sunny_rounded,
            size: 16,
            color: const Color(0xFF9D7048),
          ),
          const SizedBox(width: 5),
          Text(
            forecast,
            style: const TextStyle(
              fontSize: 12,
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String message;
  const _SpeechBubble(this.message);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: _cream.withValues(alpha: .97),
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.18,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      Transform.rotate(
        angle: .785398,
        child: Container(width: 10, height: 10, color: _cream),
      ),
    ],
  );
}

class _HomeNavigation extends StatelessWidget {
  final GameState state;
  final bool demoActive;
  final VoidCallback goal, shop, task;
  const _HomeNavigation({
    required this.state,
    required this.demoActive,
    required this.goal,
    required this.shop,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final availableTasks = kFinancialTasks
        .where(
          (item) =>
              (demoActive || item.day <= state.day) &&
              !state.completedTasks.any((done) => done.taskId == item.id),
        )
        .toList();
    final currentGoal = kAvailableGoals.firstWhere(
      (goal) => goal.id == state.goal.goalId,
      orElse: () => kAvailableGoals.first,
    );
    final goalLabel = switch (currentGoal.id) {
      'rocket' => 'Ракета',
      'treehouse' => 'Домик',
      'skate' => 'Скейт',
      _ => currentGoal.name,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      decoration: const BoxDecoration(
        color: FinnyColors.surface,
        border: Border(top: BorderSide(color: FinnyColors.border)),
      ),
      child: Row(
        children: [
          _NavButton(
            Icons.school_rounded,
            'Задания',
            availableTasks.isEmpty ? 'Все решены' : availableTasks.first.title,
            task,
          ),
          const SizedBox(width: 8),
          _NavButton(
            Icons.storefront_rounded,
            'Лавка',
            'Еда: ${state.inventory.foodReserveDays}',
            shop,
          ),
          const SizedBox(width: 8),
          _NavButton(
            Icons.star_rounded,
            'Мечта',
            '$goalLabel · ${state.savings}/${state.goal.targetAmount}',
            goal,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback action;
  const _NavButton(this.icon, this.label, this.subtitle, this.action);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: FinnyColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          SoundService.instance.playTap();
          action();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FinnyColors.borderLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: FinnyColors.primary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  subtitle,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: FinnyColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RoomHotspot extends StatelessWidget {
  final BoxConstraints room;
  final double x, y;
  final String label;
  final VoidCallback onTap;

  const _RoomHotspot({
    required this.room,
    required this.x,
    required this.y,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    left: (room.maxWidth * x / 360 - 24).clamp(0.0, room.maxWidth - 48),
    top: (room.maxHeight * y / 360 - 24).clamp(0.0, room.maxHeight - 48),
    child: Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: const BoxDecoration(
                    color: _cream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 13,
                    color: FinnyColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
