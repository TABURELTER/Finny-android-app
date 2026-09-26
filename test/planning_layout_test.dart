import 'dart:io';
import 'dart:ui' as ui;

import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:finny/main.dart';
import 'package:finny/shared/widgets/finny_svg.dart';
import 'package:finny/features/work/work_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Daily plan fits 360 × 640 and stays in wallet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final nunito = FontLoader('Nunito')
        ..addFont(rootBundle.load('fonts/Nunito-Regular.ttf'))
        ..addFont(rootBundle.load('fonts/Nunito-Bold.ttf'));
      await nunito.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final repo = GameRepository(await SharedPreferences.getInstance());
    final initial = GameState.initial();
    await repo.saveGameState(
      initial.copyWith(
        profile: PlayerProfile(
          petName: 'Финни',
          startDate: initial.profile.startDate,
          onboardingComplete: true,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: const FinnyApp(),
      ),
    );

    await tester.runAsync(() => FinnySvg.assets);
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text('План').last);
    await tester.pump();
    await tester.tap(find.text('План').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.text('Бюджет на день'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Бюджет на день')).dy, lessThan(640));
    expect(find.text('Закрепить план'), findsOneWidget);
    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640),
        pixelRatio: 2,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/visual-review').create(recursive: true);
      await File('build/visual-review/planning-360-640.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.text('Запас'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Закрепить план'));
    await tester.pump(const Duration(milliseconds: 600));
    final context = tester.element(find.text('План готов!'));
    final state = ProviderScope.containerOf(context).read(gameEngineProvider);
    expect(state.plannedBudget?.isConfirmed, isTrue);
    expect(state.plannedBudget?.reserve, 20);
    expect(state.balance, 50);
    expect(find.text('Было 50, осталось 50 монет'), findsOneWidget);
    expect(find.text('К работе · +10 монет'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(
        const Rect.fromLTWH(0, 0, 360, 640),
        pixelRatio: 2,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/visual-review/planning-confirmed-360-640.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.text('К работе · +10 монет'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkScreen), findsOneWidget);
  });
}
