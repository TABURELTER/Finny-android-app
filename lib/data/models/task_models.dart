enum TaskCategory {
  budget, // Бюджетирование и распределение
  savings, // Накопления и цели
  purchase, // Выбор покупок и подготовка впрок
}

class FinancialTask {
  final String id;
  final int day;
  final TaskCategory category;
  final String title;
  final String description;
  final String prompt;
  final String educationalFeedback;
  final TaskScenario? scenario;

  const FinancialTask({
    required this.id,
    required this.day,
    required this.category,
    required this.title,
    required this.description,
    required this.prompt,
    required this.educationalFeedback,
    this.scenario,
  });
}

/// Content-only choice scenario. New situations can reuse the challenge screen
/// without adding another task ID to its game logic.
class TaskScenario {
  final String situation;
  final String instruction;
  final String takeaway;
  final List<TaskScenarioOption> options;

  const TaskScenario({
    required this.situation,
    required this.instruction,
    required this.takeaway,
    required this.options,
  });
}

class TaskScenarioOption {
  final String title;
  final String hint;
  final String feedback;

  const TaskScenarioOption({
    required this.title,
    required this.hint,
    required this.feedback,
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
