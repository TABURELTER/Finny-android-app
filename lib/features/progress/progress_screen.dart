import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/theme/finny_tokens.dart';
import '../../core/theme/finny_widgets.dart';
import '../../game/content/financial_tasks.dart';
import '../../game/content/glossary.dart';
import '../../game/engine/game_engine.dart';
import '../../data/models/history_models.dart';
import '../tasks/task_challenge_screen.dart';
import '../../shared/widgets/conditional_motion.dart';

class ProgressScreen extends ConsumerWidget {
  final int initialTab;
  const ProgressScreen({super.key, this.initialTab = 0});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProgressScreen()),
    );
  }

  static Future<void> openTasks(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ProgressScreen(initialTab: 1),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameEngineProvider);
    final motion =
        state.settings.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: FinnyColors.background,
        appBar: AppBar(
          title: Text(
            'Дневник Финни',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: FinnyColors.textPrimary,
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.auto_stories_rounded),
                child: Text(
                  'История',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Tab(
                icon: const Icon(Icons.task_alt_rounded),
                child: Text(
                  'Задачи',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Tab(
                icon: const Icon(Icons.menu_book_rounded),
                child: Text(
                  'Словарик',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _HistoryTab(history: state.history, motion: motion),
            const _TasksTab(),
            _GlossaryTab(motion: motion),
          ],
        ),
      ),
    );
  }
}

// ── История ──

class _HistoryTab extends StatelessWidget {
  final List<DaySummaryRecord> history;
  final bool motion;
  const _HistoryTab({required this.history, required this.motion});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, size: 44, color: FinnyColors.primary),
            const Gap(12),
            Text(
              'История пока пуста',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: FinnyColors.textPrimary,
              ),
            ),
            const Gap(6),
            Text(
              'Проживи первый день — и записи появятся!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: FinnyColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(FinnySpacing.lg),
      itemCount: history.length,
      separatorBuilder: (_, _) => const Gap(10),
      itemBuilder: (context, index) {
        final item = history[index];
        return FinnyCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FinnyBadge(
                    text: 'День ${item.day}',
                    color: FinnyColors.primaryLight,
                    textColor: FinnyColors.primary,
                  ),
                ],
              ),
              const Gap(8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _HistoryMoneyBadge(
                    label: 'Получено',
                    amount: '+${item.income}',
                    color: FinnyColors.success,
                    background: FinnyColors.successLight,
                  ),
                  _HistoryMoneyBadge(
                    label: 'Потрачено',
                    amount: '−${item.spent}',
                    color: const Color(0xFFB33E4C),
                    background: const Color(0xFFFFE6E8),
                  ),
                  _HistoryMoneyBadge(
                    label: 'В копилку',
                    amount: '+${item.saved}',
                    color: FinnyColors.primary,
                    background: FinnyColors.primaryLight,
                  ),
                ],
              ),
              const Gap(8),
              Text(
                item.reflection,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: FinnyColors.textPrimary,
                ),
              ),
              if (item.plannedNeeds != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'План/факт: еда ${item.plannedNeeds}/${item.actualNeeds}, '
                    'радости ${item.plannedWants}/${item.actualWants}, '
                    'мечта ${item.plannedSavings}/${item.saved}.\n'
                    '${item.reserveIsCash ? 'Денежный запас: план ${item.plannedReserve}, в кошельке ${item.actualReserve}, использовано ${item.actualReserveSpent}' : 'Запас и события: план ${item.plannedReserve}, потрачено ${item.actualReserve}'}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FinnyColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ).fadeInWhen(motion, delay: Duration(milliseconds: index * 60));
      },
    );
  }
}

class _HistoryMoneyBadge extends StatelessWidget {
  const _HistoryMoneyBadge({
    required this.label,
    required this.amount,
    required this.color,
    required this.background,
  });

  final String label;
  final String amount;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '$label $amount',
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: color,
      ),
    ),
  );
}

// ── Задачи ──

class _TasksTab extends ConsumerWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameEngineProvider);
    final motion =
        state.settings.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    final currentDay = state.day;
    final demoActive = ref.read(gameRepositoryProvider).isDemoActive;
    final tasks =
        kFinancialTasks
            .where((task) => demoActive || task.day <= currentDay)
            .toList()
          ..sort((a, b) {
            final aDone = state.completedTasks.any(
              (done) => done.taskId == a.id,
            );
            final bDone = state.completedTasks.any(
              (done) => done.taskId == b.id,
            );
            if (aDone != bDone) return aDone ? 1 : -1;
            final byDay = b.day.compareTo(a.day);
            return byDay != 0 ? byDay : a.title.compareTo(b.title);
          });

    return ListView.separated(
      padding: const EdgeInsets.all(FinnySpacing.lg),
      itemCount: tasks.length + 1,
      separatorBuilder: (_, _) => const Gap(10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return FinnyCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Задания Финни',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Gap(5),
                const Text(
                  'За новое решение: +3 🪙, а Финни станет лучше. Ошибаться можно — попробуй ещё раз.',
                  style: TextStyle(fontSize: 14, height: 1.3),
                ),
                const Gap(6),
                Text(
                  'Доступно сейчас: ${tasks.where((task) => !state.completedTasks.any((done) => done.taskId == task.id)).length}',
                  style: TextStyle(
                    color: FinnyColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }
        final task = tasks[index - 1];
        final matches = state.completedTasks.where(
          (done) => done.taskId == task.id,
        );
        final completed = matches.isEmpty ? null : matches.first;
        final isPassed = completed != null;
        final isCurrent = currentDay == task.day;

        return FinnyCard(
          borderColor: isCurrent ? FinnyColors.coin : null,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FinnyBadge(
                    text: isPassed
                        ? '✓ Выполнено'
                        : isCurrent
                        ? '★ Сегодня'
                        : 'День ${task.day}',
                    color: isPassed
                        ? FinnyColors.successLight
                        : isCurrent
                        ? FinnyColors.coinLight
                        : FinnyColors.surfaceMuted,
                    textColor: isPassed
                        ? FinnyColors.success
                        : isCurrent
                        ? FinnyColors.coin
                        : FinnyColors.textTertiary,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FinnyColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Text(
                task.prompt,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: FinnyColors.textPrimary,
                ),
              ),
              const Gap(8),
              if (completed != null)
                FinnyGlassCard(
                  tintColor: FinnyColors.success,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        size: 19,
                        color: FinnyColors.success,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          completed.outcomeDescription.isEmpty
                              ? task.educationalFeedback
                              : 'Твой путь: ${completed.outcomeDescription}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FinnyColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if ((demoActive || currentDay >= task.day) && !isPassed)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskChallengeScreen(task: task),
                        ),
                      ),
                      child: const Text(
                        'Решить задачу',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ).fadeInWhen(motion, delay: Duration(milliseconds: index * 60));
      },
    );
  }
}

// ── Словарик ──

class _GlossaryTab extends StatelessWidget {
  final bool motion;
  const _GlossaryTab({required this.motion});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(FinnySpacing.lg),
      itemCount: kFinancialGlossary.length,
      separatorBuilder: (_, _) => const Gap(10),
      itemBuilder: (context, index) {
        final term = kFinancialGlossary[index];
        return FinnyCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(term.icon, style: const TextStyle(fontSize: 20)),
                  const Gap(8),
                  Text(
                    term.term,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: FinnyColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Text(
                term.definition,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: FinnyColors.textPrimary,
                ),
              ),
              const Gap(4),
              Text(
                'Пример: ${term.childExample}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: FinnyColors.textTertiary,
                ),
              ),
            ],
          ),
        ).fadeInWhen(motion, delay: Duration(milliseconds: index * 60));
      },
    );
  }
}
