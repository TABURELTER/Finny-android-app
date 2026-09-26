import 'event_models.dart';

class PurchaseRecord {
  final String id;
  final String itemId;
  final String itemName;
  final int cost;
  final int day;

  const PurchaseRecord({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.cost,
    required this.day,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'itemName': itemName,
    'cost': cost,
    'day': day,
  };

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) => PurchaseRecord(
    id: json['id'] as String,
    itemId: json['itemId'] as String,
    itemName: json['itemName'] as String,
    cost: json['cost'] as int,
    day: json['day'] as int,
  );
}

class DaySummaryRecord {
  final int day;
  final int income;
  final int spent;
  final int saved;
  final int foodReserve;
  final FinnyMood mood;
  final String moodReason;
  final String reflection;
  final int? plannedNeeds;
  final int? plannedWants;
  final int? plannedReserve;
  final int? plannedSavings;
  final int actualNeeds;
  final int actualWants;

  /// Cash still in the wallet at the end of a day for newly recorded days.
  /// Older saved summaries used [actualReserve] for reserve spending instead.
  final int actualReserve;

  /// Money spent on supplies for later or on an unexpected event today.
  final int actualReserveSpent;

  /// Distinguishes new cash accounting from summaries written by older builds.
  final bool reserveIsCash;

  bool get followedPlan =>
      plannedNeeds != null &&
      actualNeeds <= plannedNeeds! &&
      actualWants <= plannedWants! &&
      (reserveIsCash
          ? actualReserveSpent <= plannedReserve! &&
                actualReserve + actualReserveSpent >= plannedReserve!
          : actualReserve <= plannedReserve!) &&
      saved >= plannedSavings! &&
      foodReserve > 0;

  const DaySummaryRecord({
    required this.day,
    required this.income,
    required this.spent,
    required this.saved,
    required this.foodReserve,
    required this.mood,
    required this.moodReason,
    required this.reflection,
    this.plannedNeeds,
    this.plannedWants,
    this.plannedReserve,
    this.plannedSavings,
    this.actualNeeds = 0,
    this.actualWants = 0,
    this.actualReserve = 0,
    this.actualReserveSpent = 0,
    this.reserveIsCash = true,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'income': income,
    'spent': spent,
    'saved': saved,
    'foodReserve': foodReserve,
    'mood': mood.name,
    'moodReason': moodReason,
    'reflection': reflection,
    'plannedNeeds': plannedNeeds,
    'plannedWants': plannedWants,
    'plannedReserve': plannedReserve,
    'plannedSavings': plannedSavings,
    'actualNeeds': actualNeeds,
    'actualWants': actualWants,
    'actualReserve': actualReserve,
    'actualReserveSpent': actualReserveSpent,
    'reserveIsCash': reserveIsCash,
  };

  factory DaySummaryRecord.fromJson(Map<String, dynamic> json) =>
      DaySummaryRecord(
        day: json['day'] as int,
        income: json['income'] as int,
        spent: json['spent'] as int,
        saved: json['saved'] as int,
        foodReserve: json['foodReserve'] as int,
        mood: FinnyMood.values.byName(json['mood'] as String),
        moodReason: json['moodReason'] as String,
        reflection: json['reflection'] as String,
        plannedNeeds: json['plannedNeeds'] as int?,
        plannedWants: json['plannedWants'] as int?,
        plannedReserve: json['plannedReserve'] as int?,
        plannedSavings: json['plannedSavings'] as int?,
        actualNeeds: json['actualNeeds'] as int? ?? 0,
        actualWants: json['actualWants'] as int? ?? 0,
        actualReserve: json['actualReserve'] as int? ?? 0,
        actualReserveSpent: json['actualReserveSpent'] as int? ?? 0,
        reserveIsCash: json['reserveIsCash'] as bool? ?? false,
      );
}
