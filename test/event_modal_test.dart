import 'dart:io';
import 'dart:ui' as ui;

import 'package:finny/core/theme/finny_theme.dart';
import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/features/events/event_modal.dart';
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

  testWidgets('Roof repair fits 360 dp and explains a confirmed withdrawal',
      (tester) async {
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
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    });
    SharedPreferences.setMockInitialValues({});
    final repo = GameRepository(await SharedPreferences.getInstance());
    final initial = GameState.initial();
    await repo.saveGameState(initial.copyWith(
      day: 5,
      phase: GamePhase.eventResolution,
      balance: 5,
      savings: 20,
      goal: initial.goal.copyWith(savedAmount: 20),
    ));
    await tester.pumpWidget(ProviderScope(
      overrides: [gameRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FinnyTheme.lightTheme,
        home: const Scaffold(body: EventModal(eventId: 'rain_roof')),
      ),
    ));
    await tester.runAsync(() => FinnySvg.assets);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Починить крышу'));
    await tester.pump();
    expect(find.text('Взять 20 из копилки'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('event_confirm')))
        .onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('event_use_savings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<CheckboxListTile>(
        find.byKey(const Key('event_use_savings')),
      ).value,
      true,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('event_confirm')))
          .onPressed,
      isNotNull,
    );
    expect(find.byKey(const Key('event_wallet_after')), findsOneWidget);
    expect(find.byKey(const Key('event_savings_after')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640), pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual-review').create(recursive: true);
      await File('build/visual-review/event-review-360.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });

    final engine = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('event_confirm'))),
    ).read(gameEngineProvider.notifier);
    await tester.tap(find.byKey(const Key('event_confirm')));
    await tester.pump();
    expect(engine.state.balance, 0);
    expect(engine.state.savings, 0);
    expect(engine.state.history.length, 1);
    expect(find.textContaining('до мечты теперь дальше'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
