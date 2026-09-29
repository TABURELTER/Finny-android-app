import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../data/models/game_state.dart';
import '../../game/engine/game_engine.dart';

/// The evening reflects choices and Finny's condition in one short glance.
class CompactEveningSummary extends ConsumerWidget {
  const CompactEveningSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameEngineProvider);
    final summary = state.history.isNotEmpty ? state.history.last : null;
    final tenDayMilestone = state.phase == GamePhase.finalSummary;
    final stats = state.balanceStats;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: const Color(0xFFFFFCF6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.sizeOf(context).height - 24,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tenDayMilestone
                            ? 'Десять дней с Финни'
                            : 'Вечер · день ${state.day}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                tenDayMilestone
                    ? 'Первые десять дней позади. Завтра ждёт новый день!'
                    : summary?.balancedDay == true
                    ? 'Сегодня Финни удалось сохранить баланс!'
                    : 'Завтра можно выбрать другой путь.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _StateTile(
                    '🍽️',
                    'Сытость',
                    stats.satiety,
                    stats.satiety <= 2
                        ? 'Нужна еда'
                        : stats.satiety < 4
                        ? 'Нормально'
                        : 'Сыт',
                  ),
                  const SizedBox(width: 6),
                  _StateTile(
                    '⚡',
                    'Силы',
                    stats.energy,
                    stats.energy <= 1
                        ? 'Нужен отдых'
                        : stats.energy < 4
                        ? 'Нормально'
                        : 'Бодр',
                  ),
                  const SizedBox(width: 6),
                  _StateTile(
                    '💚',
                    'Здоровье',
                    stats.wellbeing,
                    stats.wellbeing <= 1
                        ? 'Нужна забота'
                        : stats.wellbeing < 4
                        ? 'Нормально'
                        : 'Хорошо',
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  _CoinTile(
                    'Получено',
                    summary?.income ?? state.dayEarned,
                    '+',
                  ),
                  const SizedBox(width: 6),
                  _CoinTile('Потрачено', summary?.spent ?? state.daySpent, '−'),
                  const SizedBox(width: 6),
                  _CoinTile('В копилку', summary?.saved ?? state.daySaved, '+'),
                ],
              ),
              if (summary != null && summary.plannedNeeds != null) ...[
                const SizedBox(height: 7),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FinnyColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'План и что получилось',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _PlanRow(
                        '🍽️ Еда',
                        summary.plannedNeeds!,
                        summary.actualNeeds,
                      ),
                      _PlanRow(
                        '🎈 Радости',
                        summary.plannedWants!,
                        summary.actualWants,
                      ),
                      _PlanRow(
                        '🐷 Мечта',
                        summary.plannedSavings!,
                        summary.saved,
                      ),
                      _PlanRow(
                        '🛟 Запас',
                        summary.plannedReserve!,
                        summary.actualReserve,
                      ),
                      if (summary.actualReserveSpent > 0)
                        Text(
                          'На неожиданности ушло ${summary.actualReserveSpent} 🪙.',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: FinnyColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        summary.planFeedback,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: summary.followedPlan
                              ? FinnyColors.success
                              : FinnyColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: FinnyColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  summary?.reflection ?? 'Финни ждёт нового дня.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () {
                    ref.read(gameEngineProvider.notifier).advanceToNextDay();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Начать день ${state.day + 1}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
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

class _PlanRow extends StatelessWidget {
  final String label;
  final int planned, actual;
  const _PlanRow(this.label, this.planned, this.actual);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text(
          'план $planned 🪙',
          style: const TextStyle(
            fontSize: 12,
            color: FinnyColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'факт $actual 🪙',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _StateTile extends StatelessWidget {
  final String icon, label, status;
  final double value;
  const _StateTile(this.icon, this.label, this.value, this.status);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 5,
              minHeight: 5,
              backgroundColor: FinnyColors.borderLight,
              color: value <= 1 ? FinnyColors.warning : FinnyColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              status,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                color: value <= 1 ? FinnyColors.warning : FinnyColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CoinTile extends StatelessWidget {
  final String label, sign;
  final int value;
  const _CoinTile(this.label, this.value, this.sign);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDCE),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$sign$value 🪙',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    ),
  );
}
