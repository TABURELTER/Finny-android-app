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

/// A short line for Finny's speech bubble at the start of each day.
String finnyMorningGreeting(int day) => switch (day) {
  1 => 'Доброе утро! Обустроим мой домик?',
  2 => 'Ветерок! Что сегодня важнее?',
  3 => 'Я готов копить на нашу мечту!',
  4 => 'Вижу тучи. Сделаем запас на завтра?',
  5 => 'Слышишь ливень? Справимся вместе!',
  6 => 'Солнце вернулось! Во что поиграем?',
  7 => 'Скоро праздник. Сохраним немного 🪙?',
  8 => 'Ярмарка началась! Выберем самое интересное?',
  9 => 'Мечта уже близко! Я верю в нас.',
  10 => 'Наш большой день! Покажем, чему научились?',
  _ => [
    'Доброе утро! Что сделаем сегодня?',
    'Новый день — новый выбор. Я готов!',
    'Интересно, что нас ждёт за окном?',
    'Давай позаботимся друг о друге!',
  ][day % 4],
};

/// The first ten days are authored chapters; afterwards the same game loop
/// continues with changing weather and fresh procedural decisions.
DayContentConfig dayConfigFor(int day) {
  if (day <= kDaysConfig.length) {
    return kDaysConfig[(day - 1).clamp(0, kDaysConfig.length - 1)];
  }
  const forecasts = [
    ForecastInfo(
      title: 'Ясно и тепло',
      icon: '☀️',
      hint: 'Хороший день для прогулки.',
    ),
    ForecastInfo(
      title: 'Ветерок',
      icon: '🌤️',
      hint: 'Ветер зовёт посмотреть во двор.',
    ),
    ForecastInfo(
      title: 'Дождь',
      icon: '🌧️',
      hint: 'Для прогулки пригодится дождевик.',
    ),
    ForecastInfo(
      title: 'Облачно',
      icon: '☁️',
      hint: 'Можно выбрать домашние дела.',
    ),
  ];
  return DayContentConfig(
    day: day,
    baseIncome: 3,
    forecast: forecasts[(day - 11) % forecasts.length],
    dayTitle: 'День $day: Новые приключения',
    morningMessage: 'Семья дала на день 3 🪙. ${finnyMorningGreeting(day)}',
  );
}

final List<DayContentConfig> kDaysConfig = [
  const DayContentConfig(
    day: 1,
    baseIncome: 20,
    forecast: ForecastInfo(
      title: 'Солнечно',
      icon: '☀️',
      hint: 'Сегодня Финни обустраивает свой новый домик.',
    ),
    financialTaskId: 'task_day_2',
    scheduledEventId: 'first_home',
    dayTitle: 'День 1: Новый домик',
    morningMessage: 'Семья дала Финни 20 🪙. Сначала составим план на день?',
  ),
  const DayContentConfig(
    day: 2,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Ветерок',
      icon: '🌤️',
      hint: 'В кладовке мало еды. Сегодня можно пополнить запас.',
    ),
    financialTaskId: 'task_day_4',
    scheduledEventId: 'market_find',
    dayTitle: 'День 2: Корзина и сдача',
    morningMessage: 'Семья дала на день 3 🪙. В лавке есть еда для запасов.',
  ),
  const DayContentConfig(
    day: 3,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Ясно и тепло',
      icon: '☀️',
      hint: 'Финни мечтает о большой цели. Пора открыть копилку!',
    ),
    financialTaskId: 'task_day_3',
    scheduledEventId: 'garden_help',
    dayTitle: 'День 3: Дорожка к мечте',
    morningMessage: 'Семья дала на день 3 🪙. Что взять за помощь соседке?',
  ),
  const DayContentConfig(
    day: 4,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Надвигаются тучи',
      icon: '🌥️',
      hint: 'Завтра синоптики обещают затяжной ливень! Подготовься заранее.',
    ),
    financialTaskId: 'task_day_6',
    scheduledEventId: 'storm_warning',
    dayTitle: 'День 4: Запас на завтра',
    morningMessage: 'Семья дала на день 3 🪙. Завтра ливень: сделаем запас?',
  ),
  const DayContentConfig(
    day: 5,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Грозовой ливень',
      icon: '🌧️',
      hint: 'Дождь барабанит по стеклу. В доме слышен звук капель...',
    ),
    scheduledEventId: 'rain_roof',
    financialTaskId: 'task_day_7',
    dayTitle: 'День 5: План Б',
    morningMessage: 'Семья дала на день 3 🪙. Крыша течёт: как помочь?',
  ),
  const DayContentConfig(
    day: 6,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Солнечно и свежо',
      icon: '🌤️',
      hint: 'После дождя выглянуло солнце. В магазин завезли новинку!',
    ),
    financialTaskId: null,
    scheduledEventId: 'lantern_workshop',
    dayTitle: 'День 6: Свой выбор',
    morningMessage: 'Семья дала на день 3 🪙. В мастерской выберем награду.',
  ),
  const DayContentConfig(
    day: 7,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Праздничные огни',
      icon: '🎪',
      hint: 'Завтра на площади Большой Праздник! Билет стоит 15 🪙.',
    ),
    financialTaskId: null,
    dayTitle: 'День 7: Подготовка к празднику',
    scheduledEventId: 'festival_preview',
    morningMessage: 'Семья дала на день 3 🪙. Билет сегодня дешевле.',
  ),
  const DayContentConfig(
    day: 8,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Ярмарка и музыка',
      icon: '🎡',
      hint: 'Праздник в разгаре! Карусели, музыка и веселье!',
    ),
    scheduledEventId: 'city_festival',
    financialTaskId: null,
    dayTitle: 'День 8: Городской праздник',
    morningMessage: 'Семья дала на день 3 🪙. Карусели или концерт?',
  ),
  const DayContentConfig(
    day: 9,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Чистое небо',
      icon: '✨',
      hint: 'До большой мечты остался последний рывок!',
    ),
    financialTaskId: null,
    scheduledEventId: 'windy_gift',
    dayTitle: 'День 9: Финальный рывок',
    morningMessage: 'Семья дала на день 3 🪙. Змей или деньги на мечту?',
  ),
  const DayContentConfig(
    day: 10,
    baseIncome: 3,
    forecast: ForecastInfo(
      title: 'Ясно и тепло',
      icon: '🌟',
      hint: 'Первые десять дней позади, а приключения продолжаются.',
    ),
    financialTaskId: null,
    dayTitle: 'День 10: Первые итоги',
    scheduledEventId: 'last_day',
    morningMessage: 'Семья дала на день 3 🪙. Сегодня подведём итоги.',
  ),
];
