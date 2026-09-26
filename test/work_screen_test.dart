import 'dart:io';
import 'dart:ui' as ui;

import 'package:finny/core/theme/finny_theme.dart';
import 'package:finny/core/theme/finny_tokens.dart' as tokens;
import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/work/work_screen.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(GameRepository, ProviderContainer)> prepare(
    WidgetTester tester, {
    int day = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      final nunito = FontLoader('Nunito')
        ..addFont(rootBundle.load('fonts/Nunito-Regular.ttf'))
        ..addFont(rootBundle.load('fonts/Nunito-Bold.ttf'))
        ..addFont(rootBundle.load('fonts/Nunito-Black.ttf'));
      await icons.load();
      await nunito.load();
    });

    final repository = GameRepository(await SharedPreferences.getInstance());
    await repository.saveGameState(GameState.initial().copyWith(day: day));
    final container = ProviderContainer(
      overrides: [gameRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: FinnyTheme.lightTheme,
          home: const WorkScreen(),
        ),
      ),
    );
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    return (repository, container);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640),
        pixelRatio: 2,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual-review').create(recursive: true);
      await File('build/visual-review/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('Price-tag job fits 360x640, offers hints and pays once', (
    tester,
  ) async {
    final (_, container) = await prepare(tester);
    expect(find.text('Расставь ценники'), findsOneWidget);
    expect(find.text('Готово 0 из 3'), findsOneWidget);
    await capture(tester, 'work-prices-360');

    await tester.tap(find.byKey(const Key('price-option-12')));
    await tester.pump();
    expect(find.text('Сверь цену товара с заявкой наверху.'), findsOneWidget);
    expect(container.read(gameEngineProvider).balance, 50);

    await tester.tap(find.byKey(const Key('price-option-4')));
    await tester.pump();
    expect(find.text('Готово 1 из 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('price-option-7')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('price-option-12')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Поручение готово!'), findsOneWidget);
    expect(find.text('Заработано +10 монет'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Заработано +10 монет')).style?.color,
      tokens.FinnyColors.success,
    );
    expect(find.text('Было 50, стало 60 монет'), findsOneWidget);
    expect(container.read(gameEngineProvider).balance, 60);
    expect(container.read(gameEngineProvider).workCompletedToday, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: FinnyTheme.lightTheme,
          home: const WorkScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Сегодня уже помогли!'), findsOneWidget);
    expect(container.read(gameEngineProvider).balance, 60);
  });

  testWidgets('Order job checks quantities without penalty and fits 360x640', (
    tester,
  ) async {
    final (_, container) = await prepare(tester, day: 2);
    expect(find.text('Собери заказ'), findsOneWidget);
    await capture(tester, 'work-order-360');

    await tester.tap(find.byKey(const Key('order-plus-pencil')));
    await tester.pump();
    await tester.tap(find.text('Передать заказ'));
    await tester.pump();
    expect(
      find.text('Нужно 2 карандаша и 1 тетрадь. Хлеб не нужен.'),
      findsOneWidget,
    );
    expect(container.read(gameEngineProvider).balance, 50);

    await tester.tap(find.byKey(const Key('order-plus-pencil')));
    await tester.tap(find.byKey(const Key('order-plus-notebook')));
    await tester.pump();
    expect(find.text('В коробке: 3 шт.'), findsOneWidget);
    expect(find.text('20 мон.'), findsOneWidget);
    await tester.tap(find.text('Передать заказ'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(container.read(gameEngineProvider).balance, 60);
    expect(find.text('Поручение готово!'), findsOneWidget);
  });
}
