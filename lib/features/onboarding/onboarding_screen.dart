import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../data/models/event_models.dart';
import '../../game/content/goals.dart';
import '../../game/engine/game_engine.dart';
import '../../shared/widgets/finny_appearance.dart';
import '../../shared/widgets/pet_avatar_widget.dart';

/// One safe practice decision before the real game begins.
enum _Trial { choose, worked, rested }

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
    if (_trial == _Trial.choose) return;
    if (!ref
        .read(gameEngineProvider.notifier)
        .completeOnboarding(_name.text.trim(), _goalId)) {
      setState(() => _error = 'Проверь имя и выбери мечту');
    }
  }

  String get _actionLabel {
    if (_step == 0) return _greeted ? 'Продолжить' : 'Поздороваться';
    if (_step < 3) return 'Продолжить';
    return _trial == _Trial.choose ? 'Выбери действие' : 'Начать игру';
  }

  @override
  Widget build(BuildContext context) {
    final look = ref.watch(finnyAppearanceProvider);
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
                                          : FinnyColors.border,
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
                          1 => _appearance(compact, look),
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
                              disabledBackgroundColor: FinnyColors.border,
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
            builder: (context, box) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: PetAvatarWidget(
                      mood: FinnyMood.happy,
                      size: finnyPreviewSize(box).clamp(0, box.maxHeight * .72),
                      onTap: () => setState(() => _greeted = true),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: _Speech(
                    icon: _greeted
                        ? Icons.waving_hand_rounded
                        : Icons.touch_app_rounded,
                    message: _greeted
                        ? 'Ура, мы познакомились! Теперь выберем мой облик.'
                        : 'Нажми на меня — я отвечу!',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      SizedBox(height: compact ? 4 : 10),
    ],
  );

  Widget _appearance(bool compact, FinnyAppearance look) {
    return Column(
      children: [
        SizedBox(height: compact ? 2 : 10),
        const _Heading('Каким я буду?', 'Имя и окрас можно выбрать самому.'),
        SizedBox(height: compact ? 7 : 12),
        _nameField(),
        SizedBox(height: compact ? 7 : 12),
        Row(
          children: [
            for (final entry in FinnyAppearance.palettes.entries.where(
              (entry) => entry.key != 'custom',
            ))
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
        SizedBox(height: compact ? 7 : 12),
        Expanded(
          child: _AvatarStage(
            child: LayoutBuilder(
              builder: (context, box) => PetAvatarWidget(
                mood: FinnyMood.happy,
                size: finnyPreviewSize(box),
              ),
            ),
          ),
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
      prefixIcon: Icon(Icons.edit_rounded, color: FinnyColors.primary),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: FinnyColors.primary,
                  ),
                ),
                const SizedBox(width: 3),
                const Text('🪙', style: TextStyle(fontSize: 18)),
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
    final worked = _trial == _Trial.worked;
    final rested = _trial == _Trial.rested;
    return ListView(
      padding: EdgeInsets.only(top: compact ? 3 : 10, bottom: 10),
      children: [
        const _Heading(
          'Попробуем выбрать',
          'Смотри на цену решения: монеты, сытость, силы и здоровье.',
        ),
        SizedBox(height: compact ? 10 : 18),
        Row(
          children: [
            _trialStat('🪙', 'Монеты', worked ? '22' : '12'),
            const SizedBox(width: 6),
            _trialStat('🍽️', 'Сытость', worked ? 'Голоден' : 'В норме'),
            const SizedBox(width: 6),
            _trialStat(
              '⚡',
              'Силы',
              worked
                  ? 'Устал'
                  : rested
                  ? 'Бодр'
                  : 'В норме',
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Сосед просит помочь. Что выберем?',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: FinnyColors.textPrimary,
          ),
        ),
        const SizedBox(height: 9),
        _lessonOption(
          '🧩',
          'Помочь соседу',
          '🪙+10  🍽️−  ⚡−  ❤️−',
          worked,
          () => setState(() => _trial = _Trial.worked),
        ),
        const SizedBox(height: 8),
        _lessonOption(
          '🛏️',
          'Отдохнуть',
          '⚡+  🪙 без перемен',
          rested,
          () => setState(() => _trial = _Trial.rested),
        ),
        const SizedBox(height: 12),
        if (_trial != _Trial.choose) ...[
          _Speech(
            icon: Icons.lightbulb_rounded,
            message: worked
                ? 'Монет стало больше, но питомец устал и проголодался. Нажми «Отдохнуть», чтобы сравнить оба варианта!'
                : 'Питомец отдохнул. Монет не прибавилось, зато есть силы. Нажми «Помочь соседу», чтобы сравнить!',
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _trial = _Trial.choose),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text(
                'Сбросить и попробовать другой выбор',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ] else
          const _Speech(
            icon: Icons.touch_app_rounded,
            message:
                'Нажми любой вариант. Ошибиться нельзя: у каждого выбора есть своя польза.',
          ),
        const SizedBox(height: 12),
        const Text(
          'На главном экране',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Задания дают монеты и здоровье. В лавке есть еда и вещи для игр в комнате. В «Мечте» можно откладывать, оставляя деньги на еду.',
          style: TextStyle(fontSize: 13, height: 1.3),
        ),
      ],
    );
  }

  Widget _trialStat(String icon, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: FinnyColors.border),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );

  Widget _lessonOption(
    String icon,
    String title,
    String effect,
    bool selected,
    VoidCallback action,
  ) => Material(
    color: selected ? FinnyColors.primaryLight : Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 75),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? FinnyColors.primary : FinnyColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 27)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(effect, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: FinnyColors.primary),
          ],
        ),
      ),
    ),
  );
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
      color: FinnyColors.surfaceMuted,
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
      border: Border.all(color: FinnyColors.borderLight),
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
    color: selected ? FinnyColors.primaryLight : Colors.white,
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
