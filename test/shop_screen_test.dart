import 'dart:io';
import 'dart:ui' as ui;

import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/shop/shop_modal.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<GameRepository> repository({int balance = 50}) async {
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    await repo.saveGameState(GameState.initial().copyWith(balance: balance));
    return repo;
  }

  Future<void> pumpShop(WidgetTester tester, GameRepository repo) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await (FontLoader('Nunito')
            ..addFont(rootBundle.load('fonts/Nunito-Regular.ttf'))
            ..addFont(rootBundle.load('fonts/Nunito-Bold.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ShopModal(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Catalog scrolls locally; purchase shows math and charges once', (
    tester,
  ) async {
    final repo = await repository();
    await pumpShop(tester, repo);
    expect(find.text('Лавка Финни'), findsOneWidget);
    expect(find.byKey(const Key('shop-catalog-list')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640),
        pixelRatio: 2,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual-review').create(recursive: true);
      await File('build/visual-review/shop-360.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    await tester.tap(find.byKey(const Key('shop-item-food_1')));
    await tester.pump();
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('В кошельке'), findsOneWidget);
    expect(find.text('50 монет'), findsOneWidget);
    expect(find.text('Останется'), findsOneWidget);
    expect(find.text('43 монет'), findsOneWidget);
    expect(find.textContaining('Финни сыт'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final engine = ProviderScope.containerOf(
      tester.element(find.text('Перед покупкой')),
    ).read(gameEngineProvider.notifier);
    await tester.tap(find.text('Купить'));
    await tester.pump();
    expect(engine.state.balance, 43);
    expect(engine.state.purchases.length, 1);
    expect(find.textContaining('Было 50, осталось 43'), findsOneWidget);
    expect(find.textContaining('Финни получил'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640),
        pixelRatio: 2,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/visual-review/shop-success-360.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });

  testWidgets('Insufficient funds shows exact gap and cancel keeps coins', (
    tester,
  ) async {
    final repo = await repository(balance: 3);
    await pumpShop(tester, repo);
    await tester.tap(find.byKey(const Key('shop-item-food_1')));
    await tester.pump();
    expect(find.text('Не хватает'), findsOneWidget);
    expect(find.text('4 монеты'), findsOneWidget);
    expect(find.textContaining('Работа принесёт'), findsOneWidget);
    expect(find.text('Купить'), findsNothing);
    final engine = ProviderScope.containerOf(
      tester.element(find.text('Перед покупкой')),
    ).read(gameEngineProvider.notifier);
    await tester.tap(find.text('Отмена'));
    await tester.pump();
    expect(engine.state.balance, 3);
    expect(engine.state.purchases, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Child can switch to affordable alternatives', (tester) async {
    final repo = await repository(balance: 15);
    await pumpShop(tester, repo);
    await tester.tap(find.byKey(const Key('shop-item-food_3')));
    await tester.pump();
    expect(find.text('3 монеты'), findsOneWidget);
    await tester.tap(find.text('Дешевле'));
    await tester.pump();
    expect(find.byKey(const Key('shop-item-food_1')), findsOneWidget);
    expect(find.byKey(const Key('shop-item-food_3')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
