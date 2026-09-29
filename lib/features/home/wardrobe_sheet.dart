import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/event_models.dart';
import '../../core/theme/finny_tokens.dart';
import '../../game/engine/game_engine.dart';
import '../../shared/widgets/finny_appearance.dart';
import '../../shared/widgets/color_picker_dialog.dart';
import '../../shared/widgets/pet_avatar_widget.dart';

const _ink = Color(0xFF342B50);
Color get _purple => FinnyColors.primary;

/// All outfit controls stay beside the live preview on a small phone.
class WardrobeSheet extends ConsumerWidget {
  const WardrobeSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    clipBehavior: Clip.antiAlias,
    backgroundColor: const Color(0xFFFFFCF9),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const WardrobeSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(finnyAppearanceProvider);
    final state = ref.watch(gameEngineProvider);
    final hasRaincoat = state.inventory.hasItem('raincoat');
    final raincoatEquipped =
        hasRaincoat && state.finny.activeOutfit == 'raincoat';
    final height = MediaQuery.sizeOf(context).height;
    final compact = height < 700;

    void save(Future<void> result) {
      result.catchError((Object _) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось сохранить наряд. Попробуй ещё раз.'),
            ),
          );
        }
      });
    }

    Future<void> editColor(String part, Color current) async {
      final picked = await pickFinnyColor(
        context,
        title: 'Цвет: $part',
        initial: current,
      );
      if (picked == null || !context.mounted) return;
      save(switch (part) {
        'Шёрстка' => look.update(furColor: picked),
        'Хохолок и ушки' => look.update(tuftColor: picked),
        'Мордочка' => look.update(bellyColor: picked),
        'Куртка' => look.update(jacketColor: picked, jacket: 'custom'),
        _ => look.update(eyeColor: picked),
      });
    }

    return SizedBox(
      height: height * .96,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Гардероб · ${state.profile.petName}',
                        style: TextStyle(
                          fontSize: compact ? 20 : 22,
                          color: _ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(
                height: math.min(height * .35, 286.0),
                child: LayoutBuilder(
                  builder: (context, space) {
                    final size = math.min(
                      space.maxHeight - 8,
                      math.min(space.maxWidth, 286.0),
                    );
                    return Center(
                      child: Container(
                        width: size,
                        height: size,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4EFFA),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: PetAvatarWidget(
                            mood: FinnyMood.good,
                            size: finnyPreviewSize(
                              BoxConstraints.tightFor(
                                width: size,
                                height: size,
                              ),
                            ),
                            hasRaincoat: raincoatEquipped,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: compact ? 5 : 10),
                      _OptionGroup(
                        title: 'Окрас',
                        compact: compact,
                        selected: look.palette,
                        options: [
                          const _LookChoice(
                            'original',
                            'Лесная магия',
                            Color(0xFF8650D8),
                            Icons.circle,
                          ),
                          const _LookChoice(
                            'lagoon',
                            'Лагуна',
                            Color(0xFF228DB0),
                            Icons.circle,
                          ),
                          const _LookChoice(
                            'apricot',
                            'Абрикос',
                            Color(0xFFE69A6F),
                            Icons.circle,
                          ),
                          _LookChoice(
                            'custom',
                            'Свой цвет',
                            look.furColor,
                            Icons.palette_rounded,
                          ),
                        ],
                        onSelect: (value) => save(look.update(palette: value)),
                      ),
                      if (look.palette == 'custom') ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Раскрась Финни',
                            style: TextStyle(
                              color: _ink,
                              fontSize: compact ? 15 : 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        LayoutBuilder(
                          builder: (context, area) => Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              SizedBox(
                                width: (area.maxWidth - 7) / 2,
                                child: _ColorEdit(
                                  'Шёрстка',
                                  look.furColor,
                                  () => editColor('Шёрстка', look.furColor),
                                ),
                              ),
                              SizedBox(
                                width: (area.maxWidth - 7) / 2,
                                child: _ColorEdit(
                                  'Хохолок и ушки',
                                  look.tuftColor,
                                  () => editColor(
                                    'Хохолок и ушки',
                                    look.tuftColor,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: (area.maxWidth - 7) / 2,
                                child: _ColorEdit(
                                  'Мордочка',
                                  look.bellyColor,
                                  () => editColor('Мордочка', look.bellyColor),
                                ),
                              ),
                              SizedBox(
                                width: (area.maxWidth - 7) / 2,
                                child: _ColorEdit(
                                  'Глаза',
                                  look.eyeColor,
                                  () => editColor('Глаза', look.eyeColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 9),
                      ],
                      _OptionGroup(
                        title: 'Куртка',
                        compact: compact,
                        selected: raincoatEquipped ? 'raincoat' : look.jacket,
                        options: [
                          _LookChoice(
                            'none',
                            'Без куртки',
                            Color(0xFFB0A9B8),
                            Icons.block_rounded,
                          ),
                          _LookChoice(
                            'blue',
                            'Синяя',
                            Color(0xFF398CB3),
                            Icons.checkroom_rounded,
                          ),
                          _LookChoice(
                            'coral',
                            'Коралл',
                            Color(0xFFE78478),
                            Icons.checkroom_rounded,
                          ),
                          _LookChoice(
                            'mint',
                            'Мятная',
                            Color(0xFF5CA890),
                            Icons.checkroom_rounded,
                          ),
                          _LookChoice(
                            'custom',
                            'Свой цвет',
                            look.jacketColor,
                            Icons.palette_rounded,
                          ),
                          if (hasRaincoat)
                            const _LookChoice(
                              'raincoat',
                              'Жёлтый дождевик',
                              Color(0xFFF5C94B),
                              Icons.umbrella_rounded,
                            ),
                        ],
                        onSelect: (value) {
                          if (value == 'raincoat') {
                            ref
                                .read(gameEngineProvider.notifier)
                                .equipRaincoat(true);
                          } else {
                            ref
                                .read(gameEngineProvider.notifier)
                                .equipRaincoat(false);
                            save(look.update(jacket: value));
                          }
                        },
                      ),
                      if (look.jacket == 'custom' && !raincoatEquipped) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _ColorEdit(
                            'Цвет куртки',
                            look.jacketColor,
                            () => editColor('Куртка', look.jacketColor),
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                      _OptionGroup(
                        title: 'Шапка',
                        compact: compact,
                        selected: look.hat,
                        options: const [
                          _LookChoice(
                            'none',
                            'Без шапки',
                            Color(0xFFB0A9B8),
                            Icons.block_rounded,
                          ),
                          _LookChoice(
                            'beanie',
                            'С помпоном',
                            Color(0xFF7952C4),
                            Icons.ac_unit_rounded,
                          ),
                          _LookChoice(
                            'beret',
                            'Берет',
                            Color(0xFFE78478),
                            Icons.style_rounded,
                          ),
                        ],
                        onSelect: (value) => save(look.update(hat: value)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 2 : 7),
                        child: Row(
                          children: [
                            Expanded(
                              child: _AccessoryButton(
                                label: 'Очки',
                                icon: Icons.visibility_rounded,
                                selected: look.glasses,
                                onTap: () =>
                                    save(look.update(glasses: !look.glasses)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _AccessoryButton(
                                label: 'Бабочка',
                                icon: Icons.auto_awesome_rounded,
                                selected: look.bow,
                                onTap: () => save(look.update(bow: !look.bow)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LookChoice {
  final String id, label;
  final Color color;
  final IconData icon;
  const _LookChoice(this.id, this.label, this.color, this.icon);
}

class _ColorEdit extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ColorEdit(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: CircleAvatar(radius: 10, backgroundColor: color),
    label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    style: OutlinedButton.styleFrom(
      foregroundColor: _ink,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
  );
}

class _OptionGroup extends StatelessWidget {
  final String title, selected;
  final bool compact;
  final List<_LookChoice> options;
  final ValueChanged<String> onSelect;
  const _OptionGroup({
    required this.title,
    required this.compact,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 4 : 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _ink,
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, space) => Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < options.length; i++) ...[
                SizedBox(
                  width:
                      (space.maxWidth - (options.length >= 4 ? 6 : 12)) /
                      (options.length >= 4 ? 2 : 3),
                  child: _OptionCard(
                    option: options[i],
                    selected: options[i].id == selected,
                    compact: compact,
                    onTap: () => onSelect(options[i].id),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _OptionCard extends StatelessWidget {
  final _LookChoice option;
  final bool selected, compact;
  final VoidCallback onTap;
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? FinnyColors.primaryLight : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: selected ? _purple : const Color(0xFFE3DDE8),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: compact ? 55 : 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, size: compact ? 15 : 20, color: option.color),
              const SizedBox(height: 1),
              Text(
                option.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AccessoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _AccessoryButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? FinnyColors.primaryLight : const Color(0xFFF5F0E8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 43,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: _purple),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 5),
                Icon(Icons.check_rounded, size: 15, color: _purple),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
