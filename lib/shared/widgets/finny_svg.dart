import 'dart:convert';
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
    jsonDecode(await rootBundle.loadString('assets/finny/palettes.json')) as Map<String, dynamic>,
  );
  String render(FinnyAppearance look, FinnyMood mood, {bool wave = false,
    bool raincoat = false, DevelopmentStage stage = DevelopmentStage.start}) {
    final doc = XmlDocument.parse(source);
    final colors = palettes[look.palette]['colors'] as Map<String, dynamic>;
    final jacket = raincoat ? 'blue' : look.jacket;
    final cloth = {'blue': ['#426C9B','#2B4D76','#7296B9'], 'coral': ['#D66A59','#A74743','#EB9A7F'], 'mint': ['#65AA95','#387564','#9BD0B9']};
    final happy = mood == FinnyMood.happy;
    for (final el in doc.descendants.whereType<XmlElement>().toList()) {
      final part = el.getAttribute('data-part');
      final accessory = el.getAttribute('data-accessory');
      bool hidden = el.getAttribute('style')?.contains('display:none') ?? false;
      if (accessory != null) { hidden = !switch (accessory) {
        'glasses' => look.glasses, 'bow' => look.bow,
        'jacket' => jacket != 'none', 'beanie' => look.hat == 'beanie', 'beret' => look.hat == 'beret', _ => false,
      }; }
      if (part == 'quiff') hidden = look.hat != 'none';
      if (el.getAttribute('data-hide-under-jacket') != null) hidden = jacket != 'none';
      if (part == 'armR') hidden = !wave;
      if (part == 'armR-rest') hidden = wave;
      if (part == 'eyes-open') hidden = happy;
      if (part == 'eyes-happy') hidden = !happy;
      final mouth = el.getAttribute('data-mouth');
      if (mouth != null) hidden = mouth != (happy || wave ? 'smile' : 'rest');
      if (part == 'blush') el.setAttribute('opacity', happy ? '.8' : '0');
      if (mood == FinnyMood.worried && part == 'browL') el.setAttribute('transform','rotate(-9 246 217)');
      if (mood == FinnyMood.worried && part == 'browR') el.setAttribute('transform','rotate(9 408 217)');
      el.removeAttribute('style');
      if (hidden) { el.parent?.children.remove(el); continue; }
      final isAccessory = accessory != null || el.ancestors.whereType<XmlElement>().any((p) => p.getAttribute('data-accessory') != null);
      if (!isAccessory) { for (final attr in ['fill','stroke']) {
        final color = el.getAttribute(attr); if (color != null && colors.containsKey(color.toUpperCase())) el.setAttribute(attr, colors[color.toUpperCase()] as String);
      } }
      final tone = el.getAttribute('data-cloth');
      if (tone != null && cloth.containsKey(jacket)) el.setAttribute(el.getAttribute('fill') != null ? 'fill' : 'stroke',cloth[jacket]![['main','dark','light'].indexOf(tone)]);
    }
    // A small earned chest emblem marks growth without changing the child's outfit.
    if (stage != DevelopmentStage.start) {
      final mark = stage == DevelopmentStage.planner
          ? '<g data-part="growth-planner"><circle cx="325" cy="510" r="17" fill="#F6E5AD" stroke="#7B5C37" stroke-width="3"/><path d="M325 518c-8-9-6-16 5-20 0 9-2 16-5 20z" fill="#66A85A"/><path d="M325 518v-13" stroke="#487A4B" stroke-width="2"/></g>'
          : '<g data-part="growth-independent"><circle cx="325" cy="510" r="22" fill="#F8D47B" stroke="#98612F" stroke-width="4"/><circle cx="325" cy="510" r="17" fill="#FFF1BB"/><path d="m325 496 4 9 10 1-7 7 2 10-9-5-9 5 2-10-7-7 10-1z" fill="#D78C45"/></g>';
      doc.descendants.whereType<XmlElement>()
          .firstWhere((el) => el.getAttribute('id') == 'finny')
          .children.add(XmlDocumentFragment.parse(mark));
    }
    return doc.toXmlString();
  }
}
