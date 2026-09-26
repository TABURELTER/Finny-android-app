import 'dart:io';
import 'dart:ui' as ui;

import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/core/theme/finny_theme.dart';
import 'package:finny/features/events/event_modal.dart';
import 'package:finny/game/content/events.dart';
import 'package:finny/game/content/shop_items.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:finny/shared/widgets/finny_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(GameRepository, GameEngine)> rainyDay() async {
    SharedPreferences.setMockInitialValues({});
    final repository = GameRepository(await SharedPreferences.getInstance());
    final engine = GameEngine(repository);
    engine.jumpToDay(5);
    expect(engine.depositToGoal(20), true);
    expect(
      engine.buyItem(kShopCatalog.firstWhere((item) => item.id == 'toy_robot')),
      true,
    );
    expect(
      engine.buyItem(kShopCatalog.firstWhere((item) => item.id == 'warm_lamp')),
      true,
    );
    expect(engine.state.balance, 6);
    expect(engine.state.savings, 20);
    engine.finishDayAction();
    expect(engine.state.phase, GamePhase.eventResolution);
    return (repository, engine);
  }

  test(
    'repair uses exactly the confirmed shortage from savings once',
    () async {
      final (_, engine) = await rainyDay();
      final roof = kGameEvents.firstWhere((event) => event.id == 'rain_roof');
      final repair = roof.choices.firstWhere(
        (choice) => choice.id == 'repair_now',
      );
      expect(engine.resolveEventChoice(roof, repair), false);
      expect(engine.state.balance, 6);
      expect(engine.state.savings, 20);

      expect(engine.resolveEventChoice(roof, repair, useSavings: true), true);
      expect(engine.state.balance, 0);
      expect(engine.state.savings, 1);
      expect(engine.state.goal.savedAmount, 1);
      expect(engine.state.history.last.actualReserve, 0);
      expect(engine.state.history.last.actualReserveSpent, 25);
      expect(engine.state.phase, GamePhase.eveningSummary);
      expect(engine.resolveEventChoice(roof, repair, useSavings: true), false);
      expect(engine.state.savings, 1);
    },
  );

  testWidgets('rain choice, preview and result fit 360×640', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (repository, engine) = await rainyDay();

    await tester.runAsync(() async {
      final nunito = FontLoader('Nunito')
        ..addFont(rootBundle.load('fonts/Nunito-Regular.ttf'))
        ..addFont(rootBundle.load('fonts/Nunito-Bold.ttf'))
        ..addFont(rootBundle.load('fonts/Nunito-Black.ttf'));
      await nunito.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: FinnyTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => EventModal.show(context, 'rain_roof'),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.runAsync(() => FinnySvg.assets);
    await tester.pump();
    expect(find.text('Крыша протекает'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);

    Future<void> screenshot(String name) => tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640),
        pixelRatio: 2,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual-review').create(recursive: true);
      await File('build/visual-review/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    await tester.tap(find.text('Починить крышу'));
    await tester.pump();
    expect(find.text('Взять 19 из копилки'), findsOneWidget);
    expect(find.byKey(const Key('event_wallet_after')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('event_wallet_after'))).data,
      '?',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('event_savings_after'))).data,
      '?',
    );
    expect(engine.state.balance, 6);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('event_confirm')))
          .onPressed,
      isNull,
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await screenshot('event-review-360');

    await tester.tap(find.byKey(const Key('event_use_savings')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('event_savings_after'))).data,
      '1',
    );
    await tester.tap(find.byKey(const Key('event_confirm')));
    await tester.pump();
    expect(find.text('Вот что получилось'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('event_savings_after'))).data,
      '1',
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await screenshot('event-result-360');
  });
}
