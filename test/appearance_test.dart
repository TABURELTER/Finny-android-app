import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finny/main.dart';
import 'package:finny/data/repositories/game_repository.dart';
import 'package:finny/game/engine/game_engine.dart';
import 'package:finny/shared/widgets/finny_appearance.dart';
import 'package:finny/shared/widgets/finny_svg.dart';
import 'package:finny/data/models/event_models.dart';
import 'package:finny/data/models/game_state.dart';
import 'package:xml/xml.dart';

void main() {
  test(
    'Appearance persists independently and restores latest choice',
    () async {
      SharedPreferences.setMockInitialValues({
        'finny_game_state_v1': 'untouched',
      });
      final look = FinnyAppearance();
      await look.update(
        palette: 'lagoon',
        jacket: 'mint',
        hat: 'beret',
        glasses: true,
      );
      await look.update(palette: 'apricot', bow: true);
      final restored = FinnyAppearance();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(restored.palette, 'apricot');
      expect(restored.hat, 'beret');
      expect(restored.jacket, 'mint');
      expect(restored.glasses, true);
      expect(restored.bow, true);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'finny_game_state_v1',
        ),
        'untouched',
      );
      look.dispose();
      restored.dispose();
    },
  );
  test(
    'Demo appearance changes and reset do not change the main look',
    () async {
      SharedPreferences.setMockInitialValues({});
      final look = FinnyAppearance();
      await look.update(palette: 'lagoon', jacket: 'mint');
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('finny_demo_active_v1', true);
      await look.syncWithGameProfile();
      expect(look.palette, 'original');
      await look.update(palette: 'apricot', hat: 'beret');
      expect(prefs.getString('finny_demo_appearance_v1'), contains('apricot'));

      await look.reset();
      expect(prefs.getString('finny_demo_appearance_v1'), isNull);
      await prefs.setBool('finny_demo_active_v1', false);
      await look.syncWithGameProfile();
      expect(look.palette, 'lagoon');
      expect(look.jacket, 'mint');
      expect(look.hat, 'none');
      look.dispose();
    },
  );
  testWidgets('Native home and wardrobe render and update', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    final boundary = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gameRepositoryProvider.overrideWithValue(repo)],
        child: RepaintBoundary(key: boundary, child: const FinnyApp()),
      ),
    );
    final assets = await tester.runAsync(() => FinnySvg.assets);
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/visual-review').create(recursive: true);
        await File('build/visual-review/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('home');
    tester.view.physicalSize = const Size(320, 568);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await capture('home-compact');
    await tester.ensureVisible(find.text('Завершить день'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(390, 844);
    await tester.ensureVisible(find.byTooltip('Гардероб'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Гардероб'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Гардероб Финни'), findsOneWidget);
    await tester.ensureVisible(find.text('Лагуна'));
    await tester.pump();
    await tester.tap(find.text('Лагуна'));
    await tester.pump();
    await tester.ensureVisible(find.text('Мятная'));
    await tester.pump();
    await tester.tap(find.text('Мятная'));
    await tester.pump();
    final context = tester.element(find.text('Гардероб Финни'));
    final look = ProviderScope.containerOf(context)
        .read(finnyAppearanceProvider);
    expect(look.palette, 'lagoon');
    expect(look.jacket, 'mint');
    final svg = XmlDocument.parse(
      assets!.render(look, FinnyMood.happy, wave: true),
    );
    expect(
      svg.descendants.whereType<XmlElement>().where(
        (e) => e.getAttribute('data-part') == 'armR',
      ),
      isNotEmpty,
    );
    expect(
      svg.descendants.whereType<XmlElement>().where(
        (e) => e.getAttribute('data-part') == 'armR-rest',
      ),
      isEmpty,
    );
    final grown = XmlDocument.parse(
      assets.render(look, FinnyMood.good, stage: DevelopmentStage.independent),
    );
    expect(
      grown.descendants.whereType<XmlElement>().where(
        (e) => e.getAttribute('data-part') == 'growth-independent',
      ),
      isNotEmpty,
    );
    await tester.ensureVisible(
      find.text('Выбирай свой образ. Наряд сохраняется автоматически.'),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await capture('wardrobe');
    tester.view.physicalSize = const Size(360, 640);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('Берет'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture('wardrobe-360');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
