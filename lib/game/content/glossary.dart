class GlossaryTerm {
  final String term;
  final String icon;
  final String definition;
  final String childExample;

  const GlossaryTerm({
    required this.term,
    required this.icon,
    required this.definition,
    required this.childExample,
  });
}

final List<GlossaryTerm> kFinancialGlossary = [
  const GlossaryTerm(
    term: 'Потребности (Нужно)',
    icon: '🍎',
    definition: 'Вещи, без которых нельзя обойтись: еда, тепло, крыша над головой.',
    childExample: 'Еда для Финни — это потребность. Если её нет, питомец будет голодать.',
  ),
  const GlossaryTerm(
    term: 'Желания (Хочу)',
    icon: '🧸',
    definition: 'Вещи, которые приносят радость и веселье, но без них можно прожить.',
    childExample: 'Заводной робот или мячик — это желания. Они радуют, но еда важнее.',
  ),
  const GlossaryTerm(
    term: 'Запас (Резерв)',
    icon: '📦',
    definition: 'Покупка полезных вещей заранее, чтобы быть готовым к неожиданностям.',
    childExample: 'Купить еду на 5 дней со скидкой или дождевик до ливня — это разумный запас.',
  ),
  const GlossaryTerm(
    term: 'Бюджет',
    icon: '📋',
    definition: 'План того, сколько монет ты получил и как собираешься их потратить.',
    childExample: 'Когда ты утром решаешь: сколько отложить, а сколько потратить — ты строишь бюджет.',
  ),
  const GlossaryTerm(
    term: 'Копилка',
    icon: '🏦',
    definition: 'Безопасное место, где монеты хранятся для покупки большой мечты.',
    childExample: 'Деньги из копилки не тратят на мелочи, чтобы быстрее построить Ракету!',
  ),
  const GlossaryTerm(
    term: 'Финансовая цель',
    icon: '🎯',
    definition: 'Большая мечта, на которую нужно копить монеты несколько дней.',
    childExample: 'Ракета или Домик на дереве — это твоя главная цель в игре.',
  ),
  const GlossaryTerm(
    term: 'Доход',
    icon: '💰',
    definition: 'Монеты, которые ты получаешь каждый день или зарабатываешь трудом.',
    childExample: 'Утренние монеты и награда за помощь соседям — это твой доход.',
  ),
  const GlossaryTerm(
    term: 'Непредвиденные траты',
    icon: '⚡',
    definition: 'События, которые нельзя было точно запланировать: поломка или праздник.',
    childExample: 'Протечка крыши в ливень — неожиданность, где выручает подушка безопасности.',
  ),
];
