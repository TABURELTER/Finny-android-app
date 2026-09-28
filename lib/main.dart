import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/finny_theme.dart';
import 'core/theme/app_accent.dart';
import 'core/theme/finny_tokens.dart' as tokens;
import 'data/repositories/game_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'game/engine/game_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Фиксация портретной ориентации по спецификации (Раздел 34)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Инициализация локального хранилища
  final repository = await GameRepository.init();

  runApp(
    ProviderScope(
      overrides: [gameRepositoryProvider.overrideWithValue(repository)],
      child: const FinnyApp(),
    ),
  );
}

class FinnyApp extends ConsumerWidget {
  const FinnyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(appAccentProvider).color;
    tokens.FinnyColors.setAccent(accent);
    final hasProfile = ref.watch(
      gameEngineProvider.select((state) => state.profile.onboardingComplete),
    );
    return MaterialApp(
      key: ValueKey(accent.toARGB32()),
      title: 'Питомец Финни',
      debugShowCheckedModeBanner: false,
      theme: FinnyTheme.lightTheme,
      home: hasProfile ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
