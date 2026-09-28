import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/theme/finny_tokens.dart';
import '../../core/theme/finny_widgets.dart';
import '../../game/engine/game_engine.dart';
import '../../shared/widgets/finny_appearance.dart';

class DemoDrawer extends ConsumerWidget {
  const DemoDrawer({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DemoDrawer(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameEngineProvider);
    final demoActive = ref.read(gameRepositoryProvider).isDemoActive;

    if (!demoActive) {
      return FinnyBottomSheet(
        title: 'Демонстрация игры',
        subtitle: 'Основной прогресс сохранится отдельно',
        heightFactor: 0.48,
        child: Padding(
          padding: const EdgeInsets.all(FinnySpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Попробуй игру отдельно от своего прогресса. Вернуться можно в этой же панели.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              FinnyButton.primary(
                label: 'Начать демо',
                onPressed: () async {
                  final started = await ref
                      .read(gameEngineProvider.notifier)
                      .enterDemo();
                  if (started) {
                    await ref
                        .read(finnyAppearanceProvider)
                        .syncWithGameProfile();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return FinnyBottomSheet(
      title: 'Демо-панель',
      subtitle: 'Отдельный профиль · основная игра сохранена',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: FinnySpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(12),

            SizedBox(
              width: double.infinity,
              child: FinnyButton.secondary(
                label: 'Вернуться к своей игре',
                onPressed: () async {
                  final restored = await ref
                      .read(gameEngineProvider.notifier)
                      .exitDemo();
                  if (restored) {
                    await ref
                        .read(finnyAppearanceProvider)
                        .syncWithGameProfile();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ),
            const Gap(20),

            const Text(
              'Обычная игра и демо используют одинаковые цены и награды. '
              'Ниже можно начать отдельную сцену нужного дня; текущий демо-прогресс при этом сбросится.',
              style: TextStyle(fontSize: 13, height: 1.35),
            ),
            const Gap(16),
            // Дни
            Text(
              'Отдельная сцена дня:',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: FinnyColors.textPrimary,
              ),
            ),
            const Gap(8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(10, (index) {
                final dayNum = index + 1;
                final isCurrent = state.day == dayNum;

                final tags = {
                  1: 'Введение',
                  2: 'Лавка',
                  3: 'Мечта',
                  4: 'Прогноз',
                  5: 'Дождь',
                  6: 'Новинка',
                  7: 'Праздник',
                  8: 'Ярмарка',
                  9: 'Финиш',
                  10: 'Итог',
                };
                final tag = tags[dayNum] ?? '';

                return FinnyChip(
                  label: 'Д$dayNum $tag',
                  isSelected: isCurrent,
                  onTap: () {
                    ref.read(gameEngineProvider.notifier).jumpToDay(dayNum);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Переход к Дню $dayNum ($tag)')),
                    );
                  },
                );
              }),
            ),
            const Gap(20),

            // Сброс
            SizedBox(
              width: double.infinity,
              child: FinnyButton(
                label: 'Сбросить в День 1',
                variant: FinnyButtonVariant.danger,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Начать заново?'),
                      content: const Text(
                        'Демонстрационный прогресс, покупки и имя Финни будут удалены. Основная игра сохранится.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Отмена'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Сбросить'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;
                  await ref.read(finnyAppearanceProvider).reset();
                  if (!context.mounted) return;
                  ref.read(gameEngineProvider.notifier).resetGame();
                  Navigator.pop(context);
                },
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}
