enum ItemCategory {
  need,     // Базовые потребности (еда на 1 день)
  reserve,  // Запасы на будущее (еда на 3/5 дней, дождевик, ремкомплект)
  want,     // Сиюминутные желания (игрушки, мяч, робот)
  useful    // Полезное для дома (лежанка, лампа)
}

class ShopItem {
  final String id;
  final String name;
  final String icon;
  final int price;
  final ItemCategory category;
  final String description;
  final String immediateEffect;
  final String practicalUse;
  final int foodDaysProvided;
  final bool isPermanent;

  const ShopItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.category,
    required this.description,
    required this.immediateEffect,
    required this.practicalUse,
    this.foodDaysProvided = 0,
    this.isPermanent = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'price': price,
    'category': category.name,
    'description': description,
    'immediateEffect': immediateEffect,
    'practicalUse': practicalUse,
    'foodDaysProvided': foodDaysProvided,
    'isPermanent': isPermanent,
  };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    price: json['price'] as int,
    category: ItemCategory.values.byName(json['category'] as String),
    description: json['description'] as String,
    immediateEffect: json['immediateEffect'] as String,
    practicalUse: json['practicalUse'] as String,
    foodDaysProvided: json['foodDaysProvided'] as int? ?? 0,
    isPermanent: json['isPermanent'] as bool? ?? false,
  );
}
