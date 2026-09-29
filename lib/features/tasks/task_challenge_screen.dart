import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../data/models/event_models.dart';
import '../../data/models/task_models.dart';
import '../../game/engine/game_engine.dart';
import '../../core/sound/sound_service.dart';
import '../../shared/widgets/pet_avatar_widget.dart';

class TaskChallengeScreen extends ConsumerStatefulWidget {
  final FinancialTask task;
  const TaskChallengeScreen({super.key, required this.task});

  @override
  ConsumerState<TaskChallengeScreen> createState() =>
      _TaskChallengeScreenState();
}

class _TaskChallengeScreenState extends ConsumerState<TaskChallengeScreen> {
  int needs = 0, wants = 0, savings = 0;
  final deposits = [0, 0, 0];
  final changeCoins = <int>[];
  int? choice;
  bool useSavings = false;
  bool checked = false;
  bool completed = false;

  String get id => widget.task.id;
  int get free => 30 - needs - wants - savings;
  int get change => changeCoins.fold(0, (sum, coin) => sum + coin);

  bool get solved => widget.task.scenario != null
      ? choice != null
      : switch (id) {
          'task_day_2' => needs >= 7 && savings >= 5,
          'task_day_3' => deposits.every((amount) => amount >= 5),
          'task_day_4' => choice != null,
          'task_day_5' => change == 8,
          'task_day_6' => choice != null,
          'task_day_7' => choice != null && (choice != 0 || useSavings),
          _ => false,
        };

  String get measure =>
      widget.task.scenario?.situation ??
      switch (id) {
        'task_day_2' => 'В задаче 30 🪙 · свободно $free',
        'task_day_3' => 'По 20 🪙 на каждый день',
        'task_day_4' => 'По одному: 21 · набор: 18',
        'task_day_5' => '20 − 12 = ?  Собрано: $change',
        'task_day_6' => 'Сегодня в кошельке 20 🪙',
        _ => 'Кошелёк: 10 · копилка: 20',
      };

  String get feedback => widget.task.scenario != null
      ? choice == null
            ? widget.task.scenario!.instruction
            : widget.task.scenario!.options[choice!].feedback
      : switch (id) {
          'task_day_2' when needs < 7 =>
            'Еда стоит 7, а на неё сейчас $needs. Переложи ещё ${7 - needs}.',
          'task_day_2' when savings < 5 =>
            'На мечту отложено $savings. Попробуй найти ещё ${5 - savings}.',
          'task_day_2' =>
            'Еда обеспечена, мечта стала ближе, а свободно $free 🪙.',
          'task_day_3' when !solved => 'Небольшой взнос каждый день складывается. Отложи хотя бы 5 в каждый день.',
          'task_day_3' =>
            'Если выполнить план, за три дня добавится ${deposits.fold(0, (a, b) => a + b)} 🪙. Сейчас это только план: для взноса открой копилку.',
          'task_day_4' when choice == 0 => 'По одному выйдет 21. Набор за 18 сэкономит 3, если пригодятся все три завтрака. Выбрать по одному тоже можно.',
          'task_day_4' when choice == null =>
            'Теперь выбери подходящую корзину.',
          'task_day_4' => 'Набор дешевле на 3 🪙, если пригодится весь запас.',
          'task_day_5' when change < 8 =>
            'Сдачи не хватает: добавь ${8 - change}.',
          'task_day_5' when change > 8 =>
            'Сдачи слишком много: убери ${change - 8}.',
          'task_day_5' => 'Верно! Продавец возвращает 8: 20 − 12 = 8.',
          'task_day_6' when choice == 0 =>
            'После еды за 7 останется 13. На завтра уже есть необходимое.',
          'task_day_6' when choice == 1 =>
            'Игрушка за 18 оставит 2. Завтра на еду за 7 не хватит 5.',
          'task_day_6' when choice == 2 =>
            'Сохранив 10 в запасе, ты сможешь выбрать еду завтра и оставить 3.',
          'task_day_6' =>
            'Выбери, что оставить на завтра, и посмотри результат.',
          'task_day_7' when choice == 0 && !useSavings => 'На ремонт за 25 в кошельке есть 10. Подтверди отдельно 15 из копилки.',
          'task_day_7' when choice == 0 => 'Крыша надёжная. Из копилки ушло 15, поэтому до мечты снова дальше.',
          'task_day_7' when choice == 1 => 'Заплатка стоит 8: в кошельке останется 2. Позже потребуется ремонт.',
          'task_day_7' when choice == 2 => 'Монеты остались, но крыша протекает. Можно заработать или накопить на ремонт.',
          _ => 'Сравни варианты и выбери план на случай дождя.',
        };

  String get instruction =>
      widget.task.scenario?.instruction ??
      switch (id) {
        'task_day_2' when needs < 7 =>
          'Начни с еды: добавь в конверт 7 🪙 кнопками +5 и +.',
        'task_day_2' when savings < 5 =>
          'Еда готова! Теперь отложи хотя бы 5 🪙 на мечту.',
        'task_day_2' => 'Ты распределил главное. Нажми «Проверить решение».',
        'task_day_3' => 'Добавь по 5 🪙 для каждого из трёх дней.',
        'task_day_4' => 'Выбери корзину и проверь, сколько стоят три завтрака.',
        'task_day_5' => 'Нажимай на монеты, чтобы собрать сдачу.',
        'task_day_6' => 'Выбери один вариант и посмотри на завтрашний день.',
        _ => 'Выбери план на случай дождя и проверь последствия.',
      };

  String get takeaway =>
      widget.task.scenario?.takeaway ??
      switch (id) {
        'task_day_2' => 'Сначала оставь деньги на необходимое. Потом решай, сколько потратить и сколько отложить.',
        'task_day_3' =>
          'Маленькие взносы каждый день складываются в большую сумму.',
        'task_day_4' => 'Три завтрака по 7 стоят 21. Набор за 18 дешевле на 3, если нужен весь.',
        'task_day_5' => 'Сдачу можно проверить вычитанием: 20 − 12 = 8.',
        'task_day_6' when choice == 1 =>
          'Игрушка сейчас оставит только 2 🪙. Завтра на еду за 7 не хватит.',
        'task_day_6' =>
          'Сегодняшний выбор меняет то, что ты сможешь купить завтра.',
        'task_day_7' when choice == 0 =>
          'Запас выручил с ремонтом, но теперь до мечты снова дальше.',
        'task_day_7' => 'На неожиданность можно потратить запас, выбрать временное решение или подождать.',
        _ => widget.task.educationalFeedback,
      };

  void _envelope(int index, int delta) {
    final current = [needs, wants, savings][index];
    if (current + delta < 0 || delta > free) return;
    setState(() {
      if (index == 0) needs += delta;
      if (index == 1) wants += delta;
      if (index == 2) savings += delta;
      checked = false;
    });
  }

  void _deposit(int index, int delta) {
    if (deposits[index] + delta < 0 || deposits[index] + delta > 20) return;
    setState(() {
      deposits[index] += delta;
      checked = false;
    });
  }

  void _select(int value) => setState(() {
    choice = value;
    checked = false;
    if (id == 'task_day_7' && value != 0) useSavings = false;
  });

  void _finish() {
    if (!checked || !solved || completed) return;
    final outcome = '$measure. $feedback';
    final awarded = ref
        .read(gameEngineProvider.notifier)
        .completeFinancialTask(id, outcome);
    if (awarded) {
      SoundService.instance.playSuccess();
      setState(() => completed = true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Сейчас награду получить нельзя. Проверь день и попробуй снова.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => completed
      ? _celebrationScreen()
      : Scaffold(
          backgroundColor: FinnyColors.background,
          appBar: AppBar(title: const Text('Миссия Финни')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            color: FinnyColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.task.title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: FinnyColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.task.prompt,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          color: FinnyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: FinnyColors.accentLight,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          measure,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: FinnyColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Expanded(child: _playArea()),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(minHeight: 70),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: checked
                              ? (solved
                                    ? const Color(0xFFE2F0D9)
                                    : const Color(0xFFFFEAD5))
                              : const Color(0xFFECE7F5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              checked
                                  ? Icons.tips_and_updates_rounded
                                  : Icons.touch_app_rounded,
                              color: FinnyColors.primary,
                              size: 21,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                checked ? feedback : instruction,
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
                      const SizedBox(height: 9),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: checked && solved
                              ? _finish
                              : () {
                                  if (solved) {
                                    SoundService.instance.playCoin();
                                  } else {
                                    SoundService.instance.playWarning();
                                  }
                                  setState(() => checked = true);
                                },
                          child: Text(
                            checked && solved
                                ? 'Забрать 3 🪙'
                                : 'Проверить решение',
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
            ),
          ),
        );

  Widget _celebrationScreen() {
    final state = ref.watch(gameEngineProvider);
    final motion =
        state.settings.animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF5C36A5),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4D2B91), Color(0xFF8650C3)],
              ),
            ),
          ),
          Positioned(
            top: -85,
            right: -75,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 34),
              ),
            ),
          ),
          Positioned(
            bottom: -95,
            left: -95,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 44),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final compact = box.maxHeight < 570;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFFFD46B),
                            size: 29,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Миссия выполнена!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Финни радуется твоему решению',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF0DCFF),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 240,
                                  height: 240,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 205,
                                        height: 205,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFFFF6DD),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD46B)
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 34,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PetAvatarWidget(
                                        mood: FinnyMood.happy,
                                        size: 180,
                                      ),
                                      _CelebrationStar(
                                        top: 8,
                                        left: 8,
                                        size: 27,
                                        animate: motion,
                                      ),
                                      _CelebrationStar(
                                        top: 30,
                                        right: 6,
                                        size: 19,
                                        animate: motion,
                                      ),
                                      _CelebrationStar(
                                        bottom: 25,
                                        right: 0,
                                        size: 25,
                                        animate: motion,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: motion ? 0.72 : 1, end: 1),
                            duration: motion
                                ? const Duration(milliseconds: 450)
                                : Duration.zero,
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: Semantics(
                              liveRegion: true,
                              label:
                                  'Награда: 3 🪙. Теперь в кошельке ${state.balance} 🪙.',
                              child: Container(
                                height: compact ? 72 : 82,
                                decoration: BoxDecoration(
                                  color: FinnyColors.successLight,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: FinnyColors.success.withValues(
                                      alpha: 0.34,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33187B52),
                                      offset: Offset(0, 8),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_rounded,
                                      color: Color(0xFF935504),
                                      size: 38,
                                    ),
                                    const SizedBox(width: 9),
                                    Flexible(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '+3 🪙 · Финни стало лучше',
                                            style: TextStyle(
                                              fontSize: 23,
                                              fontWeight: FontWeight.w900,
                                              color: FinnyColors.success,
                                            ),
                                          ),
                                          Text(
                                            'Заработано · кошелёк: ${state.balance}',
                                            maxLines: 2,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF165E42),
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
                          const SizedBox(height: 11),
                          Container(
                            constraints: BoxConstraints(
                              minHeight: compact ? 82 : 94,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Что я понял',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF6540A5),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  takeaway,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: FinnyColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 11),
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.maybePop(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF54318D),
                              ),
                              icon: const Icon(Icons.home_rounded),
                              label: const Text(
                                'Вернуться в домик',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playArea() {
    final scenario = widget.task.scenario;
    if (scenario != null) {
      return ListView(
        children: [
          for (var index = 0; index < scenario.options.length; index++)
            _tile(
              scenario.options[index].title,
              scenario.options[index].hint,
              Icons.touch_app_rounded,
              selected: choice == index,
              onTap: () => _select(index),
            ),
        ],
      );
    }
    final motion =
        ref.watch(
          gameEngineProvider.select(
            (state) => state.settings.animationsEnabled,
          ),
        ) &&
        !MediaQuery.disableAnimationsOf(context);
    return switch (id) {
      'task_day_2' => Column(
        children: [
          _counter(
            'Нужно · еда',
            Icons.restaurant_rounded,
            needs,
            () => _envelope(0, -1),
            () => _envelope(0, 1),
            () => _envelope(0, 5),
            tone: const Color(0xFF15804D),
          ),
          _counter(
            'На радости',
            Icons.toys_rounded,
            wants,
            () => _envelope(1, -1),
            () => _envelope(1, 1),
            () => _envelope(1, 5),
            tone: const Color(0xFFB65422),
          ),
          _counter(
            'На мечту',
            Icons.savings_rounded,
            savings,
            () => _envelope(2, -1),
            () => _envelope(2, 1),
            () => _envelope(2, 5),
            tone: const Color(0xFF7242B3),
          ),
          Expanded(
            child: _EnvelopeBoard(
              needs: needs,
              wants: wants,
              savings: savings,
              free: free,
              animate: motion,
            ),
          ),
        ],
      ),
      'task_day_3' => Column(
        children: [
          for (var i = 0; i < 3; i++)
            _counter(
              'День ${i + 1}',
              Icons.calendar_today_rounded,
              deposits[i],
              () => _deposit(i, -5),
              () => _deposit(i, 5),
              () => _deposit(i, 5),
              stepLabel: '5',
            ),
          const Text(
            'Это только план: сегодня копилка сама не пополнится.',
            style: TextStyle(fontSize: 12, color: FinnyColors.textSecondary),
          ),
        ],
      ),
      'task_day_4' => Column(
        children: [
          _tile(
            'По одному · 21',
            '7 + 7 + 7',
            Icons.shopping_basket_rounded,
            selected: choice == 0,
            onTap: () => setState(() {
              choice = 0;
              checked = false;
            }),
          ),
          _tile(
            'Набор на 3 дня · 18',
            'Одна покупка на три завтрака',
            Icons.inventory_2_rounded,
            selected: choice == 1,
            onTap: () => setState(() {
              choice = 1;
              checked = false;
            }),
          ),
          const Text(
            'Сравни итог, если понадобятся все три завтрака.',
            style: TextStyle(fontSize: 12, color: FinnyColors.textSecondary),
          ),
        ],
      ),
      'task_day_5' => Column(
        children: [
          const Text(
            'Набери сдачу монетами. Неверную сумму можно исправить.',
            style: TextStyle(fontSize: 13, color: FinnyColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final coin in [1, 2, 5])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      height: 60,
                      child: FilledButton.tonal(
                        onPressed: () => setState(() {
                          changeCoins.add(coin);
                          checked = false;
                        }),
                        child: Text(
                          '+$coin',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: changeCoins.isEmpty
                ? null
                : () => setState(() {
                    changeCoins.removeLast();
                    checked = false;
                  }),
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Убрать последнюю'),
          ),
        ],
      ),
      'task_day_6' => Column(
        children: [
          _tile(
            'Сначала еда · 7',
            'Завтра останется 13',
            Icons.restaurant_rounded,
            selected: choice == 0,
            onTap: () => _select(0),
          ),
          _tile(
            'Игрушка · 18',
            'Завтра останется 2',
            Icons.toys_rounded,
            selected: choice == 1,
            onTap: () => _select(1),
          ),
          _tile(
            'Запас · 10',
            'На завтра есть выбор',
            Icons.shield_rounded,
            selected: choice == 2,
            onTap: () => _select(2),
          ),
        ],
      ),
      _ => Column(
        children: [
          _tile(
            'Полный ремонт · 25',
            '10 из кошелька + 15 из копилки',
            Icons.home_repair_service_rounded,
            selected: choice == 0,
            onTap: () => _select(0),
          ),
          _tile(
            'Временная заплатка · 8',
            'Останется 2 🪙',
            Icons.build_rounded,
            selected: choice == 1,
            onTap: () => _select(1),
          ),
          _tile(
            'Подождать · 0',
            'Крыша пока мокрая',
            Icons.hourglass_bottom_rounded,
            selected: choice == 2,
            onTap: () => _select(2),
          ),
          if (choice == 0)
            Row(
              children: [
                Checkbox(
                  value: useSavings,
                  onChanged: (value) => setState(() {
                    useSavings = value ?? false;
                    checked = false;
                  }),
                ),
                const Expanded(
                  child: Text(
                    'Подтверждаю 15 из копилки',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
        ],
      ),
    };
  }

  Widget _counter(
    String label,
    IconData icon,
    int value,
    VoidCallback minus,
    VoidCallback plus,
    VoidCallback plusFive, {
    String stepLabel = '+5',
    Color? tone,
  }) => Container(
    height: 56,
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: tone?.withValues(alpha: 0.10) ?? Colors.white,
      border: Border.all(
        color: tone?.withValues(alpha: 0.35) ?? FinnyColors.border,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: tone ?? FinnyColors.primary, size: 20),
        const SizedBox(width: 5),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        IconButton(
          onPressed: minus,
          tooltip: 'Уменьшить $label',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
          icon: Icon(
            Icons.remove_circle_outline_rounded,
            size: 21,
            color: tone ?? FinnyColors.primary,
          ),
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          onPressed: plus,
          tooltip: 'Увеличить $label',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
          icon: Icon(
            Icons.add_circle_outline_rounded,
            size: 21,
            color: tone ?? FinnyColors.primary,
          ),
        ),
        SizedBox(
          width: 36,
          child: TextButton(
            onPressed: plusFive,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              stepLabel,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: tone ?? FinnyColors.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tile(
    String title,
    String detail,
    IconData icon, {
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: selected ? FinnyColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? FinnyColors.primary : FinnyColors.border,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: FinnyColors.primary, size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FinnyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 21,
                color: FinnyColors.primary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The same 30 coins are visible as they move between three envelopes.
class _EnvelopeBoard extends StatelessWidget {
  final int needs, wants, savings, free;
  final bool animate;
  const _EnvelopeBoard({
    required this.needs,
    required this.wants,
    required this.savings,
    required this.free,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, area) {
      final compact = area.maxHeight < 120;
      final values = [needs, wants, savings, free];
      const labels = ['Еда', 'Радости', 'Мечта', 'Свободно'];
      const colors = [
        Color(0xFF61C987),
        Color(0xFFFFAB75),
        Color(0xFFB88BE9),
        Color(0xFFFFCF69),
      ];
      const icons = [
        Icons.restaurant_rounded,
        Icons.toys_rounded,
        Icons.savings_rounded,
        Icons.toll_rounded,
      ];
      return Container(
        padding: EdgeInsets.all(compact ? 6 : 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4ED),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          children: [
            if (!compact) ...[
              const Text(
                'Куда отправились монеты?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: FinnyColors.textPrimary,
                ),
              ),
              const SizedBox(height: 7),
            ],
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < values.length; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, box) => ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ColoredBox(
                                      color: colors[i].withValues(alpha: 0.20),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: animate
                                            ? const Duration(milliseconds: 220)
                                            : Duration.zero,
                                        curve: Curves.easeOut,
                                        width: double.infinity,
                                        height: box.maxHeight * values[i] / 30,
                                        color: colors[i],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icons[i],
                                          size: compact ? 18 : 28,
                                          color: FinnyColors.textPrimary,
                                        ),
                                        Text(
                                          '${values[i]}',
                                          style: TextStyle(
                                            fontSize: compact ? 16 : 20,
                                            fontWeight: FontWeight.w900,
                                            color: FinnyColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              labels[i],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: FinnyColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CelebrationStar extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size;
  final bool animate;

  const _CelebrationStar({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate ? const Duration(milliseconds: 620) : Duration.zero,
      curve: Curves.easeOutBack,
      builder: (context, progress, child) => Opacity(
        opacity: progress.clamp(0, 1),
        child: Transform.rotate(
          angle: (1 - progress) * -0.7,
          child: Transform.scale(scale: progress, child: child),
        ),
      ),
      child: Icon(
        Icons.star_rounded,
        size: size,
        color: const Color(0xFFFFD46B),
      ),
    ),
  );
}
