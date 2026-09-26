import '../../data/models/task_models.dart';

/// Six practice activities with distinct actions, available across five days.
/// Stable IDs preserve progress in existing local profiles.
final List<FinancialTask> kFinancialTasks = [
  const FinancialTask(
    id: 'task_day_2', day: 1, category: TaskCategory.budget,
    title: 'Три конверта',
    description: 'Разложи деньги на необходимое, радости и мечту.',
    prompt: 'У Финни 30 монет. Еда стоит 7. Отложи хотя бы 5 на мечту, остальное распредели сам.',
    educationalFeedback: 'Нужное лучше предусмотреть до покупки желаемого.',
  ),
  const FinancialTask(
    id: 'task_day_3', day: 3, category: TaskCategory.savings,
    title: 'Дорожка к мечте',
    description: 'Попробуй запланировать маленькие взносы на три дня.',
    prompt: 'Каждый день есть 20 монет. Наметь небольшой взнос в копилку на каждый из трёх дней.',
    educationalFeedback: 'Несколько небольших взносов складываются в большую сумму.',
  ),
  const FinancialTask(
    id: 'task_day_4', day: 2, category: TaskCategory.purchase,
    title: 'Корзина на три дня',
    description: 'Сравни цену отдельных завтраков и набора.',
    prompt: 'Завтрак стоит 7, а набор на три дня — 18. Если нужны все три, какую корзину возьмёшь?',
    educationalFeedback: 'Сравни итоговую цену и проверь, пригодится ли весь набор.',
  ),
  const FinancialTask(
    id: 'task_day_5', day: 2, category: TaskCategory.purchase,
    title: 'Проверь сдачу',
    description: 'Собери правильную сдачу из игровых монет.',
    prompt: 'Ты заплатил 20 монет за вещь ценой 12. Сколько монет нужно получить обратно?',
    educationalFeedback: 'Сдачу можно проверить вычитанием: уплачено минус цена.',
  ),
  const FinancialTask(
    id: 'task_day_6', day: 4, category: TaskCategory.budget,
    title: 'Что оставить на завтра?',
    description: 'Посмотри, как сегодняшнее решение меняет завтрашний день.',
    prompt: 'У тебя 20 монет. Завтра нужна еда за 7. Выбери действие и посмотри, что останется.',
    educationalFeedback: 'У каждого выбора есть цена и возможность изменить план.',
  ),
  const FinancialTask(
    id: 'task_day_7', day: 5, category: TaskCategory.savings,
    title: 'План Б для крыши',
    description: 'Сравни ремонт, заплатку и ожидание при неожиданной трате.',
    prompt: 'Дождь повредил крышу. В кошельке 10, в копилке 20. Как справиться?',
    educationalFeedback: 'Запас помогает при неожиданности, но его использование отдаляет мечту.',
  ),
];
