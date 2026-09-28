import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/theme/finny_tokens.dart';
import '../../core/theme/finny_widgets.dart';
import '../../game/content/financial_tasks.dart';
import '../../game/engine/game_engine.dart';
import '../../shared/widgets/finny_appearance.dart';
import '../../shared/widgets/conditional_motion.dart';

class AdultScreen extends ConsumerStatefulWidget {
  const AdultScreen({super.key});

  static Future<void> open(BuildContext context) async {
    final passed = await _showParentGate(context);
    if (passed == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdultScreen()),
      );
    }
  }

  static Future<bool?> _showParentGate(BuildContext context) {
    const num1 = 7;
    const num2 = 8;
    const correctAnswer = num1 * num2;
    final controller = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: FinnyColors.primary),
            const Gap(8),
            Text(
              'Для родителей',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Решите пример:',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
            ),
            const Gap(12),
            Center(
              child: Text(
                '$num1 × $num2 = ?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: FinnyColors.primary,
                ),
              ),
            ),
            const Gap(12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ответ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FinnyRadius.sm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FinnyButton.ghost(
            label: 'Отмена',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          FinnyButton.primary(
            label: 'Войти',
            onPressed: () {
              if (int.tryParse(controller.text.trim()) == correctAnswer) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Неверный ответ!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<AdultScreen> createState() => _AdultScreenState();
}

class _AdultScreenState extends ConsumerState<AdultScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameEngineProvider);
    final motion =
        state.settings.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    bool did(String taskId) =>
        state.completedTasks.any((task) => task.taskId == taskId);
    final everSaved =
        state.history.any((day) => day.saved > 0) ||
        state.daySaved > 0 ||
        state.savings > 0;
    final recentDecisions = state.completedTasks.reversed.take(3).toList();
    String titleFor(String taskId) {
      for (final task in kFinancialTasks) {
        if (task.id == taskId) return task.title;
      }
      return 'Задание';
    }

    return Scaffold(
      backgroundColor: FinnyColors.background,
      appBar: AppBar(
        title: Text(
          'Родительский раздел',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            color: FinnyColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FinnySpacing.xl),
          children: [
            // Концепция
            FinnyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: FinnyColors.primary,
                        size: 22,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          'Образовательная концепция',
                          maxLines: 2,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: FinnyColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Text(
                    '«Питомец Финни» учит финансовой грамотности через естественные последствия решений. Игра не наказывает за ошибки, а учит исправлять последствия.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      height: 1.4,
                      color: FinnyColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ).fadeInWhen(motion, duration: const Duration(milliseconds: 400)),
            const Gap(12),

            // Навыки
            FinnyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Что уже пробовали:',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: FinnyColors.textPrimary,
                    ),
                  ),
                  const Gap(12),
                  _SkillRow(
                    title: 'Потребности и желания',
                    desc: 'Приоритет необходимых трат',
                    mastered: did('task_day_2'),
                  ),
                  _SkillRow(
                    title: 'Бюджетирование',
                    desc: 'Расходы ≤ баланс',
                    mastered:
                        state.plannedBudget?.isConfirmed == true ||
                        state.history.any((day) => day.plannedNeeds != null),
                  ),
                  _SkillRow(
                    title: 'Накопления',
                    desc: 'Пополнение копилки',
                    mastered: everSaved,
                  ),
                  _SkillRow(
                    title: 'Сравнение покупок',
                    desc: 'Сравнить стоимость корзин и сдачу',
                    mastered: did('task_day_4') && did('task_day_5'),
                  ),
                  _SkillRow(
                    title: 'Подушка безопасности',
                    desc: 'Выход при неожиданной трате',
                    mastered: did('task_day_7'),
                  ),
                ],
              ),
            ).fadeInWhen(
              motion,
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
            ),
            const Gap(12),

            FinnyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Решения для разговора',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: FinnyColors.textPrimary,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    recentDecisions.isEmpty
                        ? 'После первых заданий здесь появятся решения ребёнка.'
                        : 'Спросите, почему ребёнок выбрал этот путь и что изменилось.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: FinnyColors.textSecondary,
                    ),
                  ),
                  for (final decision in recentDecisions) ...[
                    const Gap(10),
                    Text(
                      titleFor(decision.taskId),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: FinnyColors.textPrimary,
                      ),
                    ),
                    Text(
                      decision.outcomeDescription,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: FinnyColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(12),

            // Настройки
            FinnyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Настройки',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: FinnyColors.textPrimary,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: Text(
                        'Анимация Финни',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
                      ),
                      value: state.settings.animationsEnabled,
                      activeTrackColor: FinnyColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: ref
                          .read(gameEngineProvider.notifier)
                          .setAvatarAnimations,
                    ),
                  ),
                ],
              ),
            ).fadeInWhen(
              motion,
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
            ),
            const Gap(20),

            // Сброс
            Center(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: FinnyColors.danger,
                  size: 18,
                ),
                label: Text(
                  'Сбросить прогресс',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: FinnyColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => _confirmReset(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Сбросить прогресс?',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Все данные будут удалены. Игра начнётся с Дня 1.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13),
        ),
        actions: [
          FinnyButton.ghost(
            label: 'Отмена',
            onPressed: () => Navigator.pop(ctx),
          ),
          FinnyButton(
            label: 'Сбросить',
            variant: FinnyButtonVariant.danger,
            onPressed: () async {
              await ref.read(finnyAppearanceProvider).reset();
              if (!context.mounted) return;
              ref.read(gameEngineProvider.notifier).resetGame();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ── Строка навыка ──

class _SkillRow extends StatelessWidget {
  final String title;
  final String desc;
  final bool mastered;

  const _SkillRow({
    required this.title,
    required this.desc,
    required this.mastered,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            mastered
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: mastered ? FinnyColors.success : FinnyColors.textTertiary,
            size: 18,
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FinnyColors.textPrimary,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: FinnyColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
