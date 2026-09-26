import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../data/models/event_models.dart';
import '../../game/content/events.dart';
import '../../game/engine/game_engine.dart';
import '../../shared/widgets/pet_avatar_widget.dart';
import 'evening_summary_modal.dart';

enum _Step { choose, review, result }

/// The child reviews a choice before any coins move, then sees the result.
class EventModal extends ConsumerStatefulWidget {
  final String eventId;
  const EventModal({super.key, required this.eventId});

  /// HomeScreen uses this to leave the evening summary behind the result.
  static bool isOpen = false;

  static Future<void> show(BuildContext context, String eventId) {
    if (isOpen) return Future<void>.value();
    isOpen = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EventModal(eventId: eventId),
    ).whenComplete(() => isOpen = false);
  }

  @override
  ConsumerState<EventModal> createState() => _EventModalState();
}

class _EventModalState extends ConsumerState<EventModal> {
  _Step step = _Step.choose;
  EventChoice? choice;
  bool useSavings = false;
  bool failed = false;
  bool allowClose = false;
  bool usedKit = false;
  int beforeWallet = 0;
  int beforeSavings = 0;

  EventDefinition get event => kGameEvents.firstWhere(
    (e) => e.id == widget.eventId,
    orElse: () => kGameEvents.first,
  );
  bool get rainy => event.id == 'rain_roof';

  void _select(EventChoice option) => setState(() {
    choice = option;
    useSavings = false;
    failed = false;
    step = _Step.review;
  });

  void _confirm() {
    final before = ref.read(gameEngineProvider);
    final accepted = ref
        .read(gameEngineProvider.notifier)
        .resolveEventChoice(event, choice!, useSavings: useSavings);
    if (!accepted) {
      setState(() => failed = true);
      return;
    }
    setState(() {
      beforeWallet = before.balance;
      beforeSavings = before.savings;
      usedKit = choice!.freeWithItemId != null &&
          before.inventory.hasItem(choice!.freeWithItemId!);
      step = _Step.result;
    });
  }

  void _toEvening() {
    setState(() => allowClose = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final parentContext = navigator.context;
      navigator.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (parentContext.mounted) EveningSummaryModal.show(parentContext);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameEngineProvider);
    return PopScope(canPop: allowClose, child: Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 560,
        height: math.min(580, MediaQuery.sizeOf(context).height - 36),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
          child: switch (step) {
            _Step.choose => _choose(
              state.balance,
              state.savings,
              state.inventory.hasItem('repair_kit'),
            ),
            _Step.review => _review(
              state.balance,
              state.savings,
              state.inventory.hasItem('repair_kit'),
            ),
            _Step.result => _result(state.balance, state.savings),
          },
        ),
      ),
    ));
  }

  Widget _title(String heading, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            rainy ? Icons.water_drop_rounded : Icons.celebration_rounded,
            color: FinnyColors.primary,
            size: 25,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              heading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: FinnyColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          height: 1.18,
          color: FinnyColors.textSecondary,
        ),
      ),
    ],
  );

  Widget _choose(int wallet, int savings, bool hasKit) => Column(
    children: [
      _title(event.title, event.description),
      const SizedBox(height: 8),
      Expanded(child: _Scene(rainy: rainy)),
      const SizedBox(height: 8),
      _Wallet(wallet: wallet, savings: savings),
      const SizedBox(height: 7),
      for (final option in event.choices) ...[
        _Choice(
          choice: option,
          cost: option.freeWithItemId != null && hasKit ? 0 : option.cost,
          onTap: () => _select(option),
        ),
        const SizedBox(height: 6),
      ],
      const Text(
        'Коснись варианта: сначала покажу последствия.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: FinnyColors.textSecondary),
      ),
    ],
  );

  Widget _review(int wallet, int savings, bool hasKit) {
    final picked = choice!;
    final kitUsed = picked.freeWithItemId != null && hasKit;
    final cost = kitUsed ? 0 : picked.cost;
    final missing = math.max(0, cost - wallet);
    final canBorrow =
        rainy &&
        picked.id == 'repair_now' &&
        missing > 0 &&
        savings >= missing &&
        ref.read(gameEngineProvider).goal.savedAmount >= missing;
    final canPay = missing == 0 || (canBorrow && useSavings);
    final walletAfter = wallet >= cost ? wallet - cost : 0;
    final savingsAfter = savings - (useSavings ? missing : 0);

    return Column(
      children: [
        _title('Перед решением', picked.title),
        const SizedBox(height: 8),
        Expanded(child: _Scene(rainy: rainy)),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F0FA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            picked.immediateFeedback,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.18,
              fontWeight: FontWeight.w700,
              color: FinnyColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _Balance('Кошелёк', wallet,
              canPay ? walletAfter : null)),
            const SizedBox(width: 7),
            Expanded(child: _Balance('Копилка', savings,
              canPay ? savingsAfter : null)),
          ],
        ),
        const SizedBox(height: 7),
        if (kitUsed)
          const _Notice(
            Icons.handyman_rounded,
            'Набор мастера будет использован. Доплата — 0 монет.',
            FinnyColors.success,
          )
        else if (canBorrow)
          SizedBox(
            height: 64,
            child: CheckboxListTile(
              key: const Key('event_use_savings'),
              activeColor: FinnyColors.primary,
              checkColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: useSavings,
              onChanged: (value) => setState(() => useSavings = value ?? false),
              title: Text(
                'Взять $missing из копилки',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Тогда мечта станет дальше',
                style: TextStyle(fontSize: 11),
              ),
            ),
          )
        else if (missing > 0)
          _Notice(
            Icons.info_outline_rounded,
            'Не хватает $missing. Можно выбрать другой вариант.',
            FinnyColors.danger,
          ),
        const SizedBox(height: 5),
        Text(
          picked.consequenceText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.18,
            color: FinnyColors.textSecondary,
          ),
        ),
        if (failed)
          const Text(
            'Баланс изменился. Проверь выбор ещё раз.',
            style: TextStyle(fontSize: 12, color: FinnyColors.danger),
          ),
        const SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: TextButton(
            onPressed: () => setState(() => step = _Step.choose),
            child: const Text(
              'Посмотреть другие варианты',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            key: const Key('event_confirm'),
            onPressed: canPay ? _confirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: FinnyColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5DFED),
              disabledForegroundColor: FinnyColors.textSecondary,
            ),
            child: Text(
              canPay
                  ? 'Подтвердить · $cost монет'
                  : canBorrow
                  ? 'Сначала выбери копилку'
                  : 'Не хватает $missing монет',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _result(int wallet, int savings) => Column(
    children: [
      _title('Вот что получилось', choice!.title),
      const SizedBox(height: 9),
      Expanded(child: _Scene(rainy: rainy, resolved: true)),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _Balance('Кошелёк', beforeWallet, wallet)),
          const SizedBox(width: 7),
          Expanded(child: _Balance('Копилка', beforeSavings, savings)),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFF5B815C),
              size: 23,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                usedKit
                    ? 'Набор мастера помог починить крышу без новой траты.'
                    : savings < beforeSavings
                    ? '${choice!.consequenceText} Из копилки ушло ${beforeSavings - savings} монет — до мечты теперь дальше.'
                    : choice!.consequenceText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.2,
                  color: FinnyColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _toEvening,
          child: const Text(
            'Посмотреть вечер',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    ],
  );
}

class _Scene extends StatelessWidget {
  final bool rainy;
  final bool resolved;
  const _Scene({required this.rainy, this.resolved = false});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(19),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rainy
              ? const [Color(0xFFE1EAF2), Color(0xFFF5F0FA)]
              : const [Color(0xFFFCE9DD), Color(0xFFF7EEFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 17,
            bottom: -10,
            child: Icon(
              rainy ? Icons.cottage_rounded : Icons.festival_rounded,
              size: 93,
              color: rainy ? const Color(0xFF8495AF) : const Color(0xFFEFAA8E),
            ),
          ),
          Positioned(
            left: 25,
            top: 3,
            child: Icon(
              rainy ? Icons.cloud_rounded : Icons.auto_awesome_rounded,
              size: 50,
              color: Colors.white.withValues(alpha: .85),
            ),
          ),
          if (rainy && !resolved) ...[
            const Positioned(
              left: 25,
              top: 50,
              child: Icon(
                Icons.water_drop_rounded,
                size: 15,
                color: Color(0xFF8BAFCE),
              ),
            ),
            const Positioned(
              left: 85,
              top: 31,
              child: Icon(
                Icons.water_drop_rounded,
                size: 13,
                color: Color(0xFF8BAFCE),
              ),
            ),
          ],
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 13),
              child: PetAvatarWidget(
                mood: rainy && !resolved ? FinnyMood.worried : FinnyMood.good,
                size: 94,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Wallet extends StatelessWidget {
  final int wallet, savings;
  const _Wallet({required this.wallet, required this.savings});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.account_balance_wallet_rounded,
        size: 21,
        color: FinnyColors.primary,
      ),
      const SizedBox(width: 5),
      Text(
        'Кошелёк $wallet',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
      const Spacer(),
      const Icon(Icons.savings_rounded, size: 21, color: FinnyColors.piggy),
      const SizedBox(width: 5),
      Text(
        'Копилка $savings',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _Choice extends StatelessWidget {
  final EventChoice choice;
  final int cost;
  final VoidCallback onTap;
  const _Choice({
    required this.choice,
    required this.cost,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: FinnyColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 62,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            children: [
              Icon(
                cost == 0
                    ? Icons.pan_tool_alt_rounded
                    : cost >= 20
                    ? Icons.handyman_rounded
                    : Icons.construction_rounded,
                color: FinnyColors.primary,
                size: 25,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      choice.immediateFeedback,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FinnyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$cost',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: FinnyColors.primary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.toll_rounded, size: 16, color: FinnyColors.coin),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Balance extends StatelessWidget {
  final String label;
  final int before;
  final int? after;
  const _Balance(this.label, this.before, this.after);
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F4FA),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: FinnyColors.textSecondary,
          ),
        ),
        Row(
          children: [
            Text(
              '$before',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: FinnyColors.textPrimary,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: FinnyColors.primary,
              ),
            ),
            Text(
              after?.toString() ?? '?',
              key: Key(
                label == 'Копилка'
                    ? 'event_savings_after'
                    : 'event_wallet_after',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: FinnyColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _Notice(this.icon, this.message, this.color);
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
