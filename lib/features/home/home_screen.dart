import 'dart:async';

import 'widgets/compact_home_dashboard.dart';
import 'widgets/balance_decision_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/finny_tokens.dart';
import '../../core/theme/app_accent.dart';
import '../../data/models/game_state.dart';
import '../../game/content/days.dart';
import '../../game/engine/game_engine.dart';
import '../adult/adult_screen.dart';
import '../demo/demo_drawer.dart';
import '../events/evening_summary_modal.dart';
import '../events/event_modal.dart';
import '../goals/goal_sheet.dart';
import '../planning/planning_sheet.dart';
import '../progress/progress_screen.dart';
import '../shop/shop_modal.dart';
import '../work/work_screen.dart';
import '../../shared/widgets/color_picker_dialog.dart';
import '../../shared/widgets/pet_avatar_widget.dart';
import '../../core/sound/sound_service.dart';

import 'wardrobe_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _speechTimer;
  String? _petSpeech;
  String? _activeRoomItem;
  FinnyReaction? _requestedReaction;
  double _reactionTravel = 0;
  int _reactionToken = 0;

  void _say(
    String message, {
    String? roomItem,
    FinnyReaction? reaction,
    double travel = 0,
  }) {
    _speechTimer?.cancel();
    setState(() {
      _petSpeech = message;
      _activeRoomItem = roomItem;
      if (reaction != null) {
        _requestedReaction = reaction;
        _reactionTravel = travel;
        _reactionToken++;
      }
    });
    _speechTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _petSpeech = null;
          _activeRoomItem = null;
        });
      }
    });
  }

  void _onPetReact(FinnyReaction reaction) {
    SoundService.instance.playHappy();
    final message = switch (reaction) {
      FinnyReaction.wave => 'Привет! Рад тебя видеть 👋',
      FinnyReaction.hop => 'Смотри, как я прыгаю! ✨',
      FinnyReaction.dance => 'Потанцуем вместе? 🎵',
      FinnyReaction.cuddle => 'Спасибо, мне хорошо рядом с тобой 💚',
    };
    _say(message);
  }

  void _onRoomItem(String item) {
    SoundService.instance.playHappy();
    if (ref.read(gameEngineProvider).plannedBudget?.isConfirmed != true) {
      PlanningSheet.show(context);
      return;
    }
    final before = ref.read(gameEngineProvider);
    final rain = RegExp('дожд|ливень')
        .hasMatch(before.forecast.title.toLowerCase());
    final (message, reaction) = switch (item) {
      'toy_ball' => ('Лови мяч! Ещё раз? ⚽', FinnyReaction.hop),
      'toy_robot' => ('Робот танцует, и я тоже! 🤖', FinnyReaction.dance),
      'cozy_bed' => ('На лежанке так уютно! 🛏️', FinnyReaction.cuddle),
      'warm_lamp' => ('Светло! Посидим вместе? 💡', FinnyReaction.wave),
      'kite' when rain => (
        'Сейчас дождь. Запустим змея позже! 🪁',
        FinnyReaction.cuddle,
      ),
      'kite' => ('Наш змей взлетает высоко! 🪁', FinnyReaction.dance),
      _ => ('Давай поиграем вместе!', FinnyReaction.wave),
    };
    final travel = switch (item) {
      'cozy_bed' || 'toy_ball' => -28.0,
      'warm_lamp' || 'toy_robot' || 'kite' => 28.0,
      _ => 0.0,
    };
    final played = ref.read(gameEngineProvider.notifier).interactRoomItem(item);
    final speech = played
        ? ref.read(gameEngineProvider).finny.moodReason
        : before.roomActivityUsedToday
        ? 'Сегодня мы уже играли с вещами. Завтра можно снова!'
        : message;
    _say(speech, roomItem: item, reaction: reaction, travel: travel);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _speechTimer?.cancel();
    super.dispose();
  }

  Future<void> _changeAccent() async {
    final current = ref.read(appAccentProvider).color;
    final chosen = await pickFinnyColor(
      context,
      title: 'Цвет приложения',
      initial: current,
      defaultColor: const Color(0xFFC94C19),
    );
    if (chosen == null || !mounted) return;
    try {
      await ref.read(appAccentProvider).update(chosen);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить цвет')),
        );
      }
    }
  }

  Future<void> _renamePet() async {
    final controller = TextEditingController(
      text: ref.read(gameEngineProvider).profile.petName,
    );
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) {
          void save() {
            final changed = ref
                .read(gameEngineProvider.notifier)
                .renamePet(controller.text);
            if (changed) {
              Navigator.of(dialogContext).pop();
            } else {
              refresh(() => error = 'Введи имя от 1 до 16 букв');
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Как меня зовут?',
              style: TextStyle(
                color: FinnyColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 16,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => save(),
                  onChanged: (_) {
                    if (error != null) refresh(() => error = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Имя питомца',
                    errorText: error,
                    filled: true,
                    fillColor: FinnyColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: FinnyColors.border),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: save,
                style: FilledButton.styleFrom(
                  backgroundColor: FinnyColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }

  void _showGuide() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Как играть с Финни?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'У Финни есть сытость, силы и здоровье. Каждый день сначала составь короткий план, потом принимай решения.',
              ),
              SizedBox(height: 12),
              _GuideRow(
                Icons.edit_note_rounded,
                'План',
                'Выбери готовый вариант. Монеты останутся в кошельке; вечером сравнишь план и действия.',
              ),
              _GuideRow(
                Icons.view_carousel_rounded,
                'Карточка',
                'Выбери вариант. Под кнопкой показано, что изменится.',
              ),
              _GuideRow(
                Icons.handyman_rounded,
                'Работа',
                'Мини-игра принесёт монеты, но Финни устанет и проголодается.',
              ),
              _GuideRow(
                Icons.storefront_rounded,
                'Лавка и еда',
                'Еда попадает в кладовку. Купленные вещи дают действия в комнате.',
              ),
              _GuideRow(
                Icons.touch_app_rounded,
                'Комната',
                'Нажми на купленную вещь: один такой выбор доступен каждый день.',
              ),
              _GuideRow(
                Icons.school_rounded,
                'Задания',
                'Новая задача даёт 3 🪙 и немного здоровья.',
              ),
              _GuideRow(
                Icons.savings_rounded,
                'Копилка',
                'Откладывай на мечту, оставляя деньги на еду. Полученная мечта порадует Финни.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Понятно, играем'),
          ),
        ],
      ),
    );
  }

  void _finishDay(GameState state) {
    if (state.plannedBudget?.isConfirmed != true) {
      PlanningSheet.show(context);
      return;
    }
    if (pendingStory(state) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выбери ответ на карточке Финни.'),
        ),
      );
      return;
    }
    final pending = <String>[
      if (state.balanceStats.cardsToday < 4)
        'сыграть ещё ${4 - state.balanceStats.cardsToday} карточки',
    ];
    if (pending.isEmpty) {
      ref.read(gameEngineProvider.notifier).finishDayAction();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Уже вечер?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Можно завершить день сейчас. Но ещё можно: ${pending.join(', ')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Продолжить играть'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(gameEngineProvider.notifier).finishDayAction();
            },
            child: const Text('Завершить день'),
          ),
        ],
      ),
    );
  }

  void _openAfterPlan(VoidCallback action) {
    if (ref.read(gameEngineProvider).plannedBudget?.isConfirmed != true) {
      PlanningSheet.show(context);
      return;
    }
    action();
  }

  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => SoundService.instance.pauseAmbientMusic(),
      onResume: () => SoundService.instance.resumeAmbientMusic(),
    );
    // Проверяем фазу при первом открытии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(soundServiceProvider);
      _checkPhaseTriggers(ref.read(gameEngineProvider));
    });
  }

  void _checkPhaseTriggers(GameState state) {
    if (!mounted) return;

    if (state.phase == GamePhase.eventResolution) {
      final config = dayConfigFor(state.day);
      if (config.scheduledEventId != null) {
        EventModal.show(context, config.scheduledEventId!);
      }
    } else if (state.phase == GamePhase.eveningSummary ||
        state.phase == GamePhase.finalSummary) {
      if (EventModal.isOpen) return;
      EveningSummaryModal.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameEngineProvider);

    // Слушаем изменение фазы для модальных окон событий и вечера
    ref.listen<GameState>(gameEngineProvider, (previous, next) {
      if (previous?.phase != next.phase) {
        _checkPhaseTriggers(next);
      }
      if (previous != null && previous.day != next.day) {
        _speechTimer?.cancel();
        setState(() {
          _petSpeech = null;
          _activeRoomItem = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: FinnyColors.background,
      body: SafeArea(
        child: CompactHomeDashboard(
          state: state,
          demoActive: ref.read(gameRepositoryProvider).isDemoActive,
          wardrobe: () => WardrobeSheet.show(context),
          work: () => _openAfterPlan(() => WorkScreen.open(context)),
          rename: _renamePet,
          onPetReact: _onPetReact,
          onRoomItem: _onRoomItem,
          petSpeech: _petSpeech,
          activeRoomItem: _activeRoomItem,
          requestedReaction: _requestedReaction,
          reactionTravel: _reactionTravel,
          reactionToken: _reactionToken,
          shop: () => _openAfterPlan(() => ShopModal.show(context)),
          plan: () => PlanningSheet.show(context),
          goal: () => _openAfterPlan(() => GoalSheet.show(context)),
          task: () => ProgressScreen.openTasks(context),
          finish: () => _finishDay(state),
          guide: _showGuide,
          adult: () => AdultScreen.open(context),
          progress: () => ProgressScreen.open(context),
          demo: () => DemoDrawer.show(context),
          accent: _changeAccent,
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _GuideRow(this.icon, this.title, this.detail);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: FinnyColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title · ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: detail),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
