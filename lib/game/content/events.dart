import '../../data/models/event_models.dart';

final List<EventDefinition> kGameEvents = [
  const EventDefinition(
    id: 'rain_roof',
    triggerDay: 5,
    title: 'Крыша протекает',
    description: 'После ливня в домике закапало. Выбери, как помочь Финни.',
    icon: '🌧️',
    choices: [
      EventChoice(
        id: 'repair_now',
        title: 'Починить крышу',
        cost: 25,
        freeWithItemId: 'repair_kit',
        immediateFeedback: 'Крыша станет прочной и сухой.',
        consequenceText: 'В домике снова сухо. Ремонт стоил 25 монет.',
        moodEffect: FinnyMood.good,
      ),
      EventChoice(
        id: 'patch_roof',
        title: 'Сделать заплатку',
        cost: 8,
        immediateFeedback: 'Сегодня капли остановятся.',
        consequenceText: 'Сегодня сухо. Позже крышу надо проверить снова.',
        moodEffect: FinnyMood.normal,
      ),
      EventChoice(
        id: 'ignore_roof',
        title: 'Подставить тазик',
        cost: 0,
        immediateFeedback: 'Монеты останутся, но вода ещё капает.',
        consequenceText:
            'Монеты целы. Крышу всё равно придётся починить позже.',
        moodEffect: FinnyMood.worried,
      ),
    ],
  ),
  const EventDefinition(
    id: 'city_festival',
    triggerDay: 8,
    title: 'Праздник в городе',
    description: 'На площади музыка и карусели. Как проведём день?',
    icon: '🎪',
    choices: [
      EventChoice(
        id: 'buy_ticket',
        title: 'Пойти на карусели',
        cost: 15,
        immediateFeedback: 'Билет стоит 15 монет.',
        consequenceText: 'Финни прокатился на каруселях и остался доволен.',
        moodEffect: FinnyMood.happy,
      ),
      EventChoice(
        id: 'free_walk',
        title: 'Послушать концерт',
        cost: 0,
        immediateFeedback: 'Концерт бесплатный.',
        consequenceText:
            'Финни послушал музыку. Монеты остались для других планов.',
        moodEffect: FinnyMood.good,
      ),
    ],
  ),
];
