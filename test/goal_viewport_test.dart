import 'dart:io';
import 'dart:ui' as ui;

import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/models/goal_models.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/goals/goal_sheet.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final funded in [false, true]) {
    testWidgets('Goal view fits 360×640 when funded=$funded', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final repo = GameRepository(await SharedPreferences.getInstance());
      await repo.saveGameState(
        GameState.initial().copyWith(
          savings: funded ? 60 : 10,
          goal: GoalState(
            goalId: 'skate',
            savedAmount: funded ? 60 : 10,
            targetAmount: 60,
            isCompleted: funded,
          ),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [gameRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: Scaffold(body: GoalSheet())),
        ),
      );
      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('Турбо-скейт'), findsOneWidget);
      if (funded) expect(find.text('Получить мечту'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('A deposit shows where the coins went at 360×640', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await (FontLoader('Nunito')
            ..addFont(rootBundle.load('fonts/Nunito-Regular.ttf'))
            ..addFont(rootBundle.load('fonts/Nunito-Bold.ttf'))
            ..addFont(rootBundle.load('fonts/Nunito-Black.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    final initial = GameState.initial();
    await repo.saveGameState(
      initial.copyWith(
        savings: 10,
        goal: const GoalState(
          goalId: 'skate',
          savedAmount: 10,
          targetAmount: 60,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Nunito'),
          home: const Scaffold(body: GoalSheet()),
        ),
      ),
    );
    await tester.tap(find.text('+5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Мечта стала ближе!'), findsOneWidget);
    expect(find.text('Из кошелька'), findsOneWidget);
    expect(find.text('−5'), findsOneWidget);
    expect(find.text('Было 50, осталось 45'), findsOneWidget);
    expect(find.text('В копилку'), findsOneWidget);
    expect(find.text('+5'), findsWidgets);
    expect(find.text('Было 10, стало 15'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640),
        pixelRatio: 2,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual-review').create(recursive: true);
      await File('build/visual-review/goal-deposit-360.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });

  testWidgets('Putting all coins away offers a food reserve choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await (FontLoader('Nunito')
            ..addFont(rootBundle.load('fonts/Nunito-Regular.ttf'))
            ..addFont(rootBundle.load('fonts/Nunito-Bold.ttf'))
            ..addFont(rootBundle.load('fonts/Nunito-Black.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    final initial = GameState.initial();
    await repo.saveGameState(
      initial.copyWith(
        inventory: initial.inventory.copyWith(foodReserveDays: 0),
        savings: 10,
        goal: const GoalState(
          goalId: 'skate',
          savedAmount: 10,
          targetAmount: 60,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Nunito'),
          home: const Scaffold(body: GoalSheet()),
        ),
      ),
    );
    await tester.tap(find.text('Всё'));
    await tester.pumpAndSettle();
    expect(find.text('Оставим на еду?'), findsOneWidget);
    expect(find.text('Оставить 7 на еду'), findsOneWidget);
    expect(find.text('Всё равно отложить'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640),
        pixelRatio: 2,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual-review').create(recursive: true);
      await File('build/visual-review/goal-food-warning-360.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    await tester.tap(find.text('Оставить 7 на еду'));
    await tester.pumpAndSettle();
    expect(find.text('−43'), findsOneWidget);
    expect(find.text('Было 50, осталось 7'), findsOneWidget);
    expect(find.text('Было 10, стало 53'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
