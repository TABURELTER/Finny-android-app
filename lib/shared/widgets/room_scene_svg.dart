import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

import '../../data/models/game_state.dart';

class RoomSceneSvg extends StatelessWidget {
  final ForecastInfo forecast;
  final bool bed, lamp, ball, robot, kite;
  final String? activeItem;
  const RoomSceneSvg({
    super.key,
    required this.forecast,
    required this.bed,
    required this.lamp,
    this.ball = false,
    this.robot = false,
    this.kite = false,
    this.activeItem,
  });

  static final Future<String> _asset = rootBundle.loadString(
    'assets/finny/room.svg',
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _asset,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const ColoredBox(color: Color(0xFFFFE7CB));
      final doc = XmlDocument.parse(snapshot.data!);
      final title = forecast.title.toLowerCase();
      final weather = title.contains('дожд') || title.contains('ливень')
          ? 'rain'
          : title.contains('туч')
          ? 'cloud'
          : title.contains('ветер')
          ? 'windy'
          : title.contains('празд') || title.contains('ярмарк')
          ? 'festival'
          : 'sun';
      final sky = switch (weather) {
        'rain' => ['#6F8FA5', '#9EB5C1', '#C7D5D8'],
        'cloud' => ['#8FAEBB', '#C5D4D9', '#E4E0D8'],
        'windy' => ['#78CCE2', '#BDDCE5', '#FFF2D6'],
        _ => ['#6DC8EB', '#BBEAF6', '#FFF2D6'],
      };
      for (final element in doc.descendants.whereType<XmlElement>().toList()) {
        final id = element.getAttribute('id');
        if (id == 'sky-grad') {
          final stops = element.children.whereType<XmlElement>().toList();
          for (var i = 0; i < stops.length && i < sky.length; i++) {
            stops[i].setAttribute('stop-color', sky[i]);
          }
        }
        if (id == 'room-ball' && activeItem == 'toy_ball') {
          element.setAttribute('transform', 'translate(0,-12)');
        }
        if (id == 'room-robot' && activeItem == 'toy_robot') {
          element.setAttribute('transform', 'rotate(-12 244 270)');
        }
        if (id == 'room-kite' && activeItem == 'kite') {
          element.setAttribute('transform', 'translate(0,-10)');
        }
        final show = switch (id) {
          'weather-sun' => weather != 'rain' && weather != 'cloud',
          'weather-birds' => weather != 'rain' && weather != 'cloud',
          'weather-soft-cloud' => weather != 'rain' && weather != 'cloud',
          'weather-cloud' => weather == 'cloud',
          'weather-windy' => weather == 'windy',
          'weather-rain' => weather == 'rain',
          'weather-festival' => weather == 'festival',
          'sunbeam' => weather != 'rain' && weather != 'cloud',
          'room-bed' => bed,
          'room-lamp' => lamp,
          'room-bed-sparkle' => bed && activeItem == 'cozy_bed',
          'room-lamp-glow' => lamp && activeItem == 'warm_lamp',
          'room-ball' => ball,
          'room-robot' => robot,
          'room-kite' => kite,
          _ => null,
        };
        if (show == false) element.parent?.children.remove(element);
        if (show == true) element.removeAttribute('style');
      }
      return SvgPicture.string(doc.toXmlString(), fit: BoxFit.fill);
    },
  );
}
