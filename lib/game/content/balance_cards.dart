import '../../data/models/game_state.dart';

class BalanceChoice {
  final String id;
  final String title;
  final String detail;
  final int coins;
  final double satiety;
  final double energy;
  final double wellbeing;
  final String? meal;
  final bool fromPantry;
  final bool opensWork;
  final bool useSavings;

  const BalanceChoice({
    required this.id,
    required this.title,
    required this.detail,
    this.coins = 0,
    this.satiety = 0,
    this.energy = 0,
    this.wellbeing = 0,
    this.meal,
    this.fromPantry = false,
    this.opensWork = false,
    this.useSavings = false,
  });
}

/// The work preview and the actual reward must use the same trade-off.
({double satiety, double energy, double wellbeing}) workImpact(
  FinnyBalance stats,
) {
  const satiety = -1.0;
  const energy = -1.75;
  final overworked = stats.satiety + satiety <= 1 || stats.energy + energy <= 1;
  return (
    satiety: satiety,
    energy: energy,
    wellbeing: overworked ? -1.0 : -0.5,
  );
}

class BalanceCard {
  final String id;
  final String icon;
  final String title;
  final String prompt;
  final List<BalanceChoice> choices;

  const BalanceCard({
    required this.id,
    required this.icon,
    required this.title,
    required this.prompt,
    required this.choices,
  });
}

int _variantFor(GameState state, int count) =>
    ((state.profile.startDate.millisecondsSinceEpoch ~/ 1000) +
        state.day * 17 +
        state.balanceStats.cardsToday * 31) %
    count;

/// Context changes the next card, while four decisions bound each day.
BalanceCard? balanceCardFor(GameState state) {
  final balance = state.balanceStats;
  if (balance.cardsToday >= 4) return null;

  if (balance.wellbeing <= 1) {
    const titles = [
      'Финни нехорошо',
      'Нужна передышка',
      'Время позаботиться',
      'Финни просит помощи',
      'Тихий час',
      'Здоровье важнее',
    ];
    const prompts = [
      'Финни устал от дел. Поможем ему восстановиться?',
      'После трудного дня нужна забота.',
      'Финни чувствует себя неважно. Что сделаем?',
      'Можно отдохнуть дома или обратиться к врачу.',
      'Сегодня лучше выбрать спокойный путь.',
      'Попросим взрослого помочь Финни.',
    ];
    final variant = _variantFor(state, titles.length);
    return BalanceCard(
      id: 'care_$variant',
      icon: '💚',
      title: titles[variant],
      prompt: prompts[variant],
      choices: const [
        BalanceChoice(
          id: 'care_rest',
          title: 'Отдых и забота',
          detail: '❤️+ ⚡+',
          wellbeing: 1,
          energy: 1,
        ),
        BalanceChoice(
          id: 'care_doctor',
          title: 'Обратиться к врачу · 8 🪙',
          detail: '❤️+ ⚡+',
          coins: -8,
          wellbeing: 2,
          energy: 1,
        ),
      ],
    );
  }

  if (balance.satiety <= 2) return _mealCard(state);
  if (balance.energy <= 1) {
    const titles = [
      'Финни устал',
      'Пора отдохнуть',
      'Силы на исходе',
      'Нужна пауза',
      'Тихое занятие',
      'Восстановим силы',
    ];
    const prompts = [
      'Восстановим силы перед новыми делами?',
      'Финни зевает. Отдых или спокойная игра?',
      'Тело подсказывает: сейчас нужна передышка.',
      'Дел много, а сил осталось мало.',
      'Можно посидеть в домике и набраться сил.',
      'Как помочь Финни почувствовать себя бодрее?',
    ];
    final variant = _variantFor(state, titles.length);
    return BalanceCard(
      id: 'recover_$variant',
      icon: '🛏️',
      title: titles[variant],
      prompt: prompts[variant],
      choices: const [
        BalanceChoice(
          id: 'rest',
          title: 'Отдохнуть',
          detail: '⚡+',
          energy: 1.5,
        ),
        BalanceChoice(
          id: 'quiet_play',
          title: 'Спокойно поиграть',
          detail: '⚡+ ❤️+',
          energy: 0.5,
          wellbeing: 0.5,
        ),
      ],
    );
  }

  return _scenarioCard(state);
}

BalanceCard _mealCard(GameState state) {
  final pantry = state.inventory.foodReserveDays > 0;
  final featured = switch (state.day % 3) {
    0 => const BalanceChoice(
      id: 'fruit',
      title: 'Фрукты · 5 🪙',
      detail: '🍽️+ ❤️+',
      coins: -5,
      satiety: 1,
      wellbeing: 1,
      meal: 'fruit',
    ),
    1 => const BalanceChoice(
      id: 'soup',
      title: 'Тёплый суп · 7 🪙',
      detail: '🍽️+ ⚡+ ❤️+',
      coins: -7,
      satiety: 2,
      energy: 1,
      wellbeing: 1,
      meal: 'soup',
    ),
    _ => const BalanceChoice(
      id: 'pie',
      title: 'Пирожок · 4 🪙',
      detail: '🍽️+ ⚡+',
      coins: -4,
      satiety: 1,
      energy: 1,
      meal: 'pie',
    ),
  };
  final basic = pantry
      ? const BalanceChoice(
          id: 'pantry',
          title: 'Еда из кладовки',
          detail: '🍽️+ ⚡+ · одна порция из запаса',
          satiety: 2,
          energy: 1,
          fromPantry: true,
          meal: 'pantry',
        )
      : state.balance >= 7
      ? const BalanceChoice(
          id: 'soup',
          title: 'Тёплый суп · 7 🪙',
          detail: '🍽️+ ⚡+',
          coins: -7,
          satiety: 2,
          energy: 1,
          meal: 'soup',
        )
      : state.savings >= 7
      ? const BalanceChoice(
          id: 'savings_soup',
          title: 'Еда из копилки · 7 🪙',
          detail: '🍽️+ ⚡+ · мечта чуть дальше',
          coins: -7,
          satiety: 2,
          energy: 1,
          meal: 'soup',
          useSavings: true,
        )
      : const BalanceChoice(
          id: 'help_meal',
          title: 'Попросить помощь',
          detail: '🍽️+ · бесплатно',
          satiety: 1,
          meal: 'help',
        );
  final second = state.balance >= -featured.coins && featured.id != basic.id
      ? featured
      : const BalanceChoice(
          id: 'wait_meal',
          title: 'Пока не есть',
          detail: 'Монеты останутся · 🍽️− ❤️−',
          satiety: -0.5,
          wellbeing: -0.5,
        );
  const titles = [
    'Время перекусить',
    'Финни проголодался',
    'Обед в домике',
    'Что сегодня съесть?',
    'На кухне пахнет едой',
    'Нужна еда',
    'Пора подкрепиться',
    'Выбираем обед',
  ];
  const prompts = [
    'Разная еда помогает Финни чувствовать себя лучше.',
    'Сытость упала. Что есть в кладовке и кошельке?',
    'Выберем еду, чтобы хватило сил на день.',
    'Один и тот же обед каждый раз радует меньше.',
    'Пора позаботиться о сытости Финни.',
    'Еда стоит монет, зато помогает восстановиться.',
    'Можно поесть из запаса или купить что-то другое.',
    'Сначала еда, потом новые приключения.',
  ];
  final variant = _variantFor(state, titles.length);
  return BalanceCard(
    id: 'meal_$variant',
    icon: '🍽️',
    title: titles[variant],
    prompt: prompts[variant],
    choices: [basic, second],
  );
}

enum _SceneKind { play, quiet, work, spend, explore, meal }

class _Scene {
  final String id, icon, title, prompts, first, second;
  final _SceneKind kind;
  const _Scene(
    this.id,
    this.icon,
    this.title,
    this.prompts,
    this.first,
    this.second,
    this.kind,
  );
}

/// 32 distinct situations, four authored lines each, with clear/rainy
/// consequences: 256 stable narrative variants before care cards and events.
const _scenes = <_Scene>[
  _Scene(
    'music',
    '🎵',
    'Музыка из окна',
    'Финни услышал весёлую мелодию.|Знакомая песенка доносится из соседнего дома.|Кто-то играет ритм на маленьком барабане.|Финни хочет придумать свой танец.',
    'Потанцевать',
    'Послушать сидя',
    _SceneKind.play,
  ),
  _Scene(
    'boat',
    '⛵',
    'Бумажный кораблик',
    'На столе лежит цветная бумага.|Финни нашёл инструкцию для кораблика.|Сосед принёс лист с волнами.|У Финни получился крошечный парус.',
    'Пустить кораблик',
    'Сложить спокойно',
    _SceneKind.play,
  ),
  _Scene(
    'garden_window',
    '🪴',
    'Сад у окна',
    'Росток немного наклонился к свету.|Финни заметил новый зелёный лист.|Земля в горшке стала сухой.|На окне появилось место для цветка.',
    'Ухаживать за садом',
    'Посидеть рядом',
    _SceneKind.quiet,
  ),
  _Scene(
    'parcel',
    '📦',
    'Посылка соседу',
    'Соседу нужно разобрать коробки.|У двери ждёт небольшая посылка.|Сосед просит помочь с покупками.|На лестнице осталось несколько коробок.',
    'Помочь с посылкой',
    'Отдохнуть дома',
    _SceneKind.work,
  ),
  _Scene(
    'ribbons',
    '🎀',
    'Пёстрые ленты',
    'На прилавке блестят яркие ленты.|Финни заметил красивую ленточку.|Продавец показывает новый набор.|Для домика можно выбрать украшение.',
    'Купить украшение',
    'Сделать своё',
    _SceneKind.spend,
  ),
  _Scene(
    'library',
    '📚',
    'Книжный уголок',
    'В книге Финни нашёл карту леса.|На полке ждёт новая сказка.|Финни хочет узнать конец истории.|Сосед оставил книжку с картинками.',
    'Почитать вместе',
    'Отдохнуть в тишине',
    _SceneKind.quiet,
  ),
  _Scene(
    'chalk',
    '🖍️',
    'Цветные мелки',
    'Во дворе можно нарисовать дорожку.|Финни придумал огромную радугу.|У ворот остались цветные мелки.|Соседи зовут рисовать на площадке.',
    'Рисовать во дворе',
    'Рисовать дома',
    _SceneKind.explore,
  ),
  _Scene(
    'button',
    '🧵',
    'Потерянная пуговица',
    'Сосед ищет пуговицу от куртки.|Финни заметил маленький блеск под столом.|В мастерской просят разобрать мелочи.|На ковре рассыпались пуговицы.',
    'Помочь найти',
    'Передохнуть',
    _SceneKind.work,
  ),
  _Scene(
    'market_bell',
    '🔔',
    'Звонок на рынке',
    'На рынке появился весёлый колокольчик.|Финни услышал звон у лавки.|Торговец показывает маленький сувенир.|Финни хочет украсить дверь.',
    'Купить сувенир',
    'Запомнить звук',
    _SceneKind.spend,
  ),
  _Scene(
    'stars',
    '⭐',
    'Карта звёзд',
    'Финни нашёл точки на звёздной карте.|На бумаге осталось соединить созвездия.|Финни придумал имя новой звезде.|В домике можно устроить звёздную игру.',
    'Играть в космос',
    'Рисовать звёзды',
    _SceneKind.play,
  ),
  _Scene(
    'apple_tree',
    '🌳',
    'Яблоня во дворе',
    'Под деревом лежат красивые листья.|Финни заметил птицу на яблоне.|Во дворе пахнет свежими яблоками.|Соседи собирают листья у дерева.',
    'Прогуляться',
    'Смотреть из окна',
    _SceneKind.explore,
  ),
  _Scene(
    'lamp_story',
    '💡',
    'Тёплый свет',
    'В комнате хочется устроить тихий вечер.|Финни придумал историю про фонарь.|Можно посидеть рядом и поговорить.|На стене появились смешные тени.',
    'Рассказать историю',
    'Прилечь отдохнуть',
    _SceneKind.quiet,
  ),
  _Scene(
    'puppet',
    '🎭',
    'Кукольный театр',
    'На площади показывают маленький спектакль.|Афиша обещает смешную историю.|Финни увидел ширму с фигурками.|Сосед зовёт в кукольный театр.',
    'Купить билет',
    'Сыграть дома',
    _SceneKind.spend,
  ),
  _Scene(
    'river',
    '🏞️',
    'Дорожка к реке',
    'У воды видны следы маленьких птиц.|Дорожка ведёт к тихому берегу.|Финни хочет послушать ручей.|На тропинке появились новые цветы.',
    'Сходить к воде',
    'Остаться в домике',
    _SceneKind.explore,
  ),
  _Scene(
    'cleanup',
    '🧹',
    'Порядок у соседа',
    'Соседу нужна помощь с уборкой.|На полке перепутались коробочки.|После праздника осталось прибраться.|Финни нашёл работу на сегодня.',
    'Помочь убрать',
    'Сберечь силы',
    _SceneKind.work,
  ),
  _Scene(
    'birds',
    '🐦',
    'Птицы за окном',
    'На ветке сидят две птицы.|Финни услышал знакомый щебет.|У окна мелькнуло пёстрое крыло.|Можно понаблюдать за птичьим домиком.',
    'Наблюдать вместе',
    'Отдохнуть',
    _SceneKind.quiet,
  ),
  _Scene(
    'postcard',
    '💌',
    'Открытка другу',
    'Финни хочет порадовать друга.|На прилавке есть яркая открытка.|Скоро у соседки праздник.|Можно отправить доброе послание.',
    'Купить открытку',
    'Нарисовать самому',
    _SceneKind.spend,
  ),
  _Scene(
    'soup',
    '🥣',
    'Запах обеда',
    'Из кухни пахнет тёплым супом.|Финни задумался, что съесть.|В кладовке можно поискать обед.|После дел захотелось перекусить.',
    'Выбрать еду',
    'Подумать о запасе',
    _SceneKind.meal,
  ),
  _Scene(
    'puzzle',
    '🧩',
    'Коробка с загадкой',
    'На столе рассыпались детали пазла.|Финни нашёл недостающий уголок.|Сосед подарил новую загадку.|Картинка почти сложилась.',
    'Собрать пазл',
    'Отложить и отдохнуть',
    _SceneKind.play,
  ),
  _Scene(
    'flowers',
    '🌼',
    'Цветы у дороги',
    'Финни заметил жёлтые цветы.|У дорожки выросли ромашки.|Соседка зовёт посмотреть клумбу.|Во дворе распустился первый бутон.',
    'Пойти к клумбе',
    'Посмотреть из окна',
    _SceneKind.explore,
  ),
  _Scene(
    'books',
    '📖',
    'Книжная полка',
    'В лавке появилась книга с картинками.|Финни увидел новый сборник сказок.|Сосед продаёт старую добрую книгу.|Для домика можно выбрать чтение.',
    'Купить книгу',
    'Читать свою',
    _SceneKind.spend,
  ),
  _Scene(
    'sorting',
    '🧺',
    'Разобрать вещи',
    'Соседу нужно рассортировать вещи.|В корзине всё перепуталось.|Финни заметил работу на полке.|Кто-то просит помочь с порядком.',
    'Помочь разобрать',
    'Отдохнуть',
    _SceneKind.work,
  ),
  _Scene(
    'rain_drums',
    '🥁',
    'Ритм на столе',
    'Финни придумал новый ритм.|В домике можно устроить концерт.|Ложки звучат как барабаны.|Финни хочет сыграть мелодию.',
    'Устроить концерт',
    'Слушать музыку',
    _SceneKind.play,
  ),
  _Scene(
    'window',
    '🪟',
    'Чистое окно',
    'Сосед просит помочь с окном.|На стекле остались капли.|Финни хочет помочь сделать дом светлее.|Для соседки есть маленькое поручение.',
    'Помочь соседке',
    'Сначала отдохнуть',
    _SceneKind.work,
  ),
  _Scene(
    'blanket',
    '🛏️',
    'Уютный уголок',
    'Из пледа можно построить домик.|Финни ищет место для отдыха.|Подушка лежит совсем рядом.|В комнате стало особенно уютно.',
    'Построить укрытие',
    'Полежать спокойно',
    _SceneKind.quiet,
  ),
  _Scene(
    'fruit',
    '🍎',
    'Фруктовая корзина',
    'На столе лежат свежие фрукты.|Финни вспоминает про обед.|В лавке сегодня пахнет яблоками.|После прогулки хочется перекусить.',
    'Выбрать обед',
    'Проверить кладовку',
    _SceneKind.meal,
  ),
  _Scene(
    'kite',
    '🪁',
    'Лёгкий ветер',
    'Воздушный змей просится в небо.|Финни смотрит на облака.|На площадке появился ветерок.|Соседи зовут на улицу.',
    'Погулять',
    'Играть дома',
    _SceneKind.explore,
  ),
  _Scene(
    'fair',
    '🎪',
    'Маленькая ярмарка',
    'В киоске продают забавный значок.|На ярмарке появилась новая игрушка.|Финни увидел блестящий сувенир.|У палатки разложены маленькие подарки.',
    'Купить подарок',
    'Сохранить монеты',
    _SceneKind.spend,
  ),
  _Scene(
    'cat',
    '🐱',
    'Соседский кот',
    'Кот заглянул к Финни в гости.|За дверью слышно тихое мяуканье.|Соседский кот хочет поиграть.|Финни встретил пушистого друга.',
    'Поиграть вместе',
    'Посидеть рядом',
    _SceneKind.play,
  ),
  _Scene(
    'paths',
    '🌿',
    'Тропинка в саду',
    'В саду появилась новая тропинка.|Финни увидел следы на земле.|У забора виднеется зелёная дорожка.|Соседка зовёт посмотреть сад.',
    'Исследовать сад',
    'Остаться дома',
    _SceneKind.explore,
  ),
  _Scene(
    'shelf',
    '🪛',
    'Полка для соседа',
    'Соседу надо собрать полку.|Финни нашёл коробку с деталями.|В мастерской ждёт новое поручение.|Сосед просит подержать доску.',
    'Помочь собрать',
    'Восстановить силы',
    _SceneKind.work,
  ),
  _Scene(
    'evening_story',
    '🌙',
    'Тихая история',
    'Финни вспомнил сказку про лес.|В комнате стало спокойно.|Можно придумать добрый конец истории.|Финни просит немного тишины.',
    'Рассказать сказку',
    'Отдохнуть',
    _SceneKind.quiet,
  ),
];

BalanceCard _scenarioCard(GameState state) {
  final candidates = _scenes
      .where(
        (scene) => scene.kind != _SceneKind.work || !state.workCompletedToday,
      )
      .toList();
  final stats = state.balanceStats;
  final seed =
      (state.profile.startDate.millisecondsSinceEpoch ^
          (state.day * 0x9e3779) ^
          ((stats.cardsToday + 1) * 0x85ebca)) &
      0x7fffffff;
  final scene = candidates[seed % candidates.length];
  final lines = scene.prompts.split('|');
  final variant = (seed ~/ candidates.length) % lines.length;
  final rainy = RegExp('дожд|ливень')
      .hasMatch(state.forecast.title.toLowerCase());
  final weatherLine = rainy
      ? 'За окном дождь. '
      : state.forecast.title.toLowerCase().contains('ветер')
      ? 'За окном ветер. '
      : '';
  if (scene.kind == _SceneKind.meal) {
    final meal = _mealCard(state);
    return BalanceCard(
      id: '${scene.id}_$variant',
      icon: scene.icon,
      title: scene.title,
      prompt: '$weatherLine${lines[variant]}',
      choices: meal.choices,
    );
  }
  final first = switch (scene.kind) {
    _SceneKind.play => BalanceChoice(
      id: 'active',
      title: scene.first,
      detail: '❤️+ ⚡− 🍽️−',
      wellbeing: 0.5,
      energy: -1.5,
      satiety: -0.25,
    ),
    _SceneKind.quiet => BalanceChoice(
      id: 'active',
      title: scene.first,
      detail: '❤️+ ⚡+',
      wellbeing: 0.5,
      energy: 0.5,
    ),
    _SceneKind.work => BalanceChoice(
      id: 'work',
      title: scene.first,
      detail: '+10 🪙 · ⚡− 🍽️− ❤️−',
      opensWork: true,
    ),
    _SceneKind.spend => BalanceChoice(
      id: 'buy',
      title: '${scene.first} · 5 🪙',
      detail: '❤️+ · −5 🪙',
      coins: -5,
      wellbeing: 0.5,
    ),
    _SceneKind.explore => BalanceChoice(
      id: 'explore',
      title: scene.first,
      detail: rainy && !state.inventory.hasItem('raincoat')
          ? '❤️− ⚡− 🍽️−'
          : '❤️+ ⚡− 🍽️−',
      wellbeing: rainy && !state.inventory.hasItem('raincoat') ? -0.5 : 0.75,
      energy: -1.25,
      satiety: -0.75,
    ),
    _SceneKind.meal => throw StateError('Meal handled above'),
  };
  final second = switch (scene.kind) {
    _SceneKind.work => BalanceChoice(
      id: 'rest',
      title: scene.second,
      detail: '⚡+',
      energy: 1,
    ),
    _SceneKind.spend => BalanceChoice(
      id: 'free',
      title: scene.second,
      detail: '❤️+ · монеты остаются',
      wellbeing: 0.5,
    ),
    _ => BalanceChoice(
      id: 'calm',
      title: scene.second,
      detail: '⚡+',
      energy: 1,
    ),
  };
  return BalanceCard(
    id: '${scene.id}_$variant',
    icon: scene.icon,
    title: scene.title,
    prompt: '$weatherLine${lines[variant]}',
    choices: [first, second],
  );
}
