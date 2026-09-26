class GoalVisualStage {
  final int stageIndex; // 0..4
  final String title;
  final String description;
  final String icon;

  const GoalVisualStage({
    required this.stageIndex,
    required this.title,
    required this.description,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'stageIndex': stageIndex,
    'title': title,
    'description': description,
    'icon': icon,
  };

  factory GoalVisualStage.fromJson(Map<String, dynamic> json) => GoalVisualStage(
    stageIndex: json['stageIndex'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    icon: json['icon'] as String,
  );
}

class GoalDefinition {
  final String id;
  final String name;
  final String icon;
  final int targetCost;
  final String description;
  final List<GoalVisualStage> stages;

  const GoalDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetCost,
    required this.description,
    required this.stages,
  });

  GoalVisualStage getStageForProgress(int savedAmount) {
    if (stages.isEmpty) {
      return GoalVisualStage(
        stageIndex: 0,
        title: name,
        description: description,
        icon: icon,
      );
    }
    final fraction = (savedAmount / targetCost).clamp(0.0, 1.0);
    final index = (fraction * (stages.length - 1)).floor();
    return stages[index.clamp(0, stages.length - 1)];
  }
}

class GoalState {
  final String goalId;
  final int savedAmount;
  final int targetAmount;
  final bool isCompleted;

  const GoalState({
    required this.goalId,
    required this.savedAmount,
    required this.targetAmount,
    this.isCompleted = false,
  });

  double get progress => targetAmount > 0 
      ? (savedAmount / targetAmount).clamp(0.0, 1.0) 
      : 0.0;

  int get visualStageIndex => (progress * 4).floor().clamp(0, 4);

  GoalState copyWith({
    String? goalId,
    int? savedAmount,
    int? targetAmount,
    bool? isCompleted,
  }) {
    return GoalState(
      goalId: goalId ?? this.goalId,
      savedAmount: savedAmount ?? this.savedAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'savedAmount': savedAmount,
    'targetAmount': targetAmount,
    'isCompleted': isCompleted,
  };

  factory GoalState.fromJson(Map<String, dynamic> json) => GoalState(
    goalId: json['goalId'] as String,
    savedAmount: json['savedAmount'] as int,
    targetAmount: json['targetAmount'] as int,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}
