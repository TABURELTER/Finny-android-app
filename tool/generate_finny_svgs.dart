import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';

void main() {
  final source = File('assets/finny/Finny.svg').readAsStringSync();
  final palettes = jsonDecode(File('assets/finny/palettes.json').readAsStringSync()) as Map<String, dynamic>;

  String render({
    String palette = 'original',
    String mood = 'good',
    bool wave = false,
    bool raincoat = false,
    bool glasses = false,
    bool bow = false,
    String hat = 'none',
    String jacket = 'none',
    String stage = 'start',
    bool think = false,
    bool celebrate = false,
    bool coin = false,
  }) {
    final doc = XmlDocument.parse(source);
    final colors = (palettes[palette]?['colors'] as Map<String, dynamic>?) ?? {};
    final activeJacket = raincoat ? 'raincoat' : jacket;
    final cloth = {
      'blue': ['#426C9B', '#2B4D76', '#7296B9'],
      'coral': ['#D66A59', '#A74743', '#EB9A7F'],
      'mint': ['#65AA95', '#387564', '#9BD0B9'],
      'raincoat': ['#F5C94B', '#A86B1D', '#FFE68C'],
    };
    final happy = mood == 'happy';

    for (final el in doc.descendants.whereType<XmlElement>().toList()) {
      final part = el.getAttribute('data-part');
      final accessory = el.getAttribute('data-accessory');
      bool hidden = el.getAttribute('style')?.contains('display:none') ?? false;

      if (accessory != null) {
        hidden = !switch (accessory) {
          'glasses' => glasses,
          'bow' => bow,
          'jacket' => activeJacket != 'none',
          'beanie' => hat == 'beanie',
          'beret' => hat == 'beret',
          _ => false,
        };
      }
      if (part == 'hat-beanie') hidden = hat != 'beanie';
      if (part == 'hat-beret') hidden = hat != 'beret';
      if (part == 'quiff') hidden = hat != 'none';
      if (el.getAttribute('data-hide-under-jacket') != null) {
        hidden = activeJacket != 'none';
      }
      if (part == 'armR') hidden = !wave;
      if (part == 'armR-rest') hidden = wave;
      if (part == 'eyes-open') hidden = wave;
      if (part == 'eyes-happy') hidden = !wave;
      if (part == 'fx-think') hidden = !think;
      if (part == 'fx-celebrate') hidden = !celebrate;

      final mouth = el.getAttribute('data-mouth');
      if (mouth != null) hidden = mouth != (happy || wave ? 'smile' : 'rest');
      if (part == 'blush') el.setAttribute('opacity', happy || wave ? '.8' : '0');

      el.removeAttribute('style');
      if (hidden) {
        el.parent?.children.remove(el);
        continue;
      }

      final isAccessory = accessory != null ||
          el.ancestors.whereType<XmlElement>().any(
                (p) => p.getAttribute('data-accessory') != null,
              );
      if (!isAccessory && colors.isNotEmpty) {
        for (final attr in ['fill', 'stroke']) {
          final color = el.getAttribute(attr);
          if (color != null && colors.containsKey(color.toUpperCase())) {
            el.setAttribute(attr, colors[color.toUpperCase()] as String);
          }
        }
      }

      final tone = el.getAttribute('data-cloth');
      if (tone != null && cloth.containsKey(activeJacket)) {
        el.setAttribute(
          el.getAttribute('fill') != null ? 'fill' : 'stroke',
          cloth[activeJacket]![['main', 'dark', 'light'].indexOf(tone)],
        );
      }
    }

    if (stage != 'start') {
      final mark = stage == 'planner'
          ? '<g data-part="growth-planner"><path d="M302 520l-8 52 30-15 25 16-5-53" fill="#3D9B75" stroke="#256D56" stroke-width="4"/><circle cx="325" cy="510" r="34" fill="#FFF0BF" stroke="#7B5C37" stroke-width="5"/><path d="M325 530c-16-19-11-31 11-39 0 19-4 31-11 39z" fill="#66A85A"/><path d="M325 530v-28" stroke="#487A4B" stroke-width="4"/></g>'
          : '<g data-part="growth-independent"><path d="M300 523l-12 58 37-18 34 18-11-58" fill="#ED9A56" stroke="#A45F31" stroke-width="4"/><circle cx="325" cy="510" r="40" fill="#F8D47B" stroke="#98612F" stroke-width="5"/><circle cx="325" cy="510" r="32" fill="#FFF1BB"/><path d="m325 485 7 16 18 2-13 13 3 19-15-9-16 9 3-19-13-13 19-2z" fill="#D78C45"/></g>';
      doc.descendants
          .whereType<XmlElement>()
          .firstWhere((el) => el.getAttribute('id') == 'finny')
          .children
          .add(XmlDocumentFragment.parse(mark));
    }

    if (coin) {
      const coinGraphic = '<g data-part="prop-coin" transform="translate(435 440)"><circle cx="36" cy="36" r="36" fill="#F9A825" stroke="#F57F17" stroke-width="4"/><circle cx="36" cy="36" r="28" fill="#FDD835"/><text x="36" y="47" font-size="34" font-weight="900" font-family="Arial, sans-serif" text-anchor="middle" fill="#E65100">₽</text></g>';
      doc.descendants
          .whereType<XmlElement>()
          .firstWhere((el) => el.getAttribute('id') == 'finny')
          .children
          .add(XmlDocumentFragment.parse(coinGraphic));
    }

    return doc.toXmlString();
  }

  // 1. Classic waving with happy eyes & smile (Для заголовка рядом с иконкой)
  File('assets/finny/finny_wave_classic.svg').writeAsStringSync(
    render(palette: 'original', wave: true, mood: 'happy'),
  );

  // 2. Apricot with beret and jacket (Для блока кастомизации и гардероба)
  File('assets/finny/finny_apricot_happy.svg').writeAsStringSync(
    render(palette: 'apricot', mood: 'happy', jacket: 'blue', hat: 'beret'),
  );

  // 3. Lagoon in yellow raincoat (Для блока 3-слойной комнаты и погоды)
  File('assets/finny/finny_lagoon_raincoat.svg').writeAsStringSync(
    render(palette: 'lagoon', raincoat: true, mood: 'good'),
  );

  // 4. Smart Finny with glasses, bow tie and thinking bubbles (Для блока умного планирования бюджета)
  File('assets/finny/finny_smart_glasses.svg').writeAsStringSync(
    render(palette: 'original', glasses: true, bow: true, mood: 'happy', think: true),
  );

  // 5. Coin booster Finny with golden coin (Для блока Демо-режима и накрутки монет)
  File('assets/finny/finny_coin_saver.svg').writeAsStringSync(
    render(palette: 'original', mood: 'happy', coin: true, celebrate: true),
  );

  // 6. Independent Finny with star growth medal & celebratory stars (Для стадии взросления и жюри)
  File('assets/finny/finny_independent_medal.svg').writeAsStringSync(
    render(palette: 'apricot', stage: 'independent', wave: true, mood: 'happy', celebrate: true),
  );

  print('Generated 6 Finny SVGs successfully!');
}
