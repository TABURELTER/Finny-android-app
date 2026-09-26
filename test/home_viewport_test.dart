import 'dart:io';
import 'dart:ui' as ui;

import 'package:finny/data/models/game_state.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:finny/main.dart';
import 'package:finny/shared/widgets/finny_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final height in [640.0]) {
    testWidgets('Home keeps every action visible at 360×${height.toInt()}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(360, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
      SharedPreferences.setMockInitialValues({});
      final repo = GameRepository(await SharedPreferences.getInstance());
      final state = GameState.initial();
      await repo.saveGameState(
        state.copyWith(
          profile: PlayerProfile(
            petName: 'Финни',
            startDate: state.profile.startDate,
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
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(Scrollable), findsNothing);
      for (final title in [
        'Работа',
        'Лавка',
        'План',
        'Мечта',
        'Завершить день',
      ]) {
        final finder = find.text(title);
        expect(finder, findsWidgets);
        expect(tester.getBottomLeft(finder.last).dy, lessThan(height));
      }
      expect(find.text('Забота'), findsOneWidget);
      expect(find.text('План не списывает деньги'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (height == 640) {
        await tester.runAsync(() async {
          final layer =
              tester.binding.renderViews.first.debugLayer! as OffsetLayer;
          final image = await layer.toImage(
            const Rect.fromLTWH(0, 0, 360, 640),
            pixelRatio: 2,
          );
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/visual-review').create(recursive: true);
          await File('build/visual-review/home-360.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
