enum FinnyMood {
  happy,   // 😊 Счастлив
  good,    // 🙂 Доволен
  normal,  // 😐 Нормально
  worried  // 😟 Обеспокоен
}

class EventChoice {
  final String id;
  final String title;
  final int cost;
  final String? requiredItemId;    // Если есть предмет (например, raincoat или repair_kit)
  final String? freeWithItemId;    // Бесплатно, если есть предмет
  final String immediateFeedback;  // "Крыша починена!"
  final String consequenceText;   // "Теперь в доме тепло и сухо"
  final FinnyMood moodEffect;
  final int? foodReserveChange;    // Например, если поделились едой

  const EventChoice({
    required this.id,
    required this.title,
    required this.cost,
    this.requiredItemId,
    this.freeWithItemId,
    required this.immediateFeedback,
    required this.consequenceText,
    required this.moodEffect,
    this.foodReserveChange,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cost': cost,
    'requiredItemId': requiredItemId,
    'freeWithItemId': freeWithItemId,
    'immediateFeedback': immediateFeedback,
    'consequenceText': consequenceText,
    'moodEffect': moodEffect.name,
    'foodReserveChange': foodReserveChange,
  };

  factory EventChoice.fromJson(Map<String, dynamic> json) => EventChoice(
    id: json['id'] as String,
    title: json['title'] as String,
    cost: json['cost'] as int,
    requiredItemId: json['requiredItemId'] as String?,
    freeWithItemId: json['freeWithItemId'] as String?,
    immediateFeedback: json['immediateFeedback'] as String,
    consequenceText: json['consequenceText'] as String,
    moodEffect: FinnyMood.values.byName(json['moodEffect'] as String),
    foodReserveChange: json['foodReserveChange'] as int?,
  );
}

class EventDefinition {
  final String id;
  final int triggerDay;
  final String title;
  final String description;
  final String icon;
  final List<EventChoice> choices;

  const EventDefinition({
    required this.id,
    required this.triggerDay,
    required this.title,
    required this.description,
    required this.icon,
    required this.choices,
  });
}
