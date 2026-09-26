import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../data/models/event_models.dart';
import '../../game/content/goals.dart';
import '../../game/engine/game_engine.dart';
import '../../shared/widgets/finny_appearance.dart';
import '../../shared/widgets/pet_avatar_widget.dart';

/// A reversible lesson with twelve pretend coins, before the real game begins.
enum _Trial { choose, toyFirst, foodFirst, saved }

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController(text: 'Финни');
  int _step = 0;
  String _goalId = 'rocket';
  _Trial _trial = _Trial.choose;
  bool _greeted = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    setState(() {
      _step--;
      _error = null;
    });
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0 && !_greeted) {
      setState(() => _greeted = true);
      return;
    }
    if (_step == 1 &&
        (_name.text.trim().isEmpty || _name.text.trim().runes.length > 16)) {
      setState(() => _error = 'Имя должно быть от 1 до 16 букв');
      return;
    }
    if (_step < 3) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    if (_trial == _Trial.toyFirst) {
      setState(() => _trial = _Trial.choose);
      return;
    }
    if (_trial == _Trial.foodFirst) {
      setState(() => _trial = _Trial.saved);
      return;
    }
    if (_trial != _Trial.saved) return;
    if (!ref
        .read(gameEngineProvider.notifier)
        .completeOnboarding(_name.text.trim(), _goalId)) {
      setState(() => _error = 'Проверь имя и выбери мечту');
    }
  }

  String get _actionLabel {
    if (_step == 0) return _greeted ? 'Продолжить' : 'Поздороваться';
    if (_step < 3) return 'Продолжить';
    return switch (_trial) {
      _Trial.choose => 'Выбери, что купить',
      _Trial.toyFirst => 'Попробовать иначе',
      _Trial.foodFirst => 'Отложить 5 на мечту',
      _Trial.saved => 'Начать настоящий день',
    };
  }

  @override
  Widget build(BuildContext context) {
    final look = ref.watch(finnyAppearanceProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: FinnyColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LayoutBuilder(
                builder: (context, box) {
                  final compact = box.maxHeight < 690;
                  return Column(
                    children: [
                      SizedBox(
                        height: 46,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 42,
                              child: _step == 0
                                  ? null
                                  : IconButton(
                                      tooltip: 'Назад',
                                      onPressed: _back,
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                      ),
                                    ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  4,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: index == _step ? 30 : 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: index <= _step
                                          ? FinnyColors.primary
                                          : const Color(0xFFE5DCEE),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 42,
                              child: Center(
                                child: Text(
                                  '${_step + 1}/4',
                                  style: const TextStyle(
                                    color: FinnyColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: switch (_step) {
                          0 => _welcome(compact),
                          1 => _appearance(compact, keyboardOpen, look),
                          2 => _goal(compact),
                          _ => _lesson(compact),
                        },
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: FinnyColors.danger),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 7, bottom: 10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _step == 3 && _trial == _Trial.choose
                                ? null
                                : _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: FinnyColors.primary,
                              disabledBackgroundColor: const Color(0xFFD9CDE9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _actionLabel,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome(bool compact) => Column(
    children: [
      SizedBox(height: compact ? 4 : 13),
      const _Heading('Привет! Я Финни', 'Давай обустроим мой новый дом.'),
      SizedBox(height: compact ? 8 : 18),
      Expanded(
        child: _AvatarStage(
          child: LayoutBuilder(
            builder: (context, box) => PetAvatarWidget(
              mood: FinnyMood.happy,
              size: (box.maxHeight * .78).clamp(135.0, 250.0),
              onTap: () => setState(() => _greeted = true),
            ),
          ),
        ),
      ),
      SizedBox(height: compact ? 8 : 14),
      _Speech(
        icon: _greeted ? Icons.waving_hand_rounded : Icons.touch_app_rounded,
        message: _greeted
            ? 'Ура, мы познакомились! Теперь выберем мой облик.'
            : 'Нажми на меня — я отвечу!',
      ),
      SizedBox(height: compact ? 4 : 10),
    ],
  );

  Widget _appearance(bool compact, bool keyboardOpen, FinnyAppearance look) {
    if (keyboardOpen) {
      return Column(
        children: [
          const SizedBox(height: 8),
          const _Heading('Как меня зовут?', 'Придумай мне игровое имя.'),
          const SizedBox(height: 15),
          _nameField(),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(height: compact ? 2 : 10),
        const _Heading('Каким я буду?', 'Имя и окрас можно выбрать самому.'),
        SizedBox(height: compact ? 7 : 12),
        Expanded(
          child: _AvatarStage(
            child: LayoutBuilder(
              builder: (context, box) => PetAvatarWidget(
                mood: FinnyMood.happy,
                size: (box.maxHeight * .78).clamp(100.0, 170.0),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 7 : 12),
        _nameField(),
        SizedBox(height: compact ? 7 : 12),
        Row(
          children: [
            for (final entry in FinnyAppearance.palettes.entries)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _Choice(
                    selected: look.palette == entry.key,
                    onTap: () async {
                      try {
                        await look.update(palette: entry.key);
                      } catch (_) {
                        if (mounted) {
                          setState(() => _error = 'Не удалось сохранить окрас');
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: switch (entry.key) {
                            'lagoon' => const Color(0xFF4BBBC4),
                            'apricot' => const Color(0xFFF0A06F),
                            _ => const Color(0xFF8557C2),
                          },
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: FinnyColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: compact ? 2 : 8),
      ],
    );
  }

  Widget _nameField() => TextField(
    controller: _name,
    maxLength: 16,
    textCapitalization: TextCapitalization.sentences,
    textInputAction: TextInputAction.done,
    onSubmitted: (_) => FocusScope.of(context).unfocus(),
    onChanged: (_) {
      if (_error != null) setState(() => _error = null);
    },
    decoration: InputDecoration(
      labelText: 'Игровое имя питомца',
      counterText: '',
      prefixIcon: const Icon(Icons.edit_rounded, color: FinnyColors.primary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: FinnyColors.border),
      ),
    ),
  );

  Widget _goal(bool compact) => Column(
    children: [
      SizedBox(height: compact ? 4 : 15),
      const _Heading('Выберем мечту', 'На неё можно копить понемногу.'),
      const Spacer(),
      for (final goal in kAvailableGoals)
        Padding(
          padding: EdgeInsets.only(bottom: compact ? 8 : 12),
          child: _Choice(
            selected: _goalId == goal.id,
            onTap: () => setState(() => _goalId = goal.id),
            child: Row(
              children: [
                Text(goal.icon, style: const TextStyle(fontSize: 29)),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: FinnyColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${goal.targetCost}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: FinnyColors.primary,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.toll_rounded,
                  color: FinnyColors.coin,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      const Spacer(),
      const _Speech(
        icon: Icons.savings_rounded,
        message: 'Копилка сохранит монеты. Мечту можно сменить позже.',
      ),
      SizedBox(height: compact ? 3 : 10),
    ],
  );

  Widget _lesson(bool compact) {
    final toy = _trial == _Trial.toyFirst;
    final food = _trial == _Trial.foodFirst;
    final saved = _trial == _Trial.saved;
    if (saved) return _lessonComplete(compact);
    return Column(
      children: [
        SizedBox(height: compact ? 2 : 10),
        const _Heading('Первая проба', '12 учебных монет. Еда или игрушка?'),
        SizedBox(height: compact ? 8 : 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2CF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFFA76C16),
                size: 25,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Учебный кошелёк',
                  style: TextStyle(
                    color: FinnyColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${toy
                    ? 2
                    : food
                    ? 5
                    : saved
                    ? 0
                    : 12}',
                style: const TextStyle(
                  color: Color(0xFFA76C16),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 8 : 16),
        Row(
          children: [
            Expanded(
              child: _Purchase(
                icon: Icons.restaurant_rounded,
                label: 'Еда',
                category: 'НУЖНО',
                price: 7,
                color: const Color(0xFFE7F5DA),
                selected: food || saved,
                onTap: _trial == _Trial.choose
                    ? () => setState(() => _trial = _Trial.foodFirst)
                    : null,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _Purchase(
                icon: Icons.toys_rounded,
                label: 'Игрушка',
                category: 'ХОЧУ',
                price: 10,
                color: const Color(0xFFFFE9D6),
                selected: toy,
                onTap: _trial == _Trial.choose
                    ? () => setState(() => _trial = _Trial.toyFirst)
                    : null,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: saved ? const Color(0xFFECE1F9) : Colors.white,
            border: Border.all(color: const Color(0xFFE6D8F1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.savings_rounded,
                color: FinnyColors.primary,
                size: 23,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'КОПЛЮ · на мечту',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: FinnyColors.textPrimary,
                  ),
                ),
              ),
              Text(
                saved ? '5' : '0',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: FinnyColors.primary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _Speech(
          icon: toy
              ? Icons.lightbulb_rounded
              : food
              ? Icons.savings_rounded
              : Icons.touch_app_rounded,
          message: toy
              ? 'После игрушки осталось 2. На еду за 7 не хватает 5. Попробуй иначе!'
              : food
              ? 'После еды осталось 5. Их можно отложить на мечту.'
              : 'Нажми на карточку. Оба выбора можно попробовать.',
        ),
      ],
    );
  }

  Widget _lessonComplete(bool compact) {
    final realCoins = ref.watch(gameEngineProvider).balance;
    return Column(
      children: [
        SizedBox(height: compact ? 2 : 10),
        const _Heading('Ура, получилось!', 'Теперь начнём настоящий день.'),
        SizedBox(height: compact ? 8 : 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE6BA),
            border: Border.all(color: const Color(0xFFDEAA53), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'УЧЕБНАЯ ПРОБА',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                  color: Color(0xFF83510A),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '12 − 7 = 5',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: FinnyColors.textPrimary,
                ),
              ),
              const Text(
                'Еду купили, 5 монет сохранены для мечты.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: FinnyColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 5 : 9),
        const Icon(
          Icons.arrow_downward_rounded,
          size: 26,
          color: FinnyColors.primary,
        ),
        SizedBox(height: compact ? 5 : 9),
        Container(
          width: double.infinity,
          height: 101,
          padding: const EdgeInsets.only(left: 17, right: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5631A3), Color(0xFF9D68D9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'НАСТОЯЩИЙ КОШЕЛЁК',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: .5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$realCoins монет',
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Учебные монеты не переносятся.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const PetAvatarWidget(mood: FinnyMood.happy, size: 70),
            ],
          ),
        ),
        const Spacer(),
        const _Speech(
          icon: Icons.route_rounded,
          message: 'Первый шаг — план на день: еда, запас, мечта. Монеты пока не тратятся.',
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Heading(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 27,
          height: 1.12,
          fontWeight: FontWeight.w900,
          color: FinnyColors.textPrimary,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          height: 1.25,
          color: FinnyColors.textSecondary,
        ),
      ),
    ],
  );
}

class _AvatarStage extends StatelessWidget {
  final Widget child;
  const _AvatarStage({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF1EAF8),
      borderRadius: BorderRadius.circular(28),
    ),
    child: child,
  );
}

class _Speech extends StatelessWidget {
  final IconData icon;
  final String message;
  const _Speech({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 58),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE8DFF0)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, color: FinnyColors.primary, size: 25),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.22,
              color: FinnyColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  final Widget child;
  final bool selected;
  final VoidCallback onTap;
  const _Choice({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFF0E8FA) : Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: child is Row ? 72 : 68,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? FinnyColors.primary : FinnyColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        child: child,
      ),
    ),
  );
}

class _Purchase extends StatelessWidget {
  final IconData icon;
  final String label;
  final String category;
  final int price;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  const _Purchase({
    required this.icon,
    required this.label,
    required this.category,
    required this.price,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? FinnyColors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: FinnyColors.textPrimary, size: 28),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: FinnyColors.primary,
                    size: 21,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              category,
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                color: FinnyColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: FinnyColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$price',
                  style: const TextStyle(
                    fontSize: 18,
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
  );
}
