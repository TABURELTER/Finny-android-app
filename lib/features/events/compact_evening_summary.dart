import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../game/engine/game_engine.dart';

/// A fixed-size evening review that shows what changed and why on one page.
class CompactEveningSummary extends ConsumerWidget {
  const CompactEveningSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameEngineProvider);
    final summary = state.history.isNotEmpty ? state.history.last : null;
    final lastDay = state.day >= 10;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 560,
        height: math.min(560, MediaQuery.sizeOf(context).height - 54),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 15, 17, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.nights_stay_rounded,
                    color: FinnyColors.primary,
                    size: 25,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastDay
                          ? 'Десять дней с Финни'
                          : 'Вечер · день ${state.day}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: FinnyColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Посмотрим, как решения изменили день.',
                  style: TextStyle(
                    fontSize: 13,
                    color: FinnyColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Metric(
                    'Получено',
                    _signed(summary?.income ?? state.dayEarned),
                    background: FinnyColors.successLight,
                    foreground: FinnyColors.success,
                    icon: Icons.trending_up_rounded,
                    semanticLabel:
                        'За день получено ${summary?.income ?? state.dayEarned} монет',
                  ),
                  const SizedBox(width: 6),
                  _Metric(
                    'Потрачено',
                    _signed(summary?.spent ?? state.daySpent, outgoing: true),
                    background: const Color(0xFFFFE7E8),
                    foreground: const Color(0xFFAD3B4C),
                    icon: Icons.trending_down_rounded,
                    semanticLabel:
                        'За день потрачено ${summary?.spent ?? state.daySpent} монет',
                  ),
                  const SizedBox(width: 6),
                  _Metric(
                    'В копилку',
                    _signed(summary?.saved ?? state.daySaved),
                    background: FinnyColors.primaryLight,
                    foreground: FinnyColors.primaryDark,
                    icon: Icons.savings_rounded,
                    semanticLabel:
                        'Переложено в копилку ${summary?.saved ?? state.daySaved} монет',
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'План и результат',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: FinnyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (summary?.plannedNeeds == null)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Сегодня плана не было. Завтра попробуй заранее распределить монеты.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: FinnyColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        _Comparison(
                          'Нужно',
                          summary!.plannedNeeds!,
                          summary.actualNeeds,
                        ),
                        _Comparison(
                          'Радости',
                          summary.plannedWants!,
                          summary.actualWants,
                        ),
                        if (summary.reserveIsCash)
                          _CashReserveComparison(
                            planned: summary.plannedReserve!,
                            remaining: summary.actualReserve,
                            used: summary.actualReserveSpent,
                          )
                        else
                          _Comparison(
                            'Запас',
                            summary.plannedReserve!,
                            summary.actualReserve,
                          ),
                        _Comparison(
                          'Мечта',
                          summary.plannedSavings!,
                          summary.saved,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0E2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      color: Color(0xFF5B815C),
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        summary?.reflection ?? 'Завтра будет новый шанс применить то, что узнал сегодня.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: FinnyColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: lastDay
                      ? () => Navigator.pop(context)
                      : () {
                          ref
                              .read(gameEngineProvider.notifier)
                              .advanceToNextDay();
                          Navigator.pop(context);
                        },
                  child: Text(
                    lastDay
                        ? 'Вернуться в домик'
                        : 'Начать день ${state.day + 1}',
                    style: const TextStyle(
                      fontSize: 16,
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

class _Metric extends StatelessWidget {
  final String label, amount;
  final Color background, foreground;
  final IconData icon;
  final String semanticLabel;
  const _Metric(
    this.label,
    this.amount, {
    required this.background,
    required this.foreground,
    required this.icon,
    required this.semanticLabel,
  });
  @override
  Widget build(BuildContext context) {
    final amountColor = amount == '0' ? FinnyColors.textSecondary : foreground;
    return Expanded(
      child: Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: foreground.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: amountColor),
                  const SizedBox(width: 3),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _signed(int amount, {bool outgoing = false}) =>
    amount == 0 ? '0' : '${outgoing ? '-' : '+'}$amount';

class _Comparison extends StatelessWidget {
  final String label;
  final int planned, actual;
  const _Comparison(this.label, this.planned, this.actual);
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 29,
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: FinnyColors.textPrimary,
            ),
          ),
        ),
        Text(
          'план $planned · факт $actual',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: FinnyColors.primary,
          ),
        ),
      ],
    ),
  );
}

class _CashReserveComparison extends StatelessWidget {
  final int planned, remaining, used;
  const _CashReserveComparison({
    required this.planned,
    required this.remaining,
    required this.used,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Денежный запас',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: FinnyColors.textPrimary,
                ),
              ),
            ),
            Text(
              'план $planned',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: FinnyColors.primary,
              ),
            ),
          ],
        ),
        Text(
          'Осталось $remaining · использовано $used',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FinnyColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
