import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/onboarding/onboarding_screen.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:finny/shared/widgets/finny_svg.dart';
import 'package:finny/shared/widgets/pet_avatar_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'First launch teaches a reversible purchase at 360×640 and preserves real coins',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = GameRepository(await SharedPreferences.getInstance());
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [gameRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.runAsync(() => FinnySvg.assets);
      await tester.pump();

      expect(find.text('Привет! Я Финни'), findsOneWidget);
      expect(repository.loadGameState().profile.onboardingComplete, false);
      await tester.tap(find.byType(PetAvatarWidget));
      await tester.pump();
      expect(find.textContaining('мы познакомились'), findsOneWidget);
      await tester.tap(find.text('Продолжить'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      expect(find.text('Каким я буду?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Искорка');
      await tester.tap(find.text('Лагуна'));
      await tester.pump();
      await tester.tap(find.text('Продолжить'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      expect(find.text('Выберем мечту'), findsOneWidget);
      await tester.tap(find.text('Домик на дереве'));
      await tester.tap(find.text('Продолжить'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      expect(find.text('Первая проба'), findsOneWidget);
      expect(find.text('Выбери, что купить'), findsOneWidget);
      await tester.tap(find.text('Игрушка'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('не хватает 5'), findsOneWidget);
      await tester.tap(find.text('Попробовать иначе'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Еда'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('После еды осталось 5'), findsOneWidget);
      await tester.tap(find.text('Отложить 5 на мечту'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Ура, получилось!'), findsOneWidget);
      expect(find.textContaining('5 монет сохранены'), findsOneWidget);
      expect(find.text('50 монет'), findsOneWidget);
      expect(find.text('Учебные монеты не переносятся.'), findsOneWidget);
      expect(find.textContaining('Первый шаг — план на день'), findsOneWidget);
      expect(repository.loadGameState().balance, 50);
      await tester.tap(find.text('Начать настоящий день'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      final scope = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingScreen)),
      );
      final state = scope.read(gameEngineProvider);
      expect(state.profile.petName, 'Искорка');
      expect(state.profile.onboardingComplete, true);
      expect(state.goal.goalId, 'treehouse');
      expect(state.balance, 50);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
