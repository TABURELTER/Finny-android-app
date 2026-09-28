import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../core/theme/finny_widgets.dart';
import '../../data/models/game_state.dart';
import '../../game/engine/game_engine.dart';

// The envelopes are a plan, not separate balances. These colors are repeated
// in the allocation bar and the result so a child can follow each choice.
const _needColor = Color(0xFF176B4B);
const _needLight = Color(0xFFE2F5E8);
const _reserveColor = Color(0xFF255D98);
const _reserveLight = Color(0xFFE6F0FF);
const _dreamColor = Color(0xFF6939B7);
const _dreamLight = Color(0xFFEFE5FF);
const _joyColor = Color(0xFFA24E21);
const _joyLight = Color(0xFFFFE9D6);
const _walletColor = Color(0xFF805400);
const _walletLight = Color(0xFFFFEDAE);

class PlanningSheet extends ConsumerStatefulWidget {
  const PlanningSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const PlanningSheet(),
  );

  @override
  ConsumerState<PlanningSheet> createState() => _PlanningSheetState();
}

class _PlanningSheetState extends ConsumerState<PlanningSheet> {
  int _needs = 0;
  int _wants = 0;
  int _reserve = 0;
  int _savings = 0;
  String _presetName = 'Обычный';
  bool _justConfirmed = false;

  int get _allocated => _needs + _wants + _reserve + _savings;
  int get _balance => ref.read(gameEngineProvider).balance;
  int get _free => _balance - _allocated;

  @override
  void initState() {
    super.initState();
    final current = ref.read(gameEngineProvider).plannedBudget;
    if (current == null) {
      _preset(.3, .1, .2, .3, 'Обычный', notify: false);
    } else {
      _needs = current.needs;
      _wants = current.wants;
      _reserve = current.reserve;
      _savings = current.savings;
      _presetName = '';
    }
  }

  void _preset(
    double needs,
    double wants,
    double reserve,
    double savings,
    String name, {
    bool notify = true,
  }) {
    void assign() {
      // Keep a real meal affordable in the suggested plan, including day one.
      _needs = _balance >= 7
          ? (_balance * needs).round().clamp(7, _balance)
          : _balance;
      var remaining = _balance - _needs;
      _wants = (_balance * wants).round().clamp(0, remaining);
      remaining -= _wants;
      _reserve = (_balance * reserve).round().clamp(0, remaining);
      remaining -= _reserve;
      _savings = (_balance * savings).round().clamp(0, remaining);
      _presetName = name;
    }

    if (notify) {
      setState(assign);
    } else {
      assign();
    }
  }

  void _change(String jar, int delta) {
    final current = switch (jar) {
      'needs' => _needs,
      'wants' => _wants,
      'reserve' => _reserve,
      _ => _savings,
    };
    if (current + delta < 0 || delta > _free) return;
    setState(() {
      _presetName = '';
      switch (jar) {
        case 'needs':
          _needs += delta;
        case 'wants':
          _wants += delta;
        case 'reserve':
          _reserve += delta;
        case 'savings':
          _savings += delta;
      }
    });
  }

  void _confirm() {
    final saved = ref
        .read(gameEngineProvider.notifier)
        .confirmBudgetPlan(
          BudgetPlan(
            needs: _needs,
            wants: _wants,
            reserve: _reserve,
            savings: _savings,
            leftover: _free,
            isConfirmed: true,
          ),
        );
    if (saved) setState(() => _justConfirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameEngineProvider);
    final plan = state.plannedBudget;
    if (plan?.isConfirmed == true) {
      return _confirmedView(state, plan!);
    }

    return FinnyBottomSheet(
      heightFactor: .94,
      title: 'Бюджет на день',
      subtitle: 'Выбери готовую идею или поправь суммы',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 10),
        child: Column(
          children: [
            _WalletNote(balance: _balance),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Быстрые идеи — можно менять самому',
                style: TextStyle(
                  color: _dreamColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                _Preset(
                  'Обычный',
                  _presetName == 'Обычный',
                  () => _preset(.3, .1, .2, .3, 'Обычный'),
                ),
                const SizedBox(width: 5),
                _Preset(
                  'Мечта',
                  _presetName == 'Мечта',
                  () => _preset(.3, 0, .1, .5, 'Мечта'),
                ),
                const SizedBox(width: 5),
                _Preset(
                  'Запас',
                  _presetName == 'Запас',
                  () => _preset(.3, 0, .4, .2, 'Запас'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _JarRow(
              'Еда',
              Icons.restaurant_rounded,
              _needColor,
              _needLight,
              _needs,
              canAdd: _free >= 1,
              canAddFive: _free >= 5,
              minus: () => _change('needs', -1),
              plus: () => _change('needs', 1),
              plusFive: () => _change('needs', 5),
            ),
            const SizedBox(height: 5),
            _JarRow(
              'Запас в кошельке',
              Icons.shield_rounded,
              _reserveColor,
              _reserveLight,
              _reserve,
              canAdd: _free >= 1,
              canAddFive: _free >= 5,
              minus: () => _change('reserve', -1),
              plus: () => _change('reserve', 1),
              plusFive: () => _change('reserve', 5),
            ),
            const SizedBox(height: 5),
            _JarRow(
              'На мечту',
              Icons.savings_rounded,
              _dreamColor,
              _dreamLight,
              _savings,
              canAdd: _free >= 1,
              canAddFive: _free >= 5,
              minus: () => _change('savings', -1),
              plus: () => _change('savings', 1),
              plusFive: () => _change('savings', 5),
            ),
            const SizedBox(height: 5),
            _JarRow(
              'На радости',
              Icons.toys_rounded,
              _joyColor,
              _joyLight,
              _wants,
              canAdd: _free >= 1,
              canAddFive: _free >= 5,
              minus: () => _change('wants', -1),
              plus: () => _change('wants', 1),
              plusFive: () => _change('wants', 5),
            ),
            const SizedBox(height: 9),
            _AllocationBar(
              total: _balance,
              needs: _needs,
              reserve: _reserve,
              savings: _savings,
              wants: _wants,
              free: _free,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: _walletColor,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Пока свободно',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '$_free 🪙',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _walletColor,
                  ),
                ),
              ],
            ),
            if (MediaQuery.sizeOf(context).height >= 700)
              const Expanded(child: Center(child: _NextStepNote()))
            else
              const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _confirm,
                child: const Text(
                  'Закрепить план',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmedView(GameState state, BudgetPlan plan) {
    return FinnyBottomSheet(
      heightFactor: .79,
      title: _justConfirmed ? 'План готов!' : 'План на сегодня',
      subtitle: _justConfirmed
          ? 'Теперь преврати его в настоящие действия'
          : 'Вечером сравним план и действия',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: _walletLight,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFD5A538), width: 1.5),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: _walletColor,
                    child: Icon(
                      Icons.savings_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'План записан, монеты на месте!',
                          style: TextStyle(
                            color: _walletColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Было ${state.balance}, осталось ${state.balance} 🪙',
                          style: const TextStyle(
                            color: _walletColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SavedTile(
                    'Еда',
                    plan.needs,
                    _needColor,
                    _needLight,
                    Icons.restaurant_rounded,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _SavedTile(
                    'Запас',
                    plan.reserve,
                    _reserveColor,
                    _reserveLight,
                    Icons.shield_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _SavedTile(
                    'Мечта',
                    plan.savings,
                    _dreamColor,
                    _dreamLight,
                    Icons.savings_rounded,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _SavedTile(
                    'Радости',
                    plan.wants,
                    _joyColor,
                    _joyLight,
                    Icons.toys_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Свободно: ${plan.leftover} 🪙',
                style: const TextStyle(
                  fontSize: 13,
                  color: _walletColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Теперь выбери карточку и сверяйся с планом. Еда, работа и копилка доступны отдельно.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                color: FinnyColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  'К Финни',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletNote extends StatelessWidget {
  const _WalletNote({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: _walletLight,
      border: Border.all(color: const Color(0xFFD5A538)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        const Icon(Icons.toll_rounded, size: 30, color: _walletColor),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$balance 🪙 в кошельке',
                style: const TextStyle(
                  color: _walletColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'План не тратит монеты. Запас останется в кошельке.',
                style: TextStyle(
                  color: _walletColor,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Preset extends StatelessWidget {
  const _Preset(this.title, this.selected, this.action);
  final String title;
  final bool selected;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SizedBox(
      height: 35,
      child: OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFE8DCFF) : Colors.white,
          foregroundColor: selected ? _dreamColor : FinnyColors.textPrimary,
          side: BorderSide(
            color: selected ? _dreamColor : FinnyColors.border,
            width: selected ? 1.5 : 1,
          ),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(title)),
      ),
    ),
  );
}

class _JarRow extends StatelessWidget {
  const _JarRow(
    this.title,
    this.icon,
    this.color,
    this.light,
    this.value, {
    required this.canAdd,
    required this.canAddFive,
    required this.minus,
    required this.plus,
    required this.plusFive,
  });

  final String title;
  final IconData icon;
  final Color color, light;
  final int value;
  final bool canAdd, canAddFive;
  final VoidCallback minus, plus, plusFive;

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.only(left: 8, right: 4),
    decoration: BoxDecoration(
      color: light,
      border: Border.all(color: color.withValues(alpha: .35)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: value > 0 ? minus : null,
          tooltip: 'Уменьшить $title на 1',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38, minHeight: 48),
          icon: Icon(Icons.remove_circle_rounded, size: 27, color: color),
        ),
        SizedBox(
          width: 48,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: canAdd ? plus : null,
          tooltip: 'Увеличить $title на 1',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38, minHeight: 48),
          icon: Icon(Icons.add_circle_rounded, size: 27, color: color),
        ),
        SizedBox(
          width: 38,
          height: 48,
          child: TextButton(
            onPressed: canAddFive ? plusFive : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: color,
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('+5'),
          ),
        ),
      ],
    ),
  );
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({
    required this.total,
    required this.needs,
    required this.reserve,
    required this.savings,
    required this.wants,
    required this.free,
  });

  final int total, needs, reserve, savings, wants, free;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: 11,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needs > 0)
            Expanded(
              flex: needs,
              child: const ColoredBox(color: _needColor),
            ),
          if (reserve > 0)
            Expanded(
              flex: reserve,
              child: const ColoredBox(color: _reserveColor),
            ),
          if (savings > 0)
            Expanded(
              flex: savings,
              child: const ColoredBox(color: _dreamColor),
            ),
          if (wants > 0)
            Expanded(
              flex: wants,
              child: const ColoredBox(color: _joyColor),
            ),
          if (free > 0)
            Expanded(
              flex: free,
              child: const ColoredBox(color: _walletLight),
            ),
          if (total == 0)
            const Expanded(child: ColoredBox(color: _walletLight)),
        ],
      ),
    ),
  );
}

class _NextStepNote extends StatelessWidget {
  const _NextStepNote();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: _dreamLight,
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      children: [
        Icon(Icons.route_rounded, color: _dreamColor, size: 23),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Потом: работа, задача, покупка или копилка',
            style: TextStyle(
              color: _dreamColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SavedTile extends StatelessWidget {
  const _SavedTile(this.label, this.value, this.color, this.light, this.icon);
  final String label;
  final int value;
  final Color color, light;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    height: 53,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: light,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
