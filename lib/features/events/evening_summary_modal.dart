import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/finny_tokens.dart';
import '../../core/theme/finny_widgets.dart';
import '../../data/models/game_state.dart';
import '../../data/models/history_models.dart';
import '../../game/engine/game_engine.dart';
import '../../shared/widgets/finny_appearance.dart';
import 'compact_evening_summary.dart';

class EveningSummaryModal extends ConsumerWidget {
  const EveningSummaryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CompactEveningSummary(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameEngineProvider);
    final isFinalDay = state.day >= 10;
    final lastSummary = state.history.isNotEmpty ? state.history.last : null;

    if (isFinalDay) {
      return _FinalSummary(state: state);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: FinnyColors.surface,
          borderRadius: BorderRadius.circular(FinnyRadius.xl),
          border: Border.all(color: FinnyColors.border, width: 1),
          boxShadow: FinnyShadows.lg,
        ),
        padding: FinnySpacing.cardPadding,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🌙',
                style: TextStyle(fontSize: 40),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
              const Gap(8),
              Text(
                'Вечер Дня ${state.day}',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: FinnyColors.textPrimary,
                ),
              ),
              Text(
                'Финни готовится ко сну',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: FinnyColors.textSecondary,
                ),
              ),
              const Gap(16),

              // Метрики дня
              FinnyCard(
                color: FinnyColors.surfaceMuted,
                borderColor: FinnyColors.borderLight,
                child: Column(
                  children: [
                    FinnyMetricRow(
                      label: 'Получено',
                      value: '+${lastSummary?.income ?? state.dayEarned} 🪙',
                      valueColor: FinnyColors.success,
                    ),
                    const Gap(8),
                    const FinnyDivider(),
                    const Gap(8),
                    FinnyMetricRow(
                      label: 'Потрачено',
                      value: '-${lastSummary?.spent ?? state.daySpent} 🪙',
                      valueColor: const Color(0xFFAD3B4C),
                    ),
                    const Gap(8),
                    const FinnyDivider(),
                    const Gap(8),
                    FinnyMetricRow(
                      label: 'В копилку',
                      value: '+${lastSummary?.saved ?? state.daySaved} 🪙',
                      valueColor: FinnyColors.accent,
                    ),
                    const Gap(8),
                    const FinnyDivider(),
                    const Gap(8),
                    FinnyMetricRow(
                      label: 'Запас еды',
                      value: '${state.inventory.foodReserveDays} дн.',
                      valueColor: FinnyColors.success,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const Gap(12),

              if (lastSummary != null) _PlanComparison(summary: lastSummary),
              if (lastSummary != null) const Gap(12),

              // Рефлексия
              FinnyGlassCard(
                tintColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        lastSummary?.reflection ??
                            'Спокойный день! Завтра ждут новые открытия.',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: FinnyColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const Gap(20),

              FinnyButton.primary(
                label: 'Спать · День ${state.day + 1}',
                emoji: '🛏️',
                onPressed: () {
                  ref.read(gameEngineProvider.notifier).advanceToNextDay();
                  Navigator.pop(context);
                },
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _PlanComparison extends StatelessWidget {
  final DaySummaryRecord summary;
  const _PlanComparison({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.plannedNeeds == null) {
      return Text(
        'Сегодня плана не было. Завтра попробуй заранее распределить монеты.',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: FinnyColors.textSecondary,
        ),
      );
    }
    return FinnyCard(
      color: FinnyColors.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'План и результат',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: FinnyColors.textPrimary,
            ),
          ),
          const Gap(6),
          _planRow('Еда', summary.plannedNeeds!, summary.actualNeeds),
          _planRow('Радости и уют', summary.plannedWants!, summary.actualWants),
          if (summary.reserveIsCash)
            _cashReserveRow(summary)
          else
            _planRow(
              'Запас и события',
              summary.plannedReserve!,
              summary.actualReserve,
            ),
          _planRow('Мечта', summary.plannedSavings!, summary.saved),
          const Gap(4),
          Text(
            summary.followedPlan
                ? 'Ты учёл нужное и приблизил мечту. Финни учится планировать!'
                : 'Посмотри, где план изменился. Завтра можно учесть это заранее.',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: FinnyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planRow(String title, int planned, int actual) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: FinnyColors.textPrimary,
            ),
          ),
        ),
        Text(
          'план $planned · факт $actual',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: FinnyColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _cashReserveRow(DaySummaryRecord summary) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Денежный запас',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: FinnyColors.textPrimary,
                ),
              ),
            ),
            Text(
              'план ${summary.plannedReserve}',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: FinnyColors.primary,
              ),
            ),
          ],
        ),
        Text(
          'Осталось в кошельке ${summary.actualReserve} · использовано ${summary.actualReserveSpent}',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FinnyColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

// ── Финальный итог 10 дней ──

class _FinalSummary extends ConsumerWidget {
  final GameState state;

  const _FinalSummary({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int totalEarned = 0;
    int totalSpent = 0;
    int totalSaved = state.savings;

    for (final h in state.history) {
      totalEarned += h.income;
      totalSpent += h.spent;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: FinnyColors.surface,
          borderRadius: BorderRadius.circular(FinnyRadius.xl),
          border: Border.all(color: FinnyColors.border, width: 1),
          boxShadow: FinnyShadows.lg,
        ),
        child: SingleChildScrollView(
          padding: FinnySpacing.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 48))
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.5, 0.5)),
              const Gap(8),
              Text(
                '10 Дней с Финни!',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: FinnyColors.textPrimary,
                ),
              ),
              Text(
                'Приключение завершено',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: FinnyColors.textSecondary,
                ),
              ),
              const Gap(16),

              // Итоги
              FinnyGlassCard(
                tintColor: FinnyColors.coin,
                child: Column(
                  children: [
                    FinnyMetricRow(
                      label: 'Всего получено',
                      value: '+$totalEarned 🪙',
                      valueColor: FinnyColors.success,
                    ),
                    const Gap(8),
                    const FinnyDivider(),
                    const Gap(8),
                    FinnyMetricRow(
                      label: 'Всего потрачено',
                      value: '-$totalSpent 🪙',
                      valueColor: const Color(0xFFAD3B4C),
                    ),
                    const Gap(8),
                    const FinnyDivider(),
                    const Gap(8),
                    FinnyMetricRow(
                      label: 'В копилке',
                      value: '$totalSaved 🪙',
                      valueColor: FinnyColors.accent,
                    ),
                    const Gap(8),
                    const FinnyDivider(),
                    const Gap(8),
                    FinnyMetricRow(
                      label: 'Мечта',
                      value: state.goal.isCompleted
                          ? 'Собрана! 🎉'
                          : '${(state.goal.progress * 100).toInt()}%',
                      valueColor: state.goal.isCompleted
                          ? FinnyColors.success
                          : FinnyColors.accent,
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Чему научились
              FinnyCard(
                color: FinnyColors.successLight,
                borderColor: FinnyColors.success.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Чему мы научились:',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: FinnyColors.success,
                      ),
                    ),
                    const Gap(8),
                    ...[
                      'Деньги — возможность подготовиться к будущему',
                      'Запасы помогают пережить трудные дни',
                      'Если откладывать понемногу — мечта станет реальностью!',
                    ].map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•  ',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: FinnyColors.success,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                text,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: FinnyColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),

              Row(
                children: [
                  Expanded(
                    child: FinnyButton.secondary(
                      label: 'Заново',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Начать заново?'),
                            content: const Text(
                              'Прогресс, покупки и имя Финни будут удалены.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Отмена'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Сбросить'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                        await ref.read(finnyAppearanceProvider).reset();
                        if (!context.mounted) return;
                        ref.read(gameEngineProvider.notifier).resetGame();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: FinnyButton.primary(
                      label: 'Остаться',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
