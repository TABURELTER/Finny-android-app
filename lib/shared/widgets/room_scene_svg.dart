import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/game_state.dart';

/// Layer 2: Fixed Room Interior with a transparent window cutout.
/// The interior NEVER changes on weather changes and is rendered statically.
class RoomSceneSvg extends StatelessWidget {
  final ForecastInfo? forecast;
  final bool bed, lamp, ball, robot, kite;
  final String? activeItem;

  const RoomSceneSvg({
    super.key,
    this.forecast,
    this.bed = false,
    this.lamp = false,
    this.ball = false,
    this.robot = false,
    this.kite = false,
    this.activeItem,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/finny/room.svg',
      fit: BoxFit.fill,
    );
  }
}
