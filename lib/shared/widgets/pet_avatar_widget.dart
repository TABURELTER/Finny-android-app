import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/event_models.dart';
import '../../data/models/game_state.dart';
import '../../game/engine/game_engine.dart';
import 'finny_appearance.dart';
import 'finny_svg.dart';

class PetAvatarWidget extends ConsumerStatefulWidget {
  final FinnyMood mood;
  final double size;
  final bool hasRaincoat;
  final DevelopmentStage stage;
  final VoidCallback? onTap;
  const PetAvatarWidget({super.key, required this.mood, this.size = 180,
    this.hasRaincoat = false, this.stage = DevelopmentStage.start, this.onTap});
  @override
  ConsumerState<PetAvatarWidget> createState() => _PetAvatarWidgetState();
}
class _PetAvatarWidgetState extends ConsumerState<PetAvatarWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _breathing = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  Timer? _reaction;
  bool _wave = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !ref.read(gameEngineProvider).settings.animationsEnabled) { _breathing.stop(); _breathing.value = 0; }
    else { _breathing.repeat(reverse: true); }
  }
  void _tap() {
    if (!ref.read(gameEngineProvider).settings.animationsEnabled) {
      widget.onTap?.call();
      return;
    }
    _reaction?.cancel(); setState(() => _wave = true); widget.onTap?.call();
    _reaction = Timer(const Duration(milliseconds: 1300), () { if (mounted) setState(() => _wave = false); });
  }
  @override
  void dispose() { _reaction?.cancel(); _breathing.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final look = ref.watch(finnyAppearanceProvider);
    final animations = ref.watch(gameEngineProvider.select(
      (state) => state.settings.animationsEnabled,
    ));
    ref.listen<bool>(
      gameEngineProvider.select((state) => state.settings.animationsEnabled),
      (_, enabled) {
        if (enabled && !MediaQuery.disableAnimationsOf(context)) {
          _breathing.repeat(reverse: true);
        } else {
          _breathing.stop();
          _breathing.value = 0;
        }
      },
    );
    return Semantics(label: 'Финни. Нажми, чтобы поздороваться', button: true, child: InkWell(
      onTap: _tap, borderRadius: BorderRadius.circular(48),
      child: SizedBox(width: widget.size, height: widget.size * 1.125,
        child: FutureBuilder<FinnySvg>(future: FinnySvg.assets, builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: snapshot.hasError ? const Icon(Icons.pets, size: 48) : const SizedBox(width:24,height:24,child:CircularProgressIndicator(strokeWidth:2)));
          final image = SvgPicture.string(snapshot.data!.render(look,
            animations && _wave ? FinnyMood.happy : widget.mood,
            wave: animations && _wave, raincoat: widget.hasRaincoat,
            stage: widget.stage), fit: BoxFit.contain);
          if (!animations) return image;
          return AnimatedBuilder(animation: _breathing, child: image, builder: (context, child) => Transform.translate(offset: Offset(0, -3 * Curves.easeInOut.transform(_breathing.value)), child: child));
        }),
      ),
    ));
  }
}
