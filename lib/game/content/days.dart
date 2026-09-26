import '../../data/models/game_state.dart';

class DayContentConfig {
  final int day;
  final int baseIncome;
  final ForecastInfo forecast;
  final String? scheduledEventId;
  final String? financialTaskId;
  final String dayTitle;
  final String morningMessage;

  const DayContentConfig({
    required this.day,
    required this.baseIncome,
    required this.forecast,
    this.scheduledEventId,
    this.financialTaskId,
    required this.dayTitle,
    required this.morningMessage,
  });
}

final List<DayContentConfig> kDaysConfig = [
  const DayContentConfig(
    day: 1,
    baseIncome: 50,
    forecast: ForecastInfo(
      title: 'Солнечно',
      icon: '☀️',
      hint: 'Сегодня Финни обустраивает свой новый домик.',
    ),
    financialTaskId: 'task_day_2',
    dayTitle: 'День 1: Три конверта',
    morningMessage: 'У Финни 50 монет. Составь план: что нужно сегодня, что хочется и сколько отложить.',
  ),
  const DayContentConfig(
    day: 2,
    baseIncome: 10,
    forecast: ForecastInfo(
      title: 'Ветерок',
      icon: '🌤️',
      hint: 'Запасы еды закончатся завтра! Пора подумать о плане.',
    ),
    financialTaskId: 'task_day_4',
    dayTitle: 'День 2: Корзина и сдача',
    morningMessage: 'Новый день принёс 10 монет. Сравни покупки и проверь сдачу.',
  ),
  const DayContentConfig(
    day: 3,
    baseIncome: 10,
    forecast: ForecastInfo(
      title: 'Ясно и тепло',
      icon: '☀️',
      hint: 'Финни мечтает о большой цели. Пора открыть копилку!',
    ),
    financialTaskId: 'task_day_3',
    dayTitle: 'День 3: Дорожка к мечте',
    morningMessage: 'Сегодня попробуй наметить небольшие взносы в копилку.',
  ),
  const DayContentConfig(
    day: 4,
    baseIncome: 10,
    forecast: ForecastInfo(
      title: 'Надвигаются тучи',
      icon: '🌥️',
      hint: 'Завтра синоптики обещают затяжной ливень! Подготовься заранее.',
    ),
    financialTaskId: 'task_day_6',
    dayTitle: 'День 4: Запас на завтра',
    morningMessage: 'Завтра возможен ливень. Подумай, что понадобится Финни и что можно отложить.',
  ),
  const DayContentConfig(
    day: 5,
    baseIncome: 10,
    forecast: ForecastInfo(
      title: 'Грозовой ливень',
      icon: '🌧️',
      hint: 'Дождь барабанит по стеклу. В доме слышен звук капель...',
    ),
    scheduledEventId: 'rain_roof',
    financialTaskId: 'task_day_7',
    dayTitle: 'День 5: План Б',
    morningMessage: 'Ливень повредил крышу. Запас и обдуманный выбор помогут Финни справиться.',
  ),
  const DayContentConfig(
    day: 6,
    baseIncome: 20,
    forecast: ForecastInfo(
      title: 'Солнечно и свежо',
      icon: '🌤️',
      hint: 'После дождя выглянуло солнце. В магазин завезли новинку!',
    ),
    financialTaskId: null,
    dayTitle: 'День 6: Свой выбор',
    morningMessage: 'Ты уже умеешь сравнивать цены. Продолжай строить свой план и заботиться о Финни.',
  ),
  const DayContentConfig(
    day: 7,
    baseIncome: 20,
    forecast: ForecastInfo(
      title: 'Праздничные огни',
      icon: '🎪',
      hint: 'Завтра на площади Большой Праздник! Билет стоит 15 монет.',
    ),
    financialTaskId: null,
    dayTitle: 'День 7: Подготовка к празднику',
    morningMessage: 'Завтра праздник. Реши, сколько сохранить на билет и что нужно сегодня.',
  ),
  const DayContentConfig(
    day: 8,
    baseIncome: 25,
    forecast: ForecastInfo(
      title: 'Ярмарка и музыка',
      icon: '🎡',
      hint: 'Праздник в разгаре! Карусели, музыка и веселье!',
    ),
    scheduledEventId: 'city_festival',
    financialTaskId: null,
    dayTitle: 'День 8: Городской праздник',
    morningMessage: 'Сегодня день ярмарки! Время веселья или спокойной прогулки.',
  ),
  const DayContentConfig(
    day: 9,
    baseIncome: 20,
    forecast: ForecastInfo(
      title: 'Чистое небо',
      icon: '✨',
      hint: 'До большой мечты остался последний рывок!',
    ),
    financialTaskId: null,
    dayTitle: 'День 9: Финальный рывок',
    morningMessage: 'Цель уже совсем близко! Рассчитай последние монеты.',
  ),
  const DayContentConfig(
    day: 10,
    baseIncome: 10,
    forecast: ForecastInfo(
      title: 'Торжественный день',
      icon: '🌟',
      hint: 'Финальный день нашей маленькой 10-дневной жизни!',
    ),
    financialTaskId: null,
    dayTitle: 'День 10: Большой финал',
    morningMessage: 'Ура! Сегодня мы подводим итоги всех 10 дней с Финни!',
  ),
];
