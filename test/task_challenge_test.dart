import 'package:finny/data/models/game_state.dart';
import 'package:finny/core/theme/finny_tokens.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/tasks/task_challenge_screen.dart';
import 'package:finny/game/content/financial_tasks.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameRepository> repository() async {
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    await repo.saveGameState(
      GameState.initial().copyWith(day: 5, phase: GamePhase.dayAction),
    );
    return repo;
  }

  for (final option in ['По одному · 21', 'Набор на 3 дня · 18']) {
    testWidgets('Basket challenge explains $option and awards once', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = await repository();
      final challenge = kFinancialTasks.firstWhere(
        (task) => task.id == 'task_day_4',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [gameRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(home: TaskChallengeScreen(task: challenge)),
        ),
      );
      final context = tester.element(find.text(challenge.title));
      final engine = ProviderScope.containerOf(context)
          .read(gameEngineProvider.notifier);
      final startingCoins = engine.state.balance;

      await tester.tap(find.text(option));
      await tester.tap(find.text('Проверить решение'));
      await tester.pump();
      expect(
        find.textContaining(
          option == 'По одному · 21' ? 'сэкономит 3' : 'дешевле на 3',
        ),
        findsOneWidget,
      );
      expect(engine.state.completedTasks, isEmpty);
      await tester.tap(find.text('Забрать 5 монет'));
      await tester.pump();
      expect(engine.state.completedTasks.single.taskId, 'task_day_4');
      expect(
        engine.state.completedTasks.single.outcomeDescription,
        contains(
          option == 'По одному · 21'
              ? 'Выбрать по одному тоже можно'
              : 'Набор дешевле на 3 монеты',
        ),
      );
      expect(engine.state.balance, startingCoins + 5);
      expect(find.text('Миссия выполнена!'), findsOneWidget);
      expect(find.text('+5 монет'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('+5 монет')).style?.color,
        FinnyColors.success,
      );
      expect(find.text('Вернуться в домик'), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'First mission teaches food then savings and celebrates at 360×640',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = await repository();
      final challenge = kFinancialTasks.firstWhere(
        (task) => task.id == 'task_day_2',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [gameRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(home: TaskChallengeScreen(task: challenge)),
        ),
      );
      expect(find.textContaining('Начни с еды'), findsOneWidget);
      final context = tester.element(find.text(challenge.title));
      final engine = ProviderScope.containerOf(context)
          .read(gameEngineProvider.notifier);
      final startingCoins = engine.state.balance;

      await tester.tap(find.text('+5').first);
      await tester.tap(find.byTooltip('Увеличить Нужно · еда'));
      await tester.tap(find.byTooltip('Увеличить Нужно · еда'));
      await tester.pump();
      expect(find.textContaining('Теперь отложи'), findsOneWidget);
      await tester.tap(find.text('+5').last);
      await tester.tap(find.text('Проверить решение'));
      await tester.pump();
      expect(find.textContaining('Еда обеспечена'), findsOneWidget);
      await tester.tap(find.text('Забрать 5 монет'));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Миссия выполнена!'), findsOneWidget);
      expect(find.textContaining('Сначала оставь деньги'), findsOneWidget);
      expect(
        find.text('Заработано · кошелёк: ${startingCoins + 5}'),
        findsOneWidget,
      );
      expect(engine.state.balance, startingCoins + 5);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final challenge in kFinancialTasks) {
    testWidgets('${challenge.title} fits a 360×640 screen without scrolling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = await repository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [gameRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(home: TaskChallengeScreen(task: challenge)),
        ),
      );
      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('Проверить решение'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
