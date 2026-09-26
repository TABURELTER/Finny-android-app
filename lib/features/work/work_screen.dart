import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../game/engine/game_engine.dart';

class WorkScreen extends ConsumerStatefulWidget {
  const WorkScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WorkScreen()),
  );

  @override
  ConsumerState<WorkScreen> createState() => _WorkScreenState();
}

class _Product {
  final String id;
  final String name;
  final int price;
  final IconData icon;
  final Color color;

  const _Product(this.id, this.name, this.price, this.icon, this.color);
}

const _products = [
  _Product('pencil', 'Карандаш', 4, Icons.edit_rounded, Color(0xFFBBAAF0)),
  _Product('bread', 'Хлеб', 7, Icons.bakery_dining_rounded, Color(0xFFF0BE82)),
  _Product(
    'notebook',
    'Тетрадь',
    12,
    Icons.menu_book_rounded,
    Color(0xFF8DD3B3),
  ),
];

/// Two untimed activities alternate by day. Completing either pays once.
class _WorkScreenState extends ConsumerState<WorkScreen> {
  static const _reward = 10;
  final _priced = [false, false, false];
  final _basket = [0, 0, 0];
  int _selected = 0;
  int _attempts = 0;
  String? _hint;
  bool _justFinished = false;
  int? _balanceBefore;

  void _choosePrice(int price) {
    final product = _products[_selected];
    if (price != product.price) {
      setState(() {
        _attempts++;
        _hint = _attempts == 1
            ? 'Сверь цену товара с заявкой наверху.'
            : '${product.name} стоит ${product.price} монет.';
      });
      return;
    }
    setState(() {
      _priced[_selected] = true;
      _hint = null;
      _attempts = 0;
      final next = _priced.indexWhere((done) => !done);
      if (next >= 0) _selected = next;
    });
    if (ref.read(gameEngineProvider).settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (_priced.every((done) => done)) _finish();
  }

  void _changeCount(int index, int delta) {
    setState(() {
      _basket[index] = (_basket[index] + delta).clamp(0, 4);
      _hint = null;
    });
  }

  void _submitOrder() {
    if (_basket[0] == 2 && _basket[1] == 0 && _basket[2] == 1) {
      _finish();
    } else {
      setState(() {
        _hint = 'Нужно 2 карандаша и 1 тетрадь. Хлеб не нужен.';
      });
    }
  }

  void _finish() {
    final balance = ref.read(gameEngineProvider).balance;
    if (ref.read(gameEngineProvider.notifier).completeWork(reward: _reward)) {
      setState(() {
        _balanceBefore = balance;
        _justFinished = true;
        _hint = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameEngineProvider);
    final priceJob = state.day.isOdd;
    final done = state.workCompletedToday;
    return Scaffold(
      backgroundColor: FinnyColors.background,
      appBar: AppBar(
        backgroundColor: FinnyColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Поручение соседа', style: _text(19, FontWeight.w900)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              _hero(priceJob, done),
              const SizedBox(height: 12),
              Expanded(
                child: done
                    ? _finishedBoard()
                    : priceJob
                    ? _priceBoard()
                    : _orderBoard(),
              ),
              const SizedBox(height: 12),
              if (done)
                _button('Вернуться к Финни', () => Navigator.pop(context))
              else if (!priceJob)
                _button('Передать заказ', _submitOrder)
              else
                const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _text(double size, FontWeight weight, {Color? color}) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    fontWeight: weight,
    color: color ?? FinnyColors.textPrimary,
  );

  Widget _hero(bool priceJob, bool done) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEDE8FF), Color(0xFFE5F7EF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            priceJob ? Icons.sell_rounded : Icons.inventory_2_rounded,
            color: FinnyColors.primaryDark,
            size: 25,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                priceJob ? 'Расставь ценники' : 'Собери заказ',
                style: _text(17, FontWeight.w900),
              ),
              Text(
                done ? 'Поручение выполнено' : 'Без таймера и штрафов',
                style: _text(
                  13,
                  FontWeight.w600,
                  color: FinnyColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: FinnyColors.successLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FinnyColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '+10 мон.',
            style: _text(15, FontWeight.w900, color: FinnyColors.success),
          ),
        ),
      ],
    ),
  );

  Widget _board(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: FinnyColors.surface,
      border: Border.all(color: FinnyColors.border),
      borderRadius: BorderRadius.circular(24),
      boxShadow: FinnyShadows.sm,
    ),
    child: child,
  );

  Widget _request(String title, String detail, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5DE),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF9D641F), size: 25),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _text(14, FontWeight.w900)),
              Text(detail, maxLines: 2, style: _text(12, FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _productIcon(_Product product) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: product.color.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(product.icon, color: FinnyColors.textPrimary, size: 22),
  );

  Widget _priceBoard() => _board(
    Column(
      children: [
        _request(
          'Заявка на ценники',
          'Карандаш — 4 · Хлеб — 7 · Тетрадь — 12',
          Icons.assignment_turned_in_outlined,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _products.length; i++) ...[
          _priceRow(i),
          if (i < _products.length - 1) const SizedBox(height: 5),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: constraints.maxHeight < 46
                  ? _compactPriceProgress()
                  : _priceProgress(),
            ),
          ),
        ),
        Text(
          'Выбери товар, затем его ценник',
          style: _text(13, FontWeight.w700, color: FinnyColors.textSecondary),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (final price in const [12, 4, 7]) ...[
              if (price != 12) const SizedBox(width: 7),
              Expanded(
                child: OutlinedButton(
                  key: Key('price-option-$price'),
                  onPressed:
                      _priced[_products.indexWhere(
                        (product) => product.price == price,
                      )]
                      ? null
                      : () => _choosePrice(price),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    foregroundColor: FinnyColors.primaryDark,
                    backgroundColor: FinnyColors.primaryLight,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    '$price мон.',
                    style: _text(
                      14,
                      FontWeight.w900,
                      color: FinnyColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        _feedback(),
      ],
    ),
  );

  Widget _priceProgress() {
    final complete = _priced.where((done) => done).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF5E4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sell_rounded,
                color: Color(0xFF187B52),
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                'Ценники готовы: $complete из 3',
                style: _text(
                  13,
                  FontWeight.w900,
                  color: const Color(0xFF165E42),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: complete / 3,
            minHeight: 7,
            borderRadius: BorderRadius.circular(7),
            color: const Color(0xFF187B52),
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _compactPriceProgress() {
    final complete = _priced.where((done) => done).length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Готово $complete из 3',
          style: _text(12, FontWeight.w900, color: const Color(0xFF165E42)),
        ),
        const SizedBox(width: 6),
        for (var i = 0; i < 3; i++) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: i < complete
                  ? FinnyColors.success
                  : FinnyColors.successLight,
              shape: BoxShape.circle,
              border: Border.all(color: FinnyColors.success, width: 1),
            ),
          ),
          if (i < 2) const SizedBox(width: 3),
        ],
      ],
    );
  }

  Widget _priceRow(int index) {
    final product = _products[index];
    final selected = _selected == index && !_priced[index];
    return Material(
      color: _priced[index]
          ? FinnyColors.successLight
          : selected
          ? FinnyColors.primaryLight
          : FinnyColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('price-product-${product.id}'),
        onTap: _priced[index]
            ? null
            : () => setState(() {
                _selected = index;
                _hint = null;
              }),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? FinnyColors.primary : FinnyColors.borderLight,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _productIcon(product),
              const SizedBox(width: 9),
              Expanded(
                child: Text(product.name, style: _text(15, FontWeight.w800)),
              ),
              AnimatedSwitcher(
                duration:
                    ref.read(gameEngineProvider).settings.animationsEnabled &&
                        !MediaQuery.disableAnimationsOf(context)
                    ? const Duration(milliseconds: 260)
                    : Duration.zero,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Text(
                  _priced[index] ? '${product.price} мон. ✓' : '— мон.',
                  key: ValueKey(_priced[index]),
                  style: _text(
                    14,
                    FontWeight.w900,
                    color: _priced[index]
                        ? FinnyColors.success
                        : FinnyColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderBoard() => _board(
    Column(
      children: [
        _request(
          'Заказ соседа',
          '2 карандаша и 1 тетрадь. Хлеб не нужен.',
          Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _products.length; i++) ...[
          _orderRow(i),
          if (i < _products.length - 1) const SizedBox(height: 5),
        ],
        Expanded(child: Center(child: _parcelPreview())),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: FinnyColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 19,
                color: FinnyColors.primaryDark,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'В коробке: ${_basket.reduce((a, b) => a + b)} шт.',
                  style: _text(
                    14,
                    FontWeight.w900,
                    color: FinnyColors.primaryDark,
                  ),
                ),
              ),
              Text(
                '${_basket[0] * 4 + _basket[1] * 7 + _basket[2] * 12} мон.',
                style: _text(
                  14,
                  FontWeight.w900,
                  color: FinnyColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        _feedback(),
      ],
    ),
  );

  Widget _orderRow(int index) {
    final product = _products[index];
    return Container(
      height: 55,
      padding: const EdgeInsets.only(left: 8, right: 2),
      decoration: BoxDecoration(
        color: FinnyColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _productIcon(product),
          const SizedBox(width: 8),
          Expanded(
            child: Text(product.name, style: _text(15, FontWeight.w800)),
          ),
          IconButton(
            key: Key('order-minus-${product.id}'),
            tooltip: 'Убрать ${product.name.toLowerCase()}',
            onPressed: _basket[index] == 0
                ? null
                : () => _changeCount(index, -1),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: FinnyColors.primaryDark,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          SizedBox(
            width: 20,
            child: Center(
              child: Text(
                _basket[index].toString(),
                style: _text(17, FontWeight.w900),
              ),
            ),
          ),
          IconButton(
            key: Key('order-plus-${product.id}'),
            tooltip: 'Добавить ${product.name.toLowerCase()}',
            onPressed: _basket[index] == 4
                ? null
                : () => _changeCount(index, 1),
            icon: const Icon(Icons.add_circle_rounded),
            color: FinnyColors.primaryDark,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  Widget _parcelPreview() {
    final count = _basket.reduce((a, b) => a + b);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        constraints: const BoxConstraints(minWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9ED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1E1C1), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_rounded,
              size: 34,
              color: Color(0xFFAF764B),
            ),
            const SizedBox(width: 10),
            if (count == 0)
              Text(
                'Коробка ждёт товары',
                style: _text(
                  13,
                  FontWeight.w700,
                  color: FinnyColors.textSecondary,
                ),
              )
            else
              for (var i = 0; i < _basket.length; i++)
                if (_basket[i] > 0) ...[
                  _productIcon(_products[i]),
                  Text('×${_basket[i]}', style: _text(13, FontWeight.w900)),
                  const SizedBox(width: 5),
                ],
          ],
        ),
      ),
    );
  }

  Widget _feedback() => SizedBox(
    height: 37,
    child: Center(
      child: Text(
        _hint ?? 'Ошибку можно исправить без штрафа.',
        textAlign: TextAlign.center,
        maxLines: 2,
        style: _text(
          12,
          _hint == null ? FontWeight.w600 : FontWeight.w800,
          color: _hint == null
              ? FinnyColors.textSecondary
              : FinnyColors.primaryDark,
        ),
      ),
    ),
  );

  Widget _finishedBoard() => _board(
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: FinnyColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 52,
            color: FinnyColors.success,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _justFinished ? 'Поручение готово!' : 'Сегодня уже помогли!',
          textAlign: TextAlign.center,
          style: _text(23, FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          _justFinished
              ? 'Сосед получил помощь. Ты заработал 10 монет.'
              : 'Награда уже получена. Завтра будет новое поручение.',
          textAlign: TextAlign.center,
          style: _text(15, FontWeight.w600, color: FinnyColors.textSecondary),
        ),
        if (_balanceBefore != null) ...[
          const SizedBox(height: 18),
          Semantics(
            liveRegion: true,
            label:
                'Заработано 10 монет. Было $_balanceBefore, стало ${_balanceBefore! + _reward} монет.',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: FinnyColors.successLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: FinnyColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_rounded,
                    color: FinnyColors.success,
                    size: 26,
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заработано +10 монет',
                          style: _text(
                            17,
                            FontWeight.w900,
                            color: FinnyColors.success,
                          ),
                        ),
                        Text(
                          'Было $_balanceBefore, стало ${_balanceBefore! + _reward} монет',
                          style: _text(
                            13,
                            FontWeight.w800,
                            color: const Color(0xFF165E42),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _button(String label, VoidCallback action) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(
        backgroundColor: FinnyColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        label,
        style: _text(16, FontWeight.w800, color: Colors.white),
      ),
    ),
  );
}
