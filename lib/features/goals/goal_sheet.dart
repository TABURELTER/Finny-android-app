import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../core/theme/finny_widgets.dart';
import '../../game/content/goals.dart';
import '../../game/content/shop_items.dart';
import '../../game/engine/game_engine.dart';

class GoalSheet extends ConsumerWidget {
  const GoalSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const GoalSheet(),
  );

  static IconData _icon(String id) => switch (id) {
    'treehouse' => Icons.forest_rounded,
    'skate' => Icons.skateboarding_rounded,
    _ => Icons.rocket_launch_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameEngineProvider);
    final current = kAvailableGoals.firstWhere(
      (goal) => goal.id == state.goal.goalId,
      orElse: () => kAvailableGoals.first,
    );
    final stage = current.getStageForProgress(state.savings);
    final owned = state.inventory.hasItem('goal_${current.id}');
    final funded = state.savings >= current.targetCost;
    final remaining = (current.targetCost - state.savings).clamp(
      0,
      current.targetCost,
    );

    return FinnyBottomSheet(
      heightFactor: .91,
      title: 'Мечта',
      subtitle: owned
          ? 'Уже сбылась!'
          : funded
          ? 'Накоплено. Теперь можно получить.'
          : 'До цели осталось $remaining 🪙',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final goal in kAvailableGoals)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Material(
                          color: goal.id == current.id
                              ? FinnyColors.primaryLight
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => ref
                                .read(gameEngineProvider.notifier)
                                .selectGoal(goal.id),
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              height: 58,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _icon(goal.id),
                                    size: 23,
                                    color: FinnyColors.primary,
                                  ),
                                  Text(
                                    '${goal.targetCost} 🪙',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9F8),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icon(current.id),
                        size: 35,
                        color: FinnyColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.name,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: FinnyColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            owned
                                ? 'Теперь она в домике ${state.profile.petName}.'
                                : stage.description,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.2,
                              color: FinnyColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.savings_rounded,
                    size: 21,
                    color: FinnyColors.primary,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'В копилке',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${state.savings} / ${current.targetCost}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: FinnyColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: state.goal.progress,
                  color: FinnyColors.primary,
                  backgroundColor: const Color(0xFFE9E3EE),
                ),
              ),
              const SizedBox(height: 12),
              if (!funded && !owned) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Сколько отложим сегодня?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final amount in [5, 10, 25])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: SizedBox(
                            height: 49,
                            child: OutlinedButton(
                              onPressed: state.balance >= amount
                                  ? () => _depositAndCelebrate(
                                      context,
                                      ref,
                                      amount,
                                    )
                                  : null,
                              child: Text('+$amount'),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: SizedBox(
                        height: 49,
                        child: FilledButton(
                          onPressed: state.balance > 0
                              ? () => _depositAllWithFoodCheck(
                                  context,
                                  ref,
                                  state.balance,
                                )
                              : null,
                          child: const Text('Всё'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (funded && !owned)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _confirmClaim(
                      context,
                      ref,
                      current.name,
                      current.targetCost,
                      state.savings,
                    ),
                    icon: Icon(_icon(current.id)),
                    label: const Text(
                      'Получить мечту',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              if (owned)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Выбери другую мечту: накопления можно сохранить для неё.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: FinnyColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'План сам не списывает монеты. Взнос и получение — отдельные решения.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: FinnyColors.textSecondary,
                ),
              ),
              if (state.savings > 0) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () =>
                      _confirmWithdrawal(context, ref, state.savings),
                  icon: const Icon(Icons.keyboard_return_rounded, size: 18),
                  label: const Text('Взять монеты из копилки'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _depositAllWithFoodCheck(
    BuildContext context,
    WidgetRef ref,
    int requestedAmount,
  ) {
    final state = ref.read(gameEngineProvider);
    final remainingForGoal = state.goal.targetAmount - state.goal.savedAmount;
    final deposit = requestedAmount.clamp(0, remainingForGoal);
    final foodCost = kShopCatalog
        .firstWhere((item) => item.id == 'food_1')
        .price;
    final walletAfter = state.balance - deposit;
    if (state.inventory.foodReserveDays > 1 || walletAfter >= foodCost) {
      _depositAndCelebrate(context, ref, requestedAmount);
      return;
    }

    final keepForFood = state.balance - foodCost;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        void proceed(int amount) {
          Navigator.pop(dialogContext);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) _depositAndCelebrate(context, ref, amount);
          });
        }

        return Dialog(
          backgroundColor: FinnyColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: FinnyColors.warningLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: FinnyColors.warning,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Оставим на еду?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: FinnyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'В копилку +$deposit',
                        style: TextStyle(
                          color: FinnyColors.primaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'В кошельке останется $walletAfter',
                        style: const TextStyle(
                          color: Color(0xFFAE3B4D),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  state.inventory.foodReserveDays == 0
                      ? 'В кладовке нет еды.'
                      : 'В кладовке осталась одна порция.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Следующая порция еды — $foodCost 🪙.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FinnyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                if (keepForFood > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 47,
                    child: FilledButton(
                      onPressed: () => proceed(keepForFood),
                      child: Text('Оставить $foodCost на еду'),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => proceed(requestedAmount),
                    child: const Text('Всё равно отложить'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Пока не откладывать'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _depositAndCelebrate(BuildContext context, WidgetRef ref, int amount) {
    final before = ref.read(gameEngineProvider);
    if (!ref.read(gameEngineProvider.notifier).depositToGoal(amount)) return;
    final after = ref.read(gameEngineProvider);
    final moved = before.balance - after.balance;
    if (after.settings.hapticsEnabled) HapticFeedback.lightImpact();
    final animate =
        after.settings.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: FinnyColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .65, end: 1),
                duration: animate
                    ? const Duration(milliseconds: 430)
                    : Duration.zero,
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5D5FF),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.savings_rounded,
                        color: FinnyColors.primary,
                        size: 55,
                      ),
                      Positioned(
                        top: 4,
                        right: 5,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF9D6200),
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                after.goal.isCompleted
                    ? 'Мечта собрана!'
                    : 'Мечта стала ближе!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: FinnyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$moved 🪙 перешли в копилку. Они не пропали.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: FinnyColors.textSecondary,
                ),
              ),
              const SizedBox(height: 11),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5D5FF),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  children: [
                    _moneyMovementRow(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Из кошелька',
                      change: '−$moved',
                      detail:
                          'Было ${before.balance}, осталось ${after.balance}',
                      color: const Color(0xFFAE3B4D),
                      background: const Color(0xFFFFE8EA),
                    ),
                    const SizedBox(height: 7),
                    _moneyMovementRow(
                      icon: Icons.savings_rounded,
                      label: 'В копилку',
                      change: '+$moved',
                      detail: 'Было ${before.savings}, стало ${after.savings}',
                      color: FinnyColors.primaryDark,
                      background: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    after.goal.isCompleted ? 'Посмотреть мечту' : 'Продолжить',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moneyMovementRow({
    required IconData icon,
    required String label,
    required String change,
    required String detail,
    required Color color,
    required Color background,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          change,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    ),
  );

  void _confirmClaim(
    BuildContext context,
    WidgetRef ref,
    String name,
    int price,
    int saved,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Мечта готова!'),
        content: Text(
          '$name стоит $price 🪙 из копилки. '
          'Было $saved, останется ${saved - price} 🪙. Финни обрадуется и станет бодрее. Получить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Пока нет'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(gameEngineProvider.notifier).claimGoal();
              Navigator.pop(dialogContext);
            },
            child: const Text('Да, получить'),
          ),
        ],
      ),
    );
  }

  void _confirmWithdrawal(BuildContext context, WidgetRef ref, int saved) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Открыть копилку?'),
        content: Text(
          'Вернуть $saved 🪙 в кошелёк? '
          'В копилке станет 0. Мечта останется доступной позже.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Оставить'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(gameEngineProvider.notifier).withdrawFromGoal(saved);
              Navigator.pop(dialogContext);
            },
            child: const Text('Вернуть монеты'),
          ),
        ],
      ),
    );
  }
}
