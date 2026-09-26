import 'widgets/compact_home_dashboard.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../data/models/event_models.dart';
import '../../data/models/game_state.dart';
import '../../game/content/days.dart';
import '../../game/content/financial_tasks.dart';
import '../../game/engine/game_engine.dart';
import '../adult/adult_screen.dart';
import '../demo/demo_drawer.dart';
import '../events/evening_summary_modal.dart';
import '../events/event_modal.dart';
import '../goals/goal_sheet.dart';
import '../planning/planning_sheet.dart';
import '../progress/progress_screen.dart';
import '../shop/shop_modal.dart';
import '../work/work_screen.dart';

import 'wardrobe_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _showGuide() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Как играть с Финни?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'На первый день у тебя 50 монет. Иди по цветным шагам в домике.',
            ),
            SizedBox(height: 12),
            _GuideRow(
              Icons.donut_small_rounded,
              'План',
              'Распредели монеты на бумаге. Пока ничего не списывается.',
            ),
            _GuideRow(
              Icons.handyman_rounded,
              'Работа и задача',
              'Решения принесут новые монеты.',
            ),
            _GuideRow(
              Icons.storefront_rounded,
              'Лавка',
              'Покупка уменьшит кошелёк, зато даст еду или вещь.',
            ),
            _GuideRow(
              Icons.savings_rounded,
              'Копилка',
              'Взнос уменьшит кошелёк и приблизит мечту.',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Понятно, играем'),
          ),
        ],
      ),
    );
  }

  void _finishDay(GameState state) {
    final pending = <String>[
      if (state.plannedBudget?.isConfirmed != true) 'составить план',
      if (!state.workCompletedToday) 'выполнить поручение',
      if (kFinancialTasks.any(
        (task) =>
            task.day <= state.day &&
            !state.completedTasks.any((done) => done.taskId == task.id),
      ))
        'решить задачу',
    ];
    if (pending.isEmpty) {
      ref.read(gameEngineProvider.notifier).finishDayAction();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Уже вечер?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Можно завершить день сейчас. Но ещё можно: ${pending.join(', ')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Продолжить играть'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(gameEngineProvider.notifier).finishDayAction();
            },
            child: const Text('Завершить день'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Проверяем фазу при первом открытии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPhaseTriggers(ref.read(gameEngineProvider));
    });
  }

  void _checkPhaseTriggers(GameState state) {
    if (!mounted) return;

    if (state.phase == GamePhase.eventResolution) {
      final config = kDaysConfig.firstWhere(
        (c) => c.day == state.day,
        orElse: () => kDaysConfig.last,
      );
      if (config.scheduledEventId != null) {
        EventModal.show(context, config.scheduledEventId!);
      }
    } else if (state.phase == GamePhase.eveningSummary ||
        state.phase == GamePhase.finalSummary) {
      if (EventModal.isOpen) return;
      EveningSummaryModal.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameEngineProvider);

    // Слушаем изменение фазы для модальных окон событий и вечера
    ref.listen<GameState>(gameEngineProvider, (previous, next) {
      if (previous?.phase != next.phase) {
        _checkPhaseTriggers(next);
      }
    });

    return Scaffold(
      backgroundColor: FinnyColors.background,
      body: SafeArea(
        child: CompactHomeDashboard(
          state: state,
          wardrobe: () => WardrobeSheet.show(context),
          pet: () => ref
              .read(gameEngineProvider.notifier)
              .setFinnyMood(FinnyMood.happy, 'Как здорово, что ты рядом!'),
          work: () => WorkScreen.open(context),
          shop: () => ShopModal.show(context),
          plan: () => PlanningSheet.show(context),
          goal: () => GoalSheet.show(context),
          task: () => ProgressScreen.openTasks(context),
          finish: () => _finishDay(state),
          guide: _showGuide,
          adult: () => AdultScreen.open(context),
          progress: () => ProgressScreen.open(context),
          demo: () => DemoDrawer.show(context),
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _GuideRow(this.icon, this.title, this.detail);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: FinnyColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title · ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: detail),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
