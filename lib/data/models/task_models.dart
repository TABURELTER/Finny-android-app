enum TaskCategory {
  budget,   // Бюджетирование и распределение
  savings,  // Накопления и цели
  purchase  // Выбор покупок и подготовка впрок
}

class FinancialTask {
  final String id;
  final int day;
  final TaskCategory category;
  final String title;
  final String description;
  final String prompt;
  final String educationalFeedback;

  const FinancialTask({
    required this.id,
    required this.day,
    required this.category,
    required this.title,
    required this.description,
    required this.prompt,
    required this.educationalFeedback,
  });
}

class CompletedTask {
  final String taskId;
  final int day;
  final String outcomeDescription;

  const CompletedTask({
    required this.taskId,
    required this.day,
    required this.outcomeDescription,
  });

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'day': day,
    'outcomeDescription': outcomeDescription,
  };

  factory CompletedTask.fromJson(Map<String, dynamic> json) => CompletedTask(
    taskId: json['taskId'] as String,
    day: json['day'] as int,
    outcomeDescription: json['outcomeDescription'] as String,
  );
}
