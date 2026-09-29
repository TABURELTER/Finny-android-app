import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../core/sound/sound_service.dart';
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

class _PackItem {
  final String id, emoji, label;
  const _PackItem(this.id, this.emoji, this.label);
}

const _packItems = [
  _PackItem('umbrella', '☂️', 'Зонт'),
  _PackItem('water', '🥤', 'Вода'),
  _PackItem('boots', '🥾', 'Сапоги'),
  _PackItem('cap', '🧢', 'Кепка'),
];

enum _WorkKind { price, order, pack, pairs, sort }

class _SortItem {
  final String id, emoji, label, place;
  const _SortItem(this.id, this.emoji, this.label, this.place);
}

const _sortItemsEarly = [
  _SortItem('bread', '🍞', 'Хлеб', 'home'),
  _SortItem('book', '📒', 'Тетрадь', 'school'),
  _SortItem('cup', '🥣', 'Миска', 'home'),
  _SortItem('pencil', '✏️', 'Карандаш', 'school'),
];

const _sortItemsLate = [
  _SortItem('apple', '🍎', 'Яблоко', 'home'),
  _SortItem('ruler', '📏', 'Линейка', 'school'),
  _SortItem('lamp', '💡', 'Лампа', 'home'),
  _SortItem('backpack', '🎒', 'Рюкзак', 'school'),
];

const _pairEmoji = ['🍎', '⭐', '🎈'];

/// Five untimed activities vary through the story. Each pays once per day.
class _WorkScreenState extends ConsumerState<WorkScreen> {
  static const _reward = 10;
  final _priced = [false, false, false];
  final _basket = [0, 0, 0];
  final Set<String> _packed = {};
  final Set<String> _sorted = {};
  final Set<int> _matchedPairs = {};
  final Set<int> _revealedCards = {};
  String? _selectedSortItem;
  int? _firstCard;
  bool _pairBusy = false;
  int _selected = 0;
  int _attempts = 0;
  String? _hint;
  bool _hintIsError = false;
  bool _showExample = false;
  bool _justFinished = false;
  int? _balanceBefore;

  void _choosePrice(int price) {
    final product = _products[_selected];
    if (price != product.price) {
      SoundService.instance.playWarning();
      setState(() {
        _attempts++;
        _hintIsError = true;
        _hint = _attempts == 1
            ? 'Сверь цену товара с заявкой наверху.'
            : '${product.name} стоит ${product.price} 🪙.';
      });
      return;
    }
    SoundService.instance.playCoin();
    setState(() {
      _priced[_selected] = true;
      _hint = 'Верно! Ценник на месте.';
      _hintIsError = false;
      _showExample = false;
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
    SoundService.instance.playTap();
    setState(() {
      _basket[index] = (_basket[index] + delta).clamp(0, 4);
      _hint = null;
      _hintIsError = false;
    });
  }

  void _submitOrder() {
    final target = _orderTarget(ref.read(gameEngineProvider).day);
    if (List.generate(3, (i) => _basket[i] == target[i]).every((ok) => ok)) {
      _finish();
    } else {
      SoundService.instance.playWarning();
      setState(() {
        _hintIsError = true;
        _hint = 'Сверь коробку с заявкой наверху.';
      });
    }
  }

  List<int> _orderTarget(int day) => switch (day) {
    2 => [2, 0, 1],
    4 => [0, 1, 2],
    8 => [1, 2, 0],
    _ => [1, 1, 1],
  };

  String _orderEmoji(List<int> target) => [
    for (var i = 0; i < target[0]; i++) '✏️',
    for (var i = 0; i < target[1]; i++) '🍞',
    for (var i = 0; i < target[2]; i++) '📒',
  ].join(' ');

  String _orderDescription(List<int> target) {
    final parts = <String>[];
    if (target[0] > 0) {
      parts.add('${target[0]} ${target[0] == 1 ? 'карандаш' : 'карандаша'}');
    }
    if (target[1] > 0) {
      parts.add('${target[1]} ${target[1] == 1 ? 'буханка' : 'буханки'} хлеба');
    }
    if (target[2] > 0) {
      parts.add('${target[2]} ${target[2] == 1 ? 'тетрадь' : 'тетради'}');
    }
    return parts.join(' + ');
  }

  void _submitPack(bool rainy) {
    final expected = rainy ? {'umbrella', 'boots'} : {'water', 'cap'};
    if (_packed.length == 2 && _packed.containsAll(expected)) {
      _finish();
    } else {
      setState(() {
        _hintIsError = true;
        _hint = _packed.length != 2
            ? 'Выбери две вещи для прогулки.'
            : rainy
            ? 'Подумай, что поможет не промокнуть.'
            : 'Подумай, что поможет в тёплый день.';
      });
    }
  }

  _WorkKind _workKind(int day, bool rainy) => switch (day) {
    1 || 7 => _WorkKind.price,
    2 || 8 => _WorkKind.order,
    3 || 5 || 9 => _WorkKind.pack,
    4 || 10 => _WorkKind.sort,
    6 => _WorkKind.pairs,
    _ when rainy => _WorkKind.pack,
    _ => _WorkKind.values[(day - 1) % _WorkKind.values.length],
  };

  List<_SortItem> _sortItems(int day) =>
      day < 8 ? _sortItemsEarly : _sortItemsLate;

  void _placeSortedItem(int day, String place) {
    final id = _selectedSortItem;
    if (id == null) {
      setState(() {
        _hintIsError = false;
        _hint = 'Сначала выбери вещь.';
      });
      return;
    }
    final item = _sortItems(day).firstWhere((entry) => entry.id == id);
    if (item.place != place) {
      setState(() {
        _hintIsError = true;
        _hint = 'Попробуй другую полку.';
      });
      return;
    }
    setState(() {
      _sorted.add(id);
      _selectedSortItem = null;
      _hintIsError = false;
      _hint = 'На своём месте!';
    });
    if (_sorted.length == _sortItems(day).length) _finish();
  }

  List<int> _pairDeck(int day) =>
      day % 4 == 2 ? const [0, 1, 2, 1, 0, 2] : const [2, 0, 1, 0, 2, 1];

  Future<void> _flipPair(int day, int index) async {
    if (_pairBusy ||
        _revealedCards.contains(index) ||
        _matchedPairs.contains(_pairDeck(day)[index])) {
      return;
    }
    final first = _firstCard;
    setState(() {
      _revealedCards.add(index);
      _hint = null;
      if (first == null) _firstCard = index;
    });
    if (ref.read(gameEngineProvider).settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (first == null) return;
    if (_pairDeck(day)[first] == _pairDeck(day)[index]) {
      setState(() {
        _matchedPairs.add(_pairDeck(day)[index]);
        _firstCard = null;
        _hint = 'Пара найдена!';
      });
      if (_matchedPairs.length == _pairEmoji.length) _finish();
      return;
    }
    setState(() {
      _pairBusy = true;
      _hintIsError = false;
      _hint = 'Открой другую пару.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() {
      _revealedCards.remove(first);
      _revealedCards.remove(index);
      _firstCard = null;
      _pairBusy = false;
    });
  }

  void _finish() {
    SoundService.instance.playSuccess();
    final balance = ref.read(gameEngineProvider).balance;
    if (ref.read(gameEngineProvider.notifier).completeWork(reward: _reward)) {
      setState(() {
        _balanceBefore = balance;
        _justFinished = true;
        _hint = null;
        _hintIsError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameEngineProvider);
    final rainy = RegExp('дожд|ливень')
        .hasMatch(state.forecast.title.toLowerCase());
    final kind = _workKind(state.day, rainy);
    final done = state.workCompletedToday;
    return Scaffold(
      backgroundColor: FinnyColors.background,
      appBar: AppBar(
        backgroundColor: FinnyColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text('Поручение соседа', style: _text(19, FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Показать пример',
            onPressed: () => setState(() => _showExample = !_showExample),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              _hero(kind, done),
              const SizedBox(height: 6),
              Expanded(
                child: done
                    ? _finishedBoard()
                    : switch (kind) {
                        _WorkKind.price => _priceBoard(),
                        _WorkKind.order => _orderBoard(),
                        _WorkKind.pack => _packBoard(
                          rainy,
                          state.forecast.icon,
                        ),
                        _WorkKind.pairs => _pairsBoard(state.day),
                        _WorkKind.sort => _sortBoard(state.day),
                      },
              ),
              const SizedBox(height: 6),
              if (done)
                _button('Вернуться к Финни', () => Navigator.pop(context))
              else if (kind == _WorkKind.pack)
                _button('Передать рюкзак', () => _submitPack(rainy))
              else if (kind == _WorkKind.order)
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

  Widget _hero(_WorkKind kind, bool done) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [FinnyColors.primaryLight, const Color(0xFFE5F7EF)],
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
            switch (kind) {
              _WorkKind.price => Icons.sell_rounded,
              _WorkKind.order => Icons.inventory_2_rounded,
              _WorkKind.pack => Icons.backpack_rounded,
              _WorkKind.pairs => Icons.style_rounded,
              _WorkKind.sort => Icons.grid_view_rounded,
            },
            color: FinnyColors.primaryDark,
            size: 25,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(switch (kind) {
                _WorkKind.price => 'Расставь ценники',
                _WorkKind.order => 'Собери заказ',
                _WorkKind.pack => 'Собери рюкзак',
                _WorkKind.pairs => 'Найди пары',
                _WorkKind.sort => 'Разложи вещи',
              }, style: _text(17, FontWeight.w900)),
              if (!done)
                Text(
                  'Цена: 🍽️−  ⚡−  ❤️−',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    11,
                    FontWeight.w800,
                    color: FinnyColors.textSecondary,
                  ),
                )
              else
                Text(
                  'Поручение выполнено',
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
            '+10 🪙',
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
              Text(detail, style: _text(12, FontWeight.w600)),
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
        if (_showExample && !_priced[0]) ...[
          _example('✏️', '4 🪙', 'Нажми карандаш, затем 4 🪙'),
          const SizedBox(height: 6),
        ],
        _request(
          'Заявка на ценники',
          '✏️ 4 🪙 · 🍞 7 🪙 · 📒 12 🪙',
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
        if (!_showExample || _priced[0])
          Text(
            'Нажми товар → выбери цену снизу',
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
                    '$price 🪙',
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
                  _priced[index] ? '${product.price} 🪙 ✓' : '— 🪙',
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

  Widget _orderBoard() {
    final target = _orderTarget(ref.read(gameEngineProvider).day);
    return _board(
      Column(
        children: [
          if (_showExample) ...[
            _example(_orderEmoji(target), '📦', 'Нажимай + и −'),
            const SizedBox(height: 6),
          ],
          _request(
            'Заказ соседа',
            _orderDescription(target),
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
                Icon(
                  Icons.inventory_2_outlined,
                  size: 19,
                  color: FinnyColors.primaryDark,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'В коробке: ${_basket.reduce((a, b) => a + b)} вещей',
                    style: _text(
                      14,
                      FontWeight.w900,
                      color: FinnyColors.primaryDark,
                    ),
                  ),
                ),
                Text(
                  '${_basket[0] * 4 + _basket[1] * 7 + _basket[2] * 12} 🪙',
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
  }

  Widget _packBoard(bool rainy, String weatherIcon) => _board(
    Column(
      children: [
        _request(
          '$weatherIcon Погода за окном',
          rainy
              ? 'Идёт дождь. Выбери две вещи.'
              : 'Ясный день. Выбери две вещи.',
          Icons.backpack_rounded,
        ),
        if (_showExample) ...[
          const SizedBox(height: 8),
          Text(
            'Нажми на вещи, которые пригодятся на прогулке.',
            textAlign: TextAlign.center,
            style: _text(12, FontWeight.w700, color: FinnyColors.textSecondary),
          ),
        ],
        const SizedBox(height: 9),
        Expanded(
          child: GridView.builder(
            itemCount: _packItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final item = _packItems[index];
              final selected = _packed.contains(item.id);
              return Material(
                color: selected
                    ? FinnyColors.primaryLight
                    : FinnyColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _packed.remove(item.id);
                      } else {
                        _packed.add(item.id);
                      }
                      _hint = null;
                      _hintIsError = false;
                    });
                    if (ref.read(gameEngineProvider).settings.hapticsEnabled) {
                      HapticFeedback.selectionClick();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? FinnyColors.primary
                            : FinnyColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 30)),
                        Text(item.label, style: _text(15, FontWeight.w900)),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: FinnyColors.primary,
                            size: 19,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _feedback(),
      ],
    ),
  );

  Widget _pairsBoard(int day) => _board(
    Column(
      children: [
        _request(
          'Карточки соседа',
          'Открой две одинаковые картинки.',
          Icons.style_rounded,
        ),
        if (_showExample) ...[
          const SizedBox(height: 6),
          Text(
            'Запоминай, где они спрятаны. Ошибаться можно!',
            textAlign: TextAlign.center,
            style: _text(12, FontWeight.w700, color: FinnyColors.textSecondary),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .98,
            ),
            itemBuilder: (context, index) {
              final pair = _pairDeck(day)[index];
              final matched = _matchedPairs.contains(pair);
              final faceUp = matched || _revealedCards.contains(index);
              return Semantics(
                button: true,
                label: faceUp
                    ? _pairEmoji[pair]
                    : 'Закрытая карточка ${index + 1}',
                child: Material(
                  color: matched
                      ? FinnyColors.successLight
                      : faceUp
                      ? FinnyColors.primaryLight
                      : FinnyColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: matched ? null : () => _flipPair(day, index),
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        faceUp ? _pairEmoji[pair] : '?',
                        style: TextStyle(
                          fontSize: faceUp ? 37 : 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Text(
          'Найдено пар: ${_matchedPairs.length} из ${_pairEmoji.length}',
          style: _text(14, FontWeight.w900, color: FinnyColors.primaryDark),
        ),
        _feedback(),
      ],
    ),
  );

  Widget _sortBoard(int day) {
    final items = _sortItems(day);
    return _board(
      Column(
        children: [
          _request(
            'Помоги с уборкой',
            'Нажми вещь, затем её место.',
            Icons.grid_view_rounded,
          ),
          if (_showExample) ...[
            const SizedBox(height: 6),
            Text(
              'Еда и вещи для дома — домой. Учебные вещи — в школу.',
              textAlign: TextAlign.center,
              style: _text(
                12,
                FontWeight.w700,
                color: FinnyColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.65,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final sorted = _sorted.contains(item.id);
                final selected = _selectedSortItem == item.id;
                return Material(
                  color: sorted
                      ? FinnyColors.successLight
                      : selected
                      ? FinnyColors.primaryLight
                      : FinnyColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: sorted
                        ? null
                        : () => setState(() {
                            _selectedSortItem = item.id;
                            _hint = null;
                            _hintIsError = false;
                          }),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? FinnyColors.primary
                              : FinnyColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                          Text(item.label, style: _text(14, FontWeight.w900)),
                          if (sorted)
                            Icon(
                              Icons.check_circle_rounded,
                              color: FinnyColors.success,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _sortPlaceButton(
                  '🏠 Дом',
                  () => _placeSortedItem(day, 'home'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _sortPlaceButton(
                  '🎒 Школа',
                  () => _placeSortedItem(day, 'school'),
                ),
              ),
            ],
          ),
          _feedback(),
        ],
      ),
    );
  }

  Widget _sortPlaceButton(String label, VoidCallback action) =>
      FilledButton.tonal(
        onPressed: action,
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          backgroundColor: FinnyColors.primaryLight,
          foregroundColor: FinnyColors.primaryDark,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: _text(15, FontWeight.w900, color: FinnyColors.primaryDark),
          ),
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

  Widget _feedback() => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 42),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _hintIsError
          ? FinnyColors.dangerLight
          : _hint == null
          ? Colors.transparent
          : FinnyColors.successLight,
      borderRadius: BorderRadius.circular(10),
    ),
    child: _hint == null
        ? const SizedBox.shrink()
        : Text(
            _hint!,
            textAlign: TextAlign.center,
            style: _text(
              12,
              FontWeight.w800,
              color: _hintIsError ? FinnyColors.danger : FinnyColors.success,
            ),
          ),
  );

  Widget _example(String item, String result, String instruction) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9AD),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text('$item  →  $result', style: _text(19, FontWeight.w900)),
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: _text(11, FontWeight.w700),
        ),
      ],
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
              ? 'Сосед получил помощь. Ты заработал 10 🪙.'
              : 'Награда уже получена. Завтра будет новое поручение.',
          textAlign: TextAlign.center,
          style: _text(15, FontWeight.w600, color: FinnyColors.textSecondary),
        ),
        if (_balanceBefore != null) ...[
          const SizedBox(height: 18),
          Semantics(
            liveRegion: true,
            label:
                'Заработано 10 🪙. Было $_balanceBefore, стало ${_balanceBefore! + _reward} 🪙.',
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
                          'Заработано +10 🪙',
                          style: _text(
                            17,
                            FontWeight.w900,
                            color: FinnyColors.success,
                          ),
                        ),
                        Text(
                          'Было $_balanceBefore, стало ${_balanceBefore! + _reward} 🪙',
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
