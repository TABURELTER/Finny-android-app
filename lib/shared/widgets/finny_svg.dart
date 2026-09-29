import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

import '../../data/models/event_models.dart';
import '../../data/models/game_state.dart';
import 'finny_appearance.dart';

class FinnySvg {
  final String source;
  final Map<String, dynamic> palettes;
  FinnySvg(this.source, this.palettes);
  static final Future<FinnySvg> assets = _load();
  static Future<FinnySvg> _load() async => FinnySvg(
    await rootBundle.loadString('assets/finny/Finny.svg'),
    jsonDecode(await rootBundle.loadString('assets/finny/palettes.json'))
        as Map<String, dynamic>,
  );
  String render(
    FinnyAppearance look,
    FinnyMood mood, {
    bool wave = false,
    bool raincoat = false,
    DevelopmentStage stage = DevelopmentStage.start,
  }) {
    final doc = XmlDocument.parse(source);
    final colors = look.palette == 'custom'
        ? _customColors(look)
        : palettes[look.palette]['colors'] as Map<String, dynamic>;
    final jacket = raincoat ? 'raincoat' : look.jacket;
    final cloth = {
      'blue': ['#426C9B', '#2B4D76', '#7296B9'],
      'coral': ['#D66A59', '#A74743', '#EB9A7F'],
      'mint': ['#65AA95', '#387564', '#9BD0B9'],
      'raincoat': ['#F5C94B', '#A86B1D', '#FFE68C'],
      'custom': [
        _hex(look.jacketColor),
        _hex(_darker(look.jacketColor, .22)),
        _hex(_lighter(look.jacketColor, .22)),
      ],
    };
    final happy = mood == FinnyMood.happy;
    for (final el in doc.descendants.whereType<XmlElement>().toList()) {
      final part = el.getAttribute('data-part');
      final accessory = el.getAttribute('data-accessory');
      bool hidden = el.getAttribute('style')?.contains('display:none') ?? false;
      if (accessory != null) {
        hidden = !switch (accessory) {
          'glasses' => look.glasses,
          'bow' => look.bow,
          'jacket' => jacket != 'none',
          'beanie' => look.hat == 'beanie',
          'beret' => look.hat == 'beret',
          _ => false,
        };
      }
      if (part == 'quiff') hidden = look.hat != 'none';
      if (el.getAttribute('data-hide-under-jacket') != null) {
        hidden = jacket != 'none';
      }
      if (part == 'armR') hidden = !wave;
      if (part == 'armR-rest') hidden = wave;
      // The closed-eye expression belongs to the brief wave, not to a
      // persistent happy mood. Keep the eyes open after the reaction ends.
      if (part == 'eyes-open') hidden = wave;
      if (part == 'eyes-happy') hidden = !wave;
      final mouth = el.getAttribute('data-mouth');
      if (mouth != null) hidden = mouth != (happy || wave ? 'smile' : 'rest');
      if (part == 'blush') el.setAttribute('opacity', happy ? '.8' : '0');
      if (mood == FinnyMood.worried && part == 'browL') {
        el.setAttribute('transform', 'rotate(-9 246 217)');
      }
      if (mood == FinnyMood.worried && part == 'browR') {
        el.setAttribute('transform', 'rotate(9 408 217)');
      }
      el.removeAttribute('style');
      if (hidden) {
        el.parent?.children.remove(el);
        continue;
      }
      final isAccessory =
          accessory != null ||
          el.ancestors.whereType<XmlElement>().any(
            (p) => p.getAttribute('data-accessory') != null,
          );
      if (!isAccessory) {
        for (final attr in ['fill', 'stroke']) {
          final color = el.getAttribute(attr);
          if (color != null && colors.containsKey(color.toUpperCase())) {
            el.setAttribute(attr, colors[color.toUpperCase()] as String);
          }
        }
      }
      final tone = el.getAttribute('data-cloth');
      if (tone != null && cloth.containsKey(jacket)) {
        el.setAttribute(
          el.getAttribute('fill') != null ? 'fill' : 'stroke',
          cloth[jacket]![['main', 'dark', 'light'].indexOf(tone)],
        );
      }
    }
    // A visible earned medal distinguishes the three stages at room scale.
    if (stage != DevelopmentStage.start) {
      final mark = stage == DevelopmentStage.planner
          ? '<g data-part="growth-planner"><path d="M302 520l-8 52 30-15 25 16-5-53" fill="#3D9B75" stroke="#256D56" stroke-width="4"/><circle cx="325" cy="510" r="34" fill="#FFF0BF" stroke="#7B5C37" stroke-width="5"/><path d="M325 530c-16-19-11-31 11-39 0 19-4 31-11 39z" fill="#66A85A"/><path d="M325 530v-28" stroke="#487A4B" stroke-width="4"/></g>'
          : '<g data-part="growth-independent"><path d="M300 523l-12 58 37-18 34 18-11-58" fill="#ED9A56" stroke="#A45F31" stroke-width="4"/><circle cx="325" cy="510" r="40" fill="#F8D47B" stroke="#98612F" stroke-width="5"/><circle cx="325" cy="510" r="32" fill="#FFF1BB"/><path d="m325 485 7 16 18 2-13 13 3 19-15-9-16 9 3-19-13-13 19-2z" fill="#D78C45"/></g>';
      doc.descendants
          .whereType<XmlElement>()
          .firstWhere((el) => el.getAttribute('id') == 'finny')
          .children
          .add(XmlDocumentFragment.parse(mark));
    }
    return doc.toXmlString();
  }

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  static Color _lighter(Color color, double amount) =>
      Color.lerp(color, Colors.white, amount)!;
  static Color _darker(Color color, double amount) =>
      Color.lerp(color, Colors.black, amount)!;

  static Map<String, String> _customColors(FinnyAppearance look) {
    final fur = look.furColor;
    final tuft = look.tuftColor;
    final belly = look.bellyColor;
    return {
      '#8549E8': _hex(fur),
      '#743AD7': _hex(_darker(fur, .13)),
      '#6936CE': _hex(_darker(fur, .20)),
      '#5127A7': _hex(_darker(fur, .35)),
      '#4A259B': _hex(_darker(fur, .42)),
      '#683ABE': _hex(_darker(fur, .25)),
      '#51275E': _hex(_darker(fur, .48)),
      '#8A5294': _hex(_darker(fur, .22)),
      '#A7E75B': _hex(tuft),
      '#B6EC6E': _hex(_lighter(tuft, .2)),
      '#9FDC56': _hex(_darker(tuft, .06)),
      '#8ED047': _hex(_darker(tuft, .14)),
      '#C8F28E': _hex(_lighter(tuft, .38)),
      '#8BC74A': _hex(_darker(tuft, .19)),
      '#F1E4FF': _hex(belly),
      '#C2A1F0': _hex(_darker(belly, .15)),
      '#83C945': _hex(look.eyeColor),
    };
  }
}
