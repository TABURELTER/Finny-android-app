import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/event_models.dart';
import '../../shared/widgets/finny_appearance.dart';
import '../../shared/widgets/pet_avatar_widget.dart';

const _ink = Color(0xFF342B50);
const _purple = Color(0xFF7952C4);

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
                    child: Text(
                      'Гардероб Финни',
                      style: TextStyle(
                        fontSize: compact ? 20 : 22,
                        color: _ink,
                        fontWeight: FontWeight.w900,
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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, space) {
                    final size = math.min(
                      space.maxHeight - 8,
                      compact ? 214.0 : 254.0,
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
                            size: size * .98,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Text(
                'Выбирай свой образ. Наряд сохраняется автоматически.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Color(0xFF746E83)),
              ),
              SizedBox(height: compact ? 5 : 10),
              _OptionGroup(
                title: 'Окрас',
                compact: compact,
                selected: look.palette,
                options: const [
                  _LookChoice(
                    'original',
                    'Лесная магия',
                    Color(0xFF8650D8),
                    Icons.circle,
                  ),
                  _LookChoice(
                    'lagoon',
                    'Лагуна',
                    Color(0xFF228DB0),
                    Icons.circle,
                  ),
                  _LookChoice(
                    'apricot',
                    'Абрикос',
                    Color(0xFFE69A6F),
                    Icons.circle,
                  ),
                ],
                onSelect: (value) => save(look.update(palette: value)),
              ),
              _OptionGroup(
                title: 'Куртка',
                compact: compact,
                selected: look.jacket,
                options: const [
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
                ],
                onSelect: (value) => save(look.update(jacket: value)),
              ),
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
                        onTap: () => save(look.update(glasses: !look.glasses)),
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
    );
  }
}

class _LookChoice {
  final String id, label;
  final Color color;
  final IconData icon;
  const _LookChoice(this.id, this.label, this.color, this.icon);
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
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
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
      color: selected ? const Color(0xFFF1E9FF) : Colors.white,
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
          height: compact ? 46 : 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, size: compact ? 15 : 20, color: option.color),
              const SizedBox(height: 1),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
      color: selected ? const Color(0xFFF1E9FF) : const Color(0xFFF5F0E8),
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
                const Icon(Icons.check_rounded, size: 15, color: _purple),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
