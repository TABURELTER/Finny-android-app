import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/finny_tokens.dart';
import '../../../data/models/game_state.dart';
import '../../../data/models/event_models.dart';
import '../../../data/models/item_models.dart';
import '../../../game/content/balance_cards.dart';
import '../../../game/content/days.dart';
import '../../../game/content/events.dart';
import '../../../game/engine/game_engine.dart';
import '../../../core/sound/sound_service.dart';
import '../../work/work_screen.dart';

EventDefinition? pendingStory(GameState state) {
  final day = dayConfigFor(state.day);
  if (day.scheduledEventId == null ||
      state.activeEvents.contains(day.scheduledEventId)) {
    return null;
  }
  for (final event in kGameEvents) {
    if (event.id == day.scheduledEventId) return event;
  }
  return null;
}

class BalanceStatsStrip extends StatelessWidget {
  final FinnyBalance stats;
  const BalanceStatsStrip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
    child: Row(
      children: [
        _Stat(
          '🍽️',
          'Сытость',
          stats.satiety,
          stats.satiety <= 2
              ? 'Нужна еда'
              : stats.satiety < 4
              ? 'Нормально'
              : 'Сыт',
          const Color(0xFFD07312),
        ),
        const SizedBox(width: 9),
        _Stat(
          '⚡',
          'Силы',
          stats.energy,
          stats.energy <= 1
              ? 'Нужен отдых'
              : stats.energy < 4
              ? 'Нормально'
              : 'Бодр',
          const Color(0xFF147DA4),
        ),
        const SizedBox(width: 9),
        _Stat(
          '❤️',
          'Здоровье',
          stats.wellbeing,
          stats.wellbeing <= 1
              ? 'Нужна забота'
              : stats.wellbeing < 4
              ? 'Нормально'
              : 'Хорошо',
          FinnyColors.success,
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  final String icon, label, status;
  final double value;
  final Color color;
  const _Stat(this.icon, this.label, this.value, this.status, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: '$label: $status',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$icon $label',
            maxLines: 1,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value / 5,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class BalanceDecisionCard extends ConsumerWidget {
  final GameState state;
  final VoidCallback finish;
  final VoidCallback plan;
  const BalanceDecisionCard({
    super.key,
    required this.state,
    required this.finish,
    required this.plan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.plannedBudget?.isConfirmed != true) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧭', style: TextStyle(fontSize: 30)),
            const SizedBox(height: 4),
            const Text(
              'Сначала короткий план',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Оставим на еду, запас и мечту. Это не потратит монеты — вечером сравним с тем, что получилось.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.2),
            ),
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              height: 51,
              child: FilledButton.icon(
                onPressed: plan,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Составить план'),
              ),
            ),
          ],
        ),
      );
    }
    final story = pendingStory(state);
    final card = story == null ? balanceCardFor(state) : null;
    final finished = story == null && card == null;
    final title = story?.title ?? card?.title ?? 'Дела на сегодня готовы';
    final icon = story?.icon ?? card?.icon ?? '🌙';
    final prompt =
        story?.description ??
        card?.prompt ??
        'Можно посмотреть комнату, зайти в лавку или начать новый день.';

    int price(Object option) {
      if (option is EventChoice) {
        return option.freeWithItemId != null &&
                state.inventory.hasItem(option.freeWithItemId!)
            ? 0
            : option.cost;
      }
      final choice = option as BalanceChoice;
      return choice.coins < 0 ? -choice.coins : 0;
    }

    bool available(Object option) {
      if (option is EventChoice) {
        if (state.balance >= price(option)) return true;
        final missing = price(option) - state.balance;
        return story?.id == 'rain_roof' &&
            option.id == 'repair_now' &&
            state.savings >= missing &&
            state.goal.savedAmount >= missing;
      }
      final choice = option as BalanceChoice;
      if (choice.opensWork) return true;
      return (choice.useSavings ? state.savings : state.balance) >=
          price(option);
    }

    String categoryLabel(Object option) {
      if (option is EventChoice) {
        return switch (option.expenseCategory) {
          ItemCategory.need => 'Нужное',
          ItemCategory.reserve => 'Запас',
          ItemCategory.want || ItemCategory.useful => 'Желаемое',
        };
      }
      final choice = option as BalanceChoice;
      if (choice.meal != null) return 'Нужное';
      return choice.id == 'buy' ? 'Желаемое' : 'Запас';
    }

    String? note(Object option) {
      if (option is EventChoice &&
          option.freeWithItemId != null &&
          state.inventory.hasItem(option.freeWithItemId!)) {
        return 'Используем набор из дома';
      }
      if (option is EventChoice &&
          state.balance < price(option) &&
          available(option)) {
        return 'Часть возьмём из копилки';
      }
      if (!available(option)) {
        final availableCoins = option is BalanceChoice && option.useSavings
            ? state.savings
            : state.balance;
        return 'Не хватает ${price(option) - availableCoins} 🪙';
      }
      if (option is EventChoice) {
        return price(option) > 0 ? categoryLabel(option) : null;
      }
      final choice = option as BalanceChoice;
      if (choice.meal == state.balanceStats.lastMeal && choice.wellbeing > 0) {
        return 'Та же еда: без бонуса разнообразия';
      }
      if (choice.fromPantry) return 'Возьмём из запаса';
      if (choice.useSavings) return 'Мечта станет чуть дальше';
      return price(option) > 0 ? categoryLabel(option) : null;
    }

    String optionTitle(Object option) {
      if (option is BalanceChoice) {
        return option.title.replaceFirst(RegExp(r' · \d+ 🪙$'), '');
      }
      final storyChoice = option as EventChoice;
      return storyChoice.title.replaceFirst(RegExp(r' · [+-]?\d+ 🪙$'), '');
    }

    List<Widget> effects(Object option) {
      double satiety = 0, energy = 0, wellbeing = 0;
      int coins = 0;
      if (option is BalanceChoice) {
        final impact = option.opensWork ? workImpact(state.balanceStats) : null;
        satiety = impact?.satiety ?? option.satiety;
        energy = impact?.energy ?? option.energy;
        wellbeing =
            impact?.wellbeing ??
            (option.meal == state.balanceStats.lastMeal ? 0 : option.wellbeing);
        coins = option.opensWork ? 10 : option.coins;
      } else if (option is EventChoice) {
        satiety = option.satiety.toDouble();
        energy = option.energy.toDouble();
        wellbeing = option.wellbeing.toDouble();
        coins = option.reward - price(option);
      }
      final badges = <Widget>[];
      if (coins != 0) {
        badges.add(
          _EffectBadge(
            '🪙${coins > 0 ? '+' : '−'}${coins.abs()}',
            coins > 0 ? FinnyColors.primaryDark : FinnyColors.warning,
          ),
        );
      }
      if (option is EventChoice &&
          option.foodReserveChange != null &&
          option.foodReserveChange != 0) {
        final amount = option.foodReserveChange!;
        badges.add(
          _EffectBadge(
            '🥪${amount > 0 ? '+' : '−'}${amount.abs()}',
            amount > 0 ? FinnyColors.success : FinnyColors.danger,
          ),
        );
      }
      if (option is EventChoice && option.grantItemId != null) {
        badges.add(_EffectBadge('🎁+', FinnyColors.primaryDark));
      }
      if (option is BalanceChoice && option.fromPantry) {
        badges.add(const _EffectBadge('🥪−1', FinnyColors.warning));
      }
      if (satiety != 0) {
        badges.add(
          _EffectBadge(
            '🍽️${satiety > 0 ? '+' : '−'}',
            satiety > 0 ? FinnyColors.success : FinnyColors.danger,
          ),
        );
      }
      if (energy != 0) {
        badges.add(
          _EffectBadge(
            '⚡${energy > 0 ? '+' : '−'}',
            energy > 0 ? FinnyColors.success : FinnyColors.danger,
          ),
        );
      }
      if (wellbeing != 0) {
        badges.add(
          _EffectBadge(
            '❤️${wellbeing > 0 ? '+' : '−'}',
            wellbeing > 0 ? FinnyColors.success : FinnyColors.danger,
          ),
        );
      }
      if (badges.isEmpty) {
        badges.add(
          const _EffectBadge('Без перемен', FinnyColors.textSecondary),
        );
      }
      return badges;
    }

    final List<Object> options = story != null
        ? story.choices
              .where(
                (choice) =>
                    choice.grantItemId == null ||
                    !state.inventory.hasItem(choice.grantItemId!),
              )
              .toList()
        : card?.choices ?? [];

    void confirmSpending(Object option, VoidCallback onConfirm) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Подтвердить покупку?'),
          content: Text(
            '${optionTitle(option)} — ${price(option)} 🪙. Категория: ${categoryLabel(option)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Пока не покупать'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              child: const Text('Подтвердить'),
            ),
          ],
        ),
      );
    }

    Widget optionButton(Object option, int index) => _DecisionButton(
      number: index + 1,
      title: optionTitle(option),
      effects: effects(option),
      note: note(option),
      enabled: available(option),
      onTap: () {
        if (option is EventChoice) {
          final useSavings = state.balance < price(option);
          if (useSavings) {
            SoundService.instance.playWarning();
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Взять из копилки?'),
                content: Text(
                  'На ремонт не хватает ${price(option) - state.balance} 🪙. Мечта станет дальше.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Другой вариант'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      SoundService.instance.playCoin();
                      ref
                          .read(gameEngineProvider.notifier)
                          .resolveEventChoice(story!, option, useSavings: true);
                    },
                    child: const Text('Починить крышу'),
                  ),
                ],
              ),
            );
          } else {
            void choose() {
              if (price(option) > 0) {
                SoundService.instance.playCoin();
              } else {
                SoundService.instance.playTap();
              }
              ref
                  .read(gameEngineProvider.notifier)
                  .resolveEventChoice(story!, option);
            }
            if (price(option) > 0) {
              confirmSpending(option, choose);
            } else {
              choose();
            }
          }
        } else if (option is BalanceChoice) {
          if (option.opensWork) {
            SoundService.instance.playTap();
            WorkScreen.open(context);
          } else {
            void choose() {
              if (price(option) > 0) {
                SoundService.instance.playCoin();
              } else {
                SoundService.instance.playTap();
              }
              ref
                  .read(gameEngineProvider.notifier)
                  .chooseBalanceCard(card!.id, option.id);
            }
            if (price(option) > 0) {
              confirmSpending(option, choose);
            } else {
              choose();
            }
          }
        }
      },
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 230),
      child: Container(
        key: ValueKey('$title-${state.balanceStats.cardsToday}'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: FinnyColors.primaryLight.withValues(alpha: .58),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FinnyColors.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: FinnyColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 25)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: FinnyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          prompt,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.22,
                            color: FinnyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${state.balanceStats.cardsToday}/4',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: FinnyColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (finished)
              SizedBox(
                width: double.infinity,
                height: 53,
                child: FilledButton.icon(
                  onPressed: finish,
                  icon: const Icon(Icons.nights_stay_rounded),
                  label: const Text('Посмотреть вечер'),
                ),
              )
            else
              Column(
                children: [
                  for (final (index, option) in options.indexed) ...[
                    if (index > 0) const SizedBox(height: 8),
                    optionButton(option, index),
                  ],
                ],
              ),
            if (state.day == 1 && state.balanceStats.cardsToday == 0) ...[
              const SizedBox(height: 5),
              const Text(
                'Нажми вариант. Сначала посмотри цену и результат.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final int number;
  final String title;
  final String? note;
  final List<Widget> effects;
  final bool enabled;
  final VoidCallback onTap;
  const _DecisionButton({
    required this.number,
    required this.title,
    required this.effects,
    required this.note,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: enabled ? FinnyColors.surface : FinnyColors.surfaceMuted,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 69),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: FinnyColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: FinnyColors.primaryLight,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: FinnyColors.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(spacing: 5, runSpacing: 4, children: effects),
                    if (note != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        note!,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.12,
                          color: FinnyColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 5),
              CircleAvatar(
                radius: 15,
                backgroundColor: enabled
                    ? FinnyColors.primary
                    : FinnyColors.border,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EffectBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _EffectBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
    ),
  );
}
