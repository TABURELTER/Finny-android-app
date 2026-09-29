import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/event_models.dart';
import '../../data/models/game_state.dart';
import '../../game/engine/game_engine.dart';
import 'finny_appearance.dart';
import 'finny_svg.dart';

/// Keep the character at the same visual scale in introduction and wardrobe.
double finnyPreviewSize(BoxConstraints space) => math.min(
  240,
  math.min(space.maxWidth * .94, space.maxHeight * .94 / 1.125),
);

enum FinnyReaction { wave, hop, dance, cuddle }

class PetAvatarWidget extends ConsumerStatefulWidget {
  final FinnyMood mood;
  final double size;
  final bool hasRaincoat;
  final DevelopmentStage stage;
  final VoidCallback? onTap;
  final ValueChanged<FinnyReaction>? onReact;
  final FinnyReaction? requestedReaction;
  final double reactionTravel;
  final int reactionToken;
  const PetAvatarWidget({
    super.key,
    required this.mood,
    this.size = 180,
    this.hasRaincoat = false,
    this.stage = DevelopmentStage.start,
    this.onTap,
    this.onReact,
    this.requestedReaction,
    this.reactionTravel = 0,
    this.reactionToken = 0,
  });
  @override
  ConsumerState<PetAvatarWidget> createState() => _PetAvatarWidgetState();
}

class _PetAvatarWidgetState extends ConsumerState<PetAvatarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gesture = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _reaction;
  FinnyReaction? _activeReaction;
  double _travelX = 0;
  int _tapCount = 0;

  @override
  void didUpdateWidget(covariant PetAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reactionToken != oldWidget.reactionToken &&
        widget.requestedReaction != null) {
      final token = widget.reactionToken;
      final reaction = widget.requestedReaction!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.reactionToken == token) {
          _play(reaction, travelX: widget.reactionTravel);
        }
      });
    }
  }

  void _play(FinnyReaction reaction, {double travelX = 0}) {
    _reaction?.cancel();
    _gesture.stop();
    _gesture.value = 0;
    if (!ref.read(gameEngineProvider).settings.animationsEnabled ||
        MediaQuery.disableAnimationsOf(context)) {
      if (_activeReaction != null) setState(() => _activeReaction = null);
      return;
    }
    setState(() {
      _activeReaction = reaction;
      _travelX = travelX;
    });
    _gesture.forward(from: 0);
    _reaction = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _activeReaction = null);
      }
    });
  }

  void _tap() {
    final reaction =
        FinnyReaction.values[_tapCount % FinnyReaction.values.length];
    _tapCount++;
    _play(reaction);
    if (ref.read(gameEngineProvider).settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    widget.onReact?.call(reaction);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _reaction?.cancel();
    _gesture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = ref.watch(finnyAppearanceProvider);
    final petName = ref.watch(
      gameEngineProvider.select((state) => state.profile.petName),
    );
    final animations = ref.watch(
      gameEngineProvider.select((state) => state.settings.animationsEnabled),
    );
    return Semantics(
      label: '$petName. Нажимай, чтобы увидеть разные реакции',
      button: true,
      child: InkWell(
        onTap: _tap,
        borderRadius: BorderRadius.circular(48),
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.125,
          child: FutureBuilder<FinnySvg>(
            future: FinnySvg.assets,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: snapshot.hasError
                      ? const Icon(Icons.pets, size: 48)
                      : const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                );
              }
              final reacting = animations && _activeReaction != null;
              final waving = reacting && _activeReaction == FinnyReaction.wave;
              // Wrap SVG in a dedicated RepaintBoundary so Skia / Impeller caches
              // the raster texture instead of re-tessellating vector paths.
              final image = RepaintBoundary(
                child: SvgPicture.string(
                  snapshot.data!.render(
                    look,
                    reacting ? FinnyMood.happy : widget.mood,
                    wave: waving,
                    raincoat: widget.hasRaincoat,
                    stage: widget.stage,
                  ),
                  fit: BoxFit.contain,
                ),
              );
              // Zero idle frame scheduling: return static image when not reacting
              if (!animations || _activeReaction == null) return image;
              return AnimatedBuilder(
                animation: _gesture,
                child: image,
                builder: (context, child) {
                  final progress = _gesture.value;
                  final jump = _activeReaction == FinnyReaction.hop
                      ? -22 * math.sin(math.pi * progress)
                      : 0.0;
                  final angle = _activeReaction == FinnyReaction.dance
                      ? .12 * math.sin(4 * math.pi * progress) * (1 - progress)
                      : _activeReaction == FinnyReaction.wave
                      ? .04 * math.sin(3 * math.pi * progress)
                      : 0.0;
                  final scale = _activeReaction == FinnyReaction.cuddle
                      ? 1 + .09 * math.sin(math.pi * progress)
                      : 1.0;
                  return Transform.translate(
                    offset: Offset(
                      _travelX * math.sin(math.pi * progress),
                      jump,
                    ),
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
