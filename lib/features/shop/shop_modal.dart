import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../data/models/game_state.dart';
import '../../data/models/item_models.dart';
import '../../game/content/shop_items.dart';
import '../../game/engine/game_engine.dart';
import '../../core/sound/sound_service.dart';

const _expenseColor = Color(0xFFAD3B4C);
const _expenseSurface = Color(0xFFFFE7E9);

/// The old name stays for callers. The shop itself is a full-screen route:
/// its header and purchase controls stay fixed while only the catalog scrolls.
class ShopModal extends ConsumerStatefulWidget {
  const ShopModal({super.key});

  static Future<void> show(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const ShopModal()));

  @override
  ConsumerState<ShopModal> createState() => _ShopModalState();
}

class _ShopModalState extends ConsumerState<ShopModal> {
  ItemCategory? _category;
  ShopItem? _selected;
  ShopItem? _lastPurchased;
  int? _balanceBeforePurchase;
  bool _affordableOnly = false;
  String? _receipt;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameEngineProvider);
    return Scaffold(
      backgroundColor: FinnyColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              balance: state.balance,
              title: _lastPurchased != null
                  ? 'Готово!'
                  : _selected == null
                  ? 'Лавка'
                  : 'Покупка',
              back: () => _selected == null && _lastPurchased == null
                  ? Navigator.of(context).pop()
                  : setState(() {
                      _selected = null;
                      _lastPurchased = null;
                    }),
            ),
            Expanded(
              child: _lastPurchased != null
                  ? _purchaseSuccess(state, _lastPurchased!)
                  : _selected == null
                  ? _catalog(state)
                  : _purchase(state, _selected!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalog(GameState state) {
    final items = kShopCatalog.where((item) {
      if (_category != null && item.category != _category) return false;
      if (_affordableOnly && item.price > state.balance) return false;
      if (_affordableOnly && _owned(state, item)) return false;
      return true;
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              state.balanceStats.satiety <= 2
                  ? 'Финни голоден. Пополни кладовку и выбери еду на карточке.'
                  : 'Вещи из лавки дают новые действия в комнате.',
              style: _text(14, FontWeight.w600, FinnyColors.textSecondary),
            ),
          ),
        ),
        if (_receipt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 3, 16, 6),
            child: Semantics(
              liveRegion: true,
              child: _Info(
                Icons.check_circle_rounded,
                _receipt!,
                const Color(0xFF147649),
                const Color(0xFFE9F8EF),
              ),
            ),
          ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _Pill('Все', _category == null && !_affordableOnly, () {
                setState(() {
                  _category = null;
                  _affordableOnly = false;
                });
              }),
              _Pill('По карману', _affordableOnly, () {
                setState(() {
                  _category = null;
                  _affordableOnly = true;
                });
              }),
              for (final category in ItemCategory.values)
                _Pill(
                  _categoryName(category),
                  _category == category && !_affordableOnly,
                  () {
                    setState(() {
                      _category = category;
                      _affordableOnly = false;
                    });
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Пока нет доступных вещей. Можно накопить монеты и вернуться позже.',
                      textAlign: TextAlign.center,
                      style: _text(
                        17,
                        FontWeight.w700,
                        FinnyColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  key: const Key('shop-catalog-list'),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ItemCard(
                      key: Key('shop-item-${item.id}'),
                      item: item,
                      petName: state.profile.petName,
                      owned: _owned(state, item),
                      onTap: () => setState(() {
                        _selected = item;
                        _receipt = null;
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _purchase(GameState state, ShopItem item) {
    final balance = state.balance;
    final owned = _owned(state, item);
    final missing = owned ? 0 : (item.price - balance).clamp(0, item.price);
    final alternatives = kShopCatalog
        .where(
          (candidate) =>
              candidate.id != item.id &&
              candidate.price <= balance &&
              !_owned(state, candidate),
        )
        .toList();
    final note = owned
        ? 'Эта вещь уже есть в домике. Второй раз платить не нужно.'
        : missing > 0
        ? alternatives.isNotEmpty
              ? 'Можно выбрать вещь по карману или отложить покупку.'
              : state.workCompletedToday
              ? 'Покупку можно отложить до следующего дохода.'
              : 'Работа принесёт ещё монеты и приблизит покупку.'
        : 'Подумай: сейчас это нужное, запас или радость? Отмена сохранит все монеты.';
    final color = owned || missing == 0
        ? const Color(0xFF147649)
        : const Color(0xFF9D5B1B);

    final details = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Art(item, 78),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryName(item.category),
                      style: _text(
                        13,
                        FontWeight.w800,
                        _categoryColor(item.category),
                      ),
                    ),
                    Text(
                      item.name,
                      style: _text(
                        20,
                        FontWeight.w900,
                        FinnyColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${item.price} 🪙',
                      style: _text(
                        17,
                        FontWeight.w800,
                        const Color(0xFF795000),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Info(
            Icons.auto_awesome_rounded,
            '${item.immediateEffect} ${item.practicalUse}'.replaceAll(
              'Финни',
              state.profile.petName,
            ),
            _categoryColor(item.category),
            _categoryColor(item.category).withValues(alpha: .09),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FinnyColors.border),
            ),
            child: Column(
              children: [
                _MoneyRow('В кошельке', '$balance 🪙'),
                const SizedBox(height: 7),
                _MoneyRow(
                  'Потратим',
                  owned ? '0 🪙' : '− ${item.price} 🪙',
                  color: _expenseColor,
                  bold: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 7),
                  child: Divider(height: 1),
                ),
                _MoneyRow(
                  missing == 0 ? 'Останется' : 'Не хватает',
                  missing == 0
                      ? '${owned ? balance : balance - item.price} 🪙'
                      : '$missing 🪙',
                  color: missing == 0 ? FinnyColors.textPrimary : _expenseColor,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Info(
            owned || missing == 0
                ? Icons.check_circle_rounded
                : Icons.lightbulb_rounded,
            note,
            color,
            owned || missing == 0
                ? const Color(0xFFE9F8EF)
                : const Color(0xFFFFF3DE),
          ),
        ],
      ),
    );

    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: details)),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: FinnyColors.background,
            border: Border(top: BorderSide(color: FinnyColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Action(
                  owned ? 'В каталог' : 'Отмена',
                  false,
                  () => setState(() => _selected = null),
                ),
              ),
              if (!owned) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    missing == 0
                        ? 'Купить'
                        : alternatives.isNotEmpty
                        ? 'Дешевле'
                        : 'В комнату',
                    true,
                    missing == 0
                        ? () {
                            final bought = ref
                                .read(gameEngineProvider.notifier)
                                .buyItem(item);
                            if (!bought) return;
                            SoundService.instance.playCoin();
                            final left = ref.read(gameEngineProvider).balance;
                            if (state.settings.hapticsEnabled) {
                              HapticFeedback.lightImpact();
                            }
                            setState(() {
                              _selected = null;
                              _lastPurchased = item;
                              _balanceBeforePurchase = balance;
                              _receipt =
                                  'Покупка: ${item.name}. Было $balance 🪙, осталось $left 🪙.';
                            });
                          }
                        : alternatives.isNotEmpty
                        ? () => setState(() {
                            _selected = null;
                            _category = null;
                            _affordableOnly = true;
                          })
                        : () => Navigator.of(context).pop(),
                    key: const Key('shop-purchase-action'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _purchaseSuccess(GameState state, ShopItem item) {
    final before = _balanceBeforePurchase ?? state.balance + item.price;
    final animate =
        state.settings.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    final effect = item.foodDaysProvided > 0
        ? 'В кладовке ${state.inventory.foodReserveDays} порций еды.'
        : item.immediateEffect.replaceAll('Финни', state.profile.petName);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: .6, end: 1),
                      duration: animate
                          ? const Duration(milliseconds: 420)
                          : Duration.zero,
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: Container(
                        width: 156,
                        height: 156,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE9A3),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _Art(item, 104),
                            const Positioned(
                              top: 10,
                              right: 8,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF9D6200),
                                size: 28,
                              ),
                            ),
                            const Positioned(
                              bottom: 11,
                              left: 9,
                              child: Icon(
                                Icons.star_rounded,
                                color: Color(0xFF9D6200),
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Покупка: ${item.name}!',
                      textAlign: TextAlign.center,
                      style: _text(
                        22,
                        FontWeight.w900,
                        FinnyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      effect,
                      textAlign: TextAlign.center,
                      style: _text(
                        15,
                        FontWeight.w800,
                        FinnyColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 17),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _expenseSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _expenseColor.withValues(alpha: .24),
                        ),
                      ),
                      child: Column(
                        children: [
                          _MoneyRow(
                            'Потратили',
                            '−${item.price} 🪙',
                            bold: true,
                            color: _expenseColor,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Было $before 🪙, осталось ${state.balance} 🪙.',
                            style: _text(
                              14,
                              FontWeight.w800,
                              FinnyColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Action('Ещё в лавке', false, () {
                  setState(() => _lastPurchased = null);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Action(
                  item.id == 'raincoat' ? 'Надеть дождевик' : 'В домик',
                  true,
                  () {
                    if (item.id == 'raincoat') {
                      ref.read(gameEngineProvider.notifier).equipRaincoat(true);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _owned(GameState state, ShopItem item) =>
      item.isPermanent && state.inventory.hasItem(item.id);
}

class _Header extends StatelessWidget {
  const _Header({
    required this.balance,
    required this.title,
    required this.back,
  });
  final int balance;
  final String title;
  final VoidCallback back;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: FinnyColors.border)),
    ),
    child: Row(
      children: [
        IconButton(
          key: const Key('shop-back'),
          onPressed: back,
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back_rounded),
          color: FinnyColors.textPrimary,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: _text(20, FontWeight.w900, FinnyColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: FinnyColors.coinLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$balance 🪙',
            style: _text(15, FontWeight.w900, const Color(0xFF795000)),
          ),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7, bottom: 4),
    child: Material(
      color: selected ? FinnyColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? FinnyColors.primary : FinnyColors.border,
            ),
          ),
          child: Text(
            label,
            style: _text(
              14,
              FontWeight.w800,
              selected ? Colors.white : FinnyColors.textPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.petName,
    required this.owned,
    required this.onTap,
  });
  final ShopItem item;
  final String petName;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: FinnyColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Art(item, 68),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: _text(
                            16,
                            FontWeight.w900,
                            FinnyColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        owned ? 'Есть' : '${item.price} 🪙',
                        style: _text(
                          14,
                          FontWeight.w900,
                          owned
                              ? const Color(0xFF147649)
                              : const Color(0xFF795000),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _categoryName(item.category),
                    style: _text(
                      12,
                      FontWeight.w800,
                      _categoryColor(item.category),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.practicalUse.replaceAll('Финни', petName),
                    style: _text(
                      13,
                      FontWeight.w600,
                      FinnyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Art extends StatelessWidget {
  const _Art(this.item, this.size);
  final ShopItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(item.category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(size * .25),
      ),
      child: Center(
        child: item.id == 'raincoat'
            ? CustomPaint(
                size: Size.square(size * .65),
                painter: const _RaincoatPainter(),
              )
            : Text(
                item.icon,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: size * .53, height: 1),
              ),
      ),
    );
  }
}

class _RaincoatPainter extends CustomPainter {
  const _RaincoatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final outline = Paint()
      ..color = const Color(0xFFA86B1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final hood = Path()
      ..moveTo(37, 24)
      ..quadraticBezierTo(50, 1, 63, 24)
      ..lineTo(60, 33)
      ..quadraticBezierTo(50, 27, 40, 33)
      ..close();
    canvas.drawPath(hood, Paint()..color = const Color(0xFFFFE68C));
    canvas.drawPath(hood, outline);

    final coat = Path()
      ..moveTo(31, 28)
      ..lineTo(41, 25)
      ..lineTo(50, 35)
      ..lineTo(59, 25)
      ..lineTo(69, 28)
      ..lineTo(91, 65)
      ..lineTo(77, 72)
      ..lineTo(69, 56)
      ..lineTo(69, 89)
      ..lineTo(31, 89)
      ..lineTo(31, 56)
      ..lineTo(23, 72)
      ..lineTo(9, 65)
      ..close();
    canvas.drawPath(coat, Paint()..color = const Color(0xFFF5C94B));
    canvas.drawPath(coat, outline);
    canvas.drawLine(
      const Offset(50, 35),
      const Offset(50, 88),
      outline..strokeWidth = 2.5,
    );
    for (final x in [38.0, 62.0]) {
      canvas.drawLine(
        Offset(x - 4, 66),
        Offset(x + 4, 70),
        outline..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.amount, {this.bold = false, this.color});
  final String label;
  final String amount;
  final bool bold;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: _text(
            bold ? 15 : 14,
            bold ? FontWeight.w900 : FontWeight.w700,
            FinnyColors.textPrimary,
          ),
        ),
      ),
      Text(
        amount,
        style: _text(
          bold ? 17 : 15,
          FontWeight.w900,
          color ?? FinnyColors.textPrimary,
        ),
      ),
    ],
  );
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.message, this.color, this.background);
  final IconData icon;
  final String message;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: _text(14, FontWeight.w700, FinnyColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.primary, this.onTap, {super.key});
  final String label;
  final bool primary;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary ? FinnyColors.primary : Colors.white,
        foregroundColor: primary ? Colors.white : FinnyColors.textPrimary,
        side: primary ? null : const BorderSide(color: FinnyColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: _text(
            15,
            FontWeight.w900,
            primary ? Colors.white : FinnyColors.textPrimary,
          ),
        ),
      ),
    ),
  );
}

TextStyle _text(double size, FontWeight weight, Color color) => TextStyle(
  fontFamily: 'Nunito',
  fontSize: size,
  fontWeight: weight,
  color: color,
);

String _categoryName(ItemCategory category) => switch (category) {
  ItemCategory.need => 'Нужно',
  ItemCategory.reserve => 'Запас',
  ItemCategory.want => 'Хочу',
  ItemCategory.useful => 'Для дома',
};

Color _categoryColor(ItemCategory category) => switch (category) {
  ItemCategory.need => const Color(0xFF147649),
  ItemCategory.reserve => const Color(0xFF3473AA),
  ItemCategory.want => const Color(0xFFB66045),
  ItemCategory.useful => FinnyColors.primaryDark,
};
