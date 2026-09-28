import '../../data/models/task_models.dart';

/// Six practice activities with distinct actions, available across five days.
/// Stable IDs preserve progress in existing local profiles.
final List<FinancialTask> kFinancialTasks = [
  const FinancialTask(
    id: 'task_day_2',
    day: 1,
    category: TaskCategory.budget,
    title: 'Три конверта',
    description: 'Разложи деньги на необходимое, радости и мечту.',
    prompt: 'У Финни 30 🪙. Еда стоит 7 🪙. Отложи хотя бы 5 🪙 на мечту, остальное распредели сам.',
    educationalFeedback: 'Нужное лучше предусмотреть до покупки желаемого.',
  ),
  const FinancialTask(
    id: 'task_day_3',
    day: 3,
    category: TaskCategory.savings,
    title: 'Дорожка к мечте',
    description: 'Попробуй запланировать маленькие взносы на три дня.',
    prompt: 'Каждый день есть 20 🪙. Наметь небольшой взнос в копилку на каждый из трёх дней.',
    educationalFeedback:
        'Несколько небольших взносов складываются в большую сумму.',
  ),
  const FinancialTask(
    id: 'task_day_4',
    day: 2,
    category: TaskCategory.purchase,
    title: 'Корзина на три дня',
    description: 'Сравни цену отдельных завтраков и набора.',
    prompt: 'Завтрак стоит 7 🪙, а набор на три дня — 18 🪙. Если нужны все три, какую корзину возьмёшь?',
    educationalFeedback:
        'Сравни итоговую цену и проверь, пригодится ли весь набор.',
  ),
  const FinancialTask(
    id: 'task_day_5',
    day: 2,
    category: TaskCategory.purchase,
    title: 'Проверь сдачу',
    description: 'Собери правильную сдачу из игровых монет.',
    prompt: 'Ты заплатил 20 🪙 за вещь ценой 12 🪙. Сколько 🪙 нужно получить обратно?',
    educationalFeedback:
        'Сдачу можно проверить вычитанием: уплачено минус цена.',
  ),
  const FinancialTask(
    id: 'task_day_6',
    day: 4,
    category: TaskCategory.budget,
    title: 'Что оставить на завтра?',
    description: 'Посмотри, как сегодняшнее решение меняет завтрашний день.',
    prompt: 'У тебя 20 🪙. Завтра нужна еда за 7 🪙. Выбери действие и посмотри, что останется.',
    educationalFeedback:
        'У каждого выбора есть цена и возможность изменить план.',
  ),
  const FinancialTask(
    id: 'task_day_7',
    day: 5,
    category: TaskCategory.savings,
    title: 'План Б для крыши',
    description: 'Сравни ремонт, заплатку и ожидание при неожиданной трате.',
    prompt: 'Дождь повредил крышу. В кошельке 10 🪙, в копилке 20 🪙. Как справиться?',
    educationalFeedback: 'Запас помогает при неожиданности, но его использование отдаляет мечту.',
  ),
  const FinancialTask(
    id: 'task_day_6_fair',
    day: 6,
    category: TaskCategory.purchase,
    title: 'Перед ярмаркой',
    description: 'Реши, на что хватит денег сегодня и завтра.',
    prompt: 'У Финни 12 🪙, а на завтра нет еды. На ярмарке есть значок за 10 🪙 и завтрак за 7 🪙. Что выберешь?',
    educationalFeedback: 'Когда монет мало, сначала подумай о завтрашней еде.',
    scenario: TaskScenario(
      situation: 'Кошелёк: 12 🪙 · завтрак: 7 🪙 · значок: 10 🪙',
      instruction: 'Выбери один путь и узнай, что будет завтра.',
      takeaway: 'Покупка сегодня влияет на то, что останется завтра. План можно изменить.',
      options: [
        TaskScenarioOption(
          title: 'Сначала завтрак · 7 🪙',
          hint: 'Останется 5 🪙',
          feedback: 'Завтрак на завтра готов, в кошельке останется 5 🪙. Значок можно купить позже.',
        ),
        TaskScenarioOption(
          title: 'Значок сейчас · 10 🪙',
          hint: 'Останется 2 🪙',
          feedback: 'Значок радует, но на завтрак не хватает 5 🪙. Можно заработать или попросить помощи.',
        ),
        TaskScenarioOption(
          title: 'Пока сохранить 12 🪙',
          hint: 'Оба решения ещё доступны',
          feedback: 'Монеты останутся, но еды пока нет. Перед завтрашним днём стоит вернуться к выбору.',
        ),
      ],
    ),
  ),
];
