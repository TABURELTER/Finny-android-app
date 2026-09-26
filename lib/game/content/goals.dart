import '../../data/models/goal_models.dart';

final List<GoalDefinition> kAvailableGoals = [
  const GoalDefinition(
    id: 'rocket',
    name: 'Космическая ракета',
    icon: '🚀',
    targetCost: 100,
    description: 'Настоящая межзвёздная ракета для полёта к звёздам!',
    stages: [
      GoalVisualStage(
        stageIndex: 0,
        title: 'Чертежи и металл',
        description: 'Мы собрали первые чертежи и груду блестящих деталей.',
        icon: '📐',
      ),
      GoalVisualStage(
        stageIndex: 1,
        title: 'Основание и двигатели',
        description: 'Установлена стартовая опора и мощные реактивные турбины.',
        icon: '⚙️',
      ),
      GoalVisualStage(
        stageIndex: 2,
        title: 'Корпус и иллюминаторы',
        description: 'Белоснежный корпус собран! В круглые иллюминаторы виден космос.',
        icon: '🛰️',
      ),
      GoalVisualStage(
        stageIndex: 3,
        title: 'Кабина пилота',
        description: 'Установлен штурвал, мягкое кресло для Финни и приборы.',
        icon: '💺',
      ),
      GoalVisualStage(
        stageIndex: 4,
        title: 'Готовая ракета!',
        description: 'Ракета сияет на стартовой площадке! Финни готов к полёту!',
        icon: '🚀',
      ),
    ],
  ),
  const GoalDefinition(
    id: 'treehouse',
    name: 'Домик на дереве',
    icon: '🏠',
    targetCost: 80,
    description: 'Тайное убежище на ветвях векового дуба с видом на лес.',
    stages: [
      GoalVisualStage(
        stageIndex: 0,
        title: 'Доски и балки',
        description: 'Заготовлены крепкие брёвна и доски для пола.',
        icon: '🪵',
      ),
      GoalVisualStage(
        stageIndex: 1,
        title: 'Платформа на ветвях',
        description: 'Надёжная площадка закреплена высоко над землёй.',
        icon: '🪜',
      ),
      GoalVisualStage(
        stageIndex: 2,
        title: 'Стены и крыша',
        description: 'Появились деревянные стены и крыша из сосновой коры.',
        icon: '🏡',
      ),
      GoalVisualStage(
        stageIndex: 3,
        title: 'Окна и лесенка',
        description: 'Натянута верёвочная лестница и вставлены уютные окошки.',
        icon: '🪟',
      ),
      GoalVisualStage(
        stageIndex: 4,
        title: 'Уютный домик!',
        description: 'Развевается флаг, внутри гамак и фонарики! Лучший домик на дереве!',
        icon: '🏕️',
      ),
    ],
  ),
  const GoalDefinition(
    id: 'skate',
    name: 'Турбо-скейт',
    icon: '🛹',
    targetCost: 60,
    description: 'Скоростной скейтборд с неоновыми светящимися колёсами.',
    stages: [
      GoalVisualStage(
        stageIndex: 0,
        title: 'Прочная доска',
        description: 'Выбрана легкая дека из канадского клена.',
        icon: '🛹',
      ),
      GoalVisualStage(
        stageIndex: 1,
        title: 'Подвески и крепления',
        description: 'Установлены стальные подвески и амортизаторы.',
        icon: '🔩',
      ),
      GoalVisualStage(
        stageIndex: 2,
        title: 'Светящиеся колёса',
        description: 'Яркие полиуретановые колеса весело светятся в темноте.',
        icon: '🛞',
      ),
      GoalVisualStage(
        stageIndex: 3,
        title: 'Неоновые наклейки',
        description: 'Доска покрыта крутыми рисунками и антискользящим слоем.',
        icon: '🎨',
      ),
      GoalVisualStage(
        stageIndex: 4,
        title: 'Супер-скейт готов!',
        description: 'Финни крутит трюки и мчится по парку быстрее ветра!',
        icon: '⚡',
      ),
    ],
  ),
];
